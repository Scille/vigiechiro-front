'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_routier', [])
  .factory 'ProtocoleRoutier', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleRoutier extends ProtocoleMap
      constructor: (mapDiv, @factoryCallback) ->
        @_grille = []
        @_stocValid = false
        @_googleMaps = new GoogleMaps(mapDiv, @mapsCallback())
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.MARKER
              google.maps.drawing.OverlayType.POLYLINE
            ]
        )
        return

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if overlay.type == "Point"
            nbPoints = @_googleMaps.getCountOverlays('Point')
            if nbPoints <= 0
              isModified = true
          else if overlay.type == "LineString"
            length = google.maps.geometry.spherical.computeLength(overlay.getPath())
            if length >= 1800 and length <= 2200
              isModified = true
            else
              error = "Les tracés doivent avoir une longueur comprise entre 1800 et 2200 mètres. La longueur de votre tracé est de "+length+"m"
              console.log(error)
          if isModified
            @_googleMaps.addListener(overlay, 'rightclick', (event) =>
              @_googleMaps.deleteOverlay(overlay)
            )
            return true
          else
            return false

      loadMap: (mongoShapes) ->
        return @_googleMaps.loadMap(mongoShapes)

      saveMap: ->
        return @_googleMaps.saveMap()
