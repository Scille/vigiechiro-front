'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_map_routier', [])
  .factory 'ProtocoleMapRoutier', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapRoutier extends ProtocoleMap
      constructor: (@site, mapDiv, @allowEdit, @siteCallback) ->
        @_totalLength = 0
        super @site, mapDiv, @allowEdit, @siteCallback
        if @allowEdit
          @_googleMaps.setDrawingManagerOptions(
            drawingControlOptions:
              position: google.maps.ControlPosition.TOP_CENTER
              drawingModes: [
                google.maps.drawing.OverlayType.MARKER
                google.maps.drawing.OverlayType.POLYLINE
              ]
          )
        else
          @_googleMaps.setDrawingManagerOptions(drawingControl: false)
        @loading = true
        @updateSite()
        @loading = false

      getSteps: ->
        return [
          "Positionner le point d'origine.",
          "Tracer le parcours par plusieurs segments de 2 km (+/-10%). "+
          "Les segments trop courts sont en violet et les trop longs en rouge.",
          "Atteindre une longueur de tracé globale de 30 km ou plus. "+
          "Longueur actuelle "+@_totalLength+" mètres"
        ]

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if overlay.type == "Point"
            nbPoints = @_googleMaps.getCountOverlays('Point')
            if nbPoints <= 0
              @_step = 1
              isModified = true
          else if overlay.type == "LineString"
            @_totalLength += @checkLength(overlay)
            isModified = true
            # when use mouseup, overlay is still not changed.
            @_googleMaps.addListener(overlay, 'mouseout', (event) =>
              @checkLength(overlay)
              @_totalLength = @_googleMaps.getTotalLength()
              @updateSite()
            )
          else
            console.log("Error : géométrie non autorisée "+overlay.type)
          if isModified
            @updateSite()
            if @allowEdit
              @_googleMaps.addListener(overlay, 'rightclick', (event) =>
                @_googleMaps.deleteOverlay(overlay)
                @_totalLength = @_googleMaps.getTotalLength()
                @updateSite()
              )
            else
              overlay.setOptions(
                draggable: false
                editable: false
              )
            return true
          return false
