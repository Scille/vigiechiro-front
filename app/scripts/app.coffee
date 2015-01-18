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
    'listSites',
    'viewSite',
    'utilisateurViews',
    'taxonViews',
    'protocoleViews'
  ])
  .run (Backend, SETTINGS) ->
    Backend.setBaseUrl(SETTINGS.API_DOMAIN)
  .config ($routeProvider, RestangularProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'scripts/views/welcome/welcome.html'
      .when '/profil',
        templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurCtrl'
        resolve: {$routeParams: (session) -> return {'userId': 'moi'}}
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
  .directive 'navbarDirective', ($location, session)->
    restrict: 'E'
    templateUrl: 'navbar.html'
    link: ($scope, elem, attrs) ->
      $scope.activePath = $location.path()
      $scope.isAdmin = false
      session.getUserPromise().then (user) ->
        $scope.isAdmin = user.role == 'Administrateur'
