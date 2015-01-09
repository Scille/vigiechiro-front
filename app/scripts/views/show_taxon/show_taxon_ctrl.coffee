'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowtaxonCtrl
 # @description
 # # ShowtaxonCtrl
 # Controller of the vigiechiroApp
###
angular.module('showTaxon', ['ngRoute', 'xin_backend'])
  .controller 'ShowTaxonCtrl', ($routeParams, $scope, Backend, action) ->
    $scope.taxon = {}
    orig_taxon = undefined
    Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
      orig_taxon = taxon
      $scope.taxon = taxon.plain()
    $scope.saveTaxon = ->
      if not $scope.taxonForm.$valid
        return
      if action == 'edit'
        if not orig_taxon
          return
        modif_taxon = {}
        if not $scope.taxonForm.$dirty
          return
        if $scope.taxonForm.libelle_long.$dirty
          modif_taxon.libelle_long = $scope.taxon.libelle_long
        if $scope.taxonForm.libelle_court.$dirty
          modif_taxon.libelle_court = $scope.taxon.libelle_court
        if $scope.taxonForm.description.$dirty
          modif_taxon.description = $scope.taxon.description
#      if $scope.taxonForm.parents.$dirty
#        modif_taxon.parents = $scope.taxon.parents
#      if $scope.taxonForm.liens.$dirty
#        modif_taxon.liens = $scope.taxon.liens
#      if $scope.taxonForm.tags.$dirty
#        modif_taxon.tags = $scope.taxon.tags
#      if $scope.taxonForm.photos.$dirty
#        modif_taxon.photos = $scope.taxon.photos
        orig_taxon.patch(modif_taxon).then(
          ->
            $scope.taxonForm.$setPristine()
          ->
            return
        )
        return
      taxon =
        'libelle_long': $scope.taxonForm.libelle_long.$modelValue
        'libelle_court': $scope.taxonForm.libelle_court.$modelValue
        'description': $scope.taxonForm.description.$modelValue
      Backend.all('taxons').post(taxon).then(
        ->
          window.location = '#/taxons'
        ->
          return
        )
