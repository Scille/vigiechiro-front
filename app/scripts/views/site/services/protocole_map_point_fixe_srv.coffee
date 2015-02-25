'use strict'


angular.module('protocole_map_point_fixe', [])
  .factory 'ProtocoleMapPointFixe', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapPointFixe extends ProtocoleMap
      constructor: (@site, mapDiv, @allowEdit, @siteCallback) ->
        super @site, mapDiv, @allowEdit, @siteCallback
        @_steps = [
          "Positionner le point d'origine.",
          "Sélectionner un carré.",
          "Définir au moins 1 localité à l'intérieur du carré."
        ]
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.MARKER
            ]
        )
        if (@_step < 2 or not @allowEdit)
          @_googleMaps.setDrawingManagerOptions(drawingControl: false)
        @loading = true
        @updateSite()
        @loading = false

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if overlay.type == "Point"
            if @_googleMaps.isPointInPolygon(overlay, @_grille[0].item)
              isModified = true
          else
            throw "Error : bad shape type " + overlay.type
          if isModified
            if @allowEdit
              @_googleMaps.addListener(overlay, 'rightclick', (event) =>
                @deleteOverlay(overlay)
                if @getCountOverlays() == 0
                  @_step = 2
                @updateSite()
              )
            else
              overlay.setOptions(
                draggable: false
                editable: false
              )
            # TODO : Check number of overlay
            @_step = 2
            @updateSite()
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
