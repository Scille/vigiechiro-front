'use strict'


###*
 # @ngdoc function
 # @name xin.controller:LoginCtrl
 # @description
 # # LoginCtrl
 # Controller of the xin
###
angular.module('xin_login', ['ngRoute', 'xin_session', 'appSettings'])
  .directive 'loginDirective', ($location, $route, session, SETTINGS) ->
    restrict: 'E'
    templateUrl: 'scripts/xin/login_drt/login.html'
    link: ($scope, elem, attrs) ->
      # If a token is provided by the request, proceed to the login
      routeParams = $route.current.params
      if routeParams.token?
        # Remove token in params to avoid infinite loop
        token = routeParams.token
        $location.search('token', null)
        session.login(token)
      $scope.api_domain = SETTINGS.API_DOMAIN
      elem.hide()
      session.getUserPromise().then(
        ->
        -> elem.show() # Display login on error
      )
