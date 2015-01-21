'use strict'


angular.module('xin_session', ['xin_storage', 'xin_backend'])
  .factory 'session', ($q, $window, $location, storage, Backend) ->
    # If the auth-session element is modified by another tab (i.g.
    # for session refresh or logout) we have to reload the page
    storage.addEventListener (e) ->
      if e.key == 'auth-session-token'
        $window.location.reload()
    class Session
      @_userPromise = undefined
      @refreshPromise = =>
        # Get back the user from the backend
        token = storage.getItem('auth-session-token')
        if token?
          # Force the cache to really get current user
          @_userPromise = Backend.one('utilisateurs', 'moi').get(
            {},
            {'Cache-Control': 'no-cache'}
          )
        else
          # If the user is not logged, no need to call the backend
          deferred = $q.defer()
          deferred.reject()
          @_userPromise = deferred.promise
      @getUserPromise = => @_userPromise
      @getIsAdminPromise = =>
        deferred = $q.defer()
        @_userPromise.then(
          (user) -> deferred.resolve(user.role == 'Administrateur')
          -> deferred.resolve(false)
        )
        return deferred.promise
      @login: (token) ->
        storage.setItem('auth-session-token', token)
        # TODO : Find a cleaner fix
        # Under firefox, `$window.location.reload()` do to a page reload while
        # keeping the token params, leading to an infinite reload loop...
        url = '/#' + $location.path() + '?'
        for key, value in $location.search()
          if key != 'token'
            url += "#{value}&"
        $window.location.href = url
      @logout: ->
        postLogout = (e)->
          storage.removeItem('auth-session-token')
          $window.location.reload()
        # Error or success on backend logout, we delete the session token
        Backend.one('logout').post().then(postLogout, postLogout)
    Session.refreshPromise()
    return Session

angular.module('xin_session_tools', ['xin_storage'])
  .factory 'sessionTools', ($window, storage) ->
    class sessionTools
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
        # logged in (i.e. no auth-session-token is set), otherwise it means the
        # current auth-session-token is no longer valid (thus we have to force
        # the user to login again)
        authSession = storage.getItem('auth-session-token')
        if authSession?
          storage.removeItem('auth-session-token')
          $window.location.reload()
