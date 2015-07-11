do ->

  xinSection100 = =>
    restrict: 'E'
    priority: 10000
    transclude: true
    replace: true
    template: "<section class='well white xin-heightsection100'><ng-transclude></ng-transclude></section>"



  xinSection = =>
    restrict: 'E'
    transclude: true
    priority: 10000
    replace: true
    template: "<section class='well white'><ng-transclude></ng-transclude></section>"


  xinForm100 = =>
    restrict: 'E'
    priority: 10000
    transclude: true
    replace: true
    template: "<form class='form-floating xin-placeholders xin-heightform100' novalidate='novalidate' name='xinForm' ng-submit='save()'><ng-transclude></ng-transclude></form>"


  xinForm = =>
    restrict: 'E'
    priority: 10000
    transclude: true
    replace: true
    template: "<form class='form-floating xin-placeholders' novalidate='novalidate' name='xinForm' ng-submit='save()'><ng-transclude></ng-transclude></form>"


  angular.module('xin_tag', [])
  .directive 'xinSection100', xinSection100
  .directive 'xinSection', xinSection
  .directive 'xinForm100', xinForm100
  .directive 'xinForm', xinForm
