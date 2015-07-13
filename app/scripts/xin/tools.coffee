'use strict'

window.resizeContainer = =>
  grid = $('.k-grid-content')
  if (grid? and grid.length > 0)
    grid.height( $(window).height() - grid.offset().top)
    dataKendoGrid = grid.data('kendoGrid')
    if (dataKendoGrid?)
      dataKendoGrid.resize()

  grid = $('.k-content')
  panelSubmit = $('#panelSubmit')
  if (grid? and grid.length > 0)
    if (panelSubmit? and panelSubmit.length is 1)
      grid.css( 'min-height', panelSubmit.offset().top - grid.offset().top)
    else
      grid.css( 'min-height', $(window).height() -  grid.offset().top)

  ## a revoir
  tags = $('.xin-height100')
  if (tags? and tags.length > 0)
    if (panelSubmit? and panelSubmit.length is 1)
      tags.height( panelSubmit.offset().top - tags.offset().top)
    else
      tags.height( $(window).height() - tags.offset().top)


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

