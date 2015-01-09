"user strict"


angular.module('xin_content', ['xin_session'])
  .directive 'contentDirective', (session) ->
    restrict: 'E'
    link: (scope, elem, attrs) ->
      if session.get_user_id()?
        elem.show()
      else
        elem.hide()
      scope.$on 'event:auth-loginRequired', ->
        elem.hide()
      scope.$on 'event:auth-loginConfirmed', ->
        elem.show()
