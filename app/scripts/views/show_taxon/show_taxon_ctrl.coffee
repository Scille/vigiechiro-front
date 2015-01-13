'use strict'


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowtaxonCtrl
 # @description
 # # ShowtaxonCtrl
 # Controller of the vigiechiroApp
###
angular.module('showTaxon', ['ngRoute', 'ngSanitize', 'textAngular', 'xin_backend'])
  .controller 'ShowTaxonCtrl', ($routeParams, $scope, Backend, action) ->
    $scope.taxon = {}
    $scope.editMode = true # TODO : add display mode in addition to edit mode
    orig_taxon = undefined
    Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
      orig_taxon = taxon
      $scope.taxon = taxon.plain()
    $scope.saveTaxon = ->
      if not $scope.taxonForm.$valid
        return
      if action == 'edit'
        # Modify an existing taxon
        if not orig_taxon or not $scope.taxonForm.$dirty
          return
        payload = {}
        # Retrieve the modified fields from the form
        for key, value of $scope.taxonForm
          if key.charAt(0) != '$' and value.$dirty
            payload[key] = $scope.taxon[key]
        # Special handle for description
        payload.description = $scope.taxon.description
        console.log(payload)
        orig_taxon.patch(payload).then(
          -> $scope.taxonForm.$setPristine()
          ->
        )
      else
        # Post a new taxon
        taxon =
          'libelle_long': $scope.taxonForm.libelle_long.$modelValue
          'libelle_court': $scope.taxonForm.libelle_court.$modelValue
          'description': $scope.taxon.description
        Backend.all('taxons').post(taxon).then(
          -> window.location = '#/taxons'
          ->
        )
