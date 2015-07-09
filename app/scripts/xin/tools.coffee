'use strict'

window.resizeContainer = =>
  grid = $('.k-grid-content')
  if (grid? and grid.length > 0)
    grid.height( $(window).height() - grid.offset().top - 6)
    dataKendoGrid = grid.data('kendoGrid')
    if (dataKendoGrid?)
      dataKendoGrid.resize()
  grid = $('.k-content')
  panelSubmit = $('#panelSubmit')
  if (grid? and grid.length > 0 and panelSubmit?)
    grid.css( 'min-height', panelSubmit.offset().top - grid.offset().top - 10)

$(window).resize( ->
  window.resizeContainer()
)


window.ngInject = (v) ->
  if v instanceof Array
    func = v.pop()
    func.$inject = v
    return func
  else if typeof(v) is 'function'
    return v
  else
    throw 'ngInject must receive a function'


angular.module('xin_tools', [])
.service 'DelayedEvent', ($timeout) ->
  class DelayedEvent
    constructor: (@timer) ->
      @eventCount = 0
    triggerEvent: (action) ->
      @eventCount += 1
      eventCurrent = @eventCount
      $timeout(
        =>
          if eventCurrent is @eventCount
            action()
        @timer
      )

.filter "xinDate", ($filter) ->
  dateFilter = $filter('date')
  (input, format, timezone) ->
    dateFilter(Date.parse(input), format, timezone)

.service 'evalCallDefered', ($q, $injector) ->
  (elem) ->
    if typeof(elem) is 'function'
      result = $injector.invoke(elem)
      if result.then?
        return result
      else
        defer = $q.defer()
        defer.resolve(result)
    else
      defer = $q.defer()
      defer.resolve(elem)
    return defer.promise

