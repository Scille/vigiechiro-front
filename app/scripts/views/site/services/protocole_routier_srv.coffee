'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_routier', [])
  .factory 'ProtocoleRoutier', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleRoutier extends ProtocoleMap
      constructor: (@site, mapDiv, @siteCallback) ->
        super @site, mapDiv, @siteCallback
        @_steps = [
          "Positionner le point d'origine.",
          "Tracer le parcours par plusieurs segments de 2 km (+/-10%). "+
          "Les segments trop courts sont en violet et les trop longs en rouge.",
          "Atteindre une longueur de tracé globale de 30 km ou plus."
        ]
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.MARKER
              google.maps.drawing.OverlayType.POLYLINE
            ]
        )
        @loading = true
        @updateSite()
        @loading = false

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if overlay.type == "Point"
            nbPoints = @_googleMaps.getCountOverlays('Point')
            if nbPoints <= 0
              isModified = true
          else if overlay.type == "LineString"
            @checkLength(overlay)
            isModified = true
            # when use mouseup, overlay is still not changed.
            @_googleMaps.addListener(overlay, 'mouseout', (event) =>
              @checkLength(overlay)
            )
          else
            console.log("Error : géométrie non autorisée "+overlay.type)
          if isModified
            @updateSite()
            @_googleMaps.addListener(overlay, 'rightclick', (event) =>
              @_googleMaps.deleteOverlay(overlay)
            )
            return true
          return false

      checkLength: (overlay) ->
        length = google.maps.geometry.spherical.computeLength(overlay.getPath())
        if length < 1800
          overlay.setOptions(strokeColor: '#800090')
        else if length > 2200
          overlay.setOptions(strokeColor: '#FF0000')
        else
          overlay.setOptions(strokeColor: '#000000')
