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
      .when '/participations/:participationId',
        templateUrl: 'scripts/views/participation/display_participation.html'
        controller: 'DisplayParticipationCtrl'

  .controller 'CreateParticipationCtrl', ($route, $routeParams, $scope,
    session, Backend) ->
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
    $scope.saveParticipation = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty)
        return
      payload = {}
#        'protocole': $scope.protocoleId
#        'localites': mapProtocole.saveMap()
#        'commentaire': $scope.siteForm.commentaire.$modelValue
#        'grille_stoc': mapProtocole.getIdGrilleStoc()
      Backend.all('participations').post(payload).then(
        -> $route.reload()
        (error) -> console.log("error", error)
      )

  .controller 'DisplayParticipationCtrl', ($route, $routeParams, $scope,
    session, Backend) ->
