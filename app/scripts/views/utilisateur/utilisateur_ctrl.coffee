'use strict'

breadcrumbsGetUtilisateurDefer = undefined


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowUtilisateurCtrl
 # @description
 # # ShowUtilisateurCtrl
 # Controller of the vigiechiroApp
###
angular.module('utilisateurViews', ['ngRoute', 'xin_listResource', 'xin_tools',
                                    'xin_session', 'xin_backend'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/utilisateurs',
        templateUrl: 'scripts/views/utilisateur/list_utilisateurs.html'
        controller: 'ListUtilisateursController'
        breadcrumbs: 'Utilisateurs'
      .when '/utilisateurs/:userId',
        templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurController'
        breadcrumbs: ngInject ($q) ->
            breadcrumbsDefer = $q.defer()
            breadcrumbsGetUtilisateurDefer = $q.defer()
            breadcrumbsGetUtilisateurDefer.promise.then (utilisateur) ->
              breadcrumbsDefer.resolve([
                ['Utilisateurs', '#/utilisateurs']
                [utilisateur.pseudo, '#/utilisateurs/' + utilisateur._id]
              ])
            return breadcrumbsDefer.promise

  .controller 'ListUtilisateursController', ($scope, Backend, DelayedEvent) ->
    $scope.lookup = {}
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('utilisateurs')

  .controller 'ShowUtilisateurController', ($scope, $route, $routeParams, Backend, session) ->
    $scope.submitted = false
    $scope.utilisateur = {}
    $scope.readOnly = false
    $scope.isAdmin = false
    $scope.displayCharte = -> $('#charteModal').modal()
    userResource = undefined
    origin_role = undefined
    userBackend = undefined
    if $routeParams.userId == 'moi'
      userBackend = Backend.one('moi')
    else
      userBackend = Backend.one('utilisateurs', $routeParams.userId)
    userBackend.get().then(
      (utilisateur) ->
        if breadcrumbsGetUtilisateurDefer?
          breadcrumbsGetUtilisateurDefer.resolve(utilisateur)
          breadcrumbsGetUtilisateurDefer = undefined
        userResource = utilisateur
        $scope.utilisateur = utilisateur.plain()
        origin_role = $scope.utilisateur.role
        session.getUserPromise().then (user) ->
          $scope.isAdmin = user.role == 'Administrateur'
          $scope.readOnly = (not $scope.isAdmin and
                             user._id != utilisateur._id)
      (error) -> window.location = '#/404'
    )

    $scope.saveUser = ->
      $scope.submitted = true
      if (not $scope.userForm.$valid or
          not $scope.userForm.$dirty or
          not userResource?)
        return
      payload = {}
      # Retrieve the modified fields from the form
      for key, value of $scope.userForm
        if key.charAt(0) != '$' and value.$dirty
          payload[key] = $scope.utilisateur[key]
      # Special handling for radio buttons
      for field in ['professionnel', 'donnees_publiques', 'charte_acceptee']
        payload[field] = $scope.utilisateur[field]
      # Special handling for select
      if $scope.utilisateur.role != origin_role
        payload.role = $scope.utilisateur.role
      userBackend.patch(payload).then(
        -> $route.reload()
        (error) -> $scope.saveError = true
      )
