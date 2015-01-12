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
    storage.addEventListener (e) ->
      if e.key == 'auth-session'
        if e.newValue?
          authService.loginConfirmed(null, SessionTools.authUpdater)
        else
          $rootScope.$broadcast 'event:auth-loginRequired'
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
      @getUserStatus: (callback) =>
        user_id = @getUserId()
        if user_id
          Backend.one('utilisateurs', user_id).get().then (user) ->
            callback(user)
