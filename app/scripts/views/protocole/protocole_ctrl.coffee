'use strict'

make_payload_macro = ($scope) ->
  payload =
    'titre': $scope.protocoleForm.titre.$modelValue
    'description': $scope.protocole.description
    'macro_protocole': $scope.protocole.macro_protocole

make_payload = ($scope) ->
  payload = make_payload_macro($scope)
  payload.type_site = $scope.protocole.type_site
  payload.taxon = $scope.protocole.taxon._id
  return payload


angular.module('protocoleViews', ['ngRoute', 'ng-breadcrumbs', 'textAngular',
                                  'ui.select', 'ngSanitize',
                                  'xin_listResource',
                                  'xin_backend', 'xin_session', 'xin_tools',
                                  'displaySiteViews'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/protocoles',
        templateUrl: 'scripts/views/protocole/list_protocoles.html'
        controller: 'ListProtocolesController'
        label: 'Protocoles'
      .when '/protocoles/mes-protocoles',
        templateUrl: 'scripts/views/protocole/list_mesprotocoles.html'
        controller: 'ListMesProtocolesController'
        label: 'Mes Protocoles'
      .when '/protocoles/nouveau',
        templateUrl: 'scripts/views/protocole/edit_protocole.html'
        controller: 'CreateProtocoleController'
        label: 'Nouveau Protocole'
      .when '/protocoles/:protocoleId',
        templateUrl: 'scripts/views/protocole/display_protocole.html'
        controller: 'DisplayProtocoleController'
        label: 'Libelle'
      .when '/protocoles/:protocoleId/edition',
        templateUrl: 'scripts/views/protocole/edit_protocole.html'
        controller: 'EditProtocoleController'
        label: 'Edition'

  .controller 'ListProtocolesController', ($scope, $q, $location, Backend, Session,  PubSub) ->
    $scope.lookup = {}
    $scope.isAdmin = Session.isAdmin()
    PubSub.subscribe 'search', (filterValue) =>
      if filterValue? and filterValue isnt ''
        $scope.lookup.q = filterValue
      else if $scope.lookup.q?
        delete $scope.lookup.q
        location.reload

    $scope.resourceBackend = Backend.all('protocoles')
    # Wrap protocole backend to check if the user is registered (see _status_*)
    resourceBackend_getList = $scope.resourceBackend.getList
    userProtocolesDictDefer = $q.defer()
    user = Session.getUser()
    userProtocolesDict = {}
    for userProtocole in user.protocoles or []
      userProtocolesDict[userProtocole.protocole._id] = userProtocole
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

  .controller 'ListMesProtocolesController', ($scope, $q, $location, Backend, Session,  DelayedEvent, PubSub) ->
    $scope.lookup = {}
    delayedFilter = new DelayedEvent(500)
    PubSub.subscribe 'search', (filterValue) =>
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue isnt ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('moi/protocoles')
    # Wrap protocole backend to check if the user is registered (see _status_*)
    resourceBackend_getList = $scope.resourceBackend.getList
    userProtocolesDictDefer = $q.defer()
    user = Session.getUser()
    userProtocolesDict = {}
    for userProtocole in user.protocoles or []
      userProtocolesDict[userProtocole.protocole._id] = userProtocole
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


  .controller 'DisplayProtocoleController', ($route, $routeParams, breadcrumbs, $scope, Backend, Session) ->
    $scope.protocole = {}
    $scope.userRegistered = false
    $scope.user = Session.getUser()
    Backend.one('protocoles', $routeParams.protocoleId).get().then(
      (protocole) ->
        $scope.protocole = protocole
        breadcrumbs.options =
          'Libelle': $scope.protocole.titre
        for protocole in $scope.user.protocoles or []
          if protocole.protocole._id is $scope.protocole._id
            $scope.userRegistered = true
            break
      (error) -> window.location = '#/404'
    )
    $scope.registerItem = ->
      Backend.one('moi/protocoles/' + $scope.protocole._id).put().then(
        (response) ->
          Session.refreshPromise()
          $route.reload()
        (error) -> throw error
      )

  .controller 'EditProtocoleController', ($route, $routeParams, $scope, Backend) ->
    $scope.submitted = false
    $scope.protocole = {}
    $scope.taxons = []
    protocoleResource = undefined
    $scope.protocoleId = $routeParams.protocoleId
    Backend.all('taxons').getList().then (taxons) ->
      $scope.taxons = taxons.plain()
    # Force the cache control to get back the last version on the serveur
    Backend.one('protocoles', $routeParams.protocoleId).get().then(
      (protocole) ->
        protocoleResource = protocole
        $scope.protocole = protocole.plain()
      (error) -> window.location = '#/404'
    )
    $scope.saveProtocole = ->
      $scope.submitted = true
      if (not $scope.protocoleForm.$valid or
          not $scope.protocoleForm.$dirty or
          not protocoleResource?)
        return
      payload = null
      if $scope.protocole.macro_protocole
        payload = make_payload_macro($scope)
      else
        payload = make_payload($scope)
      # Finally refresh the page (needed for cache reasons)
      protocoleResource.patch(payload).then(
        -> $route.reload()
        (error) -> throw error
      )

  .controller 'CreateProtocoleController', ($scope, Session, Backend) ->
    $scope.submitted = false
    $scope.protocole = {}
    $scope.configuration_participation = {}
    $scope.taxons = []

    Backend.all('taxons').all('liste').getList().then (taxons) ->
      $scope.taxons = taxons.plain()

    $scope.saveProtocole = ->
      $scope.submitted = true
      if not $scope.protocoleForm.$valid or not $scope.protocoleForm.$dirty
        return
      payload = null
      if $scope.protocole.macro_protocole
        payload = make_payload_macro($scope)
      else
        payload = make_payload($scope)
      Backend.all('protocoles').post(payload).then(
        (protocole) ->
          Backend.one('moi/protocoles/' + protocole._id).customPUT().then(
            ->
              Session.refreshPromise()
              window.location = '#/protocoles/' + protocole._id
            (error) -> throw error
          )
        (error) -> throw error
      )
