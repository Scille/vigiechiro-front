'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowProtocoleCtrl
 # @description
 # # ShowProtocoleCtrl
 # Controller of the vigiechiroApp
###
angular.module('inscriptionsProtocoles', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'ListInscriptionsProtocolesCtrl', ($routeParams, $scope, Backend) ->
    $scope.loading = true
    $scope.inscriptions = {}
    orig_protocole = undefined
    Backend.all('utilisateurs').getList(
      {
        where: {protocole: scope.protocoleId}
      }
    ).then (utilisateurs) ->
      $scope.utilisateurs = utilisateurs.plain()
      console.log($scope.utilisateurs)
#      Backend.one('taxons', $scope.protocole.taxon).get().then (taxon) ->
#        $scope.taxon = taxon.plain()
    $scope.loading = false
    $scope.valider = ->
    $scope.refuser = ->
