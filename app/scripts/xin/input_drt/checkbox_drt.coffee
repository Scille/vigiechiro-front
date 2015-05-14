do ->
  ###*
  # xin-checkbox directive
  # @ngInject
  ###
  xinCheckbox = ($compile) ->
    restrict: 'AE'
    priority: 10000
    replace: true
    templateUrl: 'scripts/xin/input_drt/input.html'
    link: (scope, elem, attrs) ->
      attrs.$set('id', attrs.ngModel.replace('.', '_'))
      attrs.$set('name', attrs.ngModel.replace('.', '_'))
      attrs.$set('ngChecked', attrs.ngModel)
      attrs.$set('ngDisabled', 'readOnly')
      attrs.$set('ngValue', 'true')
      attrs.$set('type', 'checkbox')


  angular.module('xin_checkbox', []).directive 'xinCheckbox', xinCheckbox

