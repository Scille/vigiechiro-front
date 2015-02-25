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
          @callbackDict.saveOverlay?(new_overlay)
        else
          new_overlay.setMap(null)

      addListener: google.maps.event.addListener

      deleteOverlay: (overlay) ->
        overlay.setMap(null)

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

      isPointInPolygon: (marker, polygon) ->
        result = google.maps.geometry.poly.containsLocation(marker.getPosition(),
                                                            polygon)
        return result

      # works with lineString and polygon
      isPolyInPolygon: (poly, polygon) ->
        vertices = poly.getPath()
        for i in [0..vertices.getLength()-1]
          if not google.maps.geometry.poly.containsLocation(vertices.getAt(i), polygon)
            return false
        return true

      createPoint: (lat, lng, draggable = false) ->
        latlng = new google.maps.LatLng(lat, lng)
        point = new google.maps.Marker(
          position: latlng
          map: @_map
          draggable: draggable
        )
        return point

      createPolygon: (latlngs, draggable = false, editable = false) ->
        paths = []
        for latlng in latlngs
          point = new google.maps.LatLng(latlng[0], latlng[1])
          paths.push(point)
        polygon = new google.maps.Polygon(
          paths: paths
          map: @_map
          draggable: draggable
          editable: editable
        )
        return polygon

      createLineString: (latlngs, draggable = false, editable = false) ->
        path = []
        for latlng in latlngs
          point = new google.maps.LatLng(latlng[0], latlng[1])
          path.push(point)
        lineString = new google.maps.Polyline(
          path: path
          map: @_map
          draggable: draggable
          editable: editable
        )
        return lineString

      getPosition: (overlay) ->
        return [overlay.getPosition().lat(), overlay.getPosition().lng()]

      getPath: (overlay) ->
        vertices = overlay.getPath()
        latlngs = []
        for i in [1..vertices.getLength()]
          vertice = vertices.getAt(i-1)
          latlngs.push([xy.lat(), xy.lng()])
        return latlngs

      computeLength: (overlay) ->
        return google.maps.geometry.spherical.computeLength(overlay.getPath())
