'use strict'

###
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowUtilisateurCtrl
 # @description
 # # MainCtrl
 # Controller of the vigiechiroApp
###
angular.module('showUtilisateur', ['xin_backend'])
  .controller 'showUtilisateurCtrl', ($scope, Backend) ->
    $scope.utilisateur = {}
    Backend.all('utilisateurs').get().then (utilisateurs) ->
      $scope.utilisateur = utilisateur
