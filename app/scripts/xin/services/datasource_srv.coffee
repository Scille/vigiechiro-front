'use strict'


angular.module('xin_datasource', ['xin_session_tools', 'appSettings', 'xin_tools'])
.factory 'DataSource', (sessionTools, SETTINGS) ->
  class DataSource
    @getGridReadOption: (uri, aModel, aColumns) ->
      gridOption =
        dataSource:
          transport:
            read:
              url: SETTINGS.API_DOMAIN + uri
              dataType: "json"
              data:
                max_results: 20
              headers:
                Authorization: sessionTools.getAuthorizationHeader()
          serverPaging: true
          serverSorting: false
          pageSize: 20
          schema:
            type: "json"
            data: "_items"
            total: (response) =>
              return response._meta.total
            model: aModel
        columns: aColumns
        resizable: true
        filterable:
          extra: false
          operators:
            string:
              contains: "Contains"
        sortable: true
        dataBound: window.resizeContainer()
        scrollable:
          virtual: true
      return gridOption
