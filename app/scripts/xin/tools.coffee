'use strict'

window.resizeContainer = () =>
  footer = $('footer')
  mainContent = $('#main-content')
  if (mainContent.length > 0 && footer.length > 0)
    footerOffset = footer.offset()
    mainOffset = mainContent.offset()
    if (footerOffset? && mainOffset?)
      height = footerOffset.top - mainOffset.top - 20
      mainContent.height(height)
      grid = $('#kendoGrid1')
      if (grid.length > 0)
        grid.height( height)
        dataKendoGrid = grid.data('kendoGrid')
        if (dataKendoGrid?)
          dataKendoGrid.resize()
      grid = $('#kendoGrid2')
      if (grid.length > 0)
        grid.height( height)
        dataKendoGrid = grid.data('kendoGrid')
        if (dataKendoGrid?)
          dataKendoGrid.resize()
      grid = $('.k-editor')
      if (grid.length > 0)
        grid.height( height - 70)
      grid = $('#xinPaneContent')
      if (grid.length > 0)
        grid.height( height - 40)


$(window).resize(() ->
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
          if eventCurrent == @eventCount
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

.service 'createHtmlEditor', () ->
  (description) ->
    $('#kendoEditor').kendoEditor(
      domain: description
      resizable:
        min: 100
        max: 600
      tools: [
        "bold"
        "italic"
        "underline"
        "strikethrough"
        "justifyLeft"
        "justifyCenter"
        "justifyRight"
        "justifyFull"
        "insertUnorderedList"
        "insertOrderedList"
        "indent"
        "outdent"
        "createLink"
        "unlink"
        "insertImage"
        "subscript"
        "superscript"
        "createTable"
        "addRowAbove"
        "addRowBelow"
        "addColumnLeft"
        "addColumnRight"
        "deleteRow"
        "deleteColumn"
        "viewHtml"
        "formatting"
        "cleanFormatting"
        "fontName"
        "fontSize"
        "foreColor"
        "backColor"
        "print"
      ]
    )
    $(window).trigger("resize")
