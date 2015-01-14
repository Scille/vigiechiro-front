'use strict'

initMap = (scope) ->
  scope.site = {}
  mapOptions =
    # Paris
    center: new google.maps.LatLng(48.8588589, 2.3470599)
    zoom: 8
  scope.map = new google.maps.Map(angular.element('#map-canvas')[0], mapOptions)
  scope.overlay = []
  scope.drawingManager = new google.maps.drawing.DrawingManager(
    drawingMode: google.maps.drawing.OverlayType.MARKER
    drawingControl: true
    drawingControlOptions:
      position: google.maps.ControlPosition.TOP_CENTER
      drawingModes: [
        google.maps.drawing.OverlayType.MARKER,
        google.maps.drawing.OverlayType.POLYGON,
        google.maps.drawing.OverlayType.POLYLINE,
        google.maps.drawing.OverlayType.RECTANGLE
      ]
      markerOptions:
        draggable: true
      polygonOptions:
        draggable: true
        editable: true
      polylineOptions:
        draggable: true
        editable: true
      rectangleOptions:
        draggable: true
        editable: true
  )
  scope.drawingManager.setMap(scope.map)
  google.maps.event.addListener(scope.drawingManager, 'overlaycomplete', (event) ->
    new_overlay = event.overlay
    new_overlay.type = event.type
    google.maps.event.addListener(new_overlay, 'click', ->
    )
    scope.overlay.push(new_overlay)
  )

loadMap = (scope) ->
  overlay = angular.fromJson(scope.site.commentaire)
  for shape in overlay
    topush = {}
    if shape.type == google.maps.drawing.OverlayType.MARKER
      topush = new google.maps.Marker(
        position: new google.maps.LatLng(shape.lat, shape.lng)
        map: scope.map
      )
#    if shape.type == google.maps.drawing.OverlayType.POLYGON
#      topush = new google.maps.Polygon(
#        paths: shape.paths
#      )
#      topush.setMap(scope.map);
#    if shape.type == google.maps.drawing.OverlayType.POLYLINE
#      topush = new google.maps.Polyline(
#        path: shape.path
#      )
#      topush.setMap(scope.map)
#    if shape.type == google.maps.drawing.OverlayType.RECTANGLE
#      topush = new google.maps.Rectangle(
#        map: scope.map
#        bounds: shape.bounds
#      )
    scope.overlay.push(topush)

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowSiteCtrl
 # @description
 # # ShowSiteCtrl
 # Controller of the vigiechiroApp
###
angular.module('viewSite', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'ShowSiteCtrl', ($routeParams, $scope, Backend) ->
    orig_site = undefined
    initMap($scope)
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      orig_site = site
      $scope.site = site.plain()
      loadMap($scope)
    $scope.saveSite = ->
      if not $scope.siteForm.$valid
        return
      if not orig_site
        return
      modif_site = {}
      if not $scope.siteForm.$dirty
        return
#        if $scope.siteForm.titre.$dirty
#          modif_site.titre = $scope.site.titre
      orig_site.patch(modif_site).then(
        ->
          $scope.siteForm.$setPristine()
        ->
          return
      )
  .controller 'CreateSiteCtrl', ($routeParams, $scope, Backend) ->
    orig_site = undefined
    initMap($scope)
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      orig_site = site
      $scope.site = site.plain()
    $scope.saveSite = ->
      toSave = []
      if not $scope.siteForm.$valid
        return
      for shape in $scope.overlay
        shapetosave = {}
        if shape.type == google.maps.drawing.OverlayType.MARKER
          shapetosave =
            type: google.maps.drawing.OverlayType.MARKER
            lat: shape.getPosition().lat()
            lng: shape.getPosition().lng()
        if shape.type == google.maps.drawing.OverlayType.POLYGON
          shapetosave =
            type: google.maps.drawing.OverlayType.POLYGON
            paths: shape.getPaths()
        if shape.type == google.maps.drawing.OverlayType.POLYLINE
          shapetosave =
            type: google.maps.drawing.OverlayType.POLYLINE
            path: shape.getPath()
        if shape.type == google.maps.drawing.OverlayType.RECTANGLE
          shapetosave =
            type: google.maps.drawing.OverlayType.RECTANGLE
            bounds: shape.getBounds()
         toSave.push(shapetosave)
      toSave = angular.toJson(toSave, false)
      site =
        'protocole': $scope.protocoleId
        'commentaire': toSave
        #'commentaire': $scope.siteForm.commentaire.$modelValue
      Backend.all('sites').post(site).then(
        ->
#          window.location = '#/sites'
        ->
          return
      )
  .directive 'viewSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/view_site/view_site.html'
    controller: 'CreateSiteCtrl'
    link: (scope, elem, attrs) ->
      attrs.$observe('protocoleId', (value) ->
        if value
          scope.protocoleId = value
      )
