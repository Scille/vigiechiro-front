'use strict'


angular.module('xin_session_tools', ['xin_storage'])
  .factory 'SessionTools', ($rootScope, storage) ->
    class SessionTools
      @authUpdater: (config) =>
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
    # Register a listener to launch login/logout event on storage alteration
    storage.addEventListener (e) ->
      if e.key == 'auth-session'
        if e.newValue?
          authService.loginConfirmed(null, SessionTools.authUpdater)
        else if e.oldValue?
          $rootScope.$broadcast 'event:auth-loginRequired'
    class Session
      @login: (user_id, token) ->
        storage.setItem 'auth-session', JSON.stringify
          user_id: user_id
          token: token
      @logout: ->
        Backend.one('logout').post().then ->
          storage.removeItem 'auth-session'
      @get_user_id: -> SessionTools.get_element('user_id')
      @get_token: -> SessionTools.get_element('token')
      @get_user_status: (callback) =>
        user_id = @get_user_id()
        if user_id
          Backend.one('utilisateurs', user_id).get().then (user) ->
            callback(user)
