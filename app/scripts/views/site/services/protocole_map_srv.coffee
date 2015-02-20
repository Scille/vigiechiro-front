'use strict'


angular.module('protocole_map', ['protocole_map_carre', 'protocole_map_point_fixe', 'protocole_map_routier'])
  .factory 'protocolesFactory', (ProtocoleMapCarre, ProtocoleMapRoutier, ProtocoleMapPointFixe) ->
    (site, protocoleAlgoSite, mapDiv, allowEdit = true, siteCallback = {}) ->
      if protocoleAlgoSite == 'ROUTIER'
        return new ProtocoleMapRoutier(site, mapDiv, allowEdit, siteCallback)
      else if protocoleAlgoSite == 'CARRE'
        return new ProtocoleMapCarre(site, mapDiv, allowEdit, siteCallback)
      else if protocoleAlgoSite == 'POINT_FIXE'
        return new ProtocoleMapPointFixe(site, mapDiv, allowEdit, siteCallback)
      else
        throw "Error : unknown protocole #{protocoleAlgoSite}"

  .factory 'ProtocoleMap', ($rootScope, Backend, GoogleMaps) ->
    class ProtocoleMap
      constructor: (@site, mapDiv, @allowEdit, @siteCallback) ->
        @_origin = undefined
        @_grille = []
        @_step = 0
        @_steps = []
        @_googleMaps = new GoogleMaps(mapDiv, @mapsCallback())

      selectGrilleStoc: ->
        @_step = 1
        @updateSite()

      validOrigin: (grille_stoc) ->
        cell = @createCell(grille_stoc.centre.coordinates[1],
                           grille_stoc.centre.coordinates[0])
        @validNumeroGrille(cell, grille_stoc.numero, grille_stoc._id)
        @removeOrigin()
        @updateSite()

      createOriginPoint: ->
        @_origin = new google.maps.Marker(
          map: @_googleMaps.getMap()
          title: "Point d'origine du tirage"
          position: @_googleMaps.getCenter()
          draggable: true
        )

      removeOrigin: ->
        @_origin.setMap(null)

      getOrigin: ->
        return @_origin

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
        if not @loading and @siteCallback.updateForm?
          @siteCallback.updateForm()

      saveMap: ->
        localites = []
        geoDump = @_googleMaps.saveGeoJson()
        for geoJson in geoDump.geometries
          localite =
            geometries:
              type: 'GeometryCollection'
              geometries: [geoJson]
          localites.push(localite)
        return localites

      mapsCallback: ->
        overlayCreated: -> false
        zoomChanged: -> false
        mapsMoved: -> false

      loadMap: ->
        @loading = true
        if @site.grille_stoc?
          @_step = 1
          @_googleMaps.setCenter(
            @site.grille_stoc.centre.coordinates[1],
            @site.grille_stoc.centre.coordinates[0]
          )
          @_googleMaps.setZoom(14)
          newCell = @createCell(
            @site.grille_stoc.centre.coordinates[1],
            @site.grille_stoc.centre.coordinates[0]
          )
          @validNumeroGrille(newCell, @site.grille_stoc.numero, @site.grille_stoc._id)
        for localite in @site.localites or []
          @_googleMaps.loadGeoJson(localite.geometries)
        @loading = false

      getIdGrilleStoc: ->
        return @_grille[0].id

      mapsChanged: ->
        if (@_step == 0)
          if @_origin
            @_origin.setPosition(@_googleMaps.getCenter())
          return
        if @_step != 1
          return
        zoomLevel = @_googleMaps.getZoom()
        bounds = @_googleMaps.getBounds()
        if not bounds?
          return
        southWest = bounds.getSouthWest()
        northEast = bounds.getNorthEast()
        if zoomLevel > 11
          parameters =
            sw_lat: southWest.lat()
            sw_lng: southWest.lng()
            ne_lat: northEast.lat()
            ne_lng: northEast.lng()
          Backend.all('grille_stoc/rectangle').getList(parameters)
            .then (@createGrille)

      createGrille: (grille_stoc) =>
        validNumeroGrille = (cell) =>
          (event) => @validNumeroGrille(cell)
        displayNumeroGrille = (cell) =>
          (event) => @displayNumeroGrille(cell)
        grille_stoc = grille_stoc.plain()
        for cell in grille_stoc
          exist = false
          for item in @_grille
            if item.numero == cell.numero
              exist = true
              break
          if exist
            continue
          newCell = @createCell(cell.centre.coordinates[1], cell.centre.coordinates[0])
          @_googleMaps.addListener(newCell, 'click', validNumeroGrille(newCell))
          @_googleMaps.addListener(newCell, 'mouseover', displayNumeroGrille(newCell))
          @_grille.push({"item": newCell, "numero": cell.numero, 'id': cell._id})

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

      displayNumeroGrille: (cell) ->
        for stoc in @_grille
          if stoc.item == cell
            newString = "n° grille stoc : " + stoc.numero
            #TODO afficher numero_grille_stoc quelque part
#            if @scope.numero_grille_stoc
#              @scope.numero_grille_stoc.value = newString
            return

      validNumeroGrille: (cell, numero, id) =>
        nbStoc = @_grille.length
        if nbStoc
          for index in [nbStoc-1..0]
            if @_grille[index].item != cell
              @_grille[index].item.setMap(null)
              @_grille.splice(index, 1)
        else
          @_grille.push({"item": cell, "numero": numero, "id": id})
        @_grille[0].item.setOptions(
          strokeColor: '#00E000'
          strokeOpacity: 1
          strokeWeight: 2
        )
        @_step = 2
        @updateSite()
        if @allowEdit
          @_googleMaps.addListener(@_grille[0].item, 'rightclick', (event) =>
            if confirm("Etes vous sûre de vouloir supprimer ce carré ainsi que toutes les localités qu'il contient ?")
              @_step = 0
              @_grille[0].item.setMap(null)
              @_grille = []
              @_googleMaps.emptyMap()
              @updateSite()
              @mapsChanged()
          )
          @_googleMaps.setDrawingManagerOptions(drawingControl: true)

      checkLength: (overlay) ->
        length = google.maps.geometry.spherical.computeLength(overlay.getPath())
        if length < 1800
          overlay.setOptions(strokeColor: '#800090')
        else if length > 2200
          overlay.setOptions(strokeColor: '#FF0000')
        else
          overlay.setOptions(strokeColor: '#000000')
        return length

      getSteps: ->
        return @_steps
