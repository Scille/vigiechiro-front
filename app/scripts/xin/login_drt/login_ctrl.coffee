'use strict'


###*
 # @ngdoc function
 # @name xin.controller:LoginCtrl
 # @description
 # # LoginCtrl
 # Controller of the xin
###
angular.module('xin_login', ['ngRoute', 'xin_session', 'appSettings'])
  .directive 'loginDirective', ($route, session, SETTINGS) ->
    restrict: 'E'
    templateUrl: 'scripts/xin/login_drt/login.html'
    link: ($scope, elem, attrs) ->
      # If a token is provided by the request, proceed to the login
      route_params = $route.current.params
      if route_params.token?
        session.login(route_params.token)
      $scope.api_domain = SETTINGS.API_DOMAIN
      elem.hide()
      session.getUserPromise().then(
        ->
        -> elem.show() # Display login on error
      )
