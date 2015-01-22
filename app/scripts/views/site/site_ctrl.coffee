'use strict'


angular.module('siteViews', ['ngRoute', 'textAngular', 'xin_backend'])

  .directive 'listSitesDirective', (Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/list_sites.html'
    scope:
      protocoleId: '@'
    link: (scope, elem, attrs) ->
      scope.loading = true
      scope.sites = []
      scope.loadSites = (lookup) ->
        Backend.all('sites').getList(lookup).then (sites) ->
          scope.sites = sites.plain()
          scope.loading = false
      attrs.$observe('protocoleId', (value) ->
        if value
          lookup = {where: protocole: value}
          scope.loadSites(lookup)
      )

  .controller 'ShowSiteCtrl', ($timeout, $route, $routeParams, $scope, session, Backend, GoogleMaps) ->
    googleMaps = undefined
    siteResource = undefined
    mapLoaded = false
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    Backend.one('sites', $scope.site._id).get().then (site) ->
      siteResource = site
    # Wait for the collapse to be opened before load the google map
    drawCallback = (event) ->
      $scope.siteForm.$pristine = false
      $scope.siteForm.$dirty = true
      $scope.$apply()
    $scope.openCollapse = (collapseTarget) ->
      if not mapLoaded
        mapLoaded = true
        collapse = $(collapseTarget)
        # TODO : add a watch on .collapse.in to remove this ugly $timeout
        $timeout(
          ->
            googleMaps = new GoogleMaps(collapse.find('.g-maps')[0], drawCallback)
            googleMaps.loadMap($scope.site.numero_grille_stoc)
          100
          )
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty or
          not googleMaps and siteResource)
        return
      # TODO : stop saving the map elements in the numero_grille_stoc !
      payload =
        'numero_grille_stoc': googleMaps.saveMap()
        'commentaire': $scope.siteForm.commentaire.$modelValue
      siteResource.patch(payload).then(
        -> $scope.siteForm.$setPristine()
        (error) -> console.log("error", error)
      )

  .directive 'showSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/show_site.html'
    controller: 'ShowSiteCtrl'
    scope:
      site: '='
      title: '@'
      collapsed: '@'
    link: (scope, elem, attrs) ->
      attrs.$observe('collapsed', (value) ->
        if value == undefined
          scope.openCollapse(elem)
      )

  .controller 'CreateSiteCtrl', ($timeout, $route, $routeParams, $scope, session, Backend, GoogleMaps) ->
    googleMaps = undefined
    mapLoaded = false
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    $scope.site = {}
    drawCallback = (event) ->
      $scope.siteForm.$pristine = false
      $scope.siteForm.$dirty = true
      $scope.$apply()
    # Wait for the collapse to be opened before load the google map
    $scope.openCollapse = (collapseTarget) ->
      if not mapLoaded
        mapLoaded = true
        collapse = $(collapseTarget)
        # TODO : add a watch on .collapse.in to remove this ugly $timeout
        $timeout(
          -> googleMaps = new GoogleMaps(collapse.find('.g-maps')[0], drawCallback)
          100
          )
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty or
          not googleMaps)
        return
      # TODO : stop saving the map elements in the numero_grille_stoc !
      payload =
        'protocole': $scope.protocoleId
        'coordonnee':
          'type': 'Point'
#          'coordinates': [mapDump[0].lng, mapDump[0].lat]
        'numero_grille_stoc': googleMaps.saveMap()
        'commentaire': $scope.siteForm.commentaire.$modelValue
      console.log(payload)
#      Backend.all('sites').post(payload).then(
#        -> $route.reload()
#        (error) -> console.log("error", error)
#      )

  .directive 'createSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/create_site.html'
    controller: 'CreateSiteCtrl'
    link: (scope, elem, attrs) ->
      attrs.$observe('protocoleId', (value) ->
        if value
          scope.protocoleId = value
      )
