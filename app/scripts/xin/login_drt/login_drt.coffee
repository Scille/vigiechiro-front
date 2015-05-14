'use strict'

angular.module('xin_login', ['ngRoute', 'xin_session', 'appSettings'])
.directive 'xinLogin', ($location, $route, Session, SETTINGS) ->
  restrict: 'E'
  templateUrl: 'scripts/xin/login_drt/login.html'
  link: ($scope, elem, attrs) ->
# If a token is provided by the request, proceed to the login
    routeParams = $route.current.params
    if routeParams.token?
# Remove token in params to avoid infinite loop
      token = routeParams.token
      $location.search('token', null).replace()
      Session.login(token)
    $scope.api_domain = SETTINGS.API_DOMAIN
    Session.isLogged().then (isLogged) ->
      $scope.isNotLogged = isLogged == false

.config ($routeProvider) ->
  $routeProvider
  .when '/logout',
    controller: 'LogoutCtrl'

.controller 'LogoutCtrl', ($scope, Backend, Session) ->
  Session.logout().then (user) ->
    document.location( '/')


