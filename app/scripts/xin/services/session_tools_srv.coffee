do =>

  ###*
  # factory
  # @ngInject
  ###
  SessionTools = ($q, $window, $location, Storage) =>
    self =

      applyAuthorizationHeader: (token) =>
        Storage.setItem('auth-session-token', token)
        #remove the token parameter
        url = '/#' + $location.path()
        params = ''
        for key, value in $location.search()
          if key != 'token'
            params += "#{value}&"
        if (params.length > 0)
          url = url + '?' + params
        $window.location.href = url

      getAuthorizationHeader: () =>
        token = Storage.getItem('auth-session-token')
        if token?
          return "Basic " + btoa("#{token}:")
        else
          return undefined

      removeAuthorizationHeader: () =>
        Storage.removeItem('auth-session-token')

      logRequestError: =>
        # A 401 error happened, this is normal if the user is not currently
        # logged in (i.e. no auth-session-token is set), otherwise it means the
        # current auth-session-token is no longer valid (thus we have to force
        # the user to login again)
        if self.getAuthorizationHeader()?
          self.removeAuthorizationHeader()
          $window.location.reload()

    return self


  angular.module('xin_session_tools', [])
  .factory( 'SessionTools', SessionTools)


