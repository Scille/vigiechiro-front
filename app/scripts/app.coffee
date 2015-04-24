'use strict'


###*
 # @ngdoc overview
 # @name vigiechiroApp
 # @description
 # # vigiechiroApp
 #
 # Main module of the application.
###

$.material.init();


angular
.module('vigiechiroApp', [
    'ngAnimate',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'flow',
    'appSettings',
    'xin_tools',
    'xin_content',
    'xin_session',
    'xin_backend',
    'xin_google_maps',
    'loginViews',
    'accueilViews',
    'utilisateurViews',
    'taxonViews',
    'protocoleViews',
    'participationViews',
    'actualiteViews',
    'donneeViews'
  ])

.run (Backend, SETTINGS) ->
  Backend.setBaseUrl(SETTINGS.API_DOMAIN)

.config ($routeProvider, RestangularProvider) ->
  $.material.init()
  $routeProvider
  .when '/',
    redirectTo: '/accueil'
  .when '/403',
    templateUrl: '403.html'
  .when '/404',
    templateUrl: '404.html'
  .otherwise
      redirectTo: '/404'

.directive 'navbarDirective', (evalCallDefered, $window, $rootScope, $route, SETTINGS, session)->
  restrict: 'E'
  templateUrl: 'navbar.html'
  scope: {}
  link: ($scope, elem, attrs) ->
# Handle breadcrumbs when the route change
    loadBreadcrumbs = (currentRoute) ->
      if currentRoute.breadcrumbs?
        breadcrumbsDefer = evalCallDefered(currentRoute.breadcrumbs)
        breadcrumbsDefer.then (breadcrumbs) ->
# As shorthand, breadcrumbs can be a single string
          if typeof(breadcrumbs) == "string"
            $scope.breadcrumbs = [[breadcrumbs, '']]
          else
            $scope.breadcrumbs = breadcrumbs
      else
        $scope.breadcrumbs = []
    $rootScope.$on '$routeChangeSuccess', (currentRoute, previousRoute) ->
      loadBreadcrumbs($route.current.$$route)
      return
    loadBreadcrumbs($route.current.$$route)
    $scope.isAdmin = false
    $scope.user = {}
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = true
    session.getUserPromise().then((user) ->
      $scope.user = user
    )
    $scope.logout = ->
      session.logout()



