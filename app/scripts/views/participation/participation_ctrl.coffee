'use strict'

breadcrumbsGetParticipationDefer = undefined

angular.module('participationViews', ['ngRoute', 'textAngular', 'xin_listResource',
                                      'xin_backend', 'xin_session', 'xin_tools',
                                      'xin_uploadFile', 'xin_uploadFolder',
                                      'ui.bootstrap.datetimepicker'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/participations',
        templateUrl: 'scripts/views/participation/list_participations.html'
        controller: 'ListParticipationsController'
        breadcrumbs: 'Participations'
      .when '/participations/mes-participations',
        templateUrl: 'scripts/views/participation/list_participations.html'
        controller: 'ListMesParticipationsController'
        breadcrumbs: 'Mes Participations'
      .when '/sites/:siteId/nouvelle-participation',
        templateUrl: 'scripts/views/participation/create_participation.html'
        controller: 'CreateParticipationController'
        breadcrumbs: 'Nouvelle Participation'
      .when '/participations/:participationId',
        templateUrl: 'scripts/views/participation/display_participation.html'
        controller: 'DisplayParticipationController'
        breadcrumbs: ngInject ($q, $filter) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetParticipationDefer = $q.defer()
          breadcrumbsGetParticipationDefer.promise.then (participation) ->
            breadcrumbsDefer.resolve([
              ['Participations', '#/participations']
              ['Participation du ' + $filter('date')(participation.date_debut, 'medium'), '#/participations/' + participation._id]
            ])
          return breadcrumbsDefer.promise
      .when '/participations/:participationId/edition',
        templateUrl: 'scripts/views/participation/edit_participation.html'
        controller: 'EditParticipationController'
        breadcrumbs: ngInject ($q, $filter) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetParticipationDefer = $q.defer()
          breadcrumbsGetParticipationDefer.promise.then (participation) ->
            breadcrumbsDefer.resolve([
              ['Participations', '#/participations']
              ['Participation du ' + $filter('date')(participation.date_debut, 'medium'), '#/participations/' + participation._id]
              ['Édition', '#/participations/' + participation._id + '/edition']
            ])
          return breadcrumbsDefer.promise


  .controller 'ListParticipationsController', ($scope, Backend, DelayedEvent, session) ->
    $scope.title = "Toutes les participations"
    $scope.swap =
      title: "Voir mes participations"
      value: "/mes-participations"
    $scope.lookup =
      sort: "-date_debut"
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('participations')


  .controller 'ListMesParticipationsController', ($scope, Backend, DelayedEvent, session) ->
    $scope.title = "Mes participations"
    $scope.swap =
      title: "Voir toutes les participations"
      value: ""
    $scope.lookup =
      sort: "-date_debut"
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('moi/participations')


  .controller 'CreateParticipationController', ($routeParams, $scope, $timeout, Backend) ->
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      $scope.site = site


  .directive 'createParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/create_participation_drt.html'
    controller: 'CreateParticipationDirectiveController'
    scope:
      site: '='


  .controller 'CreateParticipationDirectiveController', ($route, $scope,
                                                         session, Backend) ->
    $scope.participation =
      date_debut: new Date()
    $scope.fileUploader = []
    $scope.folderUploader = []

    $scope.$watchCollection 'fileUploader', (newValue, oldValue) ->
      if newValue != oldValue
        $scope.participationForm.$setDirty()
        for i in [oldValue.length..newValue.length-1]
          $scope.checkFileName(newValue[i])
    $scope.$watchCollection 'folderUploader', (newValue, oldValue) ->
      if newValue != oldValue
        $scope.participationForm.$setDirty()
        for i in [oldValue.length..newValue.length-1]
          for file in newValue[i].uploaders
            $scope.checkFileName(file)

    $scope.checkFileName = (file) ->
      if not file?
        return
      if file.file.type in ['image/png', 'image/png', 'image/jpeg']
        return
      patt =
        'CARRE': /^Cir\d+-\d+-Pass\d+-Tron\d+-Chiro_[01]_\d+_000.(wav|ta|tac)$/
        'POINT_FIXE': /^Car\d+-\d\d\d\d-Pass\d+-([A-H][12]|Z[1-9])_[01]_\d+_\d+_\d+.(wav|ta|tac)$/
        'ROUTIER': /^Cir\d+-\d+-Pass\d+-Tron\d+-Chiro_[01]_\d+_000.(wav|ta|tac)$/
      res = patt[$scope.site.protocole.type_site].test(file.file.name)
      if !res
        throw "Error : bad file name format "+file.file.name

    $scope.saveParticipation = ->
      $scope.submitted = true
      if (not $scope.participationForm.$valid or
          not $scope.participationForm.$dirty)
        return
      date_debut = new Date($scope.participation.date_debut)
      date_debut = date_debut.toGMTString()
      payload =
        'date_debut': date_debut
        'commentaire': $scope.participation.commentaire
        'meteo': {}
        'configuration': {}
      if $scope.participation.date_fin?
        date_fin = new Date($scope.participation.date_fin)
        if date_fin == 'Invalid Date'
          $scope.participationForm.date_fin.$error.$invalid = true
          return
        if date_fin < date_debut
          $scope.participationForm.date_fin.$error.younger_than_date_debut = true
          return
        payload.date_fin = date_fin.toGMTString()
      # Retrieve the modified fields from the form
      for key, value of $scope.participationForm
        if key.charAt(0) != '$' and value.$dirty
          if key in ['temperature_debut', 'temperature_fin', 'vent', 'couverture']
            if $scope.participation.meteo[key]?
              payload.meteo[key] = $scope.participation.meteo[key]
          else if key in ['detecteur_enregistreur_numero_serie',
                          'micro0_position','micro0_numero_serie',
                          'micro0_hauteur', 'micro1_position',
                          'micro1_numero_serie', 'micro1_hauteur']
            if $scope.participation.configuration[key]?
              payload.configuration[key] = $scope.participation.configuration[key]
      # Check files
      for file in $scope.fileUploader or []
        if file.status != 'done'
          $scope.participationForm.pieces_jointes = {$error: {uploading: true}}
          return
      for folder in $scope.folderUploader
        for file in folder.uploaders
          if file.status != 'done'
            $scope.participationForm.pieces_jointes = {$error: {uploading: true}}
            return
      # Post
      Backend.all('sites/'+$scope.site._id+'/participations').post(payload).then(
        (participation) ->
          Backend.one('participations', participation._id).get().then (participation) ->
            if $scope.fileUploader.length == 0 && $scope.folderUploader.length == 0
              window.location = '#/participations/'+participation._id
              return
            else
            payload =
              pieces_jointes: []
            for file in $scope.fileUploader
              payload.pieces_jointes.push(file.id)
            for folder in $scope.folderUploader
              for file in folder.uploaders
                payload.pieces_jointes.push(file.id)
            participation.customPUT(payload, 'pieces_jointes').then(
              -> window.location = '#/participations/'+participation._id
              -> throw "Error : PUT files"
            )
        (error) -> throw "Error : participation save "+error
      )


  .directive 'listParticipationsDirective', (session, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/list_participations_drt.html'
    scope:
      siteId: '@'
    link: (scope, elem, attrs) ->
      scope.loading = true
      attrs.$observe 'siteId', (siteId) ->
        if siteId
          Backend.all('sites/'+siteId+'/participations').getList()
            .then (participations) ->
              scope.participations = participations.plain()
              scope.loading = false


  .controller 'DisplayParticipationController', ($scope, $route, $routeParams,
                                           session, Backend) ->
    $scope.userId = undefined
    session.getUserPromise().then (user) ->
      $scope.userId = user._id
    Backend.one('participations', $routeParams.participationId).get()
      .then (participation) ->
        if breadcrumbsGetParticipationDefer?
          breadcrumbsGetParticipationDefer.resolve(participation)
          breadcrumbsGetParticipationDefer = undefined
        $scope.participation = participation

    $scope.addPost = ->
      payload =
        message: $scope.post
      $scope.participation.customPUT(payload, 'messages').then(
        -> $route.reload()
        (error) -> throw error
      )


  .directive 'displayParticipationDirective', (Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/display_participation_drt.html'
    scope:
      participation: '='
    link: (scope, elem, attrs) ->
      scope.isObjectEmpty = (obj) ->
        if !obj
          return false
        length = Object.keys(obj).length
        if length
          return false
        return true
      scope.displayFiles = ->
        Backend.one('participations/'+scope.participation._id+'/pieces_jointes')
          .get().then (pieces_jointes) ->
            scope.pieces_jointes = pieces_jointes.plain().pieces_jointes


  .controller 'EditParticipationController', ($scope, $routeParams, Backend) ->
    $scope.participation = {}
    Backend.one('participations', $routeParams.participationId).get()
      .then (participation) ->
        if breadcrumbsGetParticipationDefer?
          breadcrumbsGetParticipationDefer.resolve(participation)
          breadcrumbsGetParticipationDefer = undefined
        $scope.participation = participation
        Backend.one('protocoles', participation.site.protocole).get()
          .then (protocole) ->
            $scope.participation.site.protocole = protocole.plain()


  .directive 'editParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/create_participation_drt.html'
    controller: 'EditParticipationDirectiveController'
    scope:
      participation: '='


  .controller 'EditParticipationDirectiveController', ($route, $scope,
                                                       session, Backend) ->
    $scope.uploaders = []

    $scope.$watchCollection 'uploaders', (newValue, oldValue) ->
      if newValue != oldValue
        $scope.participationForm.$setDirty()

    $scope.saveParticipation = ->
      $scope.submitted = true
      if (not $scope.participationForm.$valid or
          not $scope.participationForm.$dirty)
        return
      date_debut = new Date($scope.participation.date_debut)
      date_debut = date_debut.toGMTString()
      payload =
        'date_debut': date_debut
        'commentaire': $scope.participation.commentaire
        'meteo': {}
        'configuration': {}
      # date fin
      if $scope.participation.date_fin?
        date_fin = new Date($scope.participation.date_fin)
        if date_fin == 'Invalid Date'
          $scope.participationForm.date_fin.$error.$invalid = true
          return
        if date_fin < date_debut
          $scope.participationForm.date_fin.$error.younger_than_date_debut = true
          return
        payload.date_fin = date_fin.toGMTString()
      # Retrieve the modified fields from the form
      for key, value of $scope.participationForm
        if key.charAt(0) != '$' and value.$dirty
          if key == 'temperature_debut' or
             key == 'temperature_fin' or
             key == 'vent' or key == 'couverture'
            if $scope.participation.meteo[key]?
              payload.meteo[key] = $scope.participation.meteo[key]
          else if key == 'detecteur_enregistreur_numero_serie' or
             key == 'micro0_position' or key == 'micro0_numero_serie' or
             key == 'micro0_hauteur' or key == 'micro1_position' or
             key == 'micro1_numero_serie' or key == 'micro1_hauteur'
            if $scope.participation.configuration[key]?
              payload.configuration[key] = $scope.participation.configuration[key]
      if Object.keys(payload.configuration).length == 0
        delete payload.configuration
      uploadingFiles = false
      # files
      for file in $scope.uploaders
        if file.status != 'done'
          $scope.participationForm.pieces_jointes = {$error: {uploading: true}}
          return
      $scope.participation.patch(payload).then(
        (participation) ->
          Backend.one('participations', participation._id).get().then (participation) ->
            if $scope.uploaders.length == 0
              window.location = '#/participations/'+participation._id
              return
            else
            payload =
              wav: []
              ta: []
              photos: []
            for file in $scope.uploaders
              if file.file.type == 'audio/wav' or
                 file.file.type == 'audio/x-wav'
                payload.wav.push(file.id)
              else if file.file.type == 'application/ta' or
                      file.file.type == 'application/tac'
                payload.ta.push(file.id)
              else if file.file.type == 'image/bmp' or
                      file.file.type == 'image/png' or
                      file.file.type == 'image/jpeg'
                payload.photos.push(file.id)
            participation.customPUT(payload, 'pieces_jointes').then(
              -> window.location = '#/participations/'+participation._id
              -> throw "Error : PUT files"
            )
        (error) -> throw "Error : participation save "+error
      )
