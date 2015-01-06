'use strict'

###*
 # @ngdoc function
 # @name xin.controller:LoginCtrl
 # @description
 # # LoginCtrl
 # Controller of the xin
###
angular.module('xin_login', ['xin_session'])
  .controller 'LoginCtrl', ($scope, $route, xin_session, RESOURCES) ->
    $scope.api_domain = RESOURCES.API_DOMAIN
    # Display/hide login dialogue depending on session logged state
    $scope.is_logged = xin_session.get_user_id()?
    $scope.$on 'event:auth-loginRequired', ->
      $scope.is_logged = false
    $scope.$on 'event:auth-loginConfirmed', ->
      $scope.is_logged = true
    # If a token is provided by the request, proceed to the login
    route_params = $route.current.params
    if route_params.token?
      xin_session.login(route_params.id, route_params.token)
      window.close()
