"user strict"


angular.module('xin_content', ['xin_session'])
  .directive 'contentDirective', (session) ->
    restrict: 'E'
    link: (scope, elem, attrs) ->
      if session.getUserId()?
        elem.show()
      else
        elem.hide()
      scope.$on 'event:auth-loginRequired', ->
        elem.hide()
      scope.$on 'event:auth-loginConfirmed', ->
        elem.show()
