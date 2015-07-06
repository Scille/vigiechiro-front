do =>

  ###*
  # factory
  # @ngInject
  ###
  Datasource = (SessionTools, SETTINGS, PubSub) =>

    self =

      getDatasourceOption: (uri, aFields) =>
        new kendo.data.DataSource(
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
        selectable: 'multiple,row'
        change: (e) =>
          PubSub.publish('grid', e.sender.table.select())
        filterable:
          extra: false
          operators:
            string:
              contains: "Contains"
        scrollable:
          virtual: true
        sortable: true
        dataBound: window.resizeContainer

      selectItems: (idAr) ->
        grid = $("#kendoGrid")
        if not idAr instanceof Array
          idAr = [ idAr ]
        items = grid.items().filter((i, el) ->
          idAr.indexOf(grid.dataItem(el).Id) isnt -1
        )
        grid.select items
        return

    return self

  angular.module('xin_datasource', [])
  .factory('Datasource', Datasource)
