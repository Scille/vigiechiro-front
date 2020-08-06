"user strict"


angular.module('xin_content', ['xin_session'])
  .directive 'contentDirective', (session) ->
    restrict: 'E'
