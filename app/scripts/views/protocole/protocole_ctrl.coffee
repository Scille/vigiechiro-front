'use strict'

breadcrumbsGetProtocoleDefer = undefined

make_payload_macro = ($scope) ->
  payload =
    'titre': $scope.protocoleForm.titre.$modelValue
    'description': $scope.protocole.description
    'macro_protocole': $scope.protocole.macro_protocole

make_payload = ($scope) ->
  payload = make_payload_macro($scope)
  payload.type_site = $scope.protocole.type_site
  payload.taxon = $scope.protocole.taxon._id
  payload.autojoin = $scope.protocole.autojoin
  return payload


angular.module('protocoleViews', ['ngRoute', 'textAngular',
                                  'ui.select', 'ngSanitize',
                                  'xin_listResource',
                                  'xin_backend', 'xin_session', 'xin_tools',
                                  'displaySiteViews'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/protocoles',
        templateUrl: 'scripts/views/protocole/list_protocoles.html'
        controller: 'ListProtocolesController'
        breadcrumbs: 'Protocoles'
      .when '/protocoles/mes-protocoles',
        templateUrl: 'scripts/views/protocole/list_protocoles.html'
        controller: 'ListMesProtocolesController'
        breadcrumbs: 'Mes Protocoles'
      .when '/protocoles/nouveau',
        templateUrl: 'scripts/views/protocole/edit_protocole.html'
        controller: 'CreateProtocoleController'
        breadcrumbs: 'Nouveau Protocole'
      .when '/protocoles/:protocoleId',
        templateUrl: 'scripts/views/protocole/display_protocole.html'
        controller: 'DisplayProtocoleController'
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetProtocoleDefer = $q.defer()
          breadcrumbsGetProtocoleDefer.promise.then (protocole) ->
            breadcrumbsDefer.resolve([
              ['Protocoles', '#/protocoles']
              [protocole.titre, '#/protocoles/' + protocole._id]
            ])
          return breadcrumbsDefer.promise
      .when '/protocoles/:protocoleId/edition',
        templateUrl: 'scripts/views/protocole/edit_protocole.html'
        controller: 'EditProtocoleController'
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetProtocoleDefer = $q.defer()
          breadcrumbsGetProtocoleDefer.promise.then (protocole) ->
            breadcrumbsDefer.resolve([
              ['Protocoles', '#/protocoles']
              [protocole.titre, '#/protocoles/' + protocole._id]
              ['Édition', '#/protocoles/' + protocole._id + '/edition']
            ])
          return breadcrumbsDefer.promise

  .controller 'ListProtocolesController', ($scope, $q, $location, Backend,
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
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
        # TODO : fix reloadOnSearch: true
        # $location.search('where', $scope.lookup.where)
    $scope.resourceBackend = Backend.all('protocoles')
    # Wrap protocole backend to check if the user is registered (see _status_*)
    resourceBackend_getList = $scope.resourceBackend.getList
    userProtocolesDictDefer = $q.defer()
    session.getUserPromise().then (user) ->
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

  .controller 'ListMesProtocolesController', ($scope, $q, $location, Backend,
                                     session, DelayedEvent) ->
    $scope.lookup = {}
    $scope.title = "Mes protocoles"
    $scope.swap =
      title: "Voir tous les protocoles"
      value: ''
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
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
        # TODO : fix reloadOnSearch: true
        # $location.search('where', $scope.lookup.where)
    $scope.resourceBackend = Backend.all('moi/protocoles')
    # Wrap protocole backend to check if the user is registered (see _status_*)
    resourceBackend_getList = $scope.resourceBackend.getList
    userProtocolesDictDefer = $q.defer()
    session.getUserPromise().then (user) ->
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


  .controller 'DisplayProtocoleController', ($route, $routeParams, $scope, Backend, session) ->
    $scope.protocole = {}
    $scope.userRegistered = false
    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
      Backend.one('protocoles', $routeParams.protocoleId).get().then(
        (protocole) ->
          if breadcrumbsGetProtocoleDefer?
            breadcrumbsGetProtocoleDefer.resolve(protocole)
            breadcrumbsGetProtocoleDefer = undefined
          $scope.protocole = protocole
          for protocole in $scope.user.protocoles or []
            if protocole.protocole._id == $scope.protocole._id
              $scope.userRegistered = true
              break
        (error) -> window.location = '#/404'
      )
    $scope.registerProtocole = ->
      Backend.one('moi/protocoles/'+$scope.protocole._id).put().then(
        (response) ->
          session.refreshPromise()
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
        if breadcrumbsGetProtocoleDefer?
          breadcrumbsGetProtocoleDefer.resolve(protocole)
          breadcrumbsGetProtocoleDefer = undefined
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

  .controller 'CreateProtocoleController', ($scope, session, Backend) ->
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
          Backend.one('moi/protocoles/'+protocole._id).customPUT().then(
            ->
              session.refreshPromise()
              window.location = '#/protocoles/'+protocole._id
            (error) -> throw error
          )
        (error) -> throw error
      )
