'use strict'


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowUtilisateurCtrl
 # @description
 # # ShowUtilisateurCtrl
 # Controller of the vigiechiroApp
###
angular.module('utilisateurViews', ['ngRoute', 'xin_listResource', 'xin_session', 'xin_backend'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/utilisateurs',
        templateUrl: 'scripts/views/utilisateur/list_utilisateurs.html'
        controller: 'ListResourceCtrl'
        resolve: {resourceBackend: (Backend) -> Backend.all('utilisateurs')}
      .when '/utilisateurs/:userId',
        templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurCtrl'
  .controller 'ShowUtilisateurCtrl', ($scope, $routeParams, Backend, session) ->
    $scope.submitted = false
    $scope.utilisateur = {}
    $scope.readOnly = false
    $scope.isAdmin = false
    userResource = undefined
    origin_role = undefined
    Backend.one('utilisateurs', $routeParams.userId).get().then (utilisateur) ->
      userResource = utilisateur
      $scope.utilisateur = utilisateur.plain()
      origin_role = $scope.utilisateur.role
      session.getUserPromise().then (user) ->
        $scope.isAdmin = user.role == 'Administrateur'
        $scope.readOnly = (not $scope.isAdmin and
                           user._id != utilisateur._id)
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
      for field in ['professionnel', 'donnees_publiques']
        payload[field] = $scope.utilisateur[field]
      # Special handling for select
      if $scope.utilisateur.role != origin_role
        payload.role = $scope.utilisateur.role
      userResource.patch(payload).then(
        -> $scope.userForm.$setPristine()
        ->
      )
