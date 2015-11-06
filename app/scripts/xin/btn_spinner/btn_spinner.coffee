'use strict'


angular.module('sc-button', [])
  .directive 'scButton', ->
    restrict: 'E'
    template: "{{label}} <span class=\"{{waitClass}}\"></span>"
    scope:
      waitForClass: "@?"
      startWaitFor: "=?"
      cancelWaitFor: "=?"
      label: "=?"
    link: (scope, elem, attrs) ->
      scope.waitClass = ""

      if scope.startWaitFor?
        scope.startWaitFor.deferred = ->
          elem[0].setAttribute("disabled", "")
          scope.waitClass = scope.waitForClass

      if scope.cancelWaitFor?
        scope.cancelWaitFor.deferred = ->
          elem[0].removeAttribute("disabled")
          scope.waitClass = ""
