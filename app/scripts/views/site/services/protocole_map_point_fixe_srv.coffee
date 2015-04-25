'use strict'


angular.module('protocole_map_point_fixe', [])
  .factory 'ProtocoleMapPointFixe', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapPointFixe extends ProtocoleMap
      constructor: (mapDiv, @siteCallback) ->
        super mapDiv, @siteCallback
        @_smallGrille = []
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
          if @_step == 1
            @getGrilleStoc(overlay)
            return false
          else
            if overlay.type == "Point"
              if @_googleMaps.isPointInPolygon(overlay, @_grilleStoc.item)
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

      validNumeroGrille: (cell, numero, id, editable = false) =>
        # remove click event on map
        @_googleMaps.clearListeners(@_googleMaps.getMap(), 'click')
        # change color of cell
        cell.setOptions(
          strokeColor: '#00E000'
          strokeOpacity: 1
          strokeWeight: 2
          fillColor: '#000000'
          fillOpacity: 0
        )
        # get Path of cell
        path = cell.getPath()
        # register grille stoc
        @_grilleStoc =
          item: cell
          numero: numero
          id: id
        lat = (path.getAt(0).lat() + path.getAt(2).lat()) / 2
        lng = (path.getAt(0).lng() + path.getAt(2).lng()) / 2
        @_googleMaps.setCenter(lat, lng)
        @_googleMaps.setZoom(13)
        @_step = 2
        @updateSite()
        @_googleMaps.setDrawingManagerOptions(drawingControl: true)
        if editable
          @_googleMaps.addListener(@_grilleStoc.item, 'rightclick', (e) =>
            if confirm("Cette opération supprimera toutes les localités.")
              @_step = 0
              @_grilleStoc.item.setMap(null)
              @_grilleStoc = {}
              for localite in @_localites or []
                @_googleMaps.deleteOverlay(localite.overlay)
              @_localites = []
              @_googleMaps.setDrawingManagerOptions(drawingControl: false)
              @selectGrilleStoc()
              @updateSite()
          )
        @displaySmallGrille()

      # Display 4x4 grille into grille stoc
      displaySmallGrille: ->
        for small in @_smallGrille or []
          small.setMap(null)
        @_smallGrille = []
        if !@_grilleStoc? or !@_grilleStoc.item?
          return
        # Get Center
        p1 = @_grilleStoc.item.getPath().getAt(0)
        p2 = @_grilleStoc.item.getPath().getAt(2)
        center = @_googleMaps.interpolate(p1, p2, 0.5)
        # Get NW
        nw = @_googleMaps.computeOffset(center, 1000*Math.sqrt(2), -45)
        # Generate points
        p = []
        p[0] = []
        for i in [0..4]
          p[i] = []
          if i == 0
            p[0][0] = nw
          else
            p[i][0] = @_googleMaps.computeOffset(p[i-1][0], 500, 180)
          for j in [1..4]
            p[i][j] = @_googleMaps.computeOffset(p[i][j-1], 500, 90)
        # Generate Squares
        for i in [0..3]
          for j in [0..3]
            path = [p[i][j], p[i+1][j], p[i+1][j+1], p[i][j+1]]
            center = @_googleMaps.interpolate(path[0], path[2], 0.5)
            circle = @_googleMaps.createCircle(center, 25, false, false)
            circle.setOptions(
              fillOpacity: 0
              fillColor: '#000000'
              strokeWeight: 1
              strokeOpacity: 0.2
              strokeColor: '#000000'
            )
            @_smallGrille.push(circle)
        @_smallGrille[0].name = 'A1'
        @_smallGrille[1].name = 'A2'
        @_smallGrille[2].name = 'B1'
        @_smallGrille[3].name = 'B2'
        @_smallGrille[4].name = 'C2'
        @_smallGrille[5].name = 'C1'
        @_smallGrille[6].name = 'D2'
        @_smallGrille[7].name = 'D1'
        @_smallGrille[8].name = 'E1'
        @_smallGrille[9].name = 'E2'
        @_smallGrille[10].name = 'F1'
        @_smallGrille[11].name = 'F2'
        @_smallGrille[12].name = 'G2'
        @_smallGrille[13].name = 'G1'
        @_smallGrille[14].name = 'H2'
        @_smallGrille[15].name = 'H1'
