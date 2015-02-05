'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_map_point_fixe', [])
  .factory 'ProtocoleMapPointFixe', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapPointFixe extends ProtocoleMap
      constructor: (@site, mapDiv, @allowEdit, @siteCallback) ->
        super @site, mapDiv, @allowEdit, @siteCallback
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
            if @allowEdit
              @_googleMaps.addListener(overlay, 'rightclick', (event) =>
                @_googleMaps.deleteOverlay(overlay)
                if @_googleMaps.getCountOverlays() == 0
                  @_step = 1
                @updateSite()
              )
            else
              overlay.setOptions(
                draggable: false
                editable: false
              )
            @_step = 2
            @updateSite()
            return true
          return false
        zoomChanged: => @mapsChanged()
        mapsMoved: => @mapsChanged()
