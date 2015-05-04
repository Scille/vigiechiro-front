'use strict'

angular.module('xin_create', ['ngRoute', 'xin_session', 'appSettings'])
.directive 'create', ($location, $route, Session, SETTINGS) ->
  restrict: 'E'
  templateUrl: 'scripts/xin/action_drt/create.html'
  link: ($scope, elem, attrs) ->
    $scope.hrefValue = window.location.href + "/nouveau"
