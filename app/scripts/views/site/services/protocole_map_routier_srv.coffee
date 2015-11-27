'use strict'

locality_colors = [
  '#FF8000'
  '#80FF00'
  '#00FF80'
  '#0080FF'
  '#FF0080'
]
locBySection = 5
section_colors = [
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


angular.module('protocole_map_routier', [])
  .factory 'ProtocoleMapRoutier', ($rootScope, $timeout, $modal,
                                   Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocoleMapRoutier extends ProtocoleMap
      constructor: (mapDiv, @typeProtocole, @callbacks = {}) ->
        super mapDiv, @typeProtocole, @callbacks
        @_steps = [
            id: 'start'
            message: "Tracer le trajet complet en un seul trait. Le tracé doit atteindre 30 km ou plus."
          ,
            id: 'selectOrigin'
            message: "Sélectionner le point d'origine."
          ,
            id: 'editSections'
            message: "Placer les limites des tronçons de 2 km (+/-20%) sur le tracé en partant du point d'origine."
          ,
            id: 'validSections'
            message: "Valider les tronçons."
          ,
            id: 'end'
            message: "Cartographie achevée."
        ]
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.POLYLINE
            ]
        )

      loadMapDisplay: (site) ->
        @_googleMaps.hideDrawingManager()
        @loadRoute(site.tracet)
        @loadBounds(site.tracet)
        @loadLocalities(site.localites)

      loadMapEdit: (site) ->
        @_site = site
        @loadMapEditContinue()

      loadMapEditContinue: ->
        if not @_site? or not @_projectionReady
          return
        @loadRoute(@_site.tracet)
        routeValid = @validRoute()
        @loadBounds(@_site.tracet)
        if routeValid
          boundsValid = @validBounds()
        @loadLocalities(@_site.localites)
        @validLocalities()

      loadRoute: (route) ->
        # route
        bounds = @_googleMaps.createBounds()
        for point in route.chemin.coordinates
          @_googleMaps.extendBounds(bounds, point)
        @_route = @_googleMaps.createLineString(route.chemin.coordinates)
        @_routeLength = (@checkTotalLength()/1000).toFixed(1)
        @callbacks.updateLength?(@_routeLength)
        @_route.setOptions({zIndex: 1})
        @_googleMaps.setCenter(
          route.chemin.coordinates[0][1],
          route.chemin.coordinates[0][0]
        )
        @_googleMaps.fitBounds(bounds)

      hasRoute: ->
        if @_route?
          return true
        else
          return false

      validRoute: ->
        if not @_route?
          @callbacks.displayError?("Pas de tracé")
          return false
        if @_routeLength < 24
          @callbacks.displayError("Tracé trop court")
          return false
        # @_route becomes uneditable
        @_googleMaps.clearListeners(@_route, 'rightclick')
        @_route.setOptions(
          editable: false
        )
        # Pad the points array
        path = @_route.getPath()
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
                @callbacks.displayError("Certains points ne sont pas sur le tracé")
        # Update form
        @_step = 'selectOrigin'
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: []
          drawingMode: ''
        )
        @updateSite()
        return true

      loadBounds: (route) ->
        if not route.origine?
          return
        @_firstPoint = @_googleMaps.createPoint(route.origine.coordinates[1], route.origine.coordinates[0], false)
        @_lastPoint = @_googleMaps.createPoint(route.arrivee.coordinates[1], route.arrivee.coordinates[0], false)
        @_firstPoint.setTitle("Départ")
        @_lastPoint.setTitle("Arrivée")

      validBounds: ->
        if not @_route
          return false
        if not @_firstPoint?
          routePath = @_route.getPath()
          @_firstPoint = @_googleMaps.createPoint(routePath.getAt(0).lat(), routePath.getAt(0).lng(), false)
          @_lastPoint = @_googleMaps.createPoint(routePath.getAt(routePath.length-1).lat(), routePath.getAt(routePath.length-1).lng(), false)
          @_googleMaps.addListener(@_firstPoint, 'click', @onValidOriginPoint)
          @_googleMaps.addListener(@_lastPoint, 'click', @onValidOriginPoint)
          return false
        else
          @validOriginPoint()


      loadLocalities: (localities) ->
        for locality in localities or []
          newLocality =
            representatif: locality.representatif
          newLocality.overlay = @loadGeoJson(locality.geometries)
          newLocality.overlay.title = locality.nom
          if locality.nom.charAt(0) == 'T'
            num_secteur = parseInt(locality.nom[locality.nom.length-1])-1
            newLocality.overlay.setOptions(
              strokeColor: locality_colors[num_secteur]
              zIndex: 2
            )
          @_localities.push(newLocality)


      validLocalities: ->
        if @_localities.length
          @_googleMaps.clearListeners(@_route, 'click')
          @_step = 'end'
          @updateSite()
        else
          @_step = 'editSections'
          @_changeStep("Point à placer : fin tronçon 1")


      mapCallback: ->
        onProjectionReady: =>
          @_projectionReady = true
          @loadMapEditContinue()
        overlayCreated: (overlay) =>
          isModified = false
          if @_step == 'start'
            if overlay.type == "LineString"
              isModified = true
              @_route = overlay
              @_route.setOptions({draggable: false})
              @_routeLength = (@checkTotalLength()/1000).toFixed(1)
              @_googleMaps.addListener(@_route, 'mouseout', (e) =>
                @_routeLength = (@checkTotalLength()/1000).toFixed(1)
                @callbacks.updateLength(@_routeLength)
              )
              @_googleMaps.setDrawingManagerOptions(
                drawingControlOptions:
                  position: google.maps.ControlPosition.TOP_CENTER
                  drawingModes: [google.maps.drawing.OverlayType.MARKER]
                drawingMode: ''
              )
              @addRouteRightClick()
              @callbacks.updateLength?(@_routeLength)
            else if overlay.type == "Point"
              isModified = true
              @extendRoute(overlay)
            else
              @callbacks.displayError?("Géométrie non autorisée à cette étape : "+overlay.type)
          else if @_step == 'editSections'
            if overlay.type != "LineString"
              @callbacks.displayError?("Géométrie non autorisée à cette étape : "+overlay.type)
            else
              overlay.setOptions(
                draggable: false
                editable: false
              )
              isModified = true
          if isModified
            @updateSite()
            return true
          @callbacks.displayError?("Impossible de créer la forme")
          return false

      getGeoJsonRoute: ->
        route =
          chemin:
            type: 'LineString'
            coordinates: @_googleMaps.getPath(@_route)
        if @_firstPoint? and @_firstPoint.getTitle() == "Départ"
          origin = @_firstPoint.getPosition()
          route.origine =
            type: 'Point'
            coordinates: [origin.lng(), origin.lat()]
          end = @_lastPoint.getPosition()
          route.arrivee =
            type: 'Point'
            coordinates: [end.lng(), end.lat()]
        else
          delete route.origine
          delete route.arrivee
        return route

      # Route
      addRouteRightClick: ->
        @_googleMaps.addListener(@_route, 'rightclick', (e) =>
          if e.vertex?
            path = @_route.getPath()
            path.removeAt(e.vertex)
            if path.getLength() < 2
              @deleteRoute()
            else
              @_route.setPath(path)
          else
            modalInstance = $modal.open(
              templateUrl: 'scripts/views/site/modal/delete_route.html'
              controller: 'ModalDeleteRouteController'
            )
            modalInstance.result.then () =>
              @deleteRoute()
          @updateSite()
        )

      deleteRoute: ->
        @_route.setMap(null)
        @_route = null
        @_routeLength = 0
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [
              google.maps.drawing.OverlayType.POLYLINE
            ]
        )
        @updateSite()

      getRouteLength: ->
        return @_routeLength

      extendRoute: (overlay) ->
        path = @_route.getPath()
        if @extendRouteTo == 'BEGIN'
          path.insertAt(0, overlay.position)
        else
          path.push(overlay.position)
        @_route.setPath(path)
        overlay.setMap(null)

      editRoute: ->
        @_padded_points = []
        @_firstPoint.setMap(null)
        @_firstPoint = null
        @_lastPoint.setMap(null)
        @_lastPoint = null
        for point in @_points
          point.setMap(null)
        @_points = []
        for section in @_sections
          section.setMap(null)
        @_sections = []
        for locality in @_localities
          locality.overlay.setMap(null)
        @_localities = []
        # disable click event to add section point
        @_googleMaps.clearListeners(@_route, 'click')
        # @_route becomes editable
        @_googleMaps.addListener(@_route, 'mouseout', (e) =>
          @_routeLength = (@checkTotalLength()/1000).toFixed(1)
          @callbacks.updateLength?(@_routeLength)
        )
        @_googleMaps.setDrawingManagerOptions(
          drawingControlOptions:
            position: google.maps.ControlPosition.TOP_CENTER
            drawingModes: [google.maps.drawing.OverlayType.MARKER]
        )
        @addRouteRightClick()
        @_route.setOptions(
          draggable: false
          editable: true
        )
        # Update form
        @_step = 'start'
        @updateSite()

      onValidOriginPoint: (e) =>
        tmp = null
        # If click on first point
        if e.latLng.lat() != @_firstPoint.getPosition().lat() or
           e.latLng.lng() != @_firstPoint.getPosition().lng()
          tmp = @_firstPoint
          @_firstPoint = @_lastPoint
          @_lastPoint = tmp
          path = @_route.getPath()
          new_path = []
          for i in [0..path.getLength()-1]
            new_path.push(path.pop())
          @_route.setPath(new_path)
        #
        @validOriginPoint()

      validOriginPoint: ->
        for point in @_points or []
          point.setMap(null)
        @_points = []
        @_points.push(@_firstPoint)
        @_points.push(@_lastPoint)
        # Set titles and edge
        @_points[0].setMap(@_googleMaps.getMap())
        @_points[1].setMap(@_googleMaps.getMap())
        @_points[0].setTitle("Départ")
        @_points[1].setTitle("Arrivée")
        @_points[0].edge = 0
        @_points[1].edge = @_route.getPath().getLength()-2
        # Events
        @_googleMaps.addListener(@_route, 'click', @addSectionPoint)
        @_googleMaps.clearListeners(@_firstPoint, 'click')
        @_googleMaps.clearListeners(@_lastPoint, 'click')
        # InfoWindow
        @_firstPoint.infowindow = @_googleMaps.createInfoWindow("Départ")
        @_firstPoint.infowindow.open(@_googleMaps.getMap(), @_firstPoint)
        @_googleMaps.addListener(@_firstPoint, 'click', =>
          @_firstPoint.infowindow.open(@_googleMaps.getMap(), @_firstPoint)
        )
        @_lastPoint.infowindow = @_googleMaps.createInfoWindow("Arrivée")
        @_lastPoint.infowindow.open(@_googleMaps.getMap(), @_lastPoint)
        @_googleMaps.addListener(@_lastPoint, 'click', =>
          @_lastPoint.infowindow.open(@_googleMaps.getMap(), @_lastPoint)
        )
        #
        @_step = 'editSections'
        @_changeStep("Point à placer : fin tronçon 1")

      _changeStep: (message) ->
        messageOrig = "Placer les limites des tronçons de 2 km (+/-20%) sur le tracé en partant du point d'origine."
        @_steps[2].message = messageOrig+" "+message
        @updateSite()

