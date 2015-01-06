'use strict'

angular.module('xin_geolocation', [])
  .factory 'GeolocationSrv', ->
    if navigator.geolocation
      navigator.geolocation
    # TODO stub/throw errors if navigator is not available
