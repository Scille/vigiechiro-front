'use strict'


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
    if (response.status == 422 and
        response.data._error.message.match('^circular dependency'))
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


angular.module('taxonViews', ['ngRoute', 'ngSanitize', 'textAngular',
                              'ui.select', 'xin_listResource',
                              'xin_backend', 'xin_session'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/taxons',
        templateUrl: 'scripts/views/taxon/list_taxons.html'
        controller: 'ListTaxonsCtrl'
      .when '/taxons/nouveau',
        templateUrl: 'scripts/views/taxon/edit_taxon.html'
        controller: 'CreateTaxonCtrl'
      .when '/taxons/:taxonId',
        templateUrl: 'scripts/views/taxon/display_taxon.html'
        controller: 'DisplayTaxonCtrl'
      .when '/taxons/:taxonId/edition',
        templateUrl: 'scripts/views/taxon/edit_taxon.html'
        controller: 'EditTaxonCtrl'

  .controller 'ListTaxonsCtrl', ($scope, Backend, session, DelayedEvent) ->
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    $scope.lookup = {}
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.where = JSON.stringify(
              $text:
                $search: filterValue
          )
        else if $scope.lookup.where?
          delete $scope.lookup.where
    $scope.resourceBackend = Backend.all('taxons')

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
        -> window.location = '#/taxons'
        (response) -> $scope.taxonsParents.parseResponse(response)
      )

  .controller 'DisplayTaxonCtrl', ($routeParams, $scope, session, Backend) ->
    $scope.taxon = {}
    $scope.taxonId = $routeParams.taxonId
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    Backend.one('taxons', $routeParams.taxonId).get({embedded: {parents: 1}}).then (taxon) ->
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
        taxonResource = taxon
        $scope.taxon = taxon.plain()
        $scope.taxon.parents = $scope.taxonsParents.idToData($scope.taxon.parents)
    $scope.saveTaxon = ->
      $scope.submitted = true
      if (not $scope.taxonForm.$valid or
          not $scope.taxonForm.$dirty or
          not taxonResource?)
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
        -> $route.reload()
        (response) -> $scope.taxonsParents.parseResponse(response)
      )
