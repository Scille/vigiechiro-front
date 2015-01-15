'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('xin_google_maps', [])
  .factory 'GoogleMaps', ($rootScope) ->
    class GoogleMaps
      constructor: (@div) ->
        @mapOptions =
          # Paris
          center: new google.maps.LatLng(48.8588589, 2.3470599)
          zoom: 8
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
        @_overlay = []
        overlay = @_overlay
        google.maps.event.addListener(@drawingManager, 'overlaycomplete', (event) ->
          new_overlay = event.overlay
          new_overlay.type = event.type
          overlay.push(new_overlay)
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
          if shape.type == google.maps.drawing.OverlayType.POLYGON
            paths = []
            for latlng in shape.path
              paths.push(new google.maps.LatLng(latlng.lat, latlng.lng))
            topush = new google.maps.Polygon(
              paths: paths
            )
          if shape.type == google.maps.drawing.OverlayType.POLYLINE
            path = []
            if not shape.path
              continue
            for latlng in shape.path
              path.push(new google.maps.LatLng(latlng.lat, latlng.lng))
            topush = new google.maps.Polyline(
              path: path
            )
          topush.setMap(@_map)
          @_overlay.push(topush)

      saveMap: () ->
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
        shapesToJson = angular.toJson(toSave, false)
