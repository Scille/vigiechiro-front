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
    (mapDiv, protocoleAlgoSite, siteCallback = {}) ->
      if protocoleAlgoSite == 'ROUTIER'
        return new ProtocoleMapRoutier(mapDiv, siteCallback)
      else if protocoleAlgoSite == 'CARRE'
        return new ProtocoleMapCarre(mapDiv, siteCallback)
      else if protocoleAlgoSite == 'POINT_FIXE'
        return new ProtocoleMapPointFixe(mapDiv, siteCallback)
      else if protocoleAlgoSite == 'ALL_ROUTIER'
        return new ProtocoleMapDisplayRoutier(mapDiv)
      else if protocoleAlgoSite == 'ALL_CARRE'
        return new ProtocoleMapDisplayCarre(mapDiv)
      else if protocoleAlgoSite == 'ALL_POINT_FIXE'
        return new ProtocoleMapDisplayPointFixe(mapDiv)
      else
        throw "Error : unknown protocole #{protocoleAlgoSite}"

  .factory 'ProtocoleMap', ($timeout, $rootScope, $modal, Backend, GoogleMaps) ->
    class ProtocoleMap
      constructor: (mapDiv, @siteCallback) ->
        @_localites = []
        @_step = 0
        @_steps = []
        @_googleMaps = new GoogleMaps(mapDiv, @mapsCallback())
        # POINT_FIXE && PEDESTRE
        @_sites = null
        @_circleLimit = null
        @_newSelection = false
        @_grilleStoc = {}

      clearMap: ->
        return

      mapValidated: ->
        return false

