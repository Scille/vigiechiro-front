'use strict'


angular.module('xin_datasource', ['xin_session_tools', 'appSettings', 'xin_tools'])
.factory 'DataSource', (sessionTools, SETTINGS, resizeGrid ) ->
  class DataSource
    @getGridReadOption: ( uri, columns) ->
      gridOption =
        dataSource:
          type: "jsonp"
          transport:
            read:
              url: SETTINGS.API_DOMAIN + uri
              contentType: "application/json; charset=utf-8"
              dataType: "json"
              headers:
                Authorization: sessionTools.buildAuthorizationHeader()
          schema:
            type: "json"
            data: '_items'
          pageSize: 50
          serverPaging: false
          serverSorting: false
        columns: columns
        resizable: true
        dataBound: resizeGrid,
        scrollable:
          virtual: true
        sortable: true
      return gridOption



