'use strict'


angular.module('participationViews', ['ngRoute', 'textAngular', 'xin_listResource',
                                      'xin_backend', 'xin_session', 'siteViews'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/participations',
        templateUrl: 'scripts/views/participation/list_participations.html'
        controller: 'ListResourceCtrl'
        resolve: {resourceBackend: (Backend) -> Backend.all('participations')}
      .when '/participations/nouveau',
        templateUrl: 'scripts/views/participation/create_participation.html'
        controller: 'CreateParticipationCtrl'
#      .when '/sites/:siteId/nouvelle-participation',
#        templateUrl: 'scripts/views/participation/create_participation.html'
#        controller: 'CreateParticipationCtrl'
      .when '/participations/:participationId',
        templateUrl: 'scripts/views/participation/display_participation.html'
        controller: 'DisplayParticipationCtrl'

  .directive 'createParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/create_participation.html'
    controller: 'CreateParticipationCtrl'
    scope:
      siteId: '@'
    link: (scope, elem, attrs) ->
      scope.collapsed = true
      scope.title = 'Nouvelle participation'
      attrs.$observe('siteId', (siteId) ->
        scope.siteId = siteId
      )

  .controller 'CreateParticipationCtrl', ($route, $routeParams, $scope,
    session, Backend) ->
    $scope.participation = {}
    session.getUserPromise().then (user) ->
      $scope.observateur = user._id
    Backend.all('protocoles').getList().then((protocoles) ->
      $scope.protocoles = protocoles.plain()
    )
    $scope.$watch("participation.protocole", (newValue) ->
      if newValue?
        where = JSON.stringify(
          'protocole': newValue
        )
        Backend.all('sites').getList('where': where).then((sites) ->
          $scope.sites = sites.plain()
        )
    )
    if $scope.siteId
      Backend.one('sites', $scope.siteId).get().then (site) ->
        $scope.participation.protocole = site.protocole
        $scope.participation.site = site._id
    $scope.saveParticipation = ->
      $scope.submitted = true
      if (not $scope.participationForm.$valid or
          not $scope.participationForm.$dirty)
        return
      date_debut = new Date($scope.participation.date_debut)
      date_debut = date_debut.toGMTString()
      payload =
        'observateur': $scope.observateur
        'protocole' : $scope.participation.protocole
        'site' : $scope.participation.site
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

  .controller 'DisplayParticipationCtrl', ($route, $routeParams, $scope,
    session, Backend) ->
