'use strict'

angular.module('xin_submit', ['ngRoute', 'xin_session', 'appSettings'])
.directive 'xinSubmit', ($location, $route, Session, SETTINGS) ->
  restrict: 'E'
  templateUrl: 'scripts/xin/action_drt/submit.html'
  link: ($scope, elem, attrs) ->
