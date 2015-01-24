'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('xin_google_maps', [])
  .factory 'GoogleMaps', ($rootScope) ->
    class GoogleMaps
      constructor: (@div, eventCallback) ->
        # Map center policy (lowest to highest priority) :
        # 1) go over France, 2) try to geolocalize user, 3) center on the site
        @_isMapCenteredOnSite = false
        @eventCallback = eventCallback
        # France
        @mapOptions =
          center: new google.maps.LatLng(46.71109, 1.7191036)
          zoom: 6
        @_map = new google.maps.Map(@div, @mapOptions)
        @drawingManager = new google.maps.drawing.DrawingManager(
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
        @drawingManager.setMap(@_map)
        # user Geoloc html5
        if navigator.geolocation
          navigator.geolocation.getCurrentPosition((position) =>
            if not @_isMapCenteredOnSite
              pos = new google.maps.LatLng(position.coords.latitude, position.coords.longitude)
              @_map.setCenter(pos)
              @_map.setZoom(9)
          )

        @_overlay = []
        google.maps.event.addListener(@drawingManager, 'overlaycomplete', @overlayCreated)

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
        if @eventCallback?(new_overlay)
          @_overlay.push(new_overlay)
        else
          event.overlay.setMap(null)

      addListener: google.maps.event.addListener

      loadMap: (mongoShapes, eventCallback=@eventCallback) =>
        if not mongoShapes
          return
        newCenter =
          set: false
          center: null
        for mongoShape, key in mongoShapes
          shape = mongoShape.geometries[0]
          topush = {}
          if shape.type == "Point"
            point = new google.maps.LatLng(shape.coordinates[0], shape.coordinates[1])
            topush = new google.maps.Marker(
              position: point
              draggable: true
            )
            if (not newCenter.set)
              newCenter.set = true
              newCenter.center = point
          else if shape.type == "Polygon"
            paths = []
            for latlng in shape.coordinates[0]
              point = new google.maps.LatLng(latlng[0], latlng[1])
              paths.push(point)
              if (not newCenter.set)
                newCenter.set = true
                newCenter.center = point
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
              if (not newCenter.set)
                newCenter.set = true
                newCenter.center = point
            topush = new google.maps.Polyline(
              path: path
              draggable: true
              editable: true
            )
            if (not newCenter.set)
              newCenter.set = true
              newCenter.center = point
          else
            console.log('Error: Bad map shape', shape)
            continue
          topush.type = shape.type
          if @eventCallback?(topush)
            topush.setMap(@_map)
            @_overlay.push(topush)
        if (newCenter.set)
          @_map.setCenter(newCenter.center)
          @_map.setZoom(10)
          @_isMapCenteredOnSite = true

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

      getCountOverlays: (type) =>
        result = 0
        for overlay in @_overlay
          if overlay.type == type
            result++
        return result
