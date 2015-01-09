'use strict'

angular.module('xin_storage', [])
  .factory 'storage', ->
    class Storage
      # localStorage uses native code, must wrap the calls...
      @_event_handler = undefined
      @getItem: (key) -> window.localStorage.getItem(key)
      @setItem: (key, value) =>
        e =
          "key": key
          "oldValue": @getItem(key)
          "newValue": value
        window.localStorage.setItem(key, value)
        @_event_handler?(e)
      @removeItem: (key) =>
        e =
          "key": key
          "oldValue": @getItem(key)
          "newValue": null
        window.localStorage.removeItem(key)
        @_event_handler?(e)
      @clear: -> window.localStorage.clear()
      @addEventListener: (handler) =>
        @_event_handler = handler
        if window.addEventListener?
          #Normal browsers
          window.addEventListener "storage", handler, false
        else
          # for IE (why make your life more difficult)
          window.attachEvent "onstorage", handler
