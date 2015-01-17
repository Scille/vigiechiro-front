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
    'xin_user_status',
    'xin_content',
    'xin_session',
    'xin_backend',
    'xin_google_maps',
    'xin_listResource',
    'showUtilisateur',
    'displayProtocole',
    'editProtocole',
    'inscriptionsProtocoles',
    'listSites',
    'viewSite',
    'taxonView'
  ])
  .run (Backend, SETTINGS) ->
    Backend.setBaseUrl(SETTINGS.API_DOMAIN)
  .config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'scripts/views/welcome/welcome.html'
      .when '/utilisateurs',
        templateUrl: 'scripts/views/list_utilisateurs.html'
        controller: 'ListResourceCtrl'
        resolve: {resourceBackend: (Backend) -> Backend.all('utilisateurs')}
      .when '/utilisateurs/:userId',
        templateUrl: 'scripts/views/show_utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurCtrl'
      .when '/profil',
        templateUrl: 'scripts/views/show_utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurCtrl'
        resolve: {$routeParams: (session) -> return {'userId': 'moi'}}
      .when '/protocoles',
        templateUrl: 'scripts/views/list_protocoles.html'
        controller: 'ListResourceCtrl'
        resolve: {resourceBackend: (Backend) -> Backend.all('protocoles')}
      .when '/protocoles/validations',
        templateUrl: 'scripts/views/protocole/inscriptions_protocoles/inscriptions_protocoles.html'
        controller: 'ListInscriptionsProtocolesCtrl'
      .when '/protocoles/nouveau-protocole',
        templateUrl: 'scripts/views/protocole/edit_protocole/edit_protocole.html'
        controller: 'EditProtocoleCtrl'
        resolve: {action: -> 'createNew'}
      .when '/protocoles/:protocoleId',
        templateUrl: 'scripts/views/protocole/display_protocole/display_protocole.html'
        controller: 'DisplayProtocoleCtrl'
      .when '/protocoles/:protocoleId/edit',
        templateUrl: 'scripts/views/protocole/edit_protocole/edit_protocole.html'
        controller: 'EditProtocoleCtrl'
        resolve: {action: -> 'edit'}
      .when '/sites',
        templateUrl: 'scripts/views/list_sites/list_sites.html'
        controller: 'ListSitesCtrl'
      .when '/sites/nouveau-site',
        templateUrl: 'scripts/views/view_site/view_site.html'
        controller: 'CreateSiteCtrl'
      .when '/sites/:siteId',
        templateUrl: 'scripts/views/view_site/view_site.html'
        controller: 'ShowSiteCtrl'
      .when '/403',
        templateUrl: '403.html'
      .when '/404',
        templateUrl: '404.html'
      .otherwise
        redirectTo: '/404'
