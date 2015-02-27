'use strict'


angular.module('participationViews', ['ngRoute', 'textAngular', 'xin_listResource',
                                      'xin_backend', 'xin_session', 'xin_uploadFile',
                                      'xin_tools',
                                      'siteViews', 'ui.bootstrap.datetimepicker'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/participations',
        templateUrl: 'scripts/views/participation/list_participations.html'
        controller: 'ListParticipationsCtrl'
      .when '/sites/:siteId/nouvelle-participation',
        templateUrl: 'scripts/views/participation/create_participation.html'
        controller: 'CreateParticipationCtrl'
      .when '/participations/:participationId',
        templateUrl: 'scripts/views/participation/display_participation.html'
        controller: 'DisplayParticipationCtrl'
      .when '/participations/:participationId/edition',
        templateUrl: 'scripts/views/participation/create_participation.html'
        controller: 'EditParticipationController'

  .controller 'ListParticipationsCtrl', ($scope, Backend, DelayedEvent) ->
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

  .controller 'CreateParticipationCtrl', ($routeParams, $scope, $timeout, Backend) ->
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      $scope.site = site

  .directive 'createParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/create_participation_drt.html'
    controller: 'CreateParticipationDirectiveCtrl'
    scope:
      siteId: '@'
      protocoleId: '@'
      configuration: '='

  .controller 'CreateParticipationDirectiveCtrl', ($route, $scope,
                                                   session, Backend) ->
    $scope.participation =
      date_debut: new Date()
    $scope.uploaders = []
    session.getUserPromise().then (user) ->
      $scope.observateurId = user._id

    $scope.$watchCollection 'uploaders', (newValue, oldValue) ->
      if newValue != oldValue
        $scope.participationForm.$setDirty()

    $scope.checkConfiguration = (configuration) ->
      if !$scope.configuration
        return false
      for key in $scope.configuration
        if configuration == key
          return true
      return false

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
      # Retrieve the modified fields from the form
      for key, value of $scope.participationForm
        if key.charAt(0) != '$' and value.$dirty
          if key == 'date_fin'
            if $scope.participation.date_fin
              date_fin = new Date($scope.participation.date_fin)
              payload[key] = date_fin.toGMTString()
          else if key == 'date_debut'
            payload.date_debut = date_debut
          else if key == 'temperature_debut' or
             key == 'temperature_fin' or
             key == 'vent' or key == 'couverture'
            payload.meteo[key] = $scope.participation.meteo[key]
          else if key == 'detecteur_enregistreur_numero_serie' or
             key == 'micro0_position' or key == 'micro0_numero_serie' or
             key == 'micro0_hauteur' or key == 'micro1_position' or
             key == 'micro1_numero_serie' or key == 'micro1_hauteur'
            payload.configuration[key] = $scope.participation.configuration[key]
      uploadingFiles = false
      for file in $scope.uploaders
        if file.status != 'done'
          uploadingFiles = true
      if uploadingFiles
        throw "Error : Still files to upload."
      else
        console.log(payload)
        Backend.all('sites/'+$scope.siteId+'/participations').post(payload).then(
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

  .directive 'listParticipationsDirective', (session, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/list_participations_drt.html'
    scope:
      siteId: '@'
    link: (scope, elem, attrs) ->
      scope.loading = true
      attrs.$observe 'siteId', (siteId) ->
        if siteId
          params =
            where:
              site: siteId
            sort: '-date_debut'
          Backend.all('participations').getList(params).then (participations) ->
            scope.participations = participations.plain()
            scope.loading = false

  .controller 'DisplayParticipationCtrl', ($scope, $route, $routeParams,
                                           session, Backend) ->
    $scope.userId = undefined
    session.getUserPromise().then (user) ->
      $scope.userId = user._id
    Backend.one('participations', $routeParams.participationId).get()
      .then (participation) ->
        $scope.participation = participation
        console.log(participation.plain())

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
            scope.pieces_jointes = pieces_jointes.plain()

  .controller 'EditParticipationController', ($scope, $routeParams, Backend) ->
    $scope.participation = {}
    Backend.one('participations', $routeParams.participationId).get()
      .then (participation) ->
        $scope.participation = participation
