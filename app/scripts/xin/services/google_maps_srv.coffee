'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('xin_google_maps', [])
  .factory 'GoogleMaps', ($rootScope) ->
    class GoogleMaps
      constructor: (@div, eventCallback) ->
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
            pos = new google.maps.LatLng(position.coords.latitude, position.coords.longitude)
            @_map.setCenter(pos)
            @_map.setZoom(9)
          )

        @_overlay = []
        overlay = @_overlay
        google.maps.event.addListener(@drawingManager, 'overlaycomplete', (event) ->
          new_overlay = event.overlay
          new_overlay.type = event.type
          overlay.push(new_overlay)
          eventCallback?(event)
        )

      loadMap: (shapesInJson) ->
        if not shapesInJson
          return
        shapes = angular.fromJson(shapesInJson)
        for shape in shapes
          topush = {}
          if shape.type == google.maps.drawing.OverlayType.MARKER
            topush = new google.maps.Marker(
              position: new google.maps.LatLng(shape.lat, shape.lng)
            )
          else if shape.type == google.maps.drawing.OverlayType.POLYGON
            paths = []
            for latlng in shape.path
              paths.push(new google.maps.LatLng(latlng.lat, latlng.lng))
            topush = new google.maps.Polygon(
              paths: paths
            )
          else if shape.type == google.maps.drawing.OverlayType.POLYLINE
            path = []
            if not shape.path
              continue
            for latlng in shape.path
              path.push(new google.maps.LatLng(latlng.lat, latlng.lng))
            topush = new google.maps.Polyline(
              path: path
            )
          else
            console.log('Error: Bad map shape', shape)
            continue
          # TODO : Find why we need this fix...
          topush.type = shape.type
          topush.setMap(@_map)
          @_overlay.push(topush)

      saveMap: ->
        toSave = []
        for shape in @_overlay
          shapetosave = {}
          if shape.type == google.maps.drawing.OverlayType.MARKER
            shapetosave =
              lat: shape.getPosition().lat()
              lng: shape.getPosition().lng()
          if shape.type in [
            google.maps.drawing.OverlayType.POLYGON,
            google.maps.drawing.OverlayType.POLYLINE
          ]
            vertices = shape.getPath()
            latlngs = []
            for i in [1..vertices.getLength()]
              xy = vertices.getAt(i-1)
              lat = xy.lat()
              lng = xy.lng()
              latlngs.push({'lat': lat, 'lng': lng})
            shapetosave =
              path: latlngs
          shapetosave.type = shape.type
          toSave.push(shapetosave)
        return angular.toJson(toSave, false)
