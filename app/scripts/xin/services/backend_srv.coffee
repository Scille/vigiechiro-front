'use strict'


angular.module('xin_backend', ['ngRoute', 'restangular', 'xin_session_tools'])
  .factory 'Backend', ($location, Restangular, sessionTools) ->
    customToken = undefined
    backendConfig = Restangular.withConfig (RestangularConfigurer) ->
      RestangularConfigurer.setDefaultHeaders
          Authorization: ->
            if customToken?
              return sessionTools.buildAuthorizationHeader(customToken)
            else
              return sessionTools.getAuthorizationHeader()
          'Cache-Control': -> 'no-cache'
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
          if response.status == 401
            # User is not login, notify the session about this
            sessionTools.logRequestError()
            return true
          else if response.status == 404
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
