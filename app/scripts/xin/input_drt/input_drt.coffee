do ->

  ### @ngInject ###
  xinInput = ->
    restrict: 'E'
    priority: 20000
    replace: true
    template: "<input>"
    compile: (elem, attrs) ->
      modelName = elem.attr( 'ng-model').replace('.', '_')
      elem.attr('id', modelName)
      elem.attr('name', modelName)
      elem.attr('class', "form-control")
      elem.attr('ng-disabled', 'readOnly')
      elem.attr('type', 'text')
      label = elem.attr('label')
      elem.wrap( "<div class='form-group'></div>")
      elem.before( "<label class='control-label'>#{label}</label>")
      elem.removeAttr( 'label')


  ### @ngInject ###
  xinEmail = ->
    restrict: 'E'
    priority: 20000
    replace: true
    template: "<input>"
    compile: (elem, attrs) ->
      modelName = elem.attr( 'ng-model').replace('.', '_')
      elem.attr('id', modelName)
      elem.attr('name', modelName)
      elem.attr('class', "form-control")
      elem.attr('ng-disabled', 'readOnly')
      elem.attr('type', 'email')
      label = elem.attr('label')
      elem.wrap( "<div class='form-group'></div>")
      elem.before( "<label class='control-label'>Email</label>")
      elem.removeAttr( 'label')


  ### @ngInject ###
  xinTextarea = ->
    restrict: 'E'
    priority: 20000
    replace: true
    template: "<input>"
    compile: (elem, attrs) ->
      modelName = elem.attr( 'ng-model').replace('.', '_')
      elem.attr('id', modelName)
      elem.attr('name', modelName)
      elem.attr('class', "form-control")
      elem.attr('ng-disabled', 'readOnly')
      elem.attr('type', 'textarea')
      label = elem.attr('label')
      elem.wrap( "<div class='form-group'></div>")
      elem.before( "<label class='control-label'>#{label}</label>")
      elem.removeAttr( 'label')


  ### @ngInject ###
  xinCheckbox = ->
    restrict: 'AE'
    priority: 20000
    replace: true
    template: '<input>{{label}}'
    scope:
      label: 'bind'
    compile: (elem, attrs) ->
      modelName = elem.attr( 'ng-model').replace('.', '_')
      elem.attr('id', modelName)
      elem.attr('name', modelName)
      elem.attr('class', "form-control")
      elem.attr('ng-disabled', 'readOnly')
      elem.attr('type', 'checkbox')
      elem.wrap( "<label></label>")
      elem.parent().wrap( "<div class='checkbox'></div>")
      elem.parent().parent().wrap( "<div class='form-group'></div>")
      elem.removeAttr( 'label')


  ### @ngInject ###
  xinSelect = ->
    restrict: 'E'
    replace: true
    transclude: true
    template: "<select><ng-transclude></ng-transclude></select>"
    compile: (elem, attrs) ->
      modelName = elem.attr( 'ng-model').replace('.', '_')
      elem.attr('id', modelName)
      elem.attr('name', modelName)
      elem.attr('class', "form-control")
      elem.attr('ng-disabled', 'readOnly')
      label = elem.attr('label')
      elem.wrap( "<div class='form-group'></div>")
      elem.before( "<label class='control-label'>#{label}</label>")
      elem.removeAttr( 'label')


  angular.module('xin_input', [])
  .directive 'xinInput', xinInput
  .directive 'xinCheckbox', xinCheckbox
  .directive 'xinTextarea', xinTextarea
  .directive 'xinEmail', xinEmail
  .directive 'xinSelect', xinSelect
