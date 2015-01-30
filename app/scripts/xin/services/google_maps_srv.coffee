'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('xin_google_maps', [])
  .factory 'GoogleMaps', ($rootScope) ->
    class GoogleMaps
      constructor: (@div, @callbackDict) ->
        # Map center policy (lowest to highest priority) :
        # 1) go over France, 2) try to geolocalize user, 3) center on the site
        @_isMapCenteredOnSite = false
        # France
        @mapOptions =
          center: new google.maps.LatLng(46.71109, 1.7191036)
          zoom: 6
        @_map = new google.maps.Map(@div, @mapOptions)
        @_drawingManager = new google.maps.drawing.DrawingManager(
          drawingControl: true
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.MARKER,
              google.maps.drawing.OverlayType.POLYGON,
              google.maps.drawing.OverlayType.POLYLINE
            ]
          markerOptions:
            draggable: true
          polygonOptions:
            draggable: true
            editable: true
          polylineOptions:
            draggable: true
            editable: true
          rectangleOptions:
            draggable: true
            editable: true
        )
        @_drawingManager.setMap(@_map)
        # user Geoloc html5
        if navigator.geolocation
          navigator.geolocation.getCurrentPosition((position) =>
            if not @_isMapCenteredOnSite
              pos = new google.maps.LatLng(position.coords.latitude, position.coords.longitude)
              @_map.setCenter(pos)
              @_map.setZoom(9)
          )
        if @callbackDict.zoomChanged?
          google.maps.event.addListener(@_map, 'zoom_changed', @callbackDict.zoomChanged)
        if @callbackDict.mapsMoved?
          google.maps.event.addListener(@_map, 'dragend', @callbackDict.mapsMoved)
        @_overlay = []
        google.maps.event.addListener(@_drawingManager, 'overlaycomplete', @overlayCreated)

      overlayCreated: (event) =>
        new_overlay = event.overlay
        # Converting into mongo geoJSON type
        if (event.type == google.maps.drawing.OverlayType.MARKER)
          new_overlay.type = "Point"
        else if (event.type == google.maps.drawing.OverlayType.POLYGON)
          new_overlay.type = "Polygon"
        else if (event.type == google.maps.drawing.OverlayType.POLYLINE)
          new_overlay.type = "LineString"
        else
          return
        if @callbackDict.overlayCreated?(new_overlay)
          @_overlay.push(new_overlay)
        else
          new_overlay.setMap(null)

      addListener: google.maps.event.addListener

      loadMap: (mongoShapes, callbackDict=@callbackDict.overlayCreated) ->
        if not mongoShapes
          return
        for mongoShape, key in mongoShapes
          shape = mongoShape.geometries[0]
          topush = {}
          if shape.type == "Point"
            point = new google.maps.LatLng(shape.coordinates[0], shape.coordinates[1])
            topush = new google.maps.Marker(
              position: point
              draggable: true
            )
          else if shape.type == "Polygon"
            paths = []
            for latlng in shape.coordinates[0]
              point = new google.maps.LatLng(latlng[0], latlng[1])
              paths.push(point)
            topush = new google.maps.Polygon(
              paths: paths
              draggable: true
              editable: true
            )
          else if shape.type == "LineString"
            path = []
            for latlng in shape.coordinates
              point = new google.maps.LatLng(latlng[0], latlng[1])
              path.push(point)
            topush = new google.maps.Polyline(
              path: path
              draggable: true
              editable: true
            )
          else
            console.log('Error: Bad map shape', shape)
            continue
          topush.type = shape.type
          if @callbackDict.overlayCreated?(topush)
            topush.setMap(@_map)
            @_overlay.push(topush)
        return @_overlay

      saveMap: ->
        toSave = []
        for shape in @_overlay
          shapetosave = {}
          shapetosave.type = shape.type
          if shape.type == "Point"
            shapetosave.coordinates = [shape.getPosition().lat(), shape.getPosition().lng()]
          if shape.type == "Polygon"
            vertices = shape.getPath()
            latlngs = []
            for i in [1..vertices.getLength()]
              xy = vertices.getAt(i-1)
              latlngs.push([xy.lat(), xy.lng()])
            shapetosave.coordinates = [ latlngs ]
          if shape.type == "LineString"
            vertices = shape.getPath()
            latlngs = []
            for i in [1..vertices.getLength()]
              xy = vertices.getAt(i-1)
              latlngs.push([xy.lat(), xy.lng()])
            shapetosave.coordinates = latlngs
          toSave.push(shapetosave)
        return toSave

      deleteOverlay: (overlay) =>
        overlay.setMap(null)
        index = @_overlay.indexOf(overlay)
        @_overlay.splice(index, 1);

      getCountOverlays: (type = '') =>
        result = 0
        for overlay in @_overlay
          if type == ''
            result++
          else
            if overlay.type == type
              result++
        return result

      displayInfo: (overlay) ->
        infoWindow = new google.maps.InfoWindow()
        infoWindow.setContent("lat : " + overlay.getPosition().lat() + ", lng : " + overlay.getPosition().lng())
        infoWindow.open(@_map, overlay)

      getZoom: ->
        @_map.getZoom()

      setZoom: (level) ->
        @_map.setZoom(level)

      getCenter: ->
        @_map.getCenter()

      setCenter: (lat, lng) ->
        @_isMapCenteredOnSite = true
        @_map.setCenter(new google.maps.LatLng(lat, lng))

      getBounds: ->
        @_map.getBounds()

      getMap: ->
        return @_map

      setDrawingManagerOptions: (options) ->
        @_drawingManager.setOptions(options)

      # works with lineString and polygon
      isPolyInPolygon: (poly, polygon) ->
        vertices = poly.getPath()
        for i in [0..vertices.getLength()-1]
          if not google.maps.geometry.poly.containsLocation(vertices.getAt(i), polygon)
            return false
        return true

      emptyMap: ->
        for overlay in @_overlay
          overlay.setMap(null)
        @_overlay = []
