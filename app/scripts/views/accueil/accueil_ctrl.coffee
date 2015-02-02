'use strict'


angular.module('accueilViews', ['ngRoute', 'xin_backend', 'xin_session', 'siteViews'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/accueil',
        templateUrl: 'scripts/views/accueil/accueil.html'
        controller: 'AccueilCtrl'

  .controller 'AccueilCtrl', ($scope, Backend, session) ->
      session.getUserPromise().then (user) ->
        where = JSON.stringify(
          'observateur': user._id
        )
        Backend.all('sites').getList('where': where).then (sites) ->
          $scope.userSites = sites.plain()
