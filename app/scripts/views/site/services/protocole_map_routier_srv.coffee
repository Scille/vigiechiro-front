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
          "Tracer le trajet complet en un seul trait. Le tracé doit atteindre 30 km ou plus."+
          "Longueur actuelle "+@_totalLength+" mètres",
          "Sélectionner le point d'origine.",
          "Tracer les segments de 2 km (+/-10%). "+
          "Les segments trop courts sont en violet et les trop longs en rouge."
        ]

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if overlay.type == "Point"
            nbPoints = @getCountOverlays('Point')
            if nbPoints <= 0
              @_step = 1
              isModified = true
          else if overlay.type == "LineString"
            @_totalLength += @checkLength(overlay)
            isModified = true
            # when use mouseup, overlay is still not changed.
            @_googleMaps.addListener(overlay, 'mouseout', (event) =>
              @checkLength(overlay)
              @_totalLength = @getTotalLength()
              @updateSite()
            )
          else
            console.log("Error : géométrie non autorisée "+overlay.type)
          if isModified
            @updateSite()
            if @allowEdit
              @_googleMaps.addListener(overlay, 'rightclick', (event) =>
                @_googleMaps.deleteOverlay(overlay)
                @_totalLength = @getTotalLength()
                @updateSite()
              )
            else
              overlay.setOptions(
                draggable: false
                editable: false
              )
            return true
          return false

        saveOverlay: (overlay) =>
          localite = {}
          localite.overlay = overlay
          localite.name = @setLocaliteName()
          localite.representatif = false
          @_localites.push(localite)

        zoomChanged: => @mapsChanged()
        mapsMoved: => @mapsChanged()

      setLocaliteName: (name = 1) ->
        used = false
        for localite in @_localites
          if parseInt(localite.name) == name
            return @setLocaliteName(name + 1)
        return name+''
