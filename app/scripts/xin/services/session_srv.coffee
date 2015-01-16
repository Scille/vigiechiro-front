'use strict'


angular.module('xin_session', ['xin_storage', 'xin_backend'])
  .factory 'session', ($q, $window, $location, storage, Backend) ->
    # If the auth-session element is modified by another tab (i.g.
    # for session refresh or logout) we have to reload the page
    storage.addEventListener (e) ->
      if e.key == 'auth-session-token'
        $window.location.reload()
    # Get back the user from the backend
    token = storage.getItem('auth-session-token')
    if token?
      userPromise = Backend.one('utilisateurs', 'moi').get()
    else
      # If the user is not logged, no need to call the backend
      deferred = $q.defer()
      deferred.reject()
      userPromise = deferred.promise
    class Session
      @_userPromise = userPromise
      @getUserPromise = => @_userPromise
      @login: (token) ->
        storage.setItem('auth-session-token', token)
        # Remove token in params to avoid infinite loop
        $location.search('token', null)
        $window.location.reload()
      @logout: ->
        postLogout = (e)->
          storage.removeItem('auth-session-token')
          $window.location.reload()
        # Error or success on backend logout, we delete the session token
        Backend.one('logout').post().then(postLogout, postLogout)


angular.module('xin_session_tools', ['xin_storage'])
  .factory 'SessionTools', ($window, storage) ->
    class SessionTools
      @buildAuthorizationHeader: (token) ->
        "Basic " + btoa("#{token}:")
      @getAuthorizationHeader: =>
        token = storage.getItem('auth-session-token')
        if token?
          return @buildAuthorizationHeader(token)
        else
          return undefined
      @logRequestError: ->
        # A 401 error happened, this is normal if the user is not currently
        # logged in (i.e. no token is set), otherwise it means the current
        # token is no longer valid (thus we have to force the user to
        # login again)
        token = storage.getItem('auth-session-token')
        if token?
          storage.removeItem('auth-session-token')
          $window.location.reload()