# @_points
      createSectionPoint: (lat, lng) ->
        point = @_googleMaps.createPoint(lat, lng)
        # find vertex of new point
        path = @_route.getPath()
        nbPoints = path.getLength()
        vertex = []
        for key in [0..nbPoints-2]
          currVertex = [path.getAt(key), path.getAt(key+1)]
          vertex.push(currVertex)
          if @_googleMaps.isLocationOnEdge(point.getPosition(), currVertex)
            point.edge = key
        return point

      addSectionPoint: (e) =>
        closestPoint = @_googleMaps.findClosestPointOnPath(e.latLng, @_padded_points, @_points)
        point = @createSectionPoint(closestPoint.lat(), closestPoint.lng())
        # Add to @_points
        @_points.splice(@_points.length-1, 0, point)
        # Add listeners
        @_setPointListeners(point)
        # Remove listeners and infwindow on previous points
        for i in [1..@_points.length-3] when @_points.length > 3
          @_googleMaps.clearListeners(@_points[i], 'rightclick')
          @_points[i].setOptions({draggable: false})
          @_points[i].infowindow.close()
        # InfoWindow
        numSection = Math.floor(@_points.length/2)
        numSection =
          current: numSection
          next: numSection
        position = {}
        if @_points.length%2
          position =
            current: "Fin tronçon "
            next: "début tronçon "
          numSection.next++
        else
          position =
            current: "Début tronçon "
            next: "fin tronçon "
        point.infowindow = @_googleMaps.createInfoWindow(position.current+numSection.current)
        point.infowindow.open(@_googleMaps.getMap(), point)
        @_googleMaps.addListener(point, 'click', =>
          point.infowindow.open(@_googleMaps.getMap(), point)
        )
        # Up to date step
        @_changeStep("Point à placer : "+position.next+numSection.next)
        # Generate all sections
        @generateSections()

      _setPointListeners: (point) ->
        @_googleMaps.addListener(point, 'rightclick', (e) =>
          @_deleteLastPoint()
        )
        point.setOptions({draggable: true})
        @_googleMaps.addListener(point, 'dragend', (e) =>
          point.setPosition(@_googleMaps
            .findClosestPointOnPath(e.latLng, @_padded_points, @_points))
          @updatePointPosition(point)
          @generateSections()
        )
        @_googleMaps.addListener(point, 'drag', (e) =>
          point.setPosition(@_googleMaps
            .findClosestPointOnPath(e.latLng, @_padded_points, @_points))
        )

      _deleteLastPoint: ->
        index = @_points.length-2
        content = @_points[index].infowindow.getContent()
        @_points[index].setMap(null)
        @_points.splice(index, 1)
        if index > 1
          @_setPointListeners(@_points[index-1])
          @_points[index-1].infowindow.open(@_googleMaps.getMap(), @_points[index-1])
        @_changeStep("Point à placer : "+content)
        @generateSections()

