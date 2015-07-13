do ->

  xinForm = =>
    restrict: 'E'
    priority: 10000
    transclude: true
    replace: true
    template: "<form class='form-floating' novalidate='novalidate' name='xinForm' ng-submit='save()'><ng-transclude></ng-transclude></form>"


  angular.module('xin_tag', [])
  .directive 'xinForm', xinForm
