'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('xin_google_maps', ['xin_storage'])
  .factory 'GoogleMaps', ($rootScope, storage) ->
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
              google.maps.drawing.OverlayType.POLYLINE,
              google.maps.drawing.OverlayType.RECTANGLE
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
              map: @_map
            )
#    if shape.type == google.maps.drawing.OverlayType.POLYGON
#      topush = new google.maps.Polygon(
#        paths: shape.paths
#      )
#      topush.setMap(scope.map);
#    if shape.type == google.maps.drawing.OverlayType.POLYLINE
#      topush = new google.maps.Polyline(
#        path: shape.path
#      )
#      topush.setMap(scope.map)
#    if shape.type == google.maps.drawing.OverlayType.RECTANGLE
#      topush = new google.maps.Rectangle(
#        map: scope.map
#        bounds: shape.bounds
#      )
          @_overlay.push(topush)

      saveMap: () ->
        toSave = []
        for shape in @_overlay
          shapetosave = {}
          if shape.type == google.maps.drawing.OverlayType.MARKER
            shapetosave =
              type: google.maps.drawing.OverlayType.MARKER
              lat: shape.getPosition().lat()
              lng: shape.getPosition().lng()
          if shape.type == google.maps.drawing.OverlayType.POLYGON
            shapetosave =
              type: google.maps.drawing.OverlayType.POLYGON
              paths: shape.getPaths()
          if shape.type == google.maps.drawing.OverlayType.POLYLINE
            shapetosave =
              type: google.maps.drawing.OverlayType.POLYLINE
              path: shape.getPath()
          if shape.type == google.maps.drawing.OverlayType.RECTANGLE
            shapetosave =
              type: google.maps.drawing.OverlayType.RECTANGLE
              bounds: shape.getBounds()
          toSave.push(shapetosave)
        shapesToJson = angular.toJson(toSave, false)
