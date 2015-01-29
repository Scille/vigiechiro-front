'use strict'

angular.module('protocole_map', ['protocole_carre', 'protocole_point_fixe', 'protocole_routier'])
  .factory 'ProtocoleMap', ($rootScope, Backend,
    ProtocoleCarre, ProtocoleRoutier, ProtocolePointFixe) ->
    class ProtocoleMap
      constructor: (@site, protocoleAlgoSite, mapDiv, @siteCallback) ->
        if protocoleAlgoSite == 'ROUTIER'
          @mapProtocole = new ProtocoleRoutier(mapDiv, @factoryCallback())
        else if protocoleAlgoSite == 'CARRE'
          @mapProtocole = new ProtocoleCarre(mapDiv, @factoryCallback())
        else if protocoleAlgoSite == 'POINT_FIXE'
          @mapProtocole = new ProtocolePointFixe(mapDiv, @factoryCallback())
        else
          throw "Error : unknown protocole @_protocoleAlgoSite"
        @loading = true
        @mapProtocole.loadMap(@site.localites, @site.grille_stoc)
        @loading = false

      factoryCallback: ->
        allowMapChanged: ->
          if not @site.verrouille?
            return true
          return false

        allowOverlayCreated: ->
          if not @site.verrouille?
            return true
          return false

        overlayCreated: =>
          if not @loading
            @siteCallback()

      saveMap: ->
        mapDump = @mapProtocole.saveMap()
        localites = []
        for shape in mapDump
          geometries =
            geometries: [shape]
          localites.push(geometries)
        return localites

      getIdGrilleStoc: ->
        if @mapProtocole.getIdGrilleStoc?
          return @mapProtocole.getIdGrilleStoc()
        return ""
