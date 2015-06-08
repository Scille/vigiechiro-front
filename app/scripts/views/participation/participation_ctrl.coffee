'use strict'

breadcrumbsGetParticipationDefer = undefined

makeRegExp = ($scope, type_site) ->
  patt =
    'CARRE': /^Cir.+-\d+-Pass\d+-Tron\d+-Chiro_[01]_\d+_000\.(wav|ta|tac)$/
    'POINT_FIXE': /^Car.+-\d+-Pass\d+-([A-H][12]|Z[1-9])-.*[01]_\d+_\d+_\d+\.(wav|ta|tac)$/
    'ROUTIER': /^Cir.+-\d+-Pass\d+-Tron\d+-Chiro_[01]_\d+_000\.(wav|ta|tac)$/
  exemples =
    'CARRE': 'Cir170517-2014-Pass10-Tron3-Chiro_0_20140702_000.wav'
    'POINT_FIXE': 'Car170517-2014-Pass1-C1-OB-1_20140702_224038_761.wav'
    'ROUTIER': 'Cir170517-2014-Pass10-Tron3-Chiro_1_20140702_000.wav'
  $scope.regexp = [patt[type_site]]
  $scope.fileFormatExemple = exemples[type_site]

sendFiles = ($scope, participation) ->
  payload =
    pieces_jointes: []
  for file in $scope.fileUploader.queue or []
    payload.pieces_jointes.push(file.file.id)
  for file in $scope.folderUploader.queue or []
    payload.pieces_jointes.push(file.file.id)
  participation.customPUT(payload, 'pieces_jointes').then(
    -> window.location = '#/participations/'+participation._id
    -> throw "Error : PUT files"
  )


