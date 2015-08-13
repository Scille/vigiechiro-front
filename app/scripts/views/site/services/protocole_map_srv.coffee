'use strict'


angular.module('protocole_map', ['protocole_map_carre',
                                 'protocole_map_point_fixe',
                                 'protocole_map_routier',
                                 'protocole_map_display_all'])
  .factory 'protocolesFactory', (ProtocoleMapCarre,
                                 ProtocoleMapRoutier,
                                 ProtocoleMapPointFixe,
                                 ProtocoleMapDisplayCarre,
                                 ProtocoleMapDisplayRoutier,
                                 ProtocoleMapDisplayPointFixe) ->
    (mapDiv, typeProtocole, callbacks = {}) ->
      if typeProtocole == 'ROUTIER'
        return new ProtocoleMapRoutier(mapDiv, typeProtocole, callbacks)
      else if typeProtocole == 'CARRE'
        return new ProtocoleMapCarre(mapDiv, typeProtocole, callbacks)
      else if typeProtocole == 'POINT_FIXE'
        return new ProtocoleMapPointFixe(mapDiv, typeProtocole, callbacks)
      else if typeProtocole == 'ALL_ROUTIER'
        return new ProtocoleMapDisplayRoutier(mapDiv)
      else if typeProtocole == 'ALL_CARRE'
        return new ProtocoleMapDisplayCarre(mapDiv)
      else if typeProtocole == 'ALL_POINT_FIXE'
        return new ProtocoleMapDisplayPointFixe(mapDiv)
      else
        throw "Erreur : type de protocole inconnu #{typeProtocole}"

  .factory 'ProtocoleMap', ($timeout, $rootScope, $modal, Backend, GoogleMaps) ->
    class ProtocoleMap
      constructor: (mapDiv, @typeProtocole, @callbacks) ->
        @_site = null
        @_localities = []
        @_step = 'start'
        @_steps = []
        @_googleMaps = new GoogleMaps(mapDiv, @mapCallback())
        @_projectionReady = false
        # POINT_FIXE && PEDESTRE
        @_sites = null
        @_circleLimit = null
        @_newSelection = false
        @_grilleStoc = null
        # ROUTIER
        @_route = null
        @_routeLength = 0
        @_firstPoint = null
        @_lastPoint = null
        @_points = []
        @_sections = []
        @_padded_points = []

      isValid: ->
        if @typeProtocole in ['CARRE', 'POINT_FIXE']
          if @_step == 'end'
            return true
          else
            @callbacks.displayError?("Le site ne peut pas être sauvegardé. Des étapes n'ont pas été faites.")
            return false
        else
          if @_step in ['selectOrigin', 'editSections', 'end']
            return true
          else
            @callbacks.displayError?("Le site ne peut pas être sauvegardé. Des étapes obligatoires n'ont pas été faites.")
            return false

      clear: ->
        for localite in @_localities
          localite.overlay.setMap(null)
        @_localities = []
        @_step = 'start'
        if @typeProtocole in ['CARRE', 'POINT_FIXE']
          @_googleMaps.setDrawingManagerOptions(
            drawingControl: false
            drawingMode: ''
          )
        # POINT_FIXE && PEDESTRE
        if @_circleLimit?
          @_circleLimit.setMap(null)
          @_circleLimit = null
        @_newSelection = false
        if @_grilleStoc?
          @_grilleStoc.overlay.setMap(null)
          @_grilleStoc = null
        # ROUTIER
        if @_route?
          @_route.setMap(null)
          @_route = null
        @_routeLength = 0
        if @_firstPoint?
          @_firstPoint.setMap(null)
          @_firstPoint = null
        if @_lastPoint?
          @_lastPoint.setMap(null)
          @_lastPoint = null
        if @_points.length
          for point in @_points
            point.setMap(null)
          @_points = []
        if @_sections.length
          for section in @_sections
            section.setMap(null)
          @_sections = []
        @_padded_points = []
        @updateSite()

