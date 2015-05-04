'use strict'

angular.module('xin_login', ['ngRoute', 'xin_session', 'appSettings'])
.directive 'loginDirective', ($location, $route, Session, SETTINGS) ->
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
    elem.hide()
    Session.getUserPromise().then(
      ->
      -> elem.show() # Display login on error
    )
.config ($routeProvider) ->
  $routeProvider
  .when '/login',
    templateUrl: 'scripts/xin/login_drt/login.html'
    controller: 'LoginCtrl'
  .when '/logout',
    controller: 'LogoutCtrl'

.controller 'LoginCtrl', ($scope, Backend, Session) ->
  Session.getUserPromise().then (user) ->
## user.role = "Administrateur"
    $scope.isAdmin = false
    if user.role == "Administrateur"
      $scope.isAdmin = true
    document.location( '/moi/site')
.controller 'LogoutCtrl', ($scope, Backend, Session) ->
  Session.logout().then (user) ->
    document.location( '/')

'use strict'

