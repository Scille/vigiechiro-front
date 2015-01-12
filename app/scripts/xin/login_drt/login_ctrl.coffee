'use strict'


###*
 # @ngdoc function
 # @name xin.controller:LoginCtrl
 # @description
 # # LoginCtrl
 # Controller of the xin
###
angular.module('xin_login', ['ngRoute', 'xin_session', 'appSettings'])
  .controller 'LoginCtrl', ($scope, $route, $location, session, SETTINGS) ->
    $scope.api_domain = SETTINGS.API_DOMAIN
    $scope.loginWithPopup = SETTINGS.LOGIN_WITH_POPUP or false
    # Display/hide login dialogue depending on session logged state
    $scope.isLogged = session.getUserId()?
    $scope.$on 'event:auth-loginRequired', ->
      $scope.isLogged = false
      $scope.$apply()
    $scope.$on 'event:auth-loginConfirmed', ->
      $scope.isLogged = true
      $scope.$apply()
    # If a token is provided by the request, proceed to the login
    route_params = $route.current.params
    if route_params.token?
      session.login(route_params.token)
      if $scope.loginWithPopup
        window.close()
      else
        # Redirect to root path
        $location.url('/')
        $location.path('/')
  .directive 'loginDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/login_drt/login.html'
    controller: 'LoginCtrl'
