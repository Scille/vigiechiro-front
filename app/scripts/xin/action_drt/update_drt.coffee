'use strict'

angular.module('xin_update', ['ngRoute', 'xin_session', 'appSettings'])
.directive 'update', ($location, $route, Session, SETTINGS) ->
  restrict: 'E'
  templateUrl: 'scripts/xin/action_drt/update.html'
  link: ($scope, elem, attrs) ->
    $scope.hrefValue = window.location.href + "/edition"
