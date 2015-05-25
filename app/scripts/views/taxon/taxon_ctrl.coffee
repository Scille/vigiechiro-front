do =>

  ### @ngInject ###
  config = ($routeProvider) =>
    $routeProvider
    .when '/taxons',
      templateUrl: 'scripts/views/taxon/list_taxons.html'
      controller: ListTaxonsCtrl
      label: 'Taxons'
    .when '/taxons/nouveau',
      templateUrl: 'scripts/views/taxon/edit_taxon.html'
      controller: CreateTaxonCtrl
      label: 'Nouveau Taxon'
    .when '/taxons/:taxonId',
      templateUrl: 'scripts/views/taxon/display_taxon.html'
      controller: DisplayTaxonCtrl
      label: 'libelle_long'
    .when '/taxons/:taxonId/edition',
      templateUrl: 'scripts/views/taxon/edit_taxon.html'
      controller: EditTaxonCtrl
      label: 'Edition'

  ### @ngInject ###
  ListTaxonsCtrl = ($scope, Datasource) =>
    columnsTaxon =
      [
        field: "libelle_long"
        title: "Libelle"
        template: '<a href=\"\\#/taxons/#: _id #\"> #: libelle_long # </a>'
      ,
        field: "libelle_court"
        title: "Libelle court"
      ]
    fieldsTaxon =
      libelle_long:
        type: "string"
      libelle_court:
        type: "string"
    $scope.gridOptions =  Datasource.getGridReadOption('/taxons', fieldsTaxon, columnsTaxon)

  ### @ngInject ###
  CreateTaxonCtrl = ($scope, Backend, TaxonsParents) =>
    $scope.submitted = false
    $scope.taxon = {parents: []}
    $scope.taxonsParents = new TaxonsParents(Backend, $scope.taxonId)
    $scope.taxonsParents.init()
    $scope.saveTaxon = ->
      $scope.submitted = true
      if not $scope.taxonForm.$valid or not $scope.taxonForm.$dirty
        return
      parents = []
      for parent in $scope.taxon.parents
        parents.push(parent._id)
      payload =
        'libelle_long': $scope.taxonForm.libelle_long.$modelValue
        'libelle_court': $scope.taxonForm.libelle_court.$modelValue
        'description': $scope.taxon.description
        'parents': $scope.taxonsParents.dataToId($scope.taxon.parents)
      Backend.all('taxons').post(payload).then(
        -> window.location = '#/taxons/' + $routeParams.taxonId
        (response) -> $scope.taxonsParents.parseResponse(response)
      )
    $(window).trigger('resize')

  ### @ngInject ###
  DisplayTaxonCtrl = ($routeParams, $scope, Backend, breadcrumbs) =>
    $scope.taxon = {}
    $scope.taxonId = $routeParams.taxonId
    Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
      $scope.taxon = taxon.plain()
      breadcrumbs.options =
        'libelle_long': $scope.taxon.libelle_long

  ### @ngInject ###
  EditTaxonCtrl = ($route, $routeParams, $scope, Backend) =>
    taxonResource = undefined
    $scope.submitted = false
    $scope.taxonId = $routeParams.taxonId
    $scope.taxon = {}
    $scope.taxonsParents = new TaxonsParents(Backend, $scope.taxonId)
    $scope.taxonsParents.init ->
  # Force the cache control to get back the last version on the serveur
      Backend.one('taxons', $routeParams.taxonId).get(
        {}
        {'Cache-Control': 'no-cache'}
      ).then (taxon) ->
        taxonResource = taxon
        $scope.taxon = taxon.plain()
        $scope.taxon.parents = $scope.taxonsParents.idToData($scope.taxon.parents)
    $scope.saveTaxon = ->
      $scope.submitted = true
      if (not $scope.taxonForm.$valid or not $scope.taxonForm.$dirty or not taxonResource?)
        return
      payload = {parents: $scope.taxonsParents.dataToId($scope.taxon.parents)}
      # Retrieve the modified fields from the form
      for key, value of $scope.taxonForm
        if key.charAt(0) != '$' and value.$dirty
          payload[key] = $scope.taxon[key]
      # Special handle for description
      payload.description = $scope.taxon.description
      # Finally refresh the page (needed for cache reasons)
      taxonResource.patch(payload).then(
        -> window.location = '#/taxons/' + $routeParams.taxonId
        (response) -> $scope.taxonsParents.parseResponse(response)
      )
    $(window).trigger('resize')


  angular.module('taxonViews', [])
  .config( config)
  .controller( 'Edit', EditTaxonCtrl)
  .controller( 'Display', DisplayTaxonCtrl)
  .controller( 'Create', CreateTaxonCtrl)
  .controller( 'List', ListTaxonsCtrl)



