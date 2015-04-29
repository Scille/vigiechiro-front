'use strict'


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

  .service 'resizeGrid', () ->
    () ->
      window.resizeMyGrid()

window.resizeMyGrid = () =>
#Define Elements Needed
  header = $("#header-content")
  content = $("#main-content")
  grid = $("#grid")

  #Other variables
  minimumAcceptableGridHeight = 100 #This is roughly 5 rows
  otherElementsHeight = 0

  #Get Window Height
  windowHeight = $(window).innerHeight()

  #Get Header Height if its existing
  hasHeader = header.length
  headerHeight = (if hasHeader then header.outerHeight(true) else 0)

  #Get the Grid Element and Areas Inside It
  contentArea = grid.find(".k-grid-content") #This is the content Where Grid is located
  otherGridElements = grid.children().not(".k-grid-content") #This is anything ather than the Grid iteslf like header, commands, etc
  console.debug otherGridElements

  #Calcualte all Grid elements height
  otherGridElements.each ->
    otherElementsHeight += $(this).outerHeight(true)


  #Get other elements same level as Grid
  parentDiv = grid.parent("#outerGridWrapper")
  hasMainContent = parentDiv.length
  if hasMainContent
    otherSiblingElements = content.children().not(".k-grid").not("#grid").not("script")

    #Calculate all Sibling element height
    otherSiblingElements.each ->
      otherElementsHeight += $(this).outerHeight(true)

  #footer
  bottomPadding = $(".footer").outerHeight(true) + 30

  #Check if Calculated height is below threshold
  calculatedHeight = windowHeight - headerHeight - otherElementsHeight - bottomPadding
  finalHeight = (if calculatedHeight < minimumAcceptableGridHeight then minimumAcceptableGridHeight else calculatedHeight)

  #Apply the height for the content area
  contentArea.height finalHeight


window.resizeGridWrapper = ->
  $("#outerGridWrapper").height $("body").innerHeight()

$(window).resize ->
#  window.resizeGridWrapper()
  window.resizeMyGrid()
#  $("#grid").data("kendoGrid").resize();


window.ngInject = (v) ->
  if v instanceof Array
    func = v.pop()
    func.$inject = v
    return func
  else if typeof(v) is 'function'
    return v
  else
    throw 'ngInject must receive a function'
