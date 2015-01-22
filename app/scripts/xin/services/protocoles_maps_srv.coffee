'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('xin_protocoles_maps', ['xin_google_maps'])
  .factory 'ProtocolesCarres', ($rootScope) ->
    class ProtocolesCarres
      constructor: (@div, eventCallback) ->
        @googlemaps = new GoogleMaps(@div, eventCallback)

      loadMap: (mongoShapes) ->
        @googlemaps.loadMap(mongoShapes)

      saveMap: ->
        @googlemaps.saveMap()
