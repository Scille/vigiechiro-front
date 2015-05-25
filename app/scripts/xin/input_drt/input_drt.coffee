do ->

  xinInput = () ->
    type: 'text'
    restrict: 'AE'
    priority: 10000
    replace: true
    templateUrl: 'scripts/xin/input_drt/input.html'
    link: (scope, elem, attrs) ->
      attrs.$set('id', attrs.ngModel.replace('.', '_'))
      attrs.$set('name', attrs.ngModel.replace('.', '_'))
      attrs.$set('ng-message', attrs.name + '$error')
      attrs.$set('class', 'form-control floating-label')
      attrs.$set('ngDisabled', 'readOnly')
      attrs.$set('type', 'text')

  xinCheckbox = () ->
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

  xinNumber = () ->
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

  xinTextarea = () ->
    restrict: 'AE'
    priority: 10000
    replace: true
    templateUrl: 'scripts/xin/input_drt/input.html'
    link: (scope, elem, attrs) ->
      attrs.$set('id', attrs.ngModel.replace('.', '_'))
      attrs.$set('name', attrs.ngModel.replace('.', '_'))
      attrs.$set('class', 'form-control floating-label')
      attrs.$set('ngDisabled', 'readOnly')
      attrs.$set('type', 'textarea')

  xinEmail = () ->
    type: 'email'
    restrict: 'AE'
    priority: 10000
    replace: true
    templateUrl: 'scripts/xin/input_drt/input.html'
    link: (scope, elem, attrs) ->
      attrs.$set('id', attrs.ngModel.replace('.', '_'))
      attrs.$set('name', attrs.ngModel.replace('.', '_'))
      attrs.$set('class', 'form-control floating-label')
      attrs.$set('ngDisabled', 'readOnly')
      attrs.$set('type', 'email')

  xinSelect = () ->
    restrict: 'AE'
    priority: 10000
    replace: true
    templateUrl: 'scripts/xin/input_drt/select.html'
    link: (scope, elem, attrs) ->
      attrs.$set('id', attrs.ngModel.replace('.', '_'))
      attrs.$set('name', attrs.ngModel.replace('.', '_'))
      attrs.$set('class', 'form-control floating-label')
      attrs.$set('ngDisabled', 'readOnly')
      attrs.$set('ngValue', 'true')


  angular.module('xin_input', [])
  .directive 'xinInput', xinInput
  .directive 'xinCheckbox', xinCheckbox
  .directive 'xinNumber', xinNumber
  .directive 'xinTextarea', xinTextarea
  .directive 'xinEmail', xinEmail
  .directive 'xinSelect', xinSelect
