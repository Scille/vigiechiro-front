'use strict'

angular.module('xin_session', [])
  .factory 'session', ($rootScope, authService, storage) ->
    get_authorization_header = ->
      token = get_element('token')
      if token?
        "Basic " + btoa("#{token}:")
      else
        null
    updater = (config) ->
      config.headers.Authorization = get_authorization_header()
      return config
    # Register a listener to launch login/logout event on storage alteration
    storage.addEventListener (e) ->
      if e.key == 'auth-session'
        if e.newValue?
          authService.loginConfirmed(null, updater)
        else
          authService.loginCancelled()
          $rootScope.$broadcast 'event:auth-loginRequired'
    get_element = (key) ->
      auth_session = storage.getItem('auth-session')
      if auth_session?
        auth_session = JSON.parse(auth_session)
        return auth_session[key]
      else
        $rootScope.$broadcast 'event:auth-loginRequired'
        return null
    class Session
      @login: (user_id, token) ->
        storage.setItem 'auth-session', JSON.stringify
          user_id: user_id
          token: token
        authService.loginConfirmed(null, updater)
      @logout: ->
        storage.removeItem 'auth-session'
        $rootScope.$broadcast 'event:auth-loginRequired'
      @get_user_id: -> get_element('user_id')
      @get_token: -> get_element('token')
      @get_authorization_header: get_authorization_header
