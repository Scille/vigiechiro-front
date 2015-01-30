'use strict'


angular.module('protocole_map', ['protocole_carre', 'protocole_point_fixe', 'protocole_routier'])
  .factory 'protocolesFactory', (ProtocoleCarre, ProtocoleRoutier, ProtocolePointFixe) ->
    (site, protocoleAlgoSite, mapDiv, siteCallback) ->
      if protocoleAlgoSite == 'ROUTIER'
        return new ProtocoleRoutier(site, mapDiv, siteCallback)
      else if protocoleAlgoSite == 'CARRE'
        return new ProtocoleCarre(site, mapDiv, siteCallback)
      else if protocoleAlgoSite == 'POINT_FIXE'
        return new ProtocolePointFixe(site, mapDiv, siteCallback)
      else
        throw "Error : unknown protocole protocoleAlgoSite"

  .factory 'ProtocoleMap', ($rootScope, Backend, GoogleMaps) ->
    class ProtocoleMap
      constructor: (@site, mapDiv, @siteCallback) ->
        @_grille = []
        @_step = 0
        @_steps = []
        @_idGrilleStoc = ''
        @_googleMaps = new GoogleMaps(mapDiv, @mapsCallback())
        @loading = true
        @loadMap(@site.localites)
        @loading = false

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
          steps: @_steps
          step: @_step
          loading: @loading
        console.log(steps)
        @siteCallback.updateSteps(steps)
        if not @loading
          @siteCallback.updateForm()

      saveMap: ->
        mapDump = @_googleMaps.saveMap()
        localites = []
        for shape in mapDump
          geometries =
            geometries: [shape]
          localites.push(geometries)
        return localites

      mapsCallback: ->
        overlayCreated: -> return false
        zoomChanged: -> return false
        mapsMoved: -> return false

      loadMap: (mongoShapes) ->
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
        @_googleMaps.loadMap(mongoShapes)

      getIdGrilleStoc: ->
        return @_idGrilleStoc

      mapsChanged: ->
        if @_step != 0
          return
        zoomLevel = @_googleMaps.getZoom()
        bounds = @_googleMaps.getBounds()
        if not bounds?
          return
        southWest = bounds.getSouthWest()
        northEast = bounds.getNorthEast()
        if zoomLevel > 11
          where = JSON.stringify(
            centre:
              $geoWithin:
                $box: [
                  [southWest.lng(), southWest.lat()]
                  [northEast.lng(), northEast.lat()]
                ]
          )
          Backend.all('grille_stoc').getList({ where: where, max_results: 40 })
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

      validNumeroGrille: (cell, numero = 0, id = '') =>
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
        @_idGrilleStoc = @_grille[0].id
        @_step = 1
        @updateSite()
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
