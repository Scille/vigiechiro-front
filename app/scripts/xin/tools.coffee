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


  .service 'guid', ->
    ->
      s4 = ->
        return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
      id = s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()
      return id



window.ngInject = (v) ->
  if v instanceof Array
    func = v.pop()
    func.$inject = v
    return func
  else if typeof(v) is 'function'
    return v
  else
    throw 'ngInject must receive a function'
