do =>
  xinCreate = () ->
    restrict: 'E'
    templateUrl: 'scripts/xin/action_drt/create.html'
    link: ($scope) ->
      $scope.hrefValue = window.location.href + "/nouveau"

  xinSubmit = () ->
    restrict: 'E'
    templateUrl: 'scripts/xin/action_drt/submit.html'

  xinUpdate = () ->
    restrict: 'E'
    templateUrl: 'scripts/xin/action_drt/update.html'
    link: ($scope) ->
      $scope.hrefValue = window.location.href + "/edition"

  angular.module('xin_action', [])
  .directive('xinCreate', xinCreate)
  .directive('xinSubmit', xinSubmit)
  .directive('xinUpdate', xinUpdate)
