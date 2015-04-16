'use strict'


angular.module('modalSiteViews', [])
  .controller 'ModalInstanceEditTracetController', ($scope, $modalInstance) ->
    $scope.ok = ->
      $modalInstance.close(true)

    $scope.cancel = ->
      $modalInstance.dismiss('cancel')
