'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowUtilisateurCtrl
 # @description
 # # ShowUtilisateurCtrl
 # Controller of the vigiechiroApp
###
angular.module('showUtilisateur', ['xin_backend'])
  .controller 'ShowUtilisateurCtrl', ($stateParams, $scope, Backend) ->
    $scope.utilisateur = {}
    Backend.one('utilisateurs', $stateParams.id).get().then (utilisateur) ->
      $scope.utilisateur = utilisateur.plain()
