do =>

  class TaxonsParents

    constructor: (Backend, currentTaxonId) ->
      @error = undefined
      @availableTaxons = []
      @_initPromise = Backend.all('taxons').all('liste').getList()

    init: (callback) ->
      # Retrieve all the existing taxons to let the user choose parents
      @_initPromise.then (items) =>
        # Remove the current taxon from the list of possible parents
        if currentTaxonId?
          @availableTaxons = items.filter (item) -> item._id isnt currentTaxonId
        else
          @availableTaxons = items
        @parentTaxonsDict = {}
        for taxon in items
          @parentTaxonsDict[taxon._id] = taxon
        if callback?
          callback()

    parseResponse: (response) ->
      if (response.status is 422 and response.data._error.message.match('^circular dependency'))
        @error = true

    idToData: (ids) ->
      if ids?
        (@parentTaxonsDict[id] for id in ids)
      else
        ids

    dataToId: (datas) ->
      if datas?
        (data._id for data in datas)
      else
        datas


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
      label: 'Libelle'
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
  DisplayTaxonCtrl = ($routeParams, $scope, Backend, breadcrumbs, $sce) =>
    $scope.taxonId = $routeParams.taxonId
    $scope.taxon = {}
    Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
      $scope.taxon = taxon.plain()
      breadcrumbs.options =
        'Libelle': $scope.taxon.libelle_long + ' (' + $scope.taxon.libelle_court + ')'
      $(window).trigger('resize')

  ### @ngInject ###
  CreateTaxonCtrl = ($scope, Backend, $routeParams, SessionTools) =>
    $scope.submitted = false
    $scope.taxon = {parents: []}
    $scope.taxonsParents = new TaxonsParents(Backend, $scope.taxonId)
    $scope.taxonsParents.init ->
      $(window).trigger('resize')
    $scope.save = =>
      payload = SessionTools.getModifiedRessource( $scope, $scope.taxon)
      if (payload?)
        payload.parents = $scope.taxonsParents.dataToId($scope.taxon.parents)
        Backend.all('taxons').post(payload).then(
          (taxon) -> window.location = '#/taxons/' + taxon._id
          (error) -> throw error
        )


  ### @ngInject ###
  EditTaxonCtrl = ($route, $routeParams, $scope, Backend, breadcrumbs, SessionTools) =>
    $scope.taxonId = $routeParams.taxonId
    $scope.taxon = {}
    $scope.taxonsParents = new TaxonsParents(Backend, $scope.taxonId)
    $scope.taxonsParents.init ->
      # Force the cache control to get back the last version on the serveur
      Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
        $scope.taxonResource = taxon
        $scope.taxon = taxon.plain()
        breadcrumbs.options =
          'Libelle': $scope.taxon.libelle_long + ' (' + $scope.taxon.libelle_court + ')'
        $(window).trigger('resize')
    $scope.save = =>
      payload = SessionTools.getModifiedRessource( $scope, $scope.taxon)
      if (payload?)
        payload.parents = $scope.taxonsParents.dataToId($scope.taxon.parents)
        # Finally refresh the page (needed for cache reasons)
        $scope.taxonResource.patch(payload).then(
          -> window.location = '#/taxons/' + $routeParams.taxonId
        )


  angular.module('taxonViews', [])
  .config( config)
  .controller( 'Edit', EditTaxonCtrl)
  .controller( 'Display', DisplayTaxonCtrl)
  .controller( 'Create', CreateTaxonCtrl)
  .controller( 'List', ListTaxonsCtrl)
