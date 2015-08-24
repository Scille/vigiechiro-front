'use strict'


angular.module('modalParticipationViews', [])
  .controller 'ModalDeleteParticipationController', ($scope, $modalInstance) ->
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')
