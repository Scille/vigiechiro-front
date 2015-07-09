do ->

  ### @ngInject ###
  formControl = ->
    restrict: "C"
    link: (scope, element, attrs) ->

# set initial filled
      scope.$watch attrs.ngModel, (v) =>
        element.parent().addClass "filled" if (v? and v.length > 0)

      element.bind("blur", (e) ->
        input = angular.element(e.currentTarget)
        if input.val()
          input.parent().addClass "filled"
        else
          input.parent().removeClass "filled"
        input.parent().removeClass "active"
      ).bind "focus", (e) ->
        input = angular.element(e.currentTarget)
        input.parent().addClass "active"

  angular.module('form-control', [])
  .directive 'formControl', formControl
