'use strict'


angular.module('protocole_map_carre', [])
  .factory 'ProtocoleMapCarre', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapCarre extends ProtocoleMap
      constructor: (mapDiv, @typeProtocole, @callbacks) ->
        super mapDiv, @typeProtocole, @callbacks
        @_min = 5
        @_max = 13
        @_steps = [
            id: 'start'
            message: "Positionner la zone de sélection aléatoire."
          ,
            id: 'selectGrilleStoc'
            message: "Cliquer sur la carte pour sélection la grille stoc correspondante."
          ,
            id: 'editLocalities'
            message: "Définir entre 5 et 13 localités à l'intérieur du carré."
          ,
            id: 'validLocalities'
            message: "Valider les localités."
          ,
            id: 'end'
            message: "Cartographie achevée."
        ]
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.MARKER
            ]
        )
        @_googleMaps.setDrawingManagerOptions(drawingControl: false)
        @updateSite()

      mapCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if @_step == 'selectGrilleStoc'
            @getGrilleStoc(overlay)
            return false
          else
            if overlay.type == "Point"
              if @_googleMaps.isPointInPolygon(overlay, @_grilleStoc.overlay)
                isModified = true
            else
              @callbacks.displayError?("Mauvaise forme : " + overlay.type)
            if isModified
              if @getCountOverlays() >= @_max
                @callbacks.displayError?("Nombre maximum de localités atteint.")
                return false
              @saveOverlay(overlay)
              @_googleMaps.addListener(overlay, 'rightclick', (e) =>
                @deleteOverlay(overlay)
                if @getCountOverlays() < @_min
                  @_step = 'editLocalities'
                else
                  @_step = 'validLocalities'
                @updateSite()
              )
              if @getCountOverlays() >= @_min
                @_step = 'validLocalities'
              else
                @_step = 'editLocalities'
              @updateSite()
              return true
            return false

      saveOverlay: (overlay) =>
        localite = {}
        localite.overlay = overlay
        localite.name = @setLocalityName()
        localite.overlay.setOptions({ title: localite.name })
        localite.representatif = false
        @_localities.push(localite)

      setLocalityName: (name = 1) ->
        used = false
        for locality in @_localities
          if parseInt(locality.name) == name
            return @setLocalityName(name + 1)
        return name+''
