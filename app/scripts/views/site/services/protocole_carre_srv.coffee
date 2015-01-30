'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_carre', [])
  .factory 'ProtocoleCarre', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleCarre extends ProtocoleMap
      constructor: (@site, mapDiv, @siteCallback) ->
        super @site, mapDiv, @siteCallback
        @_steps = [
          "Sélectionner un carré.",
          "Définir les localités à l'intérieur du carré."
        ]
        @_googleMaps.setDrawingManagerOptions(drawingControl: false)
        @loading = true
        @updateSite()
        @loading = false

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if overlay.type == "Point"
            if google.maps.geometry.poly.containsLocation(overlay.getPosition(), @_grille[0].item)
              isModified = true
          else if overlay.type == "Polygon" or overlay.type == "LineString"
            if @_googleMaps.isPolyInPolygon(overlay, @_grille[0].item)
              isModified = true
          if isModified
            @_googleMaps.addListener(overlay, 'rightclick', (event) =>
              @_googleMaps.deleteOverlay(overlay)
              if @_googleMaps.getCountOverlays() == 0
                @_step = 1
              @updateSite()
            )
            @_step = 2
            @updateSite()
            return true
          return false
        zoomChanged: => @mapsChanged()
        mapsMoved: => @mapsChanged()
