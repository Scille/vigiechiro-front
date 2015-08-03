'use strict'

breadcrumbsGetTaxonDefer = undefined


class TaxonsParents
  constructor: (Backend, @currentTaxonId) ->
    @error = undefined
    @availableTaxons = []
    @_initPromise = Backend.all('taxons').all('liste').getList()
  init: (callback) ->
    # Retrieve all the existing taxons to let the user choose parents
    @_initPromise.then (items) =>
      # Remove the current taxon from the list of possible parents
      if @currentTaxonId?
        @availableTaxons = items.filter (item) => item._id != @currentTaxonId
      else
        @availableTaxons = items
      callback?()
  parseResponse: (response) ->
    if (response.status == 422 and
        response.data._error.message.match('^circular dependency'))
      @error = true
  datasToIds: (datas) ->
    out = []
    if datas?
      for data in datas
        out.push(data._id)
    return out

angular.module('taxonViews', ['ngRoute', 'ngSanitize', 'textAngular',
                              'ui.select', 'xin_listResource',
                              'xin_backend', 'xin_session', 'xin_tools'])
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
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
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
        'parents': $scope.taxon.parents
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
    Backend.one('taxons', $routeParams.taxonId).get().then(
      (taxon) ->
        if breadcrumbsGetTaxonDefer?
          breadcrumbsGetTaxonDefer.resolve(taxon)
          breadcrumbsGetTaxonDefer = undefined
        $scope.taxon = taxon.plain()
      (error) -> window.location = '#/404'
    )


  .controller 'EditTaxonCtrl', ($route, $routeParams, $scope, Backend) ->
    taxonResource = null
    $scope.submitted = false
    $scope.taxon = null
    $scope.taxonsParents = new TaxonsParents(Backend, $routeParams.taxonId)
    $scope.taxonsParents.init ->
      Backend.one('taxons', $routeParams.taxonId).get().then(
        (taxon) ->
          if breadcrumbsGetTaxonDefer?
            breadcrumbsGetTaxonDefer.resolve(taxon)
            breadcrumbsGetTaxonDefer = undefined
          taxonResource = taxon
          taxon.parents = $scope.taxonsParents.datasToIds(taxon.parents)
          $scope.taxon = taxon.plain()
        (error) -> window.location = '#/404'
      )

    $scope.saveTaxon = ->
      $scope.submitted = true
      if (not $scope.taxonForm.$valid or
          not $scope.taxonForm.$dirty or
          not taxonResource?)
        return
      payload = {parents: $scope.taxon.parents}
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
