'use strict'


angular.module('xin_session_tools', ['xin_storage'])
  .factory 'SessionTools', (storage) ->
    class SessionTools
      @authUpdater: (config) ->
        config.headers.Authorization = @get_authorization_header()
        return config
      @get_authorization_header: =>
        token = @get_element('token')
        if token?
          "Basic " + btoa("#{token}:")
        else
          null
      @get_element: (key) ->
        auth_session = storage.getItem('auth-session')
        if auth_session?
          auth_session = JSON.parse(auth_session)
          return auth_session[key]
        else
          $rootScope.$broadcast 'event:auth-loginRequired'
          return null


angular.module('xin_session', ['http-auth-interceptor', 'xin_storage', 'xin_session_tools', 'xin_backend'])
  .factory 'session', ($rootScope, Backend, SessionTools, authService, storage) ->
    class Session
      @login: (user_id, token) ->
        storage.setItem 'auth-session', JSON.stringify
          user_id: user_id
          token: token
        authService.loginConfirmed(null, SessionTools.authUpdater)
      @logout: ->
        Backend.one('logout').post().then ->
          storage.removeItem 'auth-session'
          $rootScope.$broadcast 'event:auth-loginRequired'
      @get_user_id: -> SessionTools.get_element('user_id')
      @get_token: -> SessionTools.get_element('token')
      @get_user_status: (callback) =>
        user_id = @get_user_id()
        if user_id
          Backend.one('utilisateurs', user_id).get().then (user) ->
            callback(user)
