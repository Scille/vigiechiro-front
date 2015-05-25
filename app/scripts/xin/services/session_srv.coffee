do =>


  ###*
  # factory
  # @ngInject
  ###
  Session = ( $rootScope, $location, SessionTools, Backend, PubSub, SETTINGS) =>
    self =
      user: {}

      init : () =>
        Backend.setBaseUrl(SETTINGS.API_DOMAIN)
        $rootScope.$on '$routeChangeSuccess', self.routeChanged
        self.connect()

      connect : () =>
        # Force the cache to really get current user
        # Get back the user from the backend
        kendo.ui.progress($("body"), true);
        Backend.one('moi').get(
          {},
          {'Cache-Control': 'false'}
        )
        .then(
          (user) =>
            self.defineUser(user)
            kendo.ui.progress($("body"), false);
          () =>
            self.undefineUser()
            kendo.ui.progress($("body"), false);
        )

      isLogged : () =>
        return SessionTools.getAuthorizationHeader() != undefined

      defineUser : (aUser) =>
        self.user = aUser.plain()
        $rootScope.isAdmin = self.isAdmin()
        $rootScope.isLogged = self.isLogged()
        PubSub.publish('user', self.user)

      undefineUser : () =>
        self.user = {}
        $rootScope.isAdmin = self.isAdmin()
        $rootScope.isLogged = self.isLogged()
        SessionTools.removeAuthorizationHeader()
        PubSub.publish('user', self.user)

      getUser : () =>
        return self.user

      isAdmin : () =>
        return self.user.role == 'Administrateur'

      logout : () =>
        self.user = {}
        SessionTools.removeAuthorizationHeader()
        Backend.one('logout').post().then(postLogout, postLogout)
        self.connect()

      routeChanged : () =>
        authToken = $location.search().token
        if (authToken?)
          SessionTools.applyAuthorizationHeader(authToken)
          self.connect()

    return self


  angular.module('xin_session', [])
  .factory('Session', Session)



