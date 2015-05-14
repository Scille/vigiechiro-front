do ->
  ###*
  # xin-input directive
  # @ngInject
  ###
  xinInput = ($compile) ->
    restrict: 'AE'
    priority: 10000
    replace: true
    templateUrl: 'scripts/xin/input_drt/input.html'
    link: (scope, elem, attrs) ->
      attrs.$set('id', attrs.ngModel.replace('.', '_'))
      attrs.$set('name', attrs.ngModel.replace('.', '_'))
      attrs.$set('class', 'form-control floating-label')
      attrs.$set('ngDisabled', 'readOnly')
      attrs.$set('type', 'text')


  angular.module('xin_input', []).directive 'xinInput', xinInput
