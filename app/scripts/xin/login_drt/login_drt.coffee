do =>

  ###
  # Directive
  # @ngInject
  ###
  xinLogin = (Session, SETTINGS) =>
    restrict: 'E'
    templateUrl: 'scripts/xin/login_drt/login.html'
    link: ($scope, elem, attrs) =>
      $scope.api_domain = SETTINGS.API_DOMAIN
      $scope.user = Session.user

  ###*
  # @ngInject
  ###
  config = ($routeProvider) =>
    $routeProvider
    .when '/logout',
      controller: 'LogoutCtrl'

  ###*
  # @ngInject
  ###
  logoutCtrl = (Session) =>
    Session.logout().then (user) ->
      document.location('/')


  angular.module('xin_login', [])
  .directive('xinLogin', xinLogin)
  .config(config)
  .controller('logoutCtrl', logoutCtrl)


