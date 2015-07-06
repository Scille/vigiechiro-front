do =>

  ###
  # Directive
  # @ngInject
  ###
  xinContent = =>
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/content_drt/content.html'
    link: (scope, elem, attrs) ->

  angular.module('xin_content', [])
  .directive('xinContent', xinContent)


