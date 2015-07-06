do =>

  ###*
  # factory
  # @ngInject
  ###
  SessionTools = ($window, $location, localStorageService) =>
    self =

      applyAuthorizationHeader: (token) =>
        localStorageService.set('auth-session-token', token)
        #remove the token parameter
        url = '/#' + $location.path()
        params = ''
        for key, value in $location.search()
          if key isnt 'token'
            params += "#{value}&"
        if (params.length > 0)
          url = url + '?' + params
        $window.location.href = url

      getAuthorizationHeader: =>
        token = localStorageService.get('auth-session-token')
        if token?
          return "Basic " + btoa("#{token}:")
        else
          return undefined

      removeAuthorizationHeader: =>
        localStorageService.remove('auth-session-token')

      logRequestError: =>
        # A 401 error happened, this is normal if the user is not currently
        # logged in (i.e. no auth-session-token is set), otherwise it means the
        # current auth-session-token is no longer valid (thus we have to force
        # the user to login again)
        if self.getAuthorizationHeader()?
          self.removeAuthorizationHeader()
          $window.location.reload()

      getModifiedRessource: ( scope, input) =>
        payload =  {}

        angular.copy( input, payload)

        payload._id = undefined
        payload._created = undefined
        payload._updated = undefined

        return payload

    return self


  angular.module('xin_session_tools', [])
  .factory( 'SessionTools', SessionTools)


