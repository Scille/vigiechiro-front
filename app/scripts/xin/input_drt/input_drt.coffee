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
    template: '<input>'
    compile: (elem, attrs) ->
      modelName = elem.attr( 'ng-model').replace('.', '_')
      elem.attr('id', modelName)
      elem.attr('name', modelName)
      elem.attr('class', "form-control")
      elem.attr('ng-disabled', 'readOnly')
      elem.attr('type', 'checkbox')
      label = elem.attr('label')
      elem.removeAttr( 'label')
      elem.wrap( "<label></label>")
      elem.after(label)
      elem.parent().wrap( "<div class='checkbox'></div>")
      elem.parent().parent().wrap( "<div class='form-group'></div>")

  ### @ngInject ###
  xinSelect = ->
    restrict: 'E'
    priority: 20000
    replace: true
    transclude: true
    template: "<select>"
    compile: (element, attrs) ->
      modelName = element.attr( 'ng-model').replace('.', '_')
      element.attr('id', modelName)
      element.attr('name', modelName)
      element.attr('class', 'form-control')
      element.attr('ng-disabled', 'readOnly')
      link =  (scope, element, attrs, ctrl, transclude) ->
        transclude (clone) ->
          element.append(clone)
        element.wrap( "<div class='form-group'></div>")
        label = element.attr('label')
        element.removeAttr( 'label')
        element.before( "<label class='control-label'>#{label}</label>")
      return link


  ### @ngInject ###
  ### don't works, pb double transclusion with ui-select ###
  xinMselect = ->
    restrict: 'E'
    priority: 20000
    replace: true
    transclude: true
    template: "<ui-select>"
    compile: (element, attrs) ->
      modelName = element.attr( 'ng-model').replace('.', '_')
      element.attr('id', modelName)
      element.attr('name', modelName)
      element.attr('class', 'form-control')
      element.attr('multiple', '')
      element.attr('ng-disabled', 'disabled')
      element.attr('theme', 'select2')
      element.attr('search-enabled', 'true')
      link = (scope, element, attrs, ctrl, transclude) ->
        transclude (clone) ->
          element.append(clone)
        element.wrap( "<div class='form-group'></div>")
        label = element.attr('label')
        element.removeAttr( 'label')
        element.before( "<label class='control-label'>#{label}</label>")
      return link



  angular.module('xin_input', [])
  .directive 'xinInput', xinInput
  .directive 'xinCheckbox', xinCheckbox
  .directive 'xinTextarea', xinTextarea
  .directive 'xinEmail', xinEmail
  .directive 'xinSelect', xinSelect
  .directive 'xinMselect', xinMselect
