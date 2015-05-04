"user strict"


angular.module('xin_content', ['xin_session'])
.directive 'contentDirective', (Session) ->
  restrict: 'E'
  link: (scope, elem, attrs) ->
    elem.hide()
    Session.getUserPromise().then ->
      elem.show()
