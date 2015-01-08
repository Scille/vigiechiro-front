'use strict'

angular.module('xin_backend', ['restangular', 'xin_session_tools'])
  .factory 'Backend', (Restangular, SessionTools) ->
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