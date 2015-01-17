'use strict'


angular.module('taxonView', ['ngRoute', 'ngSanitize', 'textAngular', 'xin_backend', 'xin_session'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/taxons',
        templateUrl: 'scripts/views/taxon/list_taxons.html'
        controller: 'ListResourceCtrl'
        resolve: {resourceBackend: (Backend) -> Backend.all('taxons')}
      .when '/taxons/nouveau',
        templateUrl: 'scripts/views/taxon/edit_taxon.html'
        controller: 'CreateTaxonCtrl'
      .when '/taxons/:taxonId',
        templateUrl: 'scripts/views/taxon/display_taxon.html'
        controller: 'DisplayTaxonCtrl'
      .when '/taxons/:taxonId/edition',
        templateUrl: 'scripts/views/taxon/edit_taxon.html'
        controller: 'EditTaxonCtrl'
  .controller 'CreateTaxonCtrl', ($scope, Backend) ->
    $scope.taxon = {}
    $scope.saveTaxon = ->
      if not $scope.taxonForm.$valid or not $scope.taxonForm.$dirty
        return
      payload =
        'libelle_long': $scope.taxonForm.libelle_long.$modelValue
        'libelle_court': $scope.taxonForm.libelle_court.$modelValue
        'description': $scope.taxon.description
      Backend.all('taxons').post(payload).then(
        -> window.location = '#/taxons'
        ->
      )
  .controller 'DisplayTaxonCtrl', ($routeParams, $scope, session, Backend) ->
    $scope.taxon = {}
    $scope.taxonId = $routeParams.taxonId
    $scope.isAdmin = false
    session.getUserPromise().then (user) ->
      $scope.isAdmin = user.role == 'Administrateur'
    Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
      $scope.taxon = taxon.plain()
  .controller 'EditTaxonCtrl', ($routeParams, $scope, Backend) ->
    $scope.taxon = {}
    taxonResource = undefined
    $scope.taxonId = $routeParams.taxonId
    Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
      taxonResource = taxon
      $scope.taxon = taxon.plain()
    $scope.saveTaxon = ->
      if (not $scope.taxonForm.$valid or
          not $scope.taxonForm.$dirty or
          not taxonResource?)
        return
      payload = {}
      # Retrieve the modified fields from the form
      for key, value of $scope.taxonForm
        if key.charAt(0) != '$' and value.$dirty
          payload[key] = $scope.taxon[key]
      # Special handle for description
      payload.description = $scope.taxon.description
      # Finally patch the resource
      taxonResource.patch(payload).then(
        -> $scope.taxonForm.$setPristine()
        ->
      )
