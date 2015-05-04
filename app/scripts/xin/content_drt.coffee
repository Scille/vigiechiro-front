"user strict"


angular.module('xin_content', ['xin_session'])
.directive 'contentDirective', (Session) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    Session.getUserPromise().then ->
      () -> elem.show()
      () -> elem.hide()
