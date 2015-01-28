'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_carre', [])
  .factory 'ProtocoleCarre', ($rootScope, Backend, GoogleMaps) ->
    class ProtocoleCarre
      constructor: (mapDiv, @factoryCallback) ->
        @_grille = []
        @_stocValid = false
        @_googleMaps = new GoogleMaps(mapDiv, @mapsCallback())
        @_googleMaps.setDrawingManagerOptions(drawingControl: false)
        return

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = true
          if isModified
            @_googleMaps.addListener(overlay, 'rightclick', (event) =>
              @_googleMaps.deleteOverlay(overlay)
            )
            @factoryCallback.overlayCreated()
            return true
          return false
        zoomChanged: => @mapsChanged()
        mapsMoved: => @mapsChanged()

      mapsChanged: ->
        if @_stocValid
          return
        map = @_googleMaps.getMaps()
        zoomLevel = @_googleMaps.getZoom()
        bounds = map.getBounds()
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
          Backend.all('grille_stoc').getList({ where: where, max_results: 40 }).then (@createGrille)

      createGrille: (grille_stoc) =>
        grille_stoc = grille_stoc.plain()
        for cell in grille_stoc
          exist = false
          for item in @_grille
            if item.numero == cell.numero
              exist = true
              break
          if exist
            continue
          lat = cell.centre.coordinates[1]
          lng = cell.centre.coordinates[0]
          @createCell(lat, lng, cell.numero, false)

      createCell: (lat, lng, numero, isValid) ->
        validItem = (item) =>
          (event) => @validNumeroGrille(event, item)
        displayItem = (item) =>
          (event) => @displayNumeroGrille(event, item)
        removeItem = (item) =>
          (event) => @removeNumeroGrille(event, item)
        toRadian = Math.PI / 180
        # 360 / (2 * Pi * rayon de la terre)
        rapport = 0.008983153
        onePoint =
          lat: lat + 0.0089982311916
          lng: lng - rapport / Math.cos(lat*toRadian)
        twoPoint =
          lat: lat - 0.0089982311916
          lng: lng + rapport / Math.cos(lat*toRadian)
        item = new google.maps.Rectangle(
          bounds: new google.maps.LatLngBounds(
            new google.maps.LatLng(onePoint.lat, onePoint.lng)
            new google.maps.LatLng(twoPoint.lat, twoPoint.lng)
          )
          map: @_googleMaps.getMaps()
          fillOpacity: 0
        )
        if isValid
          item.setOptions(
            strokeColor: '#00E000'
            strokeOpacity: 1
            strokeWeight: 2
          )
          @_googleMaps.addListener(item, 'rightclick', removeItem(item))
        else
          item.setOptions(
            strokeColor: '#606060'
            strokeOpacity: 0.65
            strokeWeight: 0.5
          )
          @_googleMaps.addListener(item, 'click', validItem(item))
          @_googleMaps.addListener(item, 'mouseover', displayItem(item))
        @_grille.push({"item": item, "numero": numero})

      validNumeroGrille: (event, cell) ->
        nbStoc = @_grille.length
        for index in [nbStoc-1..0]
          if @_grille[index].item != cell
            @_grille[index].item.setMap(null)
            @_grille.splice(index, 1)
          else
            @_grille[index].item.setOptions(
              strokeColor: '#00E000'
              strokeOpacity: 1
              strokeWeight: 2
            )
            @_stocValid = true
            #TODO addListener
#            @_googleMaps.addListener(cell, 'rightclick', removeItem(item))
            @_googleMaps.setDrawingManagerOptions(drawingControl: true)

      displayNumeroGrille: (event, cell) ->
        for stoc in @_grille
          if stoc.item == cell
            newString = "n° grille stoc : " + stoc.numero
            #TODO afficher numero_grille_stoc quelque part
#            if @scope.numero_grille_stoc
#              @scope.numero_grille_stoc.value = newString
            return

      removeNumeroGrille: (event, cell) ->
        console.log("remove")

      loadMap: (mongoShapes) ->
        loadResult = @_googleMaps.loadMap(mongoShapes)
        if loadResult
          @_grille = []
          @_stocValid = true

      saveMap: ->
        return @_googleMaps.saveMap()
