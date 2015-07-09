do =>

  ###
  # Directive
  # @ngInject
  ###
  xinPlaceholders = =>
    restrict: "C"
    link: (scope, element, attrs) ->
      angular.forEach element.find("select, xin-select"), (el) ->
        elem = angular.element(el)
        if (elem.attr('type') isnt 'checkbox')
          elem.attr().$observe 'ngModel', (v) =>
            elem.parent().addClass "filled"

  angular.module('xin_placeholders', [])
  .directive('xinPlaceholders', xinPlaceholders)

