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
