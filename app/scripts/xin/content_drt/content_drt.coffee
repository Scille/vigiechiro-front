"user strict"


angular.module('xin_content', ['ngRoute', 'xin_session'])
.directive 'contentDirective', ($location, $route, Session) ->
  restrict: 'E'
  templateUrl: 'scripts/xin/content_drt/content.html'
  link: ($scope, elem, attrs) ->
    Session.isLogged().then (isLogged) ->
      $scope.isLogged = isLogged

