'use strict'

angular.module('vigiechiroApp')
  .factory 'Geolocation', ->
    if navigator.geolocation
      navigator.geolocation
    # TODO stub/throw errors if navigator is not available
