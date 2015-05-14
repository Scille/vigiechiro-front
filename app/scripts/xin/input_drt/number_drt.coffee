do ->
  ###*
  # xin-number directive
  # @ngInject
  ###
  xinNumber = ($compile) ->
    restrict: 'AE'
    priority: 10000
    replace: true
    templateUrl: 'scripts/xin/input_drt/input.html'
    link: (scope, elem, attrs) ->
      attrs.$set('id', attrs.ngModel.replace('.', '_'))
      attrs.$set('name', attrs.ngModel.replace('.', '_'))
      attrs.$set('class', 'form-control floating-label')
      attrs.$set('ngDisabled', 'readOnly')
      attrs.$set('type', 'number')


  angular.module('xin_number', []).directive 'xinNumber', xinNumber
