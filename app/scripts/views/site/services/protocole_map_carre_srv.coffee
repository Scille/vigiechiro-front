'use strict'


angular.module('protocole_map_carre', [])
  .factory 'ProtocoleMapCarre', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapCarre extends ProtocoleMap
      constructor: (@site, mapDiv, @allowEdit, @siteCallback) ->
        super @site, mapDiv, @allowEdit, @siteCallback
        @_steps = [
          "Positionner la zone de sélection aléatoire.",
          "Cliquer sur la carte pour sélection la grille stoc correspondante.",
          "Définir entre 5 et 13 localités à l'intérieur du carré."
          "Valider les localités."
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
            @saveOverlay(overlay)
            @_googleMaps.addListener(overlay, 'rightclick', (e) =>
              @deleteOverlay(overlay)
              if @getCountOverlays() < 5
                @_step = 2
              else
                @_step = 3
              @updateSite()
            )
            if @getCountOverlays() >= 5
              @_step = 3
            else
              @_step = 2
            @updateSite()
            return true
          return false

      saveOverlay: (overlay) =>
        localite = {}
        localite.overlay = overlay
        localite.name = @setLocaliteName()
        localite.overlay.setOptions({ title: localite.name })
        localite.representatif = false
        @_localites.push(localite)

      mapValidated: ->
        if @_step == 4
          return true
        else
          return false

      setLocaliteName: (name = 1) ->
        used = false
        for localite in @_localites
          if parseInt(localite.name) == name
            return @setLocaliteName(name + 1)
        return name+''
