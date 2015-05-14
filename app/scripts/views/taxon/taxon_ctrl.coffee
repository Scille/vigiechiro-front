'use strict'

breadcrumbsGetTaxonDefer = undefined


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
        @availableTaxons = items.filter (item) -> item._id != currentTaxonId
      else
        @availableTaxons = items
      @parentTaxonsDict = {}
      for taxon in items
        @parentTaxonsDict[taxon._id] = taxon
      if callback?
        callback()
  parseResponse: (response) ->
    if (response.status == 422 and response.data._error.message.match('^circular dependency'))
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


angular
.module('taxonViews', ['ngRoute', 'ngSanitize', "kendo.directives",
                       'xin_backend', 'xin_session', 'xin_tools', 'xin_datasource'])

.config ($routeProvider) ->
  $routeProvider
  .when '/taxons',
    templateUrl: 'scripts/views/taxon/list_taxons.html'
    controller: 'ListTaxonsCtrl'
    breadcrumbs: 'Taxons'
  .when '/taxons/nouveau',
    templateUrl: 'scripts/views/taxon/edit_taxon.html'
    controller: 'CreateTaxonCtrl'
    breadcrumbs: 'Nouveau Taxon'
  .when '/taxons/:taxonId',
    templateUrl: 'scripts/views/taxon/display_taxon.html'
    controller: 'DisplayTaxonCtrl'
    breadcrumbs: ngInject ($q) ->
      breadcrumbsDefer = $q.defer()
      breadcrumbsGetTaxonDefer = $q.defer()
      breadcrumbsGetTaxonDefer.promise.then (taxon) ->
        breadcrumbsDefer.resolve([
          ['Taxons', '#/taxons']
          [taxon.libelle_long, '#/taxons/' + taxon._id]
        ])
      return breadcrumbsDefer.promise
  .when '/taxons/:taxonId/edition',
    templateUrl: 'scripts/views/taxon/edit_taxon.html'
    controller: 'EditTaxonCtrl'
    breadcrumbs: ngInject ($q) ->
      breadcrumbsDefer = $q.defer()
      breadcrumbsGetTaxonDefer = $q.defer()
      breadcrumbsGetTaxonDefer.promise.then (taxon) ->
        breadcrumbsDefer.resolve([
          ['Taxons', '#/taxons']
          [taxon.libelle_long, '#/taxons/' + taxon._id]
          ['Édition', '#/taxons/' + taxon._id + '/edition']
        ])
      return breadcrumbsDefer.promise

.controller 'ListTaxonsCtrl', ($scope, DataSource, Session, Backend) ->
  Session.getIsAdminPromise().then (isAdmin) ->
    $scope.isAdmin = isAdmin
  columnsTaxons =
    [
      field: "libelle_long"
      title: "Libelle"
      template: '<a href=\"\\#/taxons/#: _id #\"> #: libelle_long # </a>'
    ,
      field: "libelle_court"
      title: "Libelle court"
    ]
  modelTaxons =
    _id:
      type: "string"
    libelle_long:
      type: "string"
    libelle_court:
      type: "string"
  $scope.gridOptions =  DataSource.getGridReadOption('/taxons', modelTaxons, columnsTaxons)


.controller 'CreateTaxonCtrl', ($scope, Backend) ->
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

.controller 'DisplayTaxonCtrl', ($routeParams, $scope, Session, Backend) ->
  $scope.taxon = {}
  $scope.taxonId = $routeParams.taxonId
  $scope.isAdmin = false
  Session.getIsAdminPromise().then (isAdmin) ->
    $scope.isAdmin = isAdmin
  Backend.one('taxons', $routeParams.taxonId).get().then (taxon) ->
    if breadcrumbsGetTaxonDefer?
      breadcrumbsGetTaxonDefer.resolve(taxon)
      breadcrumbsGetTaxonDefer = undefined
    $scope.taxon = taxon.plain()

.controller 'EditTaxonCtrl', ($route, $routeParams, $scope, Backend) ->
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
      if breadcrumbsGetTaxonDefer?
        breadcrumbsGetTaxonDefer.resolve(taxon)
        breadcrumbsGetTaxonDefer = undefined
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


