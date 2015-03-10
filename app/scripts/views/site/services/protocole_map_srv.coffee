'use strict'


angular.module('protocole_map', ['protocole_map_carre', 'protocole_map_point_fixe', 'protocole_map_routier'])
  .factory 'protocolesFactory', (ProtocoleMapCarre, ProtocoleMapRoutier, ProtocoleMapPointFixe) ->
    (site, protocoleAlgoSite, mapDiv, allowEdit = true, siteCallback = {}) ->
      if protocoleAlgoSite == 'ROUTIER'
        return new ProtocoleMapRoutier(site, mapDiv, allowEdit, siteCallback)
      else if protocoleAlgoSite == 'CARRE'
        return new ProtocoleMapCarre(site, mapDiv, allowEdit, siteCallback)
      else if protocoleAlgoSite == 'POINT_FIXE'
        return new ProtocoleMapPointFixe(site, mapDiv, allowEdit, siteCallback)
      else
        throw "Error : unknown protocole #{protocoleAlgoSite}"

  .factory 'ProtocoleMap', ($rootScope, Backend, GoogleMaps) ->
    class ProtocoleMap
      constructor: (@site, mapDiv, @allowEdit, @siteCallback) ->
        @_localites = []
        @_step = 0
        @_steps = []
        @_googleMaps = new GoogleMaps(mapDiv, @mapsCallback())
        # POINT_FIXE && PEDESTRE
        @_circleLimit = undefined
        @_newSelection = false
        @_grille = []
        # ROUTIER
        @_tracet = {}
        @_tracet.length = 0
        @_firstPoint = undefined
        @_lastPoint = undefined
        @_points = []
        @_segments = []
        @_padded_points = []

      mapValidated: ->
        return false

      selectGrilleStoc: ->
        @_step = 1
        @updateSite()

      validOrigin: (grille_stoc) ->
        cell = @createCell(grille_stoc.centre.coordinates[1],
                           grille_stoc.centre.coordinates[0])
        @validNumeroGrille(cell, grille_stoc.numero, grille_stoc._id)
        @removeOrigin()
        @updateSite()

      createOriginPoint: ->
        @_circleLimit = new google.maps.Circle(
          map: @_googleMaps.getMap()
          center: @_googleMaps.getCenter()
          radius: 10000
          draggable: true
        )

      removeOrigin: ->
        @_newSelection = true
        @_circleLimit.setMap(null)
        @_circleLimit.setDraggable(false)

      deleteValidCell: ->
        @_grille[0].item.setMap(null)
        @_grille = []

      getOrigin: ->
        return @_circleLimit

      allowMapChanged: ->
        if not @site.verrouille?
          return true
        return false

      allowOverlayCreated: ->
        if not @site.verrouille?
          return true
        return false

      updateSite: ->
        steps =
          steps: @getSteps()
          step: @_step
          loading: @loading
        if @siteCallback.updateSteps?
          @siteCallback.updateSteps(steps)
        if not @loading and @siteCallback.updateForm?
          @siteCallback.updateForm()

      saveMap: ->
        result = []
        for localite in @_localites
          localiteToSave = {}
          shapetosave = {}
          shapetosave.type = localite.overlay.type
          if shapetosave.type == "Point"
            shapetosave.coordinates = @_googleMaps.getPosition(localite.overlay)
          else if shapetosave.type == "Polygon"
            shapetosave.coordinates = [ @_googleMaps.getPath(localite.overlay) ]
          else if shapetosave.type == "LineString"
            shapetosave.coordinates = @_googleMaps.getPath(localite.overlay)
          else
            continue
          localiteToSave =
            name: localite.name
            geometries:
              type: 'GeometryCollection'
              geometries: [shapetosave]
            representatif: false
          result.push(localiteToSave)
        return result

      mapsCallback: ->
        overlayCreated: -> false
        saveOverlay: -> false
        zoomChanged: -> false
        mapsMoved: -> false

      setLocaliteName: ->
        return ''

      loadMap: ->
        # start loading
        @loading = true
        # generate grille_stoc
        if @site.grille_stoc?
          @_step = 2
          @_googleMaps.setCenter(
            @site.grille_stoc.centre.coordinates[1],
            @site.grille_stoc.centre.coordinates[0]
          )
          @_googleMaps.setZoom(14)
          newCell = @createCell(
            @site.grille_stoc.centre.coordinates[1],
            @site.grille_stoc.centre.coordinates[0]
          )
          @validNumeroGrille(newCell, @site.grille_stoc.numero, @site.grille_stoc._id)
        # load localites
        for localite in @site.localites or []
          newLocalite =
            name: localite.nom
            representatif: localite.representatif
          newLocalite.overlay = @loadGeoJson(localite.geometries)
          @_localites.push(newLocalite)
        # end loading
        @loading = false

      loadGeoJson: (geoJson, callback=@mapsCallback.overlayCreated) ->
        overlay = undefined
        if not geoJson
          return
        if geoJson.type == 'GeometryCollection'
          for geometry in geoJson.geometries
            return @loadGeoJson(geometry)
        if geoJson.type == 'Point'
          overlay = @_googleMaps.createPoint(geoJson.coordinates[0],
                                            geoJson.coordinates[1],
                                            true)
        else if geoJson.type == 'Polygon'
          overlay = @_googleMaps.createPolygon(geoJson.coordinates[0], true, true)
        else if geoJson.type == 'LineString'
          overlay = @_googleMaps.createLineString(geoJson.coordinates, true, true)
        else
          throw "Error: Bad GeoJSON object #{geoJson}"
        overlay.type = geoJson.type
        if !@mapsCallback().overlayCreated(overlay)
          @_googleMaps.deleteOverlay(overlay)
        return overlay

      getIdGrilleStoc: ->
        return @_grille[0].id

      mapsChanged: ->
        if @_step != 1
          return
        zoomLevel = @_googleMaps.getZoom()
        bounds = @_googleMaps.getBounds()
        if not bounds?
          return
        southWest = bounds.getSouthWest()
        northEast = bounds.getNorthEast()
        if zoomLevel > 11
          parameters =
            sw_lat: southWest.lat()
            sw_lng: southWest.lng()
            ne_lat: northEast.lat()
            ne_lng: northEast.lng()
          Backend.all('grille_stoc/rectangle').getList(parameters)
            .then (@createGrille)

      createGrille: (grille_stoc) =>
        validNumeroGrille = (cell) =>
          (event) => @validNumeroGrille(cell)
        grille_stoc = grille_stoc.plain()
        for cell in grille_stoc
          exist = false
          for item in @_grille
            if item.numero == cell.numero
              exist = true
              break
          if exist
            continue
          newCell = @createCell(cell.centre.coordinates[1], cell.centre.coordinates[0])
          @_googleMaps.addListener(newCell, 'click', validNumeroGrille(newCell))
          @_grille.push({"item": newCell, "numero": cell.numero, 'id': cell._id})

      createCell: (lat, lng) ->
        # 1000*racine(2)
        distance = 1000 * Math.sqrt(2)
        origine = new google.maps.LatLng(lat, lng)
        southWest = google.maps.geometry.spherical.computeOffset(origine, distance, -135)
        northEast = google.maps.geometry.spherical.computeOffset(origine, distance, 45)
        item = new google.maps.Polygon(
          paths: [
            new google.maps.LatLng(southWest.lat(), northEast.lng())
            new google.maps.LatLng(northEast.lat(), northEast.lng())
            new google.maps.LatLng(northEast.lat(), southWest.lng())
            new google.maps.LatLng(southWest.lat(), southWest.lng())
          ]
          map: @_googleMaps.getMap()
          fillOpacity: 0
          strokeColor: '#606060'
          strokeOpacity: 0.65
          strokeWeight: 0.5
        )
        return item

      validNumeroGrille: (cell, numero, id) =>
        nbStoc = @_grille.length
        if nbStoc
          for index in [nbStoc-1..0]
            if @_grille[index].item != cell
              @_grille[index].item.setMap(null)
              @_grille.splice(index, 1)
        else
          @_grille.push({"item": cell, "numero": numero, "id": id})
        @_grille[0].item.setOptions(
          strokeColor: '#00E000'
          strokeOpacity: 1
          strokeWeight: 2
        )
        @_step = 2
        @updateSite()
        if @allowEdit
          @_googleMaps.addListener(@_grille[0].item, 'rightclick', (event) =>
            if confirm("Etes vous sûre de vouloir supprimer ce carré ainsi que toutes les localités qu'il contient ?")
              @_step = 0
              @_grille[0].item.setMap(null)
              @_grille = []
              @_googleMaps.emptyMap()
              @updateSite()
              @mapsChanged()
          )
          @_googleMaps.setDrawingManagerOptions(drawingControl: true)

      checkLength: (overlay) ->
        length = @_googleMaps.computeLength(overlay)
        if length < 1800
          overlay.setOptions(strokeColor: '#800090')
        else if length > 2200
          overlay.setOptions(strokeColor: '#FF0000')
        else
          overlay.setOptions(strokeColor: '#000000')
        return length

      checkTotalLength: ->
        if !@_tracet.overlay?
          return 0
        overlay = @_tracet.overlay
        length = @_googleMaps.computeLength(overlay)
        if length < 30000
          overlay.setOptions(strokeColor: '#FF0000')
        else
          overlay.setOptions(strokeColor: '#000000')
        return length

      getSteps: ->
        return @_steps

      emptyMap: ->
        for localite in @_localites
          localite.overlay.setMap(null)
        @_localites = []

      deleteOverlay: (overlay) ->
        for localite, key in @_localites
          if localite.overlay == overlay
            @_googleMaps.deleteOverlay(localite.overlay)
            @_localites.splice(key, 1);
            return

      getCountOverlays: (type = '') ->
        if type == ''
          return @_localites.length
        else
          result = 0
          for localite in @_localites or []
            if localite.overlay.type == type
              result++
          return result

      getTotalLength: ->
        result = 0
        for localite in @_localites
          if localite.overlay.type == 'LineString'
            result += @_googleMaps.computeLength(localite.overlay)
        return result

      getTracetLength: ->
        return @_tracet.length

      validTracet: ->
        if !@_tracet.overlay?
          return false
        # Fix tracet
        @_googleMaps.clearListeners(@_tracet.overlay, 'rightclick')
        @_tracet.overlay.setOptions(
          draggable: false
          editable: false
        )
        @_step = 1
        @updateSite()
        # Create origin points choice
        path = @_tracet.overlay.getPath()
        nbPoint = path.length
        firstPoint = path.getAt(0)
        lastPoint = path.getAt(nbPoint-1)
        @_firstPoint = @_googleMaps.createPoint(firstPoint.lat(), firstPoint.lng())
        @_lastPoint = @_googleMaps.createPoint(lastPoint.lat(), lastPoint.lng())
        @_googleMaps.addListener(@_firstPoint, 'click', @validOriginPoint)
        @_googleMaps.addListener(@_lastPoint, 'click', @validOriginPoint)
        # Pad the points array
        interval = 10
        for key in [0..path.getLength()-1]
          current_point = path.getAt(key)
          next_point = path.getAt(key+1)
          # Check if we're on the last point
          if (typeof next_point != 'undefined')
            distance = @_googleMaps.computeDistanceBetween(current_point, next_point)
            nbSections = Math.floor(distance/interval)+1
            # Get a 10th of the difference in latitude
            lat_incr = (next_point.lat() - current_point.lat()) / nbSections
            # Get a 10th of the difference in longitude
            lng_incr = (next_point.lng() - current_point.lng()) / nbSections
            # Now add interval points at lat_incr & lng_incr intervals between current and next points
            # We add this to the new padded_points array
            for i in [0..nbSections-1]
              new_pt = new google.maps.LatLng(current_point.lat() + (i * lat_incr), current_point.lng() + (i * lng_incr))
              if !(key == 0 && i == 0)
                @_padded_points.push(new_pt)
        return true

      # Used for ROUTIER protocole
      validOriginPoint: (event) =>
        @_step = 2
        @_googleMaps.addListener(@_tracet.overlay, 'click', @addSegmentPoint)
        @_googleMaps.clearListeners(@_firstPoint, 'click')
        @_googleMaps.clearListeners(@_lastPoint, 'click')
        if event.latLng.lat() == @_firstPoint.getPosition().lat() &&
           event.latLng.lng() == @_firstPoint.getPosition().lng()
          @_firstPoint.setTitle("Départ")
          @_lastPoint.setTitle("Arrivée")
          @_points.push(@_firstPoint)
          @_points.push(@_lastPoint)
        else if event.latLng.lat() == @_lastPoint.getPosition().lat() &&
                event.latLng.lng() == @_lastPoint.getPosition().lng()
          @_firstPoint.setTitle("Arrivée")
          @_lastPoint.setTitle("Origine")
          @_points.push(@_lastPoint)
          @_points.push(@_firstPoint)
        else
          throw "Error : undefined origin point"
        @generateSegments()
        @updateSite()

      addSegmentPoint: (e) =>
        closestPoint = @_googleMaps.findClosestPointOnPath(e.latLng, @_padded_points)
        point = @_googleMaps.createPoint(closestPoint.lat(), closestPoint.lng())
        @_googleMaps.addListener(point, 'rightclick', (e) =>
          @deletePoint(point)
        )
        point.setOptions({draggable: true})
        @_googleMaps.addListener(point, 'dragend', (e) =>
          point.setPosition(@_googleMaps
            .findClosestPointOnPath(e.latLng, @_padded_points))
        )
        @_googleMaps.addListener(point, 'drag', (e) =>
          point.setPosition(@_googleMaps
            .findClosestPointOnPath(e.latLng, @_padded_points))
        )
        # find vertex of new point
        path = @_tracet.overlay.getPath()
        nbPoints = path.getLength()
        index = undefined
        for key in [0..nbPoints-2]
          vertex = [path.getAt(key), path.getAt(key+1)]
          if @_googleMaps.isLocationOnEdge(point.getPosition(), vertex)
            index = key
            break
        if !index?
          throw "Error : Can not find Edge of new point"
        for pt, key in @_points
          console.log(key)
#        @_points.push(point)
        @generateSegments()

      deletePoint: (overlay) ->
        for point, key in @_points
          if point == overlay
            @_googleMaps.deleteOverlay(point)
            @_points.splice(key, 1)
            @generateSegments()
            return

      generateSegments: ->
        for segment in @_segments
          @_googleMaps.deleteOverlay(segment)
        @_segments = []
        nbPoints = @_points.length
        key = 0
        while (key < nbPoints-2)
          start = @_points[index]
          stop = @_points[index+1]
          key +=2
        @_googleMaps.createLineString()
