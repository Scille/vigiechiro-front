do ->

  ###*
  # xin-sidebar directive
  # @ngInject
  ###
  xinSidebar = (evalCallDefered, PubSub) =>
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/navbar_drt/sidebar.html'
    link: (scope) =>
      PubSub.subscribe 'user', (user) =>
        scope.user = user


  angular.module('xin_sidebar', [])
  .directive('xinSidebar', xinSidebar)
