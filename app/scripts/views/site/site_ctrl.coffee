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
      attrs.$observe('protocoleId', (protocoleId) ->
        if protocoleId
          scope.loadSites({where: protocole: protocoleId})
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
    drawCallback = (event) ->
      $scope.siteForm.$pristine = false
      $scope.siteForm.$dirty = true
      $scope.$apply()
      return true
    $scope.loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        googleMaps = new GoogleMaps(mapDiv, drawCallback)
        googleMaps.loadMap($scope.site.localites)
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty or
          not googleMaps and siteResource)
        return
      mapDump = googleMaps.saveMap()
      localites = []
      for shape in mapDump
        geometries =
          geometries: [shape]
        localites.push(geometries)
      payload =
        'protocole': $scope.protocoleId
        'localites': localites
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
      # Wait for the collapse to be opened before load the google map
      attrs.$observe('collapsed', (collapsed) ->
        if collapsed?
          $(elem).on('shown.bs.collapse', ->
            scope.loadMap(elem.find('.g-maps')[0])
            return
          )
        else
          scope.loadMap(elem.find('.g-maps')[0])
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
      return true
    $scope.loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        googleMaps = new GoogleMaps(mapDiv, drawCallback)
        googleMaps.loadMap($scope.site.localites)
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty or
          not googleMaps)
        return
      mapDump = googleMaps.saveMap()
      localites = []
      for shape in mapDump
        geometries =
          geometries: [shape]
        localites.push(geometries)
      payload =
        'protocole': $scope.protocoleId
        'localites': localites
# TODO : use coordonnee to center the map
#        'coordonnee':
#          'type': 'Point'
#          'coordinates': [mapDump[0].lng, mapDump[0].lat]
#        'numero_grille_stoc': 
        'commentaire': $scope.siteForm.commentaire.$modelValue
      Backend.all('sites').post(payload).then(
        -> $route.reload()
        (error) -> console.log("error", error)
      )

  .directive 'createSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/create_site.html'
    controller: 'CreateSiteCtrl'
    link: (scope, elem, attrs) ->
      attrs.$observe('protocoleId', (protocoleId) ->
        scope.protocoleId = protocoleId
      )
      $(elem).on('shown.bs.collapse', ->
        scope.loadMap(elem.find('.g-maps')[0])
        return
      )
