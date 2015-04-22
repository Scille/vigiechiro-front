'use strict'


angular.module('accueilViews', ['ngRoute', 'xin_backend', 'xin_session',
                                'xin_uploadFile'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/accueil',
        templateUrl: 'scripts/views/accueil/accueil.html'
        controller: 'AccueilController'

  .controller 'AccueilController', ($scope, Backend, session) ->
    session.getUserPromise().then (user) ->
      $scope.isAdmin = false
      if user.role == "Administrateur"
        $scope.isAdmin = true
      Backend.all('moi/sites').getList().then (sites) ->
        $scope.userSites = sites.plain()
