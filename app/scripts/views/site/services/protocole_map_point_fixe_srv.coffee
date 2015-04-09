'use strict'


angular.module('protocole_map_point_fixe', [])
  .factory 'ProtocoleMapPointFixe', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapPointFixe extends ProtocoleMap
      constructor: (@site, mapDiv, @siteCallback) ->
        super @site, mapDiv, @siteCallback
        @_steps = [
          "Positionner la zone de sélection aléatoire.",
          "Cliquer sur la carte pour sélection la grille stoc correspondante.",
          "Définir au moins 1 localité à l'intérieur du carré."
          "Valider les localités."
        ]
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.MARKER
            ]
        )
        @_googleMaps.setDrawingManagerOptions(drawingControl: false)
        @loading = true
        @updateSite()
        @loading = false

      clearMap: ->
        @_googleMaps.setDrawingManagerOptions(
          drawingControl: false
          drawingMode: ''
        )
        for localite in @_localites
          localite.overlay.setMap(null)
        @_localites = []
        @_step = 0
        if @_circleLimit?
          @_circleLimit.setMap(null)
          @_circleLimit = null
        @_newSelection = false
        if Object.keys(@_grilleStoc).length
          @_grilleStoc.item.setMap(null)
          @_grilleStoc = {}
        @updateSite()

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
              if @getCountOverlays() < 1
                @_step = 2
              else
                @_step = 3
              @updateSite()
            )
            if @getCountOverlays() >= 1
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
