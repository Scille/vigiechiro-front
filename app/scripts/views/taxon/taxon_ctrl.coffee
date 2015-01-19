'use strict'


angular.module('taxonViews', ['ngRoute', 'ngSanitize', 'textAngular', 'xin_listResource', 'xin_backend', 'xin_session'])
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
    $scope.submitted = false
    $scope.saveTaxon = ->
      $scope.submitted = true
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
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
      $scope.taxon = taxon.plain()

  .controller 'EditTaxonCtrl', ($route, $routeParams, $scope, Backend) ->
    $scope.submitted = false
    $scope.taxon = {}
    taxonResource = undefined
    $scope.taxonId = $routeParams.taxonId
    # Force the cache control to get back the last version on the serveur
    Backend.one('taxons', $routeParams.taxonId).get(
      {}
      {'Cache-Control': 'no-cache'}
    ).then (taxon) ->
      taxonResource = taxon
      $scope.taxon = taxon.plain()
    $scope.saveTaxon = ->
      $scope.submitted = true
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
      # Finally refresh the page (needed for cache reasons)
      taxonResource.patch(payload).then(
        -> $route.reload();
        # -> $scope.taxonForm.$setPristine()
        ->
      )
