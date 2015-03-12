'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_map_routier', [])
  .factory 'ProtocoleMapRoutier', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapRoutier extends ProtocoleMap
      constructor: (@site, mapDiv, @allowEdit, @siteCallback) ->
        super @site, mapDiv, @allowEdit, @siteCallback
        if @allowEdit
          @_googleMaps.setDrawingManagerOptions(
            drawingControlOptions:
              position: google.maps.ControlPosition.TOP_CENTER
              drawingModes: [
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
          "Tracer le trajet complet en un seul trait. Le tracé doit atteindre 30 km ou plus.",
          "Sélectionner le point d'origine.",
          "Placer les limites des segments de 2 km (+/-20%) sur le tracet en partant du point d'origine. ",
          "Valider les segments."
        ]

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if @_step == 0
            if overlay.type != "LineString"
              console.log("Error : géométrie non autorisée "+overlay.type)
            else if @getCountOverlays()
              console.log("Error : LineString déjà présente")
            else
              # when use mouseup, overlay is still not changed.
              @_googleMaps.addListener(overlay, 'mouseout', (event) =>
                @_tracet.length = (@checkTotalLength()/1000).toFixed(1)
                @updateSite()
              )
              @_googleMaps.setDrawingManagerOptions(
                drawingControlOptions:
                  position: google.maps.ControlPosition.TOP_CENTER
                  drawingModes: []
                drawingMode: ''
              )
              @_totalLength += @checkLength(overlay)
              if @allowEdit
                @_googleMaps.addListener(overlay, 'rightclick', (event) =>
                  @_googleMaps.deleteOverlay(overlay)
                  @_tracet.overlay = undefined
                  @_tracet.length = 0
                  @_googleMaps.setDrawingManagerOptions(
                    drawingControlOptions:
                      position: google.maps.ControlPosition.TOP_CENTER
                      drawingModes: [
                        google.maps.drawing.OverlayType.POLYLINE
                      ]
                  )
                  @updateSite()
                )
              else
                overlay.setOptions(
                  draggable: false
                  editable: false
                )
              isModified = true
          if isModified
            @updateSite()
            return true
          return false

        saveOverlay: (overlay) =>
          @_tracet.overlay = overlay

        zoomChanged: ->
        mapsMoved: ->

      mapValidated: ->
        if @_step < 3
          return false
        return true
