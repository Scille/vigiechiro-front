'use strict'

breadcrumbsGetUtilisateurDefer = undefined


angular.module('utilisateurViews', ['ngRoute', 'xin_listResource', 'xin_tools',
                                    'xin_session', 'xin_backend',
                                    'sc-toggle-switch', 'rzModule'])
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



  .controller 'ShowUtilisateurController', ($scope, $route, $routeParams, Backend, session, SETTINGS) ->
    $scope.saveDone = {}
    $scope.utilisateur = {}
    originUser = {}
    $scope.readOnly = false
    $scope.isAdmin = false
    userResource = undefined
    userBackend = undefined

    $scope.vitesse_connexion =
      options:
        stepsArray: ["< ou ~ 5 Mbit/s", "~ 10 Mbit/s", "~ 20 Mbit/s", "> 20 Mbit/s"]
        showTicksValues: true
        showSelectionBar: true
        getSelectionBarColor: (value) ->
          if value == 0
            return 'red'
          else if value == 1
            return 'orange'
          else if value == 2
            return 'yellow'
          return 'green'

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
        angular.copy($scope.utilisateur, originUser)

        session.getUserPromise().then (user) ->
          $scope.isAdmin = user.role == 'Administrateur'
          $scope.readOnly = (not $scope.isAdmin and
                             user._id != utilisateur._id)
      (error) -> window.location = '#/404'
    )

    $scope.save = ->
      payload = {}
      $scope.saveError = false
      for field in SETTINGS.USER_FIELDS
        if $scope.utilisateur[field] != originUser[field]
          payload[field] = $scope.utilisateur[field]
      if Object.keys(payload).length == 0
        $scope.errorMessage = "Aucune modification à sauvegarder."
        $scope.saveError = true
        $scope.saveDone.end?()
        return
      userBackend.patch(payload).then(
        -> $route.reload()
        (error) ->
          $scope.errorMessage = "Echec de l'enregistrement de l'utilisateur."
          $scope.saveError = true
          $scope.saveDone.end?()
      )
