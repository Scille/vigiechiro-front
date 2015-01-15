'use strict'


###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowProtocoleCtrl
 # @description
 # # ShowProtocoleCtrl
 # Controller of the vigiechiroApp
###
angular.module('displayProtocole', ['ngRoute', 'textAngular', 'xin_backend', 'listSites', 'viewSite', 'xin_session'])
  .controller 'DisplayProtocoleCtrl', ($routeParams, $scope, Backend, session) ->
    $scope.protocole = {}
    $scope.inscrit = false
    orig_protocole = undefined
    Backend.one('protocoles', $routeParams.protocoleId).get().then (protocole) ->
      $scope.protocole = protocole.plain()
      if $scope.protocole._id of session.getProfile().protocoles
        $scope.inscrit = true
      Backend.one('taxons', $scope.protocole.taxon).get().then (taxon) ->
        $scope.taxon = taxon.plain()
    $scope.editProtocole = ->
      window.location = '#/protocoles/'+$routeParams.protocoleId+'/edit'
    $scope.inscription = ->
      Backend.one('utilisateurs', 'moi').get().then (user) ->
        utilisateur = { protocoles: {}}
        utilisateur.protocoles[$scope.protocole._id] = {}
        user.patch(utilisateur).then (
          ->
            console.log 'OK'
            session.refreshProfile()
            window.location.reload()
          (response) ->
            console.log("error", response)
            session.refreshProfile()
            window.location.reload()
        )
