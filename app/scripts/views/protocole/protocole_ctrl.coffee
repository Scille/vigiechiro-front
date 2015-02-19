'use strict'


make_payload = ($scope) ->
  payload =
    'titre': $scope.protocoleForm.titre.$modelValue
    'description': $scope.protocole.description
    'macro_protocole': $scope.protocole.macro_protocole
    'type_site': $scope.protocole.type_site
    'taxon': $scope.protocole.taxon
    'algo_tirage_site': $scope.protocole.algo_tirage_site


angular.module('protocoleViews', ['ngRoute', 'textAngular', 'xin_listResource',
                                  'xin_backend', 'xin_session', 'xin_tools',
                                  'siteViews'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/protocoles',
        templateUrl: 'scripts/views/protocole/list_protocoles.html'
        controller: 'ListProtocolesCtrl'
      .when '/protocoles/mes-protocoles',
        templateUrl: 'scripts/views/protocole/list_protocoles.html'
        controller: 'ListMesProtocolesCtrl'
      .when '/protocoles/nouveau',
        templateUrl: 'scripts/views/protocole/edit_protocole.html'
        controller: 'CreateProtocoleCtrl'
      .when '/protocoles/validations',
        templateUrl: 'scripts/views/protocole/validations_protocole.html'
        controller: 'ValidationsProtocoleCtrl'
      .when '/protocoles/:protocoleId',
        templateUrl: 'scripts/views/protocole/display_protocole.html'
        controller: 'DisplayProtocoleCtrl'
      .when '/protocoles/:protocoleId/edition',
        templateUrl: 'scripts/views/protocole/edit_protocole.html'
        controller: 'EditProtocoleCtrl'

  .controller 'ListProtocolesCtrl', ($scope, $q, $location, Backend,
                                     session, DelayedEvent) ->
    $scope.lookup = {}
    $scope.title = "Tous les protocoles"
    $scope.swap =
      title: "Voir mes protocoles"
      value: "/mes-protocoles"
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    # params = $location.search()
    # if params.where?
    #   $scope.filterField = JSON.parse(params.where).$text.$search
    # else
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.where = JSON.stringify(
              $text:
                $search: filterValue
          )
        else if $scope.lookup.where?
          delete $scope.lookup.where
        # TODO : fix reloadOnSearch: true
        # $location.search('where', $scope.lookup.where)
    $scope.resourceBackend = Backend.all('protocoles')
    # Wrap protocole backend to check if the user is registered (see _status_*)
    resourceBackend_getList = $scope.resourceBackend.getList
    userProtocolesDictDefer = $q.defer()
    session.getUserPromise().then (user) ->
      userProtocolesDict = {}
      for userProtocole in user.protocoles or []
        userProtocolesDict[userProtocole.protocole] = userProtocole
      userProtocolesDictDefer.resolve(userProtocolesDict)
    $scope.resourceBackend.getList = (lookup) ->
      deferred = $q.defer()
      userProtocolesDictDefer.promise.then (userProtocolesDict) ->
        resourceBackend_getList(lookup).then (protocoles) ->
          for protocole in protocoles
            if userProtocolesDict[protocole._id]?
              if userProtocolesDict[protocole._id].valide
                protocole._status_registered = true
              else
                protocole._status_toValidate = true
          deferred.resolve(protocoles)
      return deferred.promise

  .controller 'ListMesProtocolesCtrl', ($scope, $q, $location, Backend,
                                     session, DelayedEvent) ->
    $scope.lookup = {}
    $scope.title = "Mes protocoles"
    $scope.swap =
      title: "Voir tous les protocoles"
      value: ''
    $scope.userProtocolesArray = []
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    # params = $location.search()
    # if params.where?
    #   $scope.filterField = JSON.parse(params.where).$text.$search
    # else
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          console.log($scope.lookup.where)
          $scope.lookup.where = JSON.stringify(
            $text:
              $search: filterValue
            _id:
              $in: $scope.userProtocolesArray
          )
        else
          $scope.lookup.where = JSON.stringify(
            _id:
              $in: $scope.userProtocolesArray
          )
        # TODO : fix reloadOnSearch: true
        # $location.search('where', $scope.lookup.where)
    $scope.resourceBackend = Backend.all('moi/protocoles')
    # Wrap protocole backend to check if the user is registered (see _status_*)
    resourceBackend_getList = $scope.resourceBackend.getList
    userProtocolesDictDefer = $q.defer()
    session.getUserPromise().then (user) ->
      userProtocolesDict = {}
      userProtocolesArray = []
      for userProtocole in user.protocoles or []
        userProtocolesDict[userProtocole.protocole] = userProtocole
        $scope.userProtocolesArray.push(userProtocole.protocole)
      userProtocolesDictDefer.resolve(userProtocolesDict)
    $scope.resourceBackend.getList = (lookup) ->
      deferred = $q.defer()
      userProtocolesDictDefer.promise.then (userProtocolesDict) ->
        resourceBackend_getList(lookup).then (protocoles) ->
          for protocole in protocoles
            if userProtocolesDict[protocole._id]?
              if userProtocolesDict[protocole._id].valide
                protocole._status_registered = true
              else
                protocole._status_toValidate = true
          deferred.resolve(protocoles)
      return deferred.promise

  .controller 'DisplayProtocoleCtrl', ($route, $routeParams, $scope, Backend, session) ->
    $scope.protocole = {}
    $scope.userRegistered = true
    Backend.one('protocoles', $routeParams.protocoleId).get().then (protocole) ->
      $scope.protocole = protocole.plain()
      session.getUserPromise().then (user) ->
        userRegistered = false
        for protocole in user.protocoles or []
          if protocole.protocole._id == $scope.protocole._id
            userRegistered = true
            break
        $scope.userRegistered = userRegistered
      Backend.one('taxons', $scope.protocole.taxon).get().then (taxon) ->
        $scope.taxon = taxon.plain()
    $scope.registerProtocole = ->
      Backend.one('moi/protocoles/'+$scope.protocole._id).put().then(
        ->
          session.refreshPromise()
          $route.reload()
        (error) -> throw error
      )

  .controller 'EditProtocoleCtrl', ($route, $routeParams, $scope, Backend) ->
    $scope.submitted = false
    $scope.protocole = {}
    $scope.taxons = []
    protocoleResource = undefined
    $scope.protocoleId = $routeParams.protocoleId
    Backend.all('taxons').getList().then (taxons) ->
      $scope.taxons = taxons.plain()
    # Force the cache control to get back the last version on the serveur
    Backend.one('protocoles', $routeParams.protocoleId).get(
      {}
      {'Cache-Control': 'no-cache'}
    ).then (protocole) ->
      protocoleResource = protocole
      $scope.protocole = protocole.plain()
    $scope.saveProtocole = ->
      $scope.submitted = true
      if (not $scope.protocoleForm.$valid or
          not $scope.protocoleForm.$dirty or
          not protocoleResource?)
        return
      payload = make_payload($scope)
      # Finally refresh the page (needed for cache reasons)
      protocoleResource.patch(payload).then(
        -> $route.reload();
        (error) -> throw error
      )

  .controller 'CreateProtocoleCtrl', ($scope, Backend) ->
    $scope.submitted = false
    $scope.protocole = {}
    $scope.taxons = []
    Backend.all('taxons').getList().then (taxons) ->
      $scope.taxons = taxons.plain()
    $scope.saveProtocole = ->
      $scope.submitted = true
      if not $scope.protocoleForm.$valid or not $scope.protocoleForm.$dirty
        return
      payload = make_payload($scope)
      Backend.all('protocoles').post(payload).then(
        -> window.location = '#/protocoles'
        (error) -> throw error
      )

  .controller 'ValidationsProtocoleCtrl', ($routeParams, $scope, $filter, Backend) ->
    $scope.loading = true
    $scope.inscriptions = []
    where = JSON.stringify(
      protocoles:
        $elemMatch:
          valide:
            $ne: true
    )
    queryParams = {
      where: where
      sort: "-protocoles.date_inscription"
     # projection:
     #   "protocoles": 1
     #   "pseudo": 1
      embedded: { "protocoles.protocole": 1 }
    }
    Backend.all('utilisateurs').getList(queryParams).then (utilisateurs) ->
      utilisateurs = utilisateurs.plain()
      for utilisateur in utilisateurs
        if not utilisateur.protocoles?
          continue
        for inscription in utilisateur.protocoles
          if not inscription.valide?
            date = new Date(inscription.protocole._updated)
            $scope.inscriptions.push(
              validated: false
              utilisateur_id: utilisateur._id
              utilisateur_pseudo: utilisateur.pseudo
              protocole_id: inscription.protocole._id
              protocole_titre: inscription.protocole.titre
              date_inscription: inscription.date_inscription
            )
      $scope.loading = false

    $scope.validate = (validateInscription) ->
      Backend.one('utilisateurs', validateInscription.utilisateur_id).get().then (utilisateur) ->
        patch = {}
        patch.protocoles = utilisateur.protocoles
        for inscription in patch.protocoles
          if inscription.protocole == validateInscription.protocole_id
            inscription.valide = true
            utilisateur.patch(patch).then (
              # TODO : fix patch return error on success...
              (error) -> throw error
              ->
                validateInscription.validated = true
            )
            return
