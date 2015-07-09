do ->

  xinSection = =>
    restrict: 'E'
    transclude: true
    priority: 10000
    replace: true
    template: "<section class='well white'><ng-transclude></ng-transclude></section>"

  xinForm = =>
    restrict: 'E'
    priority: 10000
    transclude: true
    replace: true
    template: "<form class='form-floating' ng-submit='save()' novalidate='novalidate' id='xinForm' name='xinForm'><ng-transclude></ng-transclude></form>"


  angular.module('xin_tag', [])
  .directive 'xinSection', xinSection
  .directive 'xinForm', xinForm