angular.module('participationViews', ['ngRoute', 'textAngular', 'xin_listResource',
                                      'xin_backend', 'xin_session', 'xin_tools',
                                      'xin_uploadFile',
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
                                                 Backend) ->
    Backend.one('participations', $routeParams.participationId).get().then(
      (participation) ->
        if breadcrumbsGetParticipationDefer?
          breadcrumbsGetParticipationDefer.resolve(participation)
          breadcrumbsGetParticipationDefer = undefined
        $scope.participation = participation
      (error) -> window.location = '#/404'
    )
    $scope.addPost = ->
      payload =
        message: $scope.post
      $scope.participation.customPUT(payload, 'messages').then(
        -> $route.reload()
        (error) -> throw error
      )

  .directive 'displayParticipationDirective', (Backend) ->
    restrict: 'E'
    controller: 'displayParticipationDrtController'
    templateUrl: 'scripts/views/participation/display_participation_drt.html'
    scope:
      participation: '='
    link: (scope, elem, attrs) ->
      # test if an object is empty
      scope.isObjectEmpty = (obj) ->
        if !obj
          return false
        length = Object.keys(obj).length
        if length
          return false
        return true

  .controller 'displayParticipationDrtController', ($scope, Backend) ->
    $scope.$watch('participation', (participation) ->
      if participation?
        # display images
        Backend.all('participations/'+$scope.participation._id+'/pieces_jointes')
          .getList({photos: true}).then (photos) ->
            $scope.photos = photos.plain()
    )
    $scope.displayWavFiles = ->
      if not $scope.wavBackend?
        $scope.wavBackend = Backend.all('participations/'+$scope.participation._id+'/pieces_jointes')
      if not $scope.wav_lookup?
        $scope.wav_lookup =
          wav: true
    $scope.displayTaFiles = ->
      if not $scope.taBackend?
        $scope.taBackend = Backend.all('participations/'+$scope.participation._id+'/pieces_jointes')
      if not $scope.ta_lookup?
        $scope.ta_lookup =
          ta: true
    $scope.displayTcFiles = ->
      if not $scope.tcBackend?
        $scope.tcBackend = Backend.all('participations/'+$scope.participation._id+'/pieces_jointes')
      if not $scope.tc_lookup?
        $scope.tc_lookup =
          tc: true


  .controller 'CreateParticipationController', ($routeParams, $scope, $timeout, Backend) ->
    Backend.one('sites', $routeParams.siteId).get().then(
      (site) -> $scope.site = site
      (error) -> window.location = '#/404'
    )

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
      configuration: {}
    $scope.fileUploader = []
    $scope.folderUploader = []
    $scope.badFilesNames = []

    $scope.$watch 'site', (site) ->
      if site?
        makeRegExp($scope, site.protocole.type_site)
        if site.protocole.type_site in ['ROUTIER', 'CARRE']
          $scope.participation.configuration =
            detecteur_enregistreur_numero_serie: ''
            detecteur_enregistreur_type: ''
            micro_numero_serie: ''
            micro_type: ''
            piste0_expansion: ''
            piste1_expansion: ''
        else if site.protocole.type_site == 'POINT_FIXE'
          $scope.participation.configuration =
            detecteur_enregistreur_numero_serie: ''
            detecteur_enregistreur_type: ''
            micro0_position: ''
            micro0_numero_serie: ''
            micro0_type: ''
            micro0_hauteur: ''
            micro1_position: ''
            micro1_numero_serie: ''
            micro1_type: ''
            micro1_hauteur: ''

    $scope.$watchCollection 'fileUploader', (newValue, oldValue) ->
      if newValue != oldValue
        $scope.participationForm.$setDirty()
    $scope.$watchCollection 'folderUploader', (newValue, oldValue) ->
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
                          'detecteur_enregistreur_type',
                          'micro_numero_serie', 'micro_type',
                          'micro0_position','micro0_numero_serie',
                          'micro0_hauteur', 'micro0_type',
                          'micro1_position', 'micro1_type',
                          'micro1_numero_serie', 'micro1_hauteur']
            if $scope.participation.configuration[key]?
              payload.configuration[key] = $scope.participation.configuration[key]
      # Check files
      if not $scope.fileUploader.isAllComplete() or
         not $scope.folderUploader.isAllComplete()
        $scope.participationForm.pieces_jointes = {$error: {uploading: true}}
        return
      # Post
      Backend.all('sites/'+$scope.site._id+'/participations').post(payload).then(
        (participation) ->
          Backend.one('participations', participation._id).get().then (participation) ->
            if $scope.fileUploader.queue.length == 0 && $scope.folderUploader.length == 0
              window.location = '#/participations/'+participation._id
              return
            else
              sendFiles($scope, participation)
        (error) -> throw "Error : participation save "+error
      )


  .controller 'EditParticipationController', ($scope, $routeParams, Backend) ->
    $scope.participation = {}
    Backend.one('participations', $routeParams.participationId).get().then(
      (participation) ->
        if breadcrumbsGetParticipationDefer?
          breadcrumbsGetParticipationDefer.resolve(participation)
          breadcrumbsGetParticipationDefer = undefined
        $scope.participation = participation
        Backend.one('protocoles', participation.site.protocole).get()
          .then (protocole) ->
            $scope.participation.site.protocole = protocole.plain()
      (error) -> window.location = '#/404'
    )

  .directive 'editParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/create_participation_drt.html'
    controller: 'EditParticipationDirectiveController'
    scope:
      participation: '='


  .controller 'EditParticipationDirectiveController', ($route, $scope,
                                                       session, Backend) ->
    $scope.fileUploader = []
    $scope.folderUploader = []
    $scope.badFilesNames = []

    $scope.$watch 'participation.site.protocole.type_site', (type_site) ->
      if type_site?
        makeRegExp($scope, type_site)
        if type_site in ['ROUTIER', 'CARRE']
          $scope.participation.configuration =
            detecteur_enregistreur_numero_serie: $scope.participation.configuration.detecteur_enregistreur_numero_serie or ''
            detecteur_enregistreur_type: $scope.participation.configuration.detecteur_enregistreur_type or ''
            micro_numero_serie: $scope.participation.configuration.micro_numero_serie or ''
            micro_type: $scope.participation.configuration.micro_type or ''
            piste0_expansion: $scope.participation.configuration.piste0_expansion or ''
            piste1_expansion: $scope.participation.configuration.piste1_expansion or ''
        else if type_site == 'POINT_FIXE'
          $scope.participation.configuration =
            detecteur_enregistreur_numero_serie: $scope.participation.configuration.detecteur_enregistreur_numero_serie or ''
            detecteur_enregistreur_type: $scope.participation.configuration.detecteur_enregistreur_type or ''
            micro0_position: $scope.participation.configuration.micro0_position or ''
            micro0_numero_serie: $scope.participation.configuration.micro0_numero_serie or ''
            micro0_type: $scope.participation.configuration.micro0_type or ''
            micro0_hauteur: $scope.participation.configuration.micro0_hauteur or ''
            micro1_position: $scope.participation.configuration.micro1_position or ''
            micro1_numero_serie: $scope.participation.configuration.micro1_numero_serie or ''
            micro1_type: $scope.participation.configuration.micro1_type or ''
            micro1_hauteur: $scope.participation.configuration.micro1_hauteur or ''

    $scope.$watchCollection 'fileUploader', (newValue, oldValue) ->
      if newValue != oldValue
        $scope.participationForm.$setDirty()
    $scope.$watchCollection 'folderUploader', (newValue, oldValue) ->
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
        'configuration': $scope.participation.configuration
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
      uploadingFiles = false
      # Check files
      if not $scope.fileUploader.isAllComplete() or
         not $scope.folderUploader.isAllComplete()
        $scope.participationForm.pieces_jointes = {$error: {uploading: true}}
        return
      # Patch
      $scope.participation.patch(payload).then(
        (participation) ->
          Backend.one('participations', participation._id).get().then (participation) ->
            if $scope.fileUploader.length == 0 && $scope.folderUploader.length == 0
              window.location = '#/participations/'+participation._id
              return
            else
              sendFiles($scope, participation)
        (error) -> throw "Error : participation save "+error
      )
