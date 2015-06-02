"use strict"


angular.module('xin_content', [])
.directive 'xinContent', () ->
  restrict: 'E'
  replace: true
  templateUrl: 'scripts/xin/content_drt/content.html'
  link: (scope, elem, attrs) =>

