'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('xin_google_maps', [])
  .factory 'GoogleMaps', ($rootScope) ->
    class GoogleMaps
      constructor: (@div, @callbackDict = {}) ->
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
        # projection
        google.maps.event.addListenerOnce(@_map, "projection_changed", =>
          @callbackDict.onProjectionReady?()
        )

      overlayCreated: (e) =>
        new_overlay = e.overlay
        # Converting into mongo geoJSON type
        if (e.type == google.maps.drawing.OverlayType.MARKER)
          new_overlay.type = "Point"
        else if (e.type == google.maps.drawing.OverlayType.POLYGON)
          new_overlay.type = "Polygon"
        else if (e.type == google.maps.drawing.OverlayType.POLYLINE)
          new_overlay.type = "LineString"
        else
          return
        if !@callbackDict.overlayCreated?(new_overlay)
          new_overlay.setMap(null)

      addListener: google.maps.event.addListener

      clearListeners: google.maps.event.clearListeners

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

      fitBounds: (latLngBounds) ->
        @_map.fitBounds(latLngBounds)

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

      createLatLng: (lat, lng) ->
        new latLng(lat, lng)

      createPoint: (lat, lng, draggable = false, title = '') ->
        latlng = new google.maps.LatLng(lat, lng)
        return @createPointWithLatLng(latlng, draggable, title)

      createPointWithLatLng: (latlng, draggable = false, title = '') ->
        point = new google.maps.Marker(
          position: latlng
          map: @_map
          draggable: draggable
          title: title
        )
        return point

      createCircle: (center, radius, draggable = false, editable = false) ->
        new google.maps.Circle(
          map: @_map
          center: center
          radius: radius
          draggable: draggable
          editable: editable
        )

      createBounds: (sw = null, ne = null) ->
        bounds = new google.maps.LatLngBounds()
        if sw
          bounds.extend(sw)
        if ne
          bounds.extend(ne)
        return bounds

      extendBounds: (bounds, latlng) ->
        point = new google.maps.LatLng(latlng[0], latlng[1])
        bounds.extend(point)

      createPolygon: (latlngs, draggable = false, editable = false) ->
        paths = []
        for latlng in latlngs
          point = new google.maps.LatLng(latlng[0], latlng[1])
          paths.push(point)
        return @createPolygonWithPaths(paths, draggable, editable)

      createPolygonWithPaths: (paths, draggable = false, editable = false) ->
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
        return @createLineStringWithPath(path, draggable, editable)

      createLineStringWithPath: (path, draggable = false, editable = false) ->
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
          latlngs.push([vertice.lat(), vertice.lng()])
        return latlngs

      computeOffset: google.maps.geometry.spherical.computeOffset

      computeLength: (overlay) ->
        if !overlay?
          return 0
        return google.maps.geometry.spherical.computeLength(overlay.getPath())

      computeDistanceBetween: google.maps.geometry.spherical.computeDistanceBetween

      isLocationOnEdge: (point, latlngs, tolerance = 10e-9) ->
        poly = new google.maps.Polyline(
          path: latlngs
        )
        return google.maps.geometry.poly.isLocationOnEdge(point, poly, tolerance)

      findClosestPointOnPath: (drop_pt, path_pts, banned = []) ->
        # Stores the distances of each pt on the path from the marker point
        distances = []
        # Stores the key of point on the path that corresponds to a distance
        distance_keys = []
        # For each point on the path
        for key in [0..path_pts.length-1]
          toBan = false
          for ban in banned
            if path_pts[key].lat() == ban.getPosition().lat() and
               path_pts[key].lng() == ban.getPosition().lng()
              toBan = true
              break
          if toBan
            continue
          # Find the distance in a linear crows-flight line between the marker point and the current path point
          d = google.maps.geometry.spherical
            .computeDistanceBetween(drop_pt, path_pts[key])
          # Store the distances and the key of the pt that matches that distance
          distances[key] = d
          distance_keys[d] = key
        # Return the latLng obj of the closest point to the markers drag origin.
        return path_pts[distance_keys[_.min(distances)]]

      interpolate: (from, to, fraction) ->
        projection = @_map.getProjection()
        pointFrom = projection.fromLatLngToPoint(from)
        pointTo = projection.fromLatLngToPoint(to)
        # Adjust for lines that cross the 180 meridian
        if (Math.abs(pointTo.x-pointFrom.x) > 128)
          if( pointTo.x > pointFrom.x )
            pointTo.x -= 256
          else
            pointTo.x += 256
        # Calculate point between
        x = pointFrom.x + (pointTo.x - pointFrom.x) * fraction
        y = pointFrom.y + (pointTo.y - pointFrom.y) * fraction
        pointBetween = new google.maps.Point(x, y)
        # Project back to lat/lng
        latLngBetween = projection.fromPointToLatLng(pointBetween)
        return latLngBetween

      trigger: google.maps.event.trigger

      hideDrawingManager: ->
        @setDrawingManagerOptions(
          drawingControl: false
          drawingMode: ''
        )
