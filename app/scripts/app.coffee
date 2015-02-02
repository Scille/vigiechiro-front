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
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'flow',
    'appSettings',
    'xin_login',
    'xin_content',
    'xin_session',
    'xin_backend',
    'xin_google_maps',
    'accueilViews',
    'utilisateurViews',
    'taxonViews',
    'protocoleViews',
    'participationViews'
  ])

  .run (Backend, SETTINGS) ->
    Backend.setBaseUrl(SETTINGS.API_DOMAIN)

  .config ($routeProvider, RestangularProvider) ->
    $routeProvider
      .when '/',
        redirectTo: '/accueil'
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
      session.getUserPromise().then(
        (user) ->
          $scope.user = user
          # Disable the spinner waiting for angular
          angular.element('.waiting-for-angular').hide()
        ->
          # Disable the spinner even after error
          angular.element('.waiting-for-angular').hide()
      )
      $scope.logout = ->
        session.logout()
