'use strict'


angular.module('donneeViews', ['xin_backend', 'ui.bootstrap'])

  .directive 'listDonneesDirective', (Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/donnee/list_donnees.html'
    scope:
      participationId: '@'
    link: (scope, elem, attrs) ->
      attrs.$observe 'participationId', (participationId) ->
        if participationId? && participationId != ''
          Backend.all('participations/'+participationId+'/donnees').getList().then (donnees) ->
            scope.donnees = donnees

  .directive 'displayDonneeDirective', ($route, $modal, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/donnee/display_donnee_drt.html'
    scope:
      donnee: '='
    link: (scope, elem, attrs) ->
      scope.addPost = (observation_id) ->
        console.log("Add new Post")
        payload =
          message: scope.post
        scope.donnee.customPUT(payload,
                               'observations/'+observation_id+'/messages')
          .then(
            -> $route.reload()
            (error) -> throw error
          )
      scope.editDonnee = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/views/donnee/edit_donnee.html'
          controller: 'ModalInstanceController'
          resolve:
            donnee: ->
              return scope.donnee
        )

  .controller 'ModalInstanceController', ($scope, $modalInstance, donnee) ->
    $scope.donnee = donnee
    $scope.done = (done) ->
      if !done
        $modalInstance.dismiss("cancel")
