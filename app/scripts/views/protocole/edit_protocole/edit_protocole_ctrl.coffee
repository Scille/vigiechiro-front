'use strict'


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowProtocoleCtrl
 # @description
 # # ShowProtocoleCtrl
 # Controller of the vigiechiroApp
###
angular.module('editProtocole', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'EditProtocoleCtrl', ($routeParams, $scope, Backend, action) ->
    $scope.protocole = {}
    orig_protocole = undefined
    Backend.one('protocoles', $routeParams.protocoleId).get().then (protocole) ->
      orig_protocole = protocole
      $scope.protocole = protocole.plain()
      Backend.all('taxons').getList().then (taxons) ->
        $scope.taxons = taxons.plain()
    $scope.saveProtocole = ->
      if not $scope.protocoleForm.$valid
        return
      if action == 'edit'
        if not orig_protocole or not $scope.protocoleForm.$dirty
          return
        modif_protocole = {}
        # Retrieve the modified fields from the form
        for key, value of $scope.protocoleForm
          if key.charAt(0) != '$' and value.$dirty
            modif_protocole[key] = $scope.protocole[key]
        orig_protocole.patch(modif_protocole).then(
          ->
            $scope.protocoleForm.$setPristine()
          ->
            return
        )
        return
      protocole =
        'titre': $scope.protocoleForm.titre.$modelValue
        'description': $scope.protocoleForm.description.$modelValue
        'macro_protocole': $scope.protocoleForm.macro_protocole.$modelValue
        'type_site': $scope.protocoleForm.type_site.$modelValue
        'taxon': $scope.protocoleForm.taxon.$modelValue
        'algo_tirage_site': $scope.protocoleForm.algo_tirage_site.$modelValue
      Backend.all('protocoles').post(protocole).then(
        ->
          window.location = '#/protocoles'
        ->
          return
        )
