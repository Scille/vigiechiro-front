'use strict'

window.resizeContainerGrid = (kendo, isGrid = false) =>
  footer = $('footer')
  mainContent = $('#main-content')
  grid = $('#' + kendo)
  if (mainContent? && footer? && grid?)
    footerOffset = footer.offset()
    gridOffset = mainContent.offset()
    if (footerOffset? && gridOffset?)
      height = footerOffset.top - gridOffset.top - 90
      grid.height( height)
      if (isGrid)
        grid.data('kendoGrid').resize();

window.resizeContainerEditor = (kendo) =>
  window.resizeContainerGrid( kendo, false)


$(document).ready(() =>
  $(window).resize(() ->
    window.resizeContainerEditor('kendoEditor')
    window.resizeContainerGrid('kendoGrid')
  )
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
