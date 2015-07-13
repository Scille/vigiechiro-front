do =>

  ###
  # Directive
  # @ngInject
  ###
  xinPlaceholders = =>
    restrict: "C"
    link: (scope, element, attrs) ->
      attrs.$observe 'ngModel', (v) =>
        element.parent().addClass "filled"

  angular.module('xin_placeholders', [])
  .directive('xinPlaceholders', xinPlaceholders)

