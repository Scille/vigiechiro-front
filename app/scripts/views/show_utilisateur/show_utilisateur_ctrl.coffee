'use strict'


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowUtilisateurCtrl
 # @description
 # # ShowUtilisateurCtrl
 # Controller of the vigiechiroApp
###
angular.module('showUtilisateur', ['ngRoute', 'xin_session', 'xin_backend'])
  .controller 'ShowUtilisateurCtrl', ($scope, $routeParams, Backend, session) ->
    $scope.utilisateur = {}
    userResource = undefined
    Backend.one('utilisateurs', $routeParams.userId).get().then (utilisateur) ->
      userResource = utilisateur
      $scope.utilisateur = utilisateur.plain()
      profile = session.getProfile()
      $scope.readOnly = (profile.role != 'Administrateur' and
                         profile._id != utilisateur._id)
    $scope.saveUser = ->
      if not userResource
        return
      modif_utilisateur = {}
      if not $scope.userForm.$dirty
        console.log("Pas de modification")
        return
      if $scope.userForm.prenom.$dirty
        modif_utilisateur.prenom = $scope.utilisateur.prenom
      if $scope.userForm.nom.$dirty
        modif_utilisateur.nom = $scope.utilisateur.nom
      if $scope.userForm.email.$dirty
        modif_utilisateur.email = $scope.utilisateur.email
      if $scope.userForm.pseudo.$dirty
        modif_utilisateur.pseudo = $scope.utilisateur.pseudo
      if $scope.userForm.telephone.$dirty
        modif_utilisateur.telephone = $scope.utilisateur.telephone
      if $scope.userForm.adresse.$dirty
        modif_utilisateur.adresse = $scope.utilisateur.adresse
      if $scope.userForm.commentaire.$dirty
        modif_utilisateur.commentaire = $scope.utilisateur.commentaire
      if $scope.userForm.organisation.$dirty
        modif_utilisateur.organisation = $scope.utilisateur.organisation
      userResource.patch(modif_utilisateur).then(
        -> $scope.userForm.$setPristine()
        ->
      )
