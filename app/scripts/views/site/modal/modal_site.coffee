'use strict'


angular.module('modalSiteViews', [])
  .controller 'ModalInstanceEditTracetController', ($scope, $modalInstance) ->
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

  .controller 'ModalInstanceRetrySelectionController', ($scope, $modalInstance, justification_non_aleatoire) ->
    $scope.justification_non_aleatoire = justification_non_aleatoire
    $scope.ok = ->
      console.log($scope.motif)
      if $scope.motif in [undefined, '']
        $scope.onError = true
      else
        $modalInstance.close($scope.motif)
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

  .controller 'ModalInstanceSiteOpportunisteController', ($scope, $modalInstance) ->
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')