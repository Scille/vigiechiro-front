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
