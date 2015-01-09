'use strict'

angular.module('xin_backend', ['ngRoute', 'restangular', 'xin_session_tools'])
  .factory 'Backend', ($location, Restangular, SessionTools) ->
    Restangular.withConfig (RestangularConfigurer) ->
        RestangularConfigurer.setDefaultHeaders
            Authorization: SessionTools.get_authorization_header
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
