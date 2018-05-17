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
    'angulartics',
    'angulartics.google.analytics',
    'ngAnimate',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'flow',
    'appSettings',
    'xin_login',
    'xin_tools',
    'xin_content',
    'xin_session',
    'xin_backend',
    'xin_google_maps',
    'accueilViews',
    'utilisateurViews',
    'taxonViews',
    'protocoleViews',
    'siteViews'
    'participationViews',
    'actualiteViews',
    'donneeViews',
    'uploadParticipationViews'
  ])

  .run (Backend, SETTINGS) ->
    Backend.setBaseUrl(SETTINGS.API_DOMAIN)

  .config ($routeProvider, RestangularProvider) ->
    $routeProvider
      .when '/',
        redirectTo: '/accueil'
      .when '/profil',
        templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurController'
        resolve: {$routeParams: -> return {'userId': 'moi'}}
        breadcrumbs: ngInject ($q, session) ->
          defer = $q.defer()
          session.getUserPromise().then (user) ->
            defer.resolve(user.pseudo)
          return defer.promise
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
