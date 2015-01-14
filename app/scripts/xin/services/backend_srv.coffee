'use strict'


angular.module('xin_backend', ['ngRoute', 'restangular', 'xin_session_tools'])
  .factory 'Backend', ($location, Restangular, SessionTools) ->
    customToken = undefined
    backendConfig = Restangular.withConfig (RestangularConfigurer) ->
      RestangularConfigurer.setDefaultHeaders
          Authorization: ->
            if customToken?
              return SessionTools.buildAuthorizationHeader(customToken)
            else
              return SessionTools.getAuthorizationHeader()
        .setRestangularFields
          id: "_id"
          etag: "_etag"
        .addResponseInterceptor (data, operation, what, url, response, deferred) ->
          if operation == "getList"
            extractedData = data._items
            extractedData._meta = data._meta
            extractedData._links = data._links
            extractedData.self = data.self
          else
            extractedData = data
          return extractedData
        .setErrorInterceptor (response, deferred, responseHandler) ->
          if response.status == 404
            $location.path('/404')
          else if response.status == 403
            $location.path('/403')
          else
            return true # error not handled
          return false # error handled
    backendConfig.setCustomToken = (token) ->
      # During the login process, we have to explicitly provide the token
      customToken = token
    backendConfig.resetCustomToken = (token=undefined) ->
      customToken = undefined

    return backendConfig
