do ->

  ###*
  # xin-navbar directive
  # @ngInject
  ###
  xinNavbar = (evalCallDefered, breadcrumbs, PubSub) =>
    restrict: 'E'
    replace: false
    templateUrl: 'scripts/xin/navbar_drt/navbar.html'
    link: (scope) =>
      scope.breadcrumbs = breadcrumbs;
      PubSub.subscribe 'user', (user) =>
        scope.user = user


  angular.module('xin_navbar', [])
  .directive('xinNavbar', xinNavbar)
