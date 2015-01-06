'use strict'

###
 # @ngdoc function
 # @name vigiechiroApp.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the vigiechiroApp
###
angular.module('listUtilisateurs', ['restangular'])
  .controller 'ListUtilisateursCtrl', ($scope, Restangular) ->
    $scope.utilisateurs = []
    Restangular.all('utilisateurs').getList().then (utilisateurs) ->
      $scope.utilisateurs = utilisateurs.plain()
