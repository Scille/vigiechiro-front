"use strict"


angular.module('xin_footer', ['ngRoute', 'xin_session'])
.directive 'xinFooter', ($location, $route, Session) ->
  restrict: 'E'
  templateUrl: 'scripts/xin/footer_drt/footer.html'
