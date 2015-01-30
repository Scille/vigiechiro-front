'use strict'

###*
 # args
 ## @div : element html (div) dans laquelle la map sera instanciée
###
angular.module('protocole_point_fixe', [])
  .factory 'ProtocolePointFixe', ($rootScope, Backend, GoogleMaps, ProtocoleMap) ->
    class ProtocolePointFixe extends ProtocoleMap
