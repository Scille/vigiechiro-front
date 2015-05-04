'use strict'

angular.module('xin_navbar', ['ngRoute', 'xin_session', 'appSettings'])
  .directive 'navbarDirective', (evalCallDefered, $window, $rootScope, $route, SETTINGS, Session)->
    restrict: 'E'
    templateUrl: 'scripts/xin/navbar_drt/navbar.html'
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
      Session.getIsAdminPromise().then (isAdmin) ->
        $scope.isAdmin = isAdmin
      Session.getUserPromise().then(
        (user) ->
          $scope.user = user
      )
      $scope.logout = ->
        Session.logout()
