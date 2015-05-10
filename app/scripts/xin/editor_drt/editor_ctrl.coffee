'use strict'

angular.module('xin_editor', ['ngRoute', 'xin_session', 'appSettings'])
.directive 'editorDirective', ($location, $route, Session, SETTINGS) ->
  restrict: 'E'
  templateUrl: 'scripts/xin/editor_drt/editor.html'
  link: ($scope, elem, attrs) ->

'use strict'

