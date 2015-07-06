'use strict'


angular.module('protocole_map_display_all', [])
  .factory 'ProtocoleMapDisplay', (GoogleMaps) ->
    class ProtocoleMapDisplay
      constructor: (mapDiv) ->
        @_googleMaps = new GoogleMaps(mapDiv)
        # hide drawing manager
        @_googleMaps.setDrawingManagerOptions(drawingControl: false)

      displayGrilleStoc: (lat, lng, title = '') ->
        @_googleMaps.createPoint(lat, lng, false, title)
        # 1000*racine(2)
        distance = 1000 * Math.sqrt(2)
        origine = new google.maps.LatLng(lat, lng)
        southWest = google.maps.geometry.spherical.computeOffset(origine, distance, -135)
        northEast = google.maps.geometry.spherical.computeOffset(origine, distance, 45)
        new google.maps.Polygon(
          paths: [
            new google.maps.LatLng(southWest.lat(), northEast.lng())
            new google.maps.LatLng(northEast.lat(), northEast.lng())
            new google.maps.LatLng(northEast.lat(), southWest.lng())
            new google.maps.LatLng(southWest.lat(), southWest.lng())
          ]
          map: @_googleMaps.getMap()
          fillOpacity: 0.5
          fillColor: '#00FF00'
          strokeColor: '#606060'
          strokeOpacity: 0.65
          strokeWeight: 0.5
        )

      loadMap: (sites) ->
        for site in sites or []
          # If grille stoc
          if site.grille_stoc
            coordinates = site.grille_stoc.centre.coordinates
            @displayGrilleStoc(coordinates[1], coordinates[0], site.grille_stoc.numero)
          # If tracet
          if site.tracet
            path = site.tracet.chemin.coordinates
            start = path[0]
            end = path[path.length-1]
            @_googleMaps.createPoint(start[0], start[1])
            @_googleMaps.createPoint(end[0], end[1])
            @_googleMaps.createLineString(path)


  .factory 'ProtocoleMapDisplayCarre', (GoogleMaps, ProtocoleMapDisplay) ->
    class ProtocoleMapDisplayCarre extends ProtocoleMapDisplay
      constructor: (mapDiv) ->
        super mapDiv


  .factory 'ProtocoleMapDisplayRoutier', (GoogleMaps, ProtocoleMapDisplay) ->
    class ProtocoleMapDisplayRoutier extends ProtocoleMapDisplay
      constructor: (mapDiv) ->
        super mapDiv


  .factory 'ProtocoleMapDisplayPointFixe', (GoogleMaps, ProtocoleMapDisplay) ->
    class ProtocoleMapDisplayPointFixe extends ProtocoleMapDisplay
      constructor: (mapDiv) ->
        super mapDiv
