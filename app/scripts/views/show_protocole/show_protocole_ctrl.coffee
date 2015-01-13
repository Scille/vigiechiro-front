'use strict'


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowProtocoleCtrl
 # @description
 # # ShowProtocoleCtrl
 # Controller of the vigiechiroApp
###
angular.module('showProtocole', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'ShowProtocoleCtrl', ($routeParams, $scope, Backend, action) ->
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
        if not orig_protocole
          return
        modif_protocole = {}
        if not $scope.protocoleForm.$dirty
          return
        if $scope.protocoleForm.titre.$dirty
          modif_protocole.titre = $scope.protocole.titre
        if $scope.protocoleForm.description.$dirty
          modif_protocole.description = $scope.protocole.description
#        if $scope.protocoleForm.parent.$dirty
#          modif_protocole.parent = $scope.protocole.parent
        if $scope.protocoleForm.macro_protocole.$dirty
          modif_protocole.macro_protocole = $scope.protocole.macro_protocole
#        if $scope.protocoleForm.tags.$dirty
#          modif_protocole.tags = $scope.protocole.tags
#        if $scope.protocoleForm.fichiers.$dirty
#          modif_protocole.photos = $scope.protocole.fichiers
        if $scope.protocoleForm.type_site.$dirty
          modif_protocole.type_site = $scope.protocole.type_site
        if $scope.protocoleForm.taxon.$dirty
          modif_protocole.taxon = $scope.protocole.taxon
        if $scope.protocoleForm.configuration_participation.$dirty
          modif_protocole.configuration_participation = $scope.protocole.configuration_participation
        if $scope.protocoleForm.algo_tirage_site.$dirty
          modif_protocole.algo_tirage_site = $scope.protocole.algo_tirage_site
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
