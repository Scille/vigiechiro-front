'use strict'


angular.module('participationViews', ['ngRoute', 'textAngular', 'xin_listResource',
                                      'xin_backend', 'xin_session', 'xin_uploadFile',
                                      'siteViews'])
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

  .controller 'ListParticipationsCtrl', ($scope, Backend, DelayedEvent) ->
    $scope.lookup = {}
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.where = JSON.stringify(
              $text:
                $search: filterValue
          )
        else if $scope.lookup.where?
          delete $scope.lookup.where
    $scope.resourceBackend = Backend.all('participations')

  .controller 'CreateParticipationCtrl', ($routeParams, $scope, Backend) ->
    params =
      embedded: { protocole: 1 }
    Backend.one('sites', $routeParams.siteId).get(params).then (site) ->
      $scope.site = site

  .directive 'createParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/create_participation_drt.html'
    controller: 'CreateParticipationDirectiveCtrl'
    scope:
      siteId: '@'
      protocoleId: '@'

  .controller 'CreateParticipationDirectiveCtrl', ($route, $scope,
                                                   session, Backend) ->
    $scope.participation = {}
    $scope.uploaders = []
    session.getUserPromise().then (user) ->
      $scope.observateurId = user._id

    $scope.saveParticipation = ->
      $scope.submitted = true
      if (not $scope.participationForm.$valid or
          not $scope.participationForm.$dirty)
        return
      date_debut = new Date($scope.participation.date_debut)
      date_debut = date_debut.toGMTString()
      payload =
        'observateur': $scope.observateurId
        'protocole': $scope.protocoleId
        'site': $scope.siteId
        'pieces_jointes': []
      for file in $scope.uploaders
        payload.pieces_jointes.push(file.id)
      # Retrieve the modified fields from the form
      for key, value of $scope.participationForm
        if key.charAt(0) != '$' and value.$dirty
          if key == 'date_fin'
            if $scope.participation.date_fin
              date_fin = new Date($scope.participation.date_fin)
              payload.date_fin = date_fin.toGMTString()
          else if key == 'date_debut'
            payload.date_debut = date_debut
          else if key == 'temperature_debut' or
             key == 'temperature_fin' or
             key == 'vent' or key == 'couverture'
            if not payload.meteo
              payload.meteo = {}
            payload.meteo[key] = $scope.participation.meteo[key]
          else if key == 'detecteur_enregisteur_numero_serie' or
             key == 'micro0_position' or key == 'micro0_numero_serie' or
             key == 'micro0_hauteur' or key == 'micro1_position' or
             key == 'micro1_numero_serie' or key == 'micro1_hauteur'
            if not payload.configuration
              payload.configuration = {}
            payload.configuration[key] = $scope.participation.configuration[key]
          else
            payload[key] = $scope.participation[key]
      Backend.all('participations').post(payload).then(
        -> $route.reload()
        (error) -> console.log("error", error)
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
          Backend.all('participations').getList(params).then (participations) ->
            scope.participations = participations.plain()
            scope.loading = false

  .directive 'showParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/show_participation_drt.html'
    scope:
      participation: '='
      title: '@'

  .controller 'DisplayParticipationCtrl', ($scope, $route, $routeParams, session, Backend) ->
    saveParticipation = undefined
    $scope.userId = undefined
    session.getUserPromise().then (user) ->
      $scope.userId = user._id
    params =
      embedded: {
        protocole: 1
        pieces_jointes: 1
      }
    Backend.one('participations', $routeParams.participationId).get(params).then (participation) ->
      saveParticipation = participation
      $scope.participation = participation.plain()
    $scope.addPost = (post) ->
      origPosts = $scope.participation.posts
      if not origPosts?
        origPosts = []
      newPost =
        auteur: $scope.userId
        date: new Date().toGMTString()
        message: post
      origPosts.push(newPost)
      payload =
        posts: origPosts
      saveParticipation.patch(payload).then (
        -> $route.reload()
        (error) -> throw "Error patch"
      )



  .directive 'displayParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/display_participation_drt.html'
    scope:
      participation: '='
