'use strict'


###*
 # @ngdoc overview
 # @name vigiechiroApp
 # @description
 # # vigiechiroApp
 #
 # Main module of the application.
###
angular
  .module('vigiechiroApp', [
    'ngAnimate',
    'ngCookies',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'ngResource',
    'flow',
    'appSettings',
    'xin_login',
    'xin_content',
    'xin_session',
    'xin_backend',
    'xin_google_maps',
    'utilisateurViews',
    'taxonViews',
    'protocoleViews',
    'xin_protocoles_maps'
  ])
  .run (Backend, SETTINGS) ->
    # Disable the spinner waiting for angular
    angular.element('.waiting-for-angular').hide()
    Backend.setBaseUrl(SETTINGS.API_DOMAIN)
  .config ($routeProvider, RestangularProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'scripts/views/welcome/welcome.html'
      .when '/profil',
        templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurCtrl'
        resolve: {$routeParams: (session) -> return {'userId': 'moi'}}
      .when '/403',
        templateUrl: '403.html'
      .when '/404',
        templateUrl: '404.html'
      .otherwise
        redirectTo: '/404'
  .directive 'navbarDirective', (session)->
    restrict: 'E'
    templateUrl: 'navbar.html'
    scope: {}
    link: ($scope, elem, attrs) ->
      $scope.isAdmin = false
      $scope.user = {}
      session.getIsAdminPromise().then (isAdmin) ->
        $scope.isAdmin = isAdmin
      session.getUserPromise().then (user) ->
        $scope.user = user
      $scope.logout = ->
        session.logout()
