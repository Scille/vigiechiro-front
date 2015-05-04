'use strict'


angular.module('xin_datasource', ['xin_session_tools', 'appSettings', 'xin_tools'])
.factory 'DataSource', (sessionTools, SETTINGS, resizeGrid) ->
  class DataSource
    @getGridReadOption: (uri, aModel, aColumns) ->
      gridOption =
        dataSource:
          transport:
            read:
              url: SETTINGS.API_DOMAIN + uri
              dataType: "json"
              data:
                max_results: 100
              headers:
                Authorization: sessionTools.getAuthorizationHeader()
          serverPaging: false
          serverSorting: false
          pageSize: 100
          schema:
            type: "json"
            data: '_items'
            id: "_id"
            total: "total"
            model: aModel
        columns: aColumns
        resizable: true
        filterable:
          extra: false
          operators:
            string:
              contains: "Contains"
        dataBound: resizeGrid
        scrollable:
          virtual: true
        sortable: true
      return gridOption
