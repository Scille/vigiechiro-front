'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ListUtilisateursCtrl
 # @description
 # # ListUtilisateursCtrl
 # Controller of the vigiechiroApp
###
angular.module('listUtilisateurs', ['xin_backend'])
  .controller 'ListUtilisateursCtrl', ($scope, Backend) ->
    $scope.utilisateurs = []
    Backend.all('utilisateurs').getList().then (utilisateurs) ->
      $scope.utilisateurs = utilisateurs.plain()
