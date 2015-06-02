do ->

  ### @ngInject ###
  xinInput = () ->
    type: 'text'
    restrict: 'AE'
    priority: 10000
    replace: true
    scope: {}
    template: "<input></input>",
    link: (scope, elem, attrs) ->
      scope.attrs = attrs
      scope.ngModel = attrs.ngModel
      scope.ngModel.$invalid = false
      attrs.$set('id', attrs.ngModel.replace('.', '_'))
      attrs.$set('name', attrs.ngModel.replace('.', '_'))
      attrs.$set('class', 'form-control floating-label')
      attrs.$set('ngDisabled', 'readOnly')
      attrs.$set('type', 'text')
      #      xinShow1 = attrs.required == '' || attrs.required
      #      xinShow2 = "#{attrs.ngModel}.$invalid && #{attrs.ngModel}.$dirty"
      #message = "<div ng-if='xinForm.#{attrs.name}.$pristine == false || xinForm.#{attrs.name}.$untouched == false'  ng-messages='xinForm.#{attrs.name}.$error' class='validation'><div ng-message='required'>This field is required</div><div ng-message='pattern'>Invalid input format</div><div ng-message='minlength'>Please use at least #{ attrs.minlength } characters</div><div ng-message='maxlength'>Please do not exceed #{ attrs.maxlength } characters</div></div>"
      # $compile(message)(scope);
      #elem.after( message)

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