# Grille Stoc
      loadMapDisplay: (site) ->
        @_googleMaps.hideDrawingManager()
        @loadGrilleStoc(site.grille_stoc)
        @loadLocalities(site.localites)

      loadMapEdit: (site) ->
        @_site = site
        @loadMapEditContinue()

      loadMapEditContinue: ->
        if not @_site? or not @_projectionReady
          return
        @loadGrilleStoc(@_site.grille_stoc)
        @loadLocalities(@_site.localites)
        @validLocalities()

      loadGrilleStoc: (grille_stoc) ->
        cell = @createCell(
          grille_stoc.centre.coordinates[1],
          grille_stoc.centre.coordinates[0]
        )
        # change color of cell
        cell.setOptions(
          strokeColor: '#00E000'
          strokeOpacity: 1
          strokeWeight: 2
          fillColor: '#000000'
          fillOpacity: 0
        )
        # get Path of cell
        path = cell.getPath()
        # register grille stoc
        @_grilleStoc =
          overlay: cell
          numero: grille_stoc.numero
          id: grille_stoc.id
        lat = (path.getAt(0).lat() + path.getAt(2).lat()) / 2
        lng = (path.getAt(0).lng() + path.getAt(2).lng()) / 2
        @_googleMaps.setCenter(lat, lng)
        @_googleMaps.setZoom(13)
        if @typeProtocole in ['POINT_FIXE']
          @displaySmallGrille()

      loadLocalities: (localities) ->
        for locality in localities or []
          newLocality =
            name: locality.nom
            representatif: locality.representatif
          newLocality.overlay = @loadGeoJson(locality.geometries)
          newLocality.overlay.setOptions({ title: locality.nom })
          newLocality.infowindow = @_googleMaps.createInfoWindow(locality.nom)
          newLocality.infowindow.open(@_googleMaps.getMap(), newLocality.overlay)
          @_localities.push(newLocality)

      displaySites: (sites) ->
        @_sites = sites
        for site in @_sites or []
          coordinates = site.grille_stoc.centre.coordinates
          site.overlay = @displayGrilleStocs(coordinates[1], coordinates[0])

      displayGrilleStocs: (lat, lng) ->
        # 1000*racine(2)
        distance = 1000 * Math.sqrt(2)
        origine = new google.maps.LatLng(lat, lng)
        southWest = google.maps.geometry.spherical.computeOffset(origine, distance, -135)
        northEast = google.maps.geometry.spherical.computeOffset(origine, distance, 45)
        overlay = new google.maps.Polygon(
          paths: [
            new google.maps.LatLng(southWest.lat(), northEast.lng())
            new google.maps.LatLng(northEast.lat(), northEast.lng())
            new google.maps.LatLng(northEast.lat(), southWest.lng())
            new google.maps.LatLng(southWest.lat(), southWest.lng())
          ]
          map: @_googleMaps.getMap()
          fillOpacity: 0.5
          fillColor: '#FF0000'
          strokeColor: '#FF0000'
          strokeOpacity: 0.65
          strokeWeight: 0.5
        )
        return overlay

      # Get grille_stoc where user creates point on the map
      getGrilleStoc: (overlay) ->
        payload =
          lng: overlay.getPosition().lng()
          lat: overlay.getPosition().lat()
          r: 1500
        Backend.one('grille_stoc/cercle').get(payload).then(
          (grille_stoc) =>
            cells = grille_stoc.plain()._items
            if !cells.length
              @callbacks.displayError?("Pas de grille stoc trouvée pour "+overlay.getPosition().toString())
            cell = cells[0]
            # check if site already exist with the grille stoc
            siteOp = false
            for site, index in @_sites
              if cell.numero == site.grille_stoc.numero
                siteOp = true
                modalInstance = $modal.open(
                  templateUrl: 'scripts/views/site/modal/site_opportuniste.html'
                  controller: 'ModalInstanceSiteOpportunisteController'
                )
                modalInstance.result.then(
                  (valid) =>
                    if valid
                      @validAndDisplaySiteLocalities(index)
                )
                break
            if siteOp
              return
            else
              overlay = @createCell(cell.centre.coordinates[1],
                                    cell.centre.coordinates[0])
              @validNumeroGrille(overlay, cell.numero, cell._id, true)
        )

      validAndDisplaySiteLocalities: (index) ->
        if !@_sites or !@_sites[index]
          return
        site = @_sites[index]
        @validNumeroGrille(site.overlay, site.grille_stoc.numero,
                           site.grille_stoc._id, false)
        Backend.one('sites', site._id).get().then (site) =>
          @displayLocalities(site.localites)
        @_step = 'editLocalities'
        @updateSite()

      displayLocalities: (localites) ->
        for localite in localites or []
          @displayLocality(localite)

      displayLocality: (localite) ->
        newLocalite =
          name: localite.nom
          representatif: localite.representatif
        newLocalite.overlay = @loadGeoJson(localite.geometries)
        newLocalite.overlay.setTitle(localite.nom)
        @_localities.push(newLocalite)

      selectGrilleStoc: ->
        @_step = 'selectGrilleStoc'
        @_googleMaps.setDrawingManagerOptions(drawingControl: true)
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

      deleteGrilleStoc: ->
        @_grilleStoc.overlay.setMap(null)
        @_grilleStoc = null

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
        if @callbacks.updateSteps?
          @callbacks.updateSteps(steps)

      saveMap: ->
        result = []
        for localite in @_localities
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

      loadGeoJson: (geoJson) ->
        overlay = undefined
        if not geoJson
          return
        if geoJson.type == 'GeometryCollection'
          for geometry in geoJson.geometries
            return @loadGeoJson(geometry)
        if geoJson.type == 'Point'
          overlay = @_googleMaps.createPoint(geoJson.coordinates[0],
                                             geoJson.coordinates[1])
        else if geoJson.type == 'Polygon'
          overlay = @_googleMaps.createPolygon(geoJson.coordinates[0])
        else if geoJson.type == 'LineString'
          overlay = @_googleMaps.createLineString(geoJson.coordinates)
        else
          throw "Error: Bad GeoJSON object #{geoJson}"
        overlay.type = geoJson.type
        return overlay

      getIdGrilleStoc: ->
        return @_grilleStoc.id

      getNumGrilleStoc: ->
        return @_grilleStoc.numero

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

      validNumeroGrille: (cell, numero, id, editable = false) =>
        # remove click event on map
        @_googleMaps.clearListeners(@_googleMaps.getMap(), 'click')
        # change color of cell
        cell.setOptions(
          strokeColor: '#00E000'
          strokeOpacity: 1
          strokeWeight: 2
          fillColor: '#000000'
          fillOpacity: 0
        )
        # get Path of cell
        path = cell.getPath()
        # register grille stoc
        @_grilleStoc =
          overlay: cell
          numero: numero
          id: id
        lat = (path.getAt(0).lat() + path.getAt(2).lat()) / 2
        lng = (path.getAt(0).lng() + path.getAt(2).lng()) / 2
        @_googleMaps.setCenter(lat, lng)
        @_googleMaps.setZoom(13)
        @_step = 'editLocalities'
        @updateSite()
        @_googleMaps.setDrawingManagerOptions(drawingControl: true)
        if editable
          @_googleMaps.addListener(@_grilleStoc.overlay, 'rightclick', (e) =>
            if confirm("Cette opération supprimera toutes les localités.")
              @_step = 'start'
              @_grilleStoc.overlay.setMap(null)
              @_grilleStoc = null
              for locality in @_localities or []
                locality.overlay.setMap(null)
              @_localities = []
              @_googleMaps.setDrawingManagerOptions(drawingControl: false)
              @selectGrilleStoc()
              @updateSite()
          )

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
        if not @_route?
          return 0
        length = @_googleMaps.computeLength(@_route)
        if length < 30000
          @_route.setOptions(strokeColor: '#FF0000')
        else
          @_route.setOptions(strokeColor: '#000000')
        return length

      getSteps: ->
        return @_steps

      emptyMap: ->
        for localite in @_localities
          localite.overlay.setMap(null)
        @_localities = []

      deleteOverlay: (overlay) ->
        for locality, key in @_localities
          if locality.overlay == overlay
            locality.overlay.setMap(null)
            @_localities.splice(key, 1)
            return

      getCountOverlays: (type = '') ->
        if type == ''
          return @_localities.length
        else
          result = 0
          for localite in @_localities or []
            if localite.overlay.type == type
              result++
          return result

      validLocalities: ->
        @_googleMaps.clearListeners(@_grilleStoc.overlay, 'rightclick')
        @_googleMaps.setDrawingManagerOptions(
          drawingControl: false
          drawingMode: ''
        )
        for locality in @_localities
          locality.overlay.setOptions({ draggable: false })
          @_googleMaps.clearListeners(locality.overlay, 'rightclick')
        @_step = 'end'
        @updateSite()

      editLocalities: ->
        @_googleMaps.setDrawingManagerOptions(drawingControl: true)
        for locality in @_localities
          locality.overlay.setOptions({ draggable: true })
          @addEventRightClick(locality.overlay)
        @_step = 'validLocalities'
        @updateSite()

      addEventRightClick: (overlay) ->
        @_googleMaps.addListener(overlay, 'rightclick', (e) =>
          @deleteOverlay(overlay)
          if @getCountOverlays() < @_min
            @_step = 'editLocalities'
          else
            @_step = 'validLocalities'
          @updateSite()
        )
