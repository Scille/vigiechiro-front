'use strict'

angular.module('protocole_factory', ['protocole_carre', 'protocole_point_fixe', 'protocole_routier'])
  .factory 'ProtocoleFactory', ($rootScope, Backend,
    ProtocoleCarre, ProtocoleRoutier, ProtocolePointFixe) ->
    class ProtocoleFactory
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
        @mapProtocole.loadMap(@site.localites)
        @loading = false
        return @mapProtocole

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
