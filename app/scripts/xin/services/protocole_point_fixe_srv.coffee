'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('xin_protocole_point_fixe', [])
  .factory 'ProtocolePointFixe', ($rootScope, Backend, GoogleMaps) ->
    class ProtocolePointFixe
      constructor: (@scope, mapDiv) ->
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
            @scope.siteForm.$pristine = false
            @scope.siteForm.$dirty = true
            @scope.$apply()
            return true
          else
            return false
        zoomChanged: => @mapsChanged()
        mapsMoved: => @mapsChanged()

      mapsChanged: ->
        console.log(@scope.site.verrouille)
        if @scope.site.verrouille or @_stocValid
          return
        map = @_googleMaps.getMaps()
        zoomLevel = @_googleMaps.getZoom()
        bounds = map.getBounds()
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
        toRadian = Math.PI / 180
        # 360 / (2 * Pi * rayon de la terre)
        rapport = 0.008983153
        grille_stoc = grille_stoc.plain()
        validItem = (item) =>
          (event) => @validNumeroGrille(event, item)
        displayItem = (item) =>
          (event) => @displayNumeroGrille(event, item)
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
            strokeColor: '#606060'
            strokeOpacity: 0.65
            strokeWeight: 0.5
            fillOpacity: 0
            map: @_googleMaps.getMaps()
          )
          @_googleMaps.addListener(item, 'click', validItem(item))
          @_googleMaps.addListener(item, 'mouseover', displayItem(item))
          @_grille.push({"item": item, "numero": cell.numero})

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
            @_googleMaps.setDrawingManagerOptions(drawingControl: true)

      displayNumeroGrille: (event, cell) ->
        for stoc in @_grille
          if stoc.item == cell
            newString = "n° grille stoc : " + stoc.numero
            if @scope.numero_grille_stoc
              @scope.numero_grille_stoc.value = newString
            return

      loadMap: (mongoShapes) ->
        return @_googleMaps.loadMap(mongoShapes)

      saveMap: ->
        return @_googleMaps.saveMap()
