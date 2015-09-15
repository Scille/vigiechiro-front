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
            message: "Définir vos points à l'intérieur du carré."
          ,
            id: 'validLocalities'
            message: "Valider les points."
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
        onProjectionReady: =>
          @_projectionReady = true
          @loadMapEditContinue()
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
              if @_isOpportuniste
                @saveOverlay(overlay)
                # rightclick for delete overlay
                @_googleMaps.addListener(overlay, 'rightclick', (e) =>
                  @deleteOverlay(overlay)
                  if @getCountOverlays() < 1
                    @_step = 'editLocalities'
                  else
                    @_step = 'validLocalities'
                  @updateSite()
                )
                @_step = 'validLocalities'
              else
                if @getCountOverlays() >= @_max
                  @callbacks.displayError?("Nombre maximum de points atteint.")
                  return false
                @saveOverlay(overlay)
                @checkDistanceBetweenPoints(200)
                # rightclick for delete overlay
                @_googleMaps.addListener(overlay, 'rightclick', (e) =>
                  @deleteOverlay(overlay)
                  @checkDistanceBetweenPoints(200)
                  if @getCountOverlays() < @_min
                    @_step = 'editLocalities'
                  else
                    @_step = 'validLocalities'
                  @updateSite()
                )
                # when move overlay
                @_googleMaps.addListener(overlay, 'mouseout', (e) =>
                  @checkDistanceBetweenPoints(200)
                )
                if @getCountOverlays() >= @_min
                  @_step = 'validLocalities'
                else
                  @_step = 'editLocalities'
              @updateSite()
              return true
            return false

      saveOverlay: (overlay) =>
        locality = {}
        locality.overlay = overlay
        locality.name = @setLocalityName()
        locality.overlay.setOptions({ title: locality.name })
        locality.representatif = false
        locality.infowindow = @_googleMaps.createInfoWindow(locality.name)
        locality.infowindow.open(@_googleMaps.getMap(), overlay)
        @_localities.push(locality)

      setLocalityName: (name = 1) ->
        if @_isOpportuniste
          for locality in @_fixLocalities
            if parseInt(locality.name) == name
              return @setLocalityName(name + 1)
        for locality in @_localities
          if parseInt(locality.name) == name
            return @setLocalityName(name + 1)
        return name+''

      # Display warning if point < limit meters from another point
      checkDistanceBetweenPoints: (limit) ->
        overpass = false
        for i in [0..@_localities.length-2] when i >= 0
          if overpass
            break
          for j in [i+1..@_localities.length-1] when j < @_localities.length
            firstLocality = @_localities[i]
            secondLocality = @_localities[j]
            if firstLocality == secondLocality
              break
            distance = @_googleMaps.computeDistanceBetween(firstLocality.overlay.getPosition(), secondLocality.overlay.getPosition())
            if distance < limit
              overpass = true
              break
        if overpass
          @callbacks.displayWarning?("Attention, point à moins de 200 mètres d'un autre point.", 'PROXIMITY_POINTS')
        else
          @callbacks.hideWarning?('PROXIMITY_POINTS')
