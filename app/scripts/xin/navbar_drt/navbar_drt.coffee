do ->

  ###*
  # xin-navbar directive
  # @ngInject
  ###
  xinNavbar = (evalCallDefered, PubSub, breadcrumbs) =>
    restrict: 'E'
    templateUrl: 'scripts/xin/navbar_drt/navbar.html'
    scope: {}
    link: (scope) =>
      scope.breadcrumbs = breadcrumbs;
      PubSub.subscribe 'user', (user) =>
        scope.user = user


  angular.module('xin_navbar', [])
  .directive('xinNavbar', xinNavbar)
