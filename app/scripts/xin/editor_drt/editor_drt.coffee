'use strict'

angular.module('xin_editor', ['ngRoute', 'xin_session', 'appSettings', "kendo.directives"])
.directive 'xinEditor', ($location, $route, Session, SETTINGS) ->
  restrict: 'E'
  replace: true
  templateUrl: 'scripts/xin/editor_drt/editor.html'
  link: ($scope, elem, attrs) ->

'use strict'

