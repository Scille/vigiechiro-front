do =>

  ###
  # Directive
  # @ngInject
  ###
  xinEditor = =>
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/editor_drt/editor.html'

  angular.module('xin_editor', [])
  .directive('xinEditor', xinEditor)



