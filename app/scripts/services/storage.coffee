'use strict'

angular.module('vigiechiroApp')
  .factory 'storage', ->
    class Storage
      # localStorage uses native code, must wrap the calls...
      @getItem: (key) -> window.localStorage.getItem key
      @setItem: (key, value) -> window.localStorage.setItem key, value
      @removeItem: (key) -> window.localStorage.removeItem key
      @clear: -> window.localStorage.clear()
      @addEventListener: (handler) ->
        if window.addEventListener?
          #Normal browsers
          window.addEventListener "storage", handler, false
        else
          # for IE (why make your life more difficult)
          window.attachEvent "onstorage", handler
