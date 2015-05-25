do =>

  ###*
  # factory
  # @ngInject
  ###
  Datasource = (SessionTools, SETTINGS) =>

    self =

      getDatasourceOption: (uri, aFields) =>
        dataSource = new kendo.data.DataSource(
          transport:
            read:
              url: SETTINGS.API_DOMAIN + uri
              dataType: "json"
              data:
                max_results: 20
              headers:
                Authorization: SessionTools.getAuthorizationHeader()
          serverPaging: true
          serverSorting: false
          pageSize: 20
          schema:
            type: "json"
            data: "_items"
            total: (response) =>
              return response._meta.total
            model:
              id: '_id'
              fields: aFields
        )


      getGridReadOption: (uri, aFields, aColumns) =>
        dataSource: self.getDatasourceOption(uri, aFields)
        columns: aColumns
        resizable: true
        filterable:
          extra: false
          operators:
            string:
              contains: "Contains"
        scrollable:
          virtual: true
        sortable: true
        dataBound: window.resizeContainer

    return self

  angular.module('xin_datasource', [])
  .factory('Datasource', Datasource)
