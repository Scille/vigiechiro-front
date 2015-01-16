"user strict"


angular.module('xin_content', ['xin_session'])
  .directive 'contentDirective', (session) ->
    restrict: 'E'
    link: (scope, elem, attrs) ->
      elem.hide()
      session.getUserPromise().then ->
        elem.show()
