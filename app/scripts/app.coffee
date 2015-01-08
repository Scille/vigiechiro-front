'use strict'


angular.module('appSettings', [])
  .constant 'SETTINGS',
    API_DOMAIN: 'http://api.lvh.me:8080'
    FRONT_DOMAIN: 'http://www.lvh.me:9000'


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
    'http-auth-interceptor',
    'flow',
    'appSettings',
    'xin_session',
    'xin_geolocation',
    'xin_login',
    'xin_backend',
    'xin_user_status',
    'xin_content',
    'listUtilisateurs',
    'showUtilisateur'
  ])
  .run (Backend, SETTINGS, session) ->
    Backend.setBaseUrl(SETTINGS.API_DOMAIN)
  .config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'scripts/views/welcome/welcome.html'
      .when '/utilisateurs',
        templateUrl: 'scripts/views/list_utilisateurs/list_utilisateurs.html'
        controller: 'ListUtilisateursCtrl'
      .when '/utilisateurs/:id',
        templateUrl: 'scripts/views/show_utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurCtrl'
      .when '/404',
        templateUrl: '404.html'
      .otherwise
        redirectTo: '/404'
