'use strict'


###*
 # @ngdoc function
 # @name xin.controller:LoginCtrl
 # @description
 # # LoginCtrl
 # Controller of the xin
###
angular.module('xin_login', ['xin_session', 'appSettings'])
  .controller 'LoginCtrl', ($scope, $route, session, SETTINGS) ->
    $scope.api_domain = SETTINGS.API_DOMAIN
    # Display/hide login dialogue depending on session logged state
    $scope.is_logged = session.getUserId()?
    $scope.$on 'event:auth-loginRequired', ->
      $scope.is_logged = false
    $scope.$on 'event:auth-loginConfirmed', ->
      $scope.is_logged = true
    # If a token is provided by the request, proceed to the login
    route_params = $route.current.params
    if route_params.token?
      session.login(route_params.token)
      window.close()
  .directive 'loginDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/login_drt/login.html'
    controller: 'LoginCtrl'