# @_sections
      generateSections: ->
        for section in @_sections
          section.setMap(null)
        @_sections = []
        nbPoints = @_points.length
        key = 0
        while (key < nbPoints-1)
          section = @generateSection(key)
          section.setOptions({ strokeColor: section_colors[(key/2)%11], zIndex: 10 })
          @_googleMaps.addListener(section, 'click', @addSectionPoint)
          @_sections.push(section)
          key +=2

      # generate the section between @_points[key] and @_points[key+1] points
      generateSection: (key) ->
        routePath = @_route.getPath()
        path = []
        start = @_points[key]
        stop = @_points[key+1]
        path.push([start.getPosition().lat(), start.getPosition().lng()])
        if start.edge < stop.edge
          for corner in [start.edge+1..stop.edge]
            pt = routePath.getAt(corner)
            path.push([pt.lat(), pt.lng()])
        path.push([stop.getPosition().lat(), stop.getPosition().lng()])
        return @_googleMaps.createLineString(path)

      updatePointPosition: (point) ->
        path = @_route.getPath()
        for key in [0..path.getLength()-2]
          vertex = [path.getAt(key), path.getAt(key+1)]
          if @_googleMaps.isLocationOnEdge(point.getPosition(), vertex)
            point.edge = key

      validSections: ->
        if !@_sections.length
          @callbacks.displayError?("Aucun tronçon")
          return false
        # Events and points
        @_googleMaps.clearListeners(@_route, 'click')
        for section in @_sections or []
          @_googleMaps.clearListeners(section, 'click')
        for point in @_points
          point.setMap(null)
        @_points = []
        @_firstPoint.setMap(@_googleMaps.getMap())
        @_lastPoint.setMap(@_googleMaps.getMap())
        # generation of localities
        for section, key in @_sections
          section.setMap(null)
          delta = @_googleMaps.computeLength(section) / locBySection
          sectionPath = section.getPath()
          # For each site
          # 4 firsts localities
          for index in [1..4]
            locality = {}
            localityPath = [sectionPath.getAt(0)]
            currLength = 0
            end = false
            while sectionPath.getLength() > 1 and not end
              d = @_googleMaps.computeDistanceBetween(sectionPath.getAt(0), sectionPath.getAt(1))
              if (d + currLength < delta)
                currLength += d
                localityPath.push(sectionPath.getAt(1))
                sectionPath.removeAt(0)
              else
                end = true
                # Compute where is the cut point
                ratio = (delta - currLength) / d
                cut_point = @_googleMaps.interpolate(sectionPath.getAt(0), sectionPath.getAt(1), ratio)
                # finish section and cut section
                localityPath.push(cut_point)
                sectionPath.setAt(0, cut_point)
            locality.overlay = @_googleMaps.createLineStringWithPath(localityPath)
            locality.overlay.setOptions(
              'strokeColor': locality_colors[index-1]
              'zIndex': 11
            )
            locality.overlay.type = 'LineString'
            locality.overlay.title = 'T '+(key+1)+' '+index
            locality.representatif = false
            @_localities.push(locality)
          # last locality of section
          locality = {}
          locality.overlay = @_googleMaps.createLineStringWithPath(sectionPath)
          locality.overlay.setOptions(
            'strokeColor': locality_colors[index-1]
            'zIndex': 11
          )
          locality.overlay.type = 'LineString'
          locality.overlay.title = 'T '+(key+1)+' 5'
          locality.representatif = false
          @_localities.push(locality)
        @_sections = []
        @validLocalities()
        return true

      editSections: ->
        @validOriginPoint()
        nb_sections = @_localities.length / locBySection
        # rescue all points
        for i in [0..nb_sections-1] when nb_sections > 0
          firstSectionPoint = @_localities[i*locBySection].overlay.getPath().getAt(0)
          path = @_localities[i*locBySection+4].overlay.getPath()
          path_length = path.getLength()
          lastSectionPoint = path.getAt(path_length-1)
          # if start point, no point section creation
          firstLat = firstSectionPoint.lat()
          firstLng = firstSectionPoint.lng()
          if firstLat != @_points[0].getPosition().lat() or
             firstLng != @_points[0].getPosition().lng()
            newPoint = @createSectionPoint(firstLat, firstLng)
            @_points.splice(@_points.length-1, 0, newPoint)
            @_setCurrentInfoWindow(newPoint)
          # if end point, no point section creation
          lastLat = lastSectionPoint.lat()
          lastLng = lastSectionPoint.lng()
          if lastLat != @_points[@_points.length-1].getPosition().lat() or
             lastLng != @_points[@_points.length-1].getPosition().lng()
            newPoint = @createSectionPoint(lastLat, lastLng)
            @_points.splice(@_points.length-1, 0, newPoint)
            @_setCurrentInfoWindow(newPoint)
        # Add listeners on last point
        index = @_points.length-2
        if index > 0
          @_setPointListeners(@_points[index])
          @_points[index].infowindow.open(@_googleMaps.getMap(), @_points[index])
        # delete localites
        for locality in @_localities
          locality.overlay.setMap(null)
        @_localities = []
        @generateSections()
        @_step = 'editSections'
        @updateSite()

      _setCurrentInfoWindow: (point) ->
        numSection = Math.floor(@_points.length/2)
        numSection =
          current: numSection
          next: numSection
        position = {}
        if @_points.length%2
          position =
            current: "Fin tronçon "
            next: "début tronçon "
          numSection.next++
        else
          position =
            current: "Début tronçon "
            next: "fin tronçon "
        point.infowindow = @_googleMaps.createInfoWindow(position.current+numSection.current)
        # Up to date step
        @_changeStep("Point à placer : "+position.next+numSection.next)
