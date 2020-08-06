'use strict'


###*
 # @ngdoc function
 # @name xin.controller:LoginCtrl
 # @description
 # # LoginCtrl
 # Controller of the xin
###
angular.module('xin_login', ['ngRoute', 'xin_session', 'appSettings'])
  .directive 'loginDirective', ($location, $rootScope, $route, session, SETTINGS) ->
    restrict: 'E'
    templateUrl: 'scripts/xin/login_drt/login.html'
    link: ($scope, elem, attrs) ->

      # If a token is provided by the request, proceed to the login
      routeParams = $route.current.params
      if routeParams.token?
        # Remove token in params to avoid infinite loop
        token = routeParams.token
        $location.search('token', null).replace()
        session.login(token)
      $scope.api_domain = SETTINGS.API_DOMAIN

      # Handle login/content directives show here
      login_elem = elem
      content_elem = $('content-directive')

      detectLoginNeeded = (currentRoute) ->
        if currentRoute.no_login?
          # Routes without login (e.g. 404)
          content_elem.show()
          login_elem.hide()

        else
          session.getUserPromise().then(
            ->
              # Authenticated
              content_elem.show()
              login_elem.hide()
            ->
              # Login needed
              content_elem.hide()
              login_elem.show()
          )

      $rootScope.$on '$routeChangeSuccess', (currentRoute, previousRoute) ->
        detectLoginNeeded($route.current.$$route)
        return

      detectLoginNeeded($route.current.$$route)