## For Grille Stoc ##
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
              throw "Error : no grille stoc found for "+overlay.getPosition().toString()
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
                      @validAndDisplaySiteLocalites(index)
                )
                break
            if siteOp
              return
            else
              overlay = @createCell(cell.centre.coordinates[1],
                                    cell.centre.coordinates[0])
              @validNumeroGrille(overlay, cell.numero, cell._id, true)
        )

      validAndDisplaySiteLocalites: (index) ->
        if !@_sites or !@_sites[index]
          return
        site = @_sites[index]
        @validNumeroGrille(site.overlay, site.grille_stoc.numero,
                           site.grille_stoc._id, false)
        Backend.one('sites', site._id).get().then (site) =>
          @displayLocalites(site.localites)
        @_step = 3
        @updateSite()

      displayLocalites: (localites) ->
        for localite in localites or []
          @displayLocalite(localite)

      displayLocalite: (localite) ->
        newLocalite =
          name: localite.nom
          representatif: localite.representatif
        newLocalite.overlay = @loadGeoJson(localite.geometries)
        newLocalite.overlay.setTitle(localite.nom)
        @_localites.push(newLocalite)

      selectGrilleStoc: ->
        @_step = 1
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
        @_grilleStoc.item.setMap(null)
        @_grilleStoc = {}

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
        if @siteCallback.updateSteps?
          @siteCallback.updateSteps(steps)

      displayError: (error) ->
        if @siteCallback.displayError?
          @siteCallback.displayError(error)

      saveMap: ->
        result = []
        for localite in @_localites
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

      setLocaliteName: ->
        return ''

      loadMap: (site) ->
        # start loading
        @loading = true
        # ROUTIER type site create @_tracet and center on it
        if !site.grille_stoc?
          # rescue start and stop points
          start = @getStartPoint(site.localites)
          stop = @getStopPoint(site.localites)
          # set @_tracet and bounds
          bounds = @_googleMaps.createBounds()
          tracet_latlngs = []
          for localite in site.localites
            coordinates = localite.geometries.geometries[0].coordinates
            for point in coordinates
              tracet_latlngs.push(point)
              @_googleMaps.extendBounds(bounds, point)
          @_tracet.overlay = @_googleMaps.createLineString(tracet_latlngs)
          @_tracet.overlay.setOptions({zIndex: 1})
          # set view
          @_googleMaps.setCenter(
            start.lat(),
            start.lng()
          )
          @_googleMaps.fitBounds(bounds)
          #
          continueLoading = =>
            @validTracet()
            if start.equals(@_firstPoint.getPosition())
              @_googleMaps.trigger(@_firstPoint, 'click', {latLng: start})
            else
              @_googleMaps.trigger(@_lastPoint, 'click', {latLng: start})
            @_googleMaps.clearListeners(@_tracet.overlay, 'click')
            @_step = 4
            @updateSite()
          $timeout(continueLoading, 1000)
        # load localites
        for localite in site.localites or []
          newLocalite =
            name: localite.nom
            representatif: localite.representatif
          newLocalite.overlay = @loadGeoJson(localite.geometries)
          if localite.nom[0] == 'T'
            num_secteur = parseInt(localite.nom[localite.nom.length-1])-1
            newLocalite.overlay.setOptions(
              strokeColor: localite_colors[num_secteur]
              zIndex: 2
            )
          else
            newLocalite.overlay.setOptions({ title: localite.nom })
          @_localites.push(newLocalite)
        # generate grille_stoc for CARRE and POINT_FIXE type site
        if site.grille_stoc?
          newCell = @createCell(
            site.grille_stoc.centre.coordinates[1],
            site.grille_stoc.centre.coordinates[0]
          )
          @validNumeroGrille(newCell, site.grille_stoc.numero, site.grille_stoc._id)
          @validLocalites()
        # end loading
        @loading = false
        @updateSite()

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
          item: cell
          numero: numero
          id: id
        lat = (path.getAt(0).lat() + path.getAt(2).lat()) / 2
        lng = (path.getAt(0).lng() + path.getAt(2).lng()) / 2
        @_googleMaps.setCenter(lat, lng)
        @_googleMaps.setZoom(13)
        @_step = 2
        @updateSite()
        @_googleMaps.setDrawingManagerOptions(drawingControl: true)
        if editable
          @_googleMaps.addListener(@_grilleStoc.item, 'rightclick', (e) =>
            if confirm("Cette opération supprimera toutes les localités.")
              @_step = 0
              @_grilleStoc.item.setMap(null)
              @_grilleStoc = {}
              for localite in @_localites or []
                @_googleMaps.deleteOverlay(localite.overlay)
              @_localites = []
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
        if !@_tracet.overlay?
          return 0
        overlay = @_tracet.overlay
        length = @_googleMaps.computeLength(overlay)
        if length < 30000
          overlay.setOptions(strokeColor: '#FF0000')
        else
          overlay.setOptions(strokeColor: '#000000')
        return length

      getSteps: ->
        return @_steps

      emptyMap: ->
        for localite in @_localites
          localite.overlay.setMap(null)
        @_localites = []

      deleteOverlay: (overlay) ->
        for localite, key in @_localites
          if localite.overlay == overlay
            @_googleMaps.deleteOverlay(localite.overlay)
            @_localites.splice(key, 1);
            return

      getCountOverlays: (type = '') ->
        if type == ''
          return @_localites.length
        else
          result = 0
          for localite in @_localites or []
            if localite.overlay.type == type
              result++
          return result

      validLocalites: ->
        @_step = 4
        @_googleMaps.clearListeners(@_grilleStoc.item, 'rightclick')
        @_googleMaps.setDrawingManagerOptions(
          drawingControl: false
          drawingMode: ''
        )
        for localite in @_localites
          localite.overlay.setOptions({ draggable: false })
          @_googleMaps.clearListeners(localite.overlay, 'rightclick')
        @updateSite()

      editLocalites: ->
        @_step = 3
        @_googleMaps.setDrawingManagerOptions(drawingControl: true)
        for localite, key in @_localites
          localite.overlay.setOptions({ draggable: true })
          @addEventRightClick(localite.overlay)
        @updateSite()

      addEventRightClick: (overlay) ->
        @_googleMaps.addListener(overlay, 'rightclick', (e) =>
          @deleteOverlay(overlay)
          if @getCountOverlays() < 5
            @_step = 2
          else
            @_step = 3
          @updateSite()
        )
