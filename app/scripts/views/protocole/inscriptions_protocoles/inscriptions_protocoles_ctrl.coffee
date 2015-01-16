'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowProtocoleCtrl
 # @description
 # # ShowProtocoleCtrl
 # Controller of the vigiechiroApp
###
angular.module('inscriptionsProtocoles', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'ListInscriptionsProtocolesCtrl', ($routeParams, $scope, $filter, Backend) ->
    $scope.loading = true
    $scope.inscriptions = []
    orig_protocole = undefined
    Backend.all('utilisateurs').getList().then (utilisateurs) ->
      utilisateurs = utilisateurs.plain()
      for utilisateur in utilisateurs
        if not utilisateur.protocoles?
          continue
        for protocole in utilisateur.protocoles
          if not protocole.valide?
            Backend.one('protocoles', protocole.protocole).get().then (protocole) ->
              protocole = protocole.plain()
              date = new Date(protocole._updated)
              $scope.inscriptions.push(
                utilisateur_id: utilisateur._id
                utilisateur_pseudo: utilisateur.pseudo
                protocole_id: protocole.protocole
                protocole_titre: protocole.titre
                protocole_updated: $filter('date')(date, 'EEEE dd/MM/yyyy')
              )
      $scope.loading = false

    $scope.valider = (utilisateur_id, protocole_id) ->
      Backend.one('utilisateurs', utilisateur_id).get().then (utilisateur) ->
        patch = {}
        patch.protocoles = utilisateur.protocoles
        for protocole in patch.protocoles
          if protocole.protocole == protocole_id
            protocole.valide = true
            utilisateur.patch(patch).then (
              -> console.log 'Patch OK'
              -> console.log 'Erreur patch'
            )
            return

    $scope.refuser = (utilisateur_id, protocole_id) ->
      Backend.one('utilisateurs', utilisateur_id).get().then (utilisateur) ->
        patch = {}
        patch.protocoles = utilisateur.protocoles
        for index, protocole in patch.protocoles
          if protocole.protocole == protocole_id
            patch.protocoles.splice(index, 1)
            utilisateur.patch(patch).then (
              -> console.log 'Patch OK'
              -> console.log 'Erreur patch'
            )
            return
