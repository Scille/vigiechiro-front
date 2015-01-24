'use strict'

mapsCallback = (scope, Backend) ->
  overlayCreated: (overlay) ->
    isModified = false
    if scope.protocoleAlgoSite == "ROUTIER"
      if overlay.type == "LineString"
        isModified = true
      else if overlay.type == "Point"
        nbPoints = scope.googleMaps.getCountOverlays('Point')
        if nbPoints <= 0
          isModified = true
    else if scope.protocoleAlgoSite == "CARRE"
      isModified = true
    else if scope.protocoleAlgoSite == "POINT_FIXE"
      isModified = true
    if isModified
      scope.googleMaps.addListener(overlay, 'rightclick', (event) ->
        scope.googleMaps.deleteOverlay(this)
      )
      scope.siteForm.$pristine = false
      scope.siteForm.$dirty = true
      scope.$apply()
      return true
    else
      return false

  zoomChanged: -> mapsChanged(scope, Backend)
  mapsMoved: -> mapsChanged(scope, Backend)

mapsChanged = (scope, Backend) ->
  zoomLevel = scope.googleMaps.getZoom()
  center = scope.googleMaps.getCenter()
  if zoomLevel > 10
    where = JSON.stringify(
      location:
        $near:
          $geometry:
            type: "Point"
            coordinates: [ center.lat(), center.lng() ]
          $maxDistance: 5000
    )
    Backend.all('grille_stoc').getList({ $where: where }).then (grille_stoc) ->
      grille_stoc = grille_stoc.plain()
      for cell in grille_stoc
        scope.googleMaps.createPoint()
        console.log(cell.numero)
        console.log(cell.centre.coordinates)

angular.module('siteViews', ['ngRoute', 'textAngular', 'xin_backend'])
  .directive 'listSitesDirective', (session, Backend) ->
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
      attrs.$observe 'protocoleId', (protocoleId) ->
        if protocoleId
          session.getUserPromise().then (user) ->
            scope.loadSites(
              where:
                protocole: protocoleId
                observateur: user._id
            )
      attrs.$observe('protocoleAlgoSite', (value) ->
        if value
          scope.protocoleAlgoSite = value
      )

  .controller 'ShowSiteCtrl', ($timeout, $route, $routeParams, $scope, session, Backend, GoogleMaps) ->
    $scope.googleMaps = undefined
    siteResource = undefined
    mapLoaded = false
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    Backend.one('sites', $scope.site._id).get().then (site) ->
      siteResource = site
    $scope.loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        $scope.googleMaps = new GoogleMaps(mapDiv, mapsCallback($scope, Backend))
        $scope.googleMaps.loadMap($scope.site.localites)
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty or
          not $scope.googleMaps and siteResource)
        return
      mapDump = $scope.googleMaps.saveMap()
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
    $scope.googleMaps = undefined
    mapLoaded = false
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    $scope.site = {}
    $scope.loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        $scope.googleMaps = new GoogleMaps(mapDiv, mapsCallback($scope, Backend))
        $scope.googleMaps.loadMap($scope.site.localites)
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty or
          not $scope.googleMaps)
        return
      mapDump = $scope.googleMaps.saveMap()
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
      attrs.$observe('protocoleAlgoSite', (value) ->
        if value
          scope.protocoleAlgoSite = value
      )
