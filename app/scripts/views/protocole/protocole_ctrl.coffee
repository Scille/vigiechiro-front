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
                                  'xin_backend', 'xin_session', 'siteViews'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/protocoles',
        templateUrl: 'scripts/views/protocole/list_protocoles.html'
        controller: 'ListResourceCtrl'
        resolve: {resourceBackend: (Backend) -> Backend.all('protocoles')}
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

  .controller 'DisplayProtocoleCtrl', ($route, $routeParams, $scope, Backend, session) ->
    $scope.protocole = {}
    $scope.userRegistered = true
    Backend.one('protocoles', $routeParams.protocoleId).get().then (protocole) ->
      $scope.protocole = protocole.plain()
      session.getUserPromise().then (user) ->
        userRegistered = false
        for protocole in user.protocoles or []
          if protocole.protocole == $scope.protocole._id
            userRegistered = true
            break
        $scope.userRegistered = userRegistered
      Backend.one('taxons', $scope.protocole.taxon).get().then (taxon) ->
        $scope.taxon = taxon.plain()
    $scope.registerProtocole = ->
      Backend.one('protocoles', $scope.protocole._id+"/action/join").post().then(
        ->
          session.refreshPromise()
          $route.reload()
        (error) -> console.log("error", error)
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
        (error) -> console.log("error", error)
      )

  .controller 'CreateProtocoleCtrl', ($scope, Backend) ->
    $scope.submitted = false
    $scope.protocole = {}
    $scope.taxons = []
    Backend.all('taxons').getList().then (taxons) ->
      $scope.taxons = taxons.plain()
    $scope.saveProtocole = ->
      $scope.submitted = true
      console.log($scope.protocoleForm.algo_tirage_site)
      if not $scope.protocoleForm.$valid or not $scope.protocoleForm.$dirty
        return
      payload = make_payload($scope)
      Backend.all('protocoles').post(payload).then(
        -> window.location = '#/protocoles'
        (error) -> console.log("error", error)
      )

  .controller 'ValidationsProtocoleCtrl', ($routeParams, $scope, $filter, Backend) ->
    $scope.loading = true
    $scope.inscriptions = []
    queryParams = {
#      where:
#        "protocoles": 
#          "$elemMatch":
#            "valide":
#              "ne": true
     # projection:
     #   "protocoles": 1
     #   "pseudo": 1
      embedded: { "protocoles.protocole": 1 }
    }
    Backend.all('utilisateurs').getList(queryParams).then (utilisateurs) ->
#      console.log(utilisateurs)
      utilisateurs = utilisateurs.plain()
      for utilisateur in utilisateurs
        if not utilisateur.protocoles?
          continue
        for protocole in utilisateur.protocoles
          if not protocole.protocole.valide?
            date = new Date(protocole.protocole._updated)
            $scope.inscriptions.push(
              utilisateur_id: utilisateur._id
              utilisateur_pseudo: utilisateur.pseudo
              protocole_id: protocole.protocole._id
              protocole_titre: protocole.protocole.titre
              protocole_updated: $filter('date')(date, 'EEEE dd/MM/yyyy')
            )
      $scope.loading = false

    $scope.validate = (utilisateur_id, protocole_id) ->
      Backend.one('utilisateurs', utilisateur_id).get().then (utilisateur) ->
        patch = {}
        patch.protocoles = utilisateur.protocoles
        for protocole in patch.protocoles
          if protocole.protocole == protocole_id
            protocole.valide = true
            utilisateur.patch(patch).then (
              -> console.log 'Patch OK'
              -> console.log 'Erreur patch'
            )
            return

    $scope.refuse = (utilisateur_id, protocole_id) ->
      Backend.one('utilisateurs', utilisateur_id).get().then (utilisateur) ->
        patch = {}
        patch.protocoles = utilisateur.protocoles
        for protocole, index in patch.protocoles
          if protocole.protocole == protocole_id
            patch.protocoles.splice(index, 1)
            utilisateur.patch(patch).then (
              -> console.log 'Patch OK'
              -> console.log 'Erreur patch'
            )
            return
