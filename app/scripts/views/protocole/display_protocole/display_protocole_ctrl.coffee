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
      Backend.one('utilisateurs', 'moi').get().then (user) ->
        if user.protocoles
          for protocole in user.protocoles
            if protocole.protocole == $scope.protocole._id
              $scope.inscrit = true
              break
      Backend.one('taxons', $scope.protocole.taxon).get().then (taxon) ->
        $scope.taxon = taxon.plain()
    $scope.editProtocole = ->
      window.location = '#/protocoles/'+$routeParams.protocoleId+'/edit'
    $scope.inscription = ->
      Backend.one('protocoles', $scope.protocole._id+"/action/join").post().then (
        ->
          console.log 'OK'
          window.location.reload()
        (response) ->
          console.log("error", response)
          window.location.reload()
      )
