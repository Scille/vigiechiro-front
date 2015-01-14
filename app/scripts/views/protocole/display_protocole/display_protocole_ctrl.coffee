'use strict'


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowProtocoleCtrl
 # @description
 # # ShowProtocoleCtrl
 # Controller of the vigiechiroApp
###
angular.module('displayProtocole', ['ngRoute', 'textAngular', 'xin_backend', 'listSites', 'viewSite'])
  .controller 'DisplayProtocoleCtrl', ($routeParams, $scope, Backend) ->
    $scope.protocole = {}
    orig_protocole = undefined
    Backend.one('protocoles', $routeParams.protocoleId).get().then (protocole) ->
      $scope.protocole = protocole.plain()
      Backend.one('taxons', $scope.protocole.taxon).get().then (taxon) ->
        $scope.taxon = taxon.plain()
    $scope.editProtocole = ->
      window.location = '#/protocoles/'+$routeParams.protocoleId+'/edit'
