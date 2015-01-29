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
        @_step = 0
        @_steps = [
          "Sélectionner un carré.",
          "Définir les localités à l'intérieur du carré."
        ]
        @_idGrilleStoc = ''
        @_googleMaps = new GoogleMaps(mapDiv, @mapsCallback())
        @_googleMaps.setDrawingManagerOptions(drawingControl: false)
        @factoryCallback.updateSteps(@getSteps())

      getSteps: ->
        return {
          steps: @_steps
          step: @_step
        }

      mapsCallback: ->
        overlayCreated: (overlay) =>
          isModified = false
          if overlay.type == "Point"
            if google.maps.geometry.poly.containsLocation(overlay.getPosition(), @_grille[0].item)
              isModified = true
          else if overlay.type == "Polygon"
            if @_googleMaps.isPolyInPolygon(overlay, @_grille[0].item)
              isModified = true
          else if overlay.type == "LineString"
            if @_googleMaps.isLineInPolygon(overlay, @_grille[0].item)
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
            #TODO addListener
#            @_googleMaps.addListener(cell, 'rightclick', removeItem(item))
        @_googleMaps.setDrawingManagerOptions(drawingControl: true)

      displayNumeroGrille: (cell) ->
        for stoc in @_grille
          if stoc.item == cell
            newString = "n° grille stoc : " + stoc.numero
            #TODO afficher numero_grille_stoc quelque part
#            if @scope.numero_grille_stoc
#              @scope.numero_grille_stoc.value = newString
            return

      removeNumeroGrille: (event, cell) ->
        console.log("remove")

      loadMap: (mongoShapes, grille_stoc) ->
        if grille_stoc?
          @_step = 1
          @_googleMaps.setCenter(
            grille_stoc.centre.coordinates[1],
            grille_stoc.centre.coordinates[0]
          )
          @_googleMaps.setZoom(14)
          newCell = @createCell(
            grille_stoc.centre.coordinates[1],
            grille_stoc.centre.coordinates[0]
          )
          @validNumeroGrille(newCell, grille_stoc.numero, grille_stoc._id)
        @_googleMaps.loadMap(mongoShapes)

      saveMap: ->
        return @_googleMaps.saveMap()

      getIdGrilleStoc: ->
        return @_idGrilleStoc
