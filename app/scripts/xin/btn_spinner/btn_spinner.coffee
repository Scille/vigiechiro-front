'use strict'


angular.module('sc-button', [])
  .directive 'scButton', ->
    restrict: 'E'
    template: "<span class=\"{{labelClass}}\" ng-show=\"labelClass\">&nbsp;&nbsp;</span>{{label}}
               <span class=\"{{waitClass}}\"></span>"
    scope:
      waitForClass: "@?"
      cancelWaitFor: "=?"
      label: "=?"
      labelClass: "=?"
    link: (scope, elem, attrs) ->
      scope.waitClass = ""

      elem[0].addEventListener('click', (e) ->
        elem[0].setAttribute("disabled", "")
        scope.waitClass = scope.waitForClass
      )

      if scope.cancelWaitFor?
        scope.cancelWaitFor.deferred = ->
          elem[0].removeAttribute("disabled")
          scope.waitClass = ""
