'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_map_routier', [])
  .factory 'ProtocoleMapRoutier', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapRoutier extends ProtocoleMap
      constructor: (@site, mapDiv, @siteCallback) ->
        super @site, mapDiv, @siteCallback
        @_tracet = {}
        @_tracet.length = 0
        @_firstPoint = null
        @_lastPoint = null
        @_points = []
        @_segments = []
        @_padded_points = []
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.POLYLINE
            ]
        )
        @loading = true
        @updateSite()
        @loading = false

      getSteps: ->
        return [
          "Tracer le trajet complet en un seul trait. Le tracé doit atteindre 30 km ou plus.",
          "Sélectionner le point d'origine.",
          "Placer les limites des segments de 2 km (+/-20%) sur le tracet en partant du point d'origine. ",
          "Valider les segments."
        ]

      clearMap: ->
        for localite in @_localites
          localite.overlay.setMap(null)
        @_localites = []
        @_step = 0
        if @_tracet?
          @_tracet.overlay.setMap(null)
          @_tracet =
            length: 0
        if @_firstPoint?
          @_firstPoint.setMap(null)
          @_firstPoint = null
        if @_lastPoint?
          @_lastPoint.setMap(null)
          @_lastPoint = null
        @_points = []
        @_segments = []
        @_padded_points = []
        @updateSite()

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if @_step == 0
            if overlay.type != "LineString"
              console.log("Error : géométrie non autorisée "+overlay.type)
            else if @getCountOverlays()
              console.log("Error : LineString déjà présente")
            else
              isModified = true
              @_tracet.overlay = overlay
              @_tracet.length = @checkLength(overlay)
              @_googleMaps.addListener(overlay, 'mouseout', (e) =>
                @_tracet.length = (@checkTotalLength()/1000).toFixed(1)
                @updateSite()
              )
              @_googleMaps.setDrawingManagerOptions(
                drawingControlOptions:
                  position: google.maps.ControlPosition.TOP_CENTER
                  drawingModes: []
                drawingMode: ''
              )
              @_googleMaps.addListener(overlay, 'rightclick', (e) =>
                @_googleMaps.deleteOverlay(overlay)
                @_tracet.overlay = undefined
                @_tracet.length = 0
                @_googleMaps.setDrawingManagerOptions(
                  drawingControlOptions:
                    position: google.maps.ControlPosition.TOP_CENTER
                    drawingModes: [
                      google.maps.drawing.OverlayType.POLYLINE
                    ]
                )
                @updateSite()
              )
          else if @_step == 4
            if overlay.type != "LineString"
              console.log("Error : géométrie non autorisée "+overlay.type)
            else
              overlay.setOptions(
                draggable: false
                editable: false
              )
              isModified = true
          if isModified
            @updateSite()
            return true
          return false

      mapValidated: ->
        if @_step < 3
          return false
        return true

      getTracetLength: ->
        return @_tracet.length

      validTracet: ->
        if !@_tracet.overlay?
          return false
        # @_tracet becomes uneditable
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
        for key in [0..path.getLength()-2]
          current_point = path.getAt(key)
          next_point = path.getAt(key+1)
          distance = @_googleMaps.computeDistanceBetween(current_point, next_point)
          nbSections = Math.floor(distance/interval)+1
          for i in [0..nbSections-1]
            new_pt = @_googleMaps.interpolate(current_point, next_point, i/nbSections)
            if !(key == 0 && i == 0)
              if @_googleMaps.isLocationOnEdge(new_pt, [current_point, next_point])
                @_padded_points.push(new_pt)
              else
                console.log("Error : some points not on path")
        return true

      validOriginPoint: (e) =>
        # Up to date step
        @_step = 2
        # If click on first point
        if e.latLng.lat() == @_firstPoint.getPosition().lat() &&
           e.latLng.lng() == @_firstPoint.getPosition().lng()
          @_points.push(@_firstPoint)
          @_points.push(@_lastPoint)
        # If click on last point
        else
          @_points.push(@_lastPoint)
          @_points.push(@_firstPoint)
          path = @_tracet.overlay.getPath()
          new_path = []
          for i in [0..path.getLength()-1]
            new_path.push(path.pop())
          @_tracet.overlay.setPath(new_path)
        # Set titles and edge
        @_points[0].setTitle("Départ")
        @_points[1].setTitle("Arrivée")
        @_points[0].edge = 0
        @_points[1].edge = @_tracet.overlay.getPath().getLength()-2
        # Events
        @_googleMaps.addListener(@_tracet.overlay, 'click', @addSegmentPoint)
        @_googleMaps.clearListeners(@_firstPoint, 'click')
        @_googleMaps.clearListeners(@_lastPoint, 'click')
        # Others
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
          @updatePointPosition(point)
          @generateSegments()
        )
        @_googleMaps.addListener(point, 'drag', (e) =>
          point.setPosition(@_googleMaps
            .findClosestPointOnPath(e.latLng, @_padded_points))
        )
        # find vertex of new point
        path = @_tracet.overlay.getPath()
        nbPoints = path.getLength()
        index = undefined
        vertex = []
        for key in [0..nbPoints-2]
          currVertex = [path.getAt(key), path.getAt(key+1)]
          vertex.push(currVertex)
          if @_googleMaps.isLocationOnEdge(point.getPosition(), currVertex)
            index = key
            point.edge = key
        if !index?
          @_googleMaps.deleteOverlay(point)
          throw "Error : Can not find Edge of new point"
        stop = false
        for pt, key in @_points
          for currVertex, keyVertex in vertex
            if @_googleMaps.isLocationOnEdge(pt.getPosition(), currVertex)
              if keyVertex < index
                break
              else if keyVertex > index
                stop = true
                @_points.splice(key, 0, point)
                break
              else
                d1 = @_googleMaps.computeDistanceBetween(currVertex[0], point.getPosition())
                d2 = @_googleMaps.computeDistanceBetween(currVertex[0], pt.getPosition())
                if d1 < d2
                  stop = true
                  @_points.splice(key, 0, point)
                  break
                else
                  break
          if stop
            break
        @generateSegments()

      deletePoint: (overlay) ->
        for point, key in @_points
          if point == overlay
            @_googleMaps.deleteOverlay(point)
            @_points.splice(key, 1)
            @generateSegments()
            return

      generateSegments: ->
        colors = [
          '#FF8000'
          '#FFFF00'
          '#80FF00'
          '#00FF00'
          '#00FF80'
          '#00FFFF'
          '#0080FF'
          '#0000FF'
          '#8000FF'
          '#FF00FF'
          '#FF0080'
        ]
        for segment in @_segments
          @_googleMaps.deleteOverlay(segment)
        @_segments = []
        nbPoints = @_points.length
        key = 0
        while (key < nbPoints-1)
          segment = @generateSegment(key)
          segment.setOptions({ strokeColor: colors[(key/2)%11], zIndex: 10 })
          @_googleMaps.addListener(segment, 'click', @addSegmentPoint)
          @_segments.push(segment)
          key +=2

      # generate the segment between @_points[key] and @_points[key+1] points
      generateSegment: (key) ->
        tracet = @_tracet.overlay.getPath()
        path = []
        start = @_points[key]
        stop = @_points[key+1]
        path.push([start.getPosition().lat(), start.getPosition().lng()])
        if start.edge < stop.edge
          for corner in [start.edge+1..stop.edge]
            pt = tracet.getAt(corner)
            path.push([pt.lat(), pt.lng()])
        path.push([stop.getPosition().lat(), stop.getPosition().lng()])
        return @_googleMaps.createLineString(path)

      updatePointPosition: (point) ->
        path = @_tracet.overlay.getPath()
        for key in [0..path.getLength()-2]
          vertex = [path.getAt(key), path.getAt(key+1)]
          if @_googleMaps.isLocationOnEdge(point.getPosition(), vertex)
            point.edge = key

      validSegments: ->
        if !@_segments.length
          return false
        if @_points.length % 2
          throw "Error : odd number of points"
        # Events and points
        @_googleMaps.clearListeners(@_tracet.overlay, 'click')
        for segment in @_segments or []
          @_googleMaps.clearListeners(segment, 'click')
        max_key = @_points.length-1
        for key in [max_key..0]
          @_googleMaps.clearListeners(@_points[key], 'drag')
          @_googleMaps.clearListeners(@_points[key], 'dragend')
          if (key != 0 && key != max_key)
            @_points[key].setMap(null)
            @_points.splice(key, 1)
        # generation of sites
        localites = []
        for segment, key in @_segments
          @_googleMaps.deleteOverlay(segment)
          delta = @_googleMaps.computeLength(segment) / locBySegment
          path = segment.getPath()
          # For each site
          for secteur in [1..5]
            localite = {}
            localite.name = 'T '+(key+1)+' '+secteur
            currLength = 0
            secteurPath = [segment.getPath().getAt(0)]
            end = false
            while path.getLength() > 1 && !end
              d = @_googleMaps.computeDistanceBetween(path.getAt(0), path.getAt(1))
              if (d + currLength < delta)
                currLength += d
                secteurPath.push(path.getAt(1))
                path.removeAt(0)
              else
                end = true
                # Compute where is the cut point
                rest = delta - currLength
                ratio = rest / d
                cut_point = @_googleMaps.interpolate(path.getAt(0), path.getAt(1), ratio)
                # finish secteur and cut segment
                secteurPath.push(cut_point)
                path.setAt(0, cut_point)
            secteurLineString = @_googleMaps.createLineStringWithPath(secteurPath)
            secteurLineString.setOptions({'strokeColor': localite_colors[secteur-1]})
            secteurLineString.setOptions({'zIndex': 11})
            localite.overlay = secteurLineString
            localite.overlay.type = 'LineString'
            localite.representatif = false
            @_localites.push(localite)
        @_segments = []
        @_step = 4
        @updateSite()
        return true

      editSegments: ->
        @_step = 2
        @_googleMaps.addListener(@_tracet.overlay, 'click', @addSegmentPoint)
        nb_segments = @_localites.length / locBySegment
        # rescue all points to click on
        points = []
        for i in [1..nb_segments]
          # click on first point of segment if not start point
          if i > 1
            point = @_localites[(i-1)*locBySegment].overlay.getPath().getAt(0)
            points.push(point)
          # click on last point of segment if not arrival point
          if i < nb_segments
            path = @_localites[(i-1)*locBySegment+4].overlay.getPath()
            path_length = path.getLength()
            point = path.getAt(path_length-1)
            points.push(point)
        # delete localites
        for localite in @_localites
          @_googleMaps.deleteOverlay(localite.overlay)
        @_localites = []
        # Click on points
        for point in points
          var_args =
            latLng: point
          @_googleMaps.trigger(@_tracet.overlay, 'click', var_args)
        @updateSite()
