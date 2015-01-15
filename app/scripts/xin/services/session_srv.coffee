'use strict'


angular.module('xin_session_tools', ['xin_storage'])
  .factory 'SessionTools', ($rootScope, storage) ->
    class SessionTools
      @authUpdater: (config) =>
        config.headers.Authorization = @getAuthorizationHeader()
        return config
      @buildAuthorizationHeader: (token) ->
        "Basic " + btoa("#{token}:")
      @getAuthorizationHeader: =>
        token = @getElement('token')
        if token?
          return @buildAuthorizationHeader(token)
        else
          return undefined
      @getProfile: ->
        auth_session = storage.getItem('auth-session')
        if auth_session?
          return JSON.parse(auth_session)
      @getElement: (key) =>
        profil = @getProfile()
        return profil?[key]

angular.module('xin_session', ['http-auth-interceptor', 'xin_storage', 'xin_session_tools', 'xin_backend'])
  .factory 'session', ($rootScope, Backend, SessionTools, authService, storage) ->
    # Register a listener to launch login/logout event on storage alteration
    loginConfirmed = ->
      authService.loginConfirmed(null, SessionTools.authUpdater)
    storage.addEventListener (e) ->
      if e.key == 'auth-session'
        if e.newValue?
          loginConfirmed()
        else
          $rootScope.$broadcast('event:auth-loginRequired')
    class Session
      @login: (token) ->
        Backend.setCustomToken(token)
        Backend.one('utilisateurs', 'moi').get().then (user) ->
          user.token = token
          storage.setItem('auth-session', JSON.stringify(user))
          Backend.resetCustomToken()
      @logout: ->
        Backend.one('logout').post().then ->
          storage.removeItem('auth-session')
      @getUserId: -> SessionTools.getElement('_id')
      @getToken: -> SessionTools.getElement('token')
      @getProfile: SessionTools.getProfile
      @refreshProfile: () ->
        Backend.one('utilisateurs', 'moi').get().then (user) ->
          storage.setItem('auth-session', JSON.stringify(user))
