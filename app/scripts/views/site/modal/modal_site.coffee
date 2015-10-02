'use strict'


angular.module('modalSiteViews', [])
  .controller 'ModalInstanceEditRouteController', ($scope, $modalInstance) ->
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

  .controller 'ModalDeleteRouteController', ($scope, $modalInstance) ->
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

  .controller 'ModalInstanceRetrySelectionController', ($scope, $modalInstance, justification_non_aleatoire) ->
    $scope.justification_non_aleatoire = justification_non_aleatoire
    $scope.ok = ->
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

  .controller 'ModalDeleteSiteController', ($scope, $modalInstance, site) ->
    $scope.site = site
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')
