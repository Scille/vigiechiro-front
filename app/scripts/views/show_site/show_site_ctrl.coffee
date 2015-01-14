'use strict'


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowSiteCtrl
 # @description
 # # ShowSiteCtrl
 # Controller of the vigiechiroApp
###
angular.module('showSite', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'ShowSiteCtrl', ($routeParams, $scope, Backend, action) ->
    orig_site = undefined
    $scope.site = {}
    mapOptions =
      # Paris
      center: new google.maps.LatLng(48.8588589, 2.3470599)
      zoom: 8
    $scope.map = new google.maps.Map(angular.element('#map-canvas')[0], mapOptions)
    $scope.drawingManager = new google.maps.drawing.DrawingManager(
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
    $scope.overlay = []
    $scope.drawingManager.setMap($scope.map)
    google.maps.event.addListener($scope.drawingManager, 'overlaycomplete', (event) ->
      console.log(event)
      new_overlay = event.overlay
      new_overlay.type = event.type
      google.maps.event.addListener(new_overlay, 'click', ->
      )
      $scope.overlay.push(new_overlay)
    )
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      orig_site = site
      $scope.site = site.plain()
    $scope.saveSite = ->
      if not $scope.siteForm.$valid
        return
      if action == 'edit'
        if not orig_site
          return
        modif_site = {}
        if not $scope.siteForm.$dirty
          return
#        if $scope.siteForm.titre.$dirty
#          modif_site.titre = $scope.site.titre
#        if $scope.siteForm.description.$dirty
#          modif_site.description = $scope.site.description
#        if $scope.siteForm.parent.$dirty
#          modif_site.parent = $scope.site.parent
#        if $scope.siteForm.macro_site.$dirty
#          modif_site.macro_site = $scope.site.macro_site
#        if $scope.siteForm.tags.$dirty
#          modif_site.tags = $scope.site.tags
#        if $scope.siteForm.fichiers.$dirty
#          modif_site.photos = $scope.site.fichiers
#        if $scope.siteForm.type_site.$dirty
#          modif_site.type_site = $scope.site.type_site
#        if $scope.siteForm.taxon.$dirty
#          modif_site.taxon = $scope.site.taxon
#        if $scope.siteForm.configuration_participation.$dirty
#          modif_site.configuration_participation = $scope.site.configuration_participation
#        if $scope.siteForm.algo_tirage_site.$dirty
#          modif_site.algo_tirage_site = $scope.site.algo_tirage_site
        orig_site.patch(modif_site).then(
          ->
            $scope.siteForm.$setPristine()
          ->
            return
        )
        return
      site =
        'commentaire': $scope.siteForm.commentaire.$modelValue
      Backend.all('sites').post(site).then(
        ->
          window.location = '#/sites'
        ->
          return
      )
