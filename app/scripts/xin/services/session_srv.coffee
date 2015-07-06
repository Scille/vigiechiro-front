do =>


  ###*
  # factory
  # @ngInject
  ###
  Session = ( $rootScope, $location, SessionTools, Backend, PubSub, SETTINGS) =>
    self =
      user: {}

      init: =>
        Backend.setBaseUrl(SETTINGS.API_DOMAIN)
        $rootScope.$on '$routeChangeSuccess', self.routeChanged
        self.connect()

      connect: =>
        # Force the cache to really get current user
        # Get back the user from the backend
        Backend.one('moi').get(
          {},
          {'Cache-Control': 'false'}
        )
        .then(
          (user) =>
            self.defineUser(user)
          =>
            self.undefineUser()
        )

      isLogged: =>
        return SessionTools.getAuthorizationHeader() isnt undefined

      defineUser: (aUser) =>
        self.user = aUser.plain()
        $rootScope.isAdmin = self.isAdmin()
        $rootScope.isLogged = self.isLogged()
        PubSub.publish('user', self.user)

      undefineUser: =>
        self.user = {}
        $rootScope.isAdmin = self.isAdmin()
        $rootScope.isLogged = self.isLogged()
        SessionTools.removeAuthorizationHeader()
        PubSub.publish('user', self.user)

      getUser: =>
        return self.user

      isAdmin: =>
        return self.user.role is 'Administrateur'

      logout: =>
        self.user = {}
        SessionTools.removeAuthorizationHeader()
        Backend.one('logout').post().then(postLogout, postLogout)
        self.connect()

      routeChanged: =>
        authToken = $location.search().token
        if (authToken?)
          SessionTools.applyAuthorizationHeader(authToken)
          self.connect()

    return self


  angular.module('xin_session', [])
  .factory('Session', Session)



