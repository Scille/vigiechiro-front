do ->

  ###*
  # xin-navbar directive
  # @ngInject
  ###
  xinNavbar = (evalCallDefered, PubSub) =>
    restrict: 'E'
    templateUrl: 'scripts/xin/navbar_drt/navbar.html'
    scope: false
    link: (scope) =>
      PubSub.subscribe 'user', (user) =>
        scope.user = user


  angular.module('xin_navbar', [])
  .directive( 'xinNavbar', xinNavbar)
