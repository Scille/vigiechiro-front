"use strict"


angular.module('xin_content', [])
.directive 'xinContent', () ->
  restrict: 'E'
  templateUrl: 'scripts/xin/content_drt/content.html'
  link: (scope, elem, attrs) =>

