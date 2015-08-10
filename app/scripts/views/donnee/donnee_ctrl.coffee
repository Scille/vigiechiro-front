'use strict'

breadcrumbsGetParticipationDefer = undefined


angular.module('donneeViews', ['ngRoute', 'xin_backend', 'xin_session',
                               'xin_tools',
                               'ui.bootstrap'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/participations/:participationId/donnees',
        templateUrl: 'scripts/views/donnee/list_donnees.html'
        controller: 'ListDonneesController'
        breadcrumbs: ngInject ($q, $filter) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetParticipationDefer = $q.defer()
          breadcrumbsGetParticipationDefer.promise.then (participation) ->
            breadcrumbsDefer.resolve([
              ['Participations', '#/participations']
              ['Participation du ' + $filter('date')(participation.date_debut, 'medium'), '#/participations/' + participation._id]
              ['Données', '#/participations/' + participation._id + '/donnees']
            ])
          return breadcrumbsDefer.promise


  .controller 'ListDonneesController', ($scope, $routeParams, $timeout, Backend, session) ->
    $scope.participation = {}
    $scope.others =
      isObservateur: false
      isValidateur: false
      taxons: []
    # Get participation données
    Backend.one('participations', $routeParams.participationId).get()
      .then(
        (participation) ->
          $scope.participation = participation.plain()
          if breadcrumbsGetParticipationDefer?
            breadcrumbsGetParticipationDefer.resolve(participation)
            breadcrumbsGetParticipationDefer = undefined
          $scope.lookup = {}
          $scope.resourceBackend = Backend.all('participations/'+$routeParams.participationId+'/donnees')
          session.getUserPromise().then (user) ->
            if participation.observateur._id == user._id
              $scope.others.isObservateur = true
            if user.role in ['Validateur', 'Administrateur']
              $scope.others.isValidateur = true
        (error) -> window.location = '#404'
      )
    # Get taxons list
    Backend.all('taxons/liste').getList().then (taxons) ->
      $scope.others.taxons = taxons.plain()


  .directive 'displayDonneeDirective', ($route, $modal, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/donnee/display_donnee_drt.html'
    scope:
      donnee: '='
      isObservateur: '='
      isValidateur: '='
      taxons: '='
    link: (scope, elem, attrs) ->
      scope.addPost = (index, post) ->
        payload =
          message: post
        scope.post = ''
        Backend.one('donnees', scope.donnee._id).get().then (donnee) ->
          donnee.customPUT(payload, 'observations/'+index+'/messages')
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
        modalInstance.result.then (payload) ->
          Backend.one('donnees', scope.donnee._id).get().then (donnee) ->
            donnee.patch(payload).then(
              -> $route.reload()
              (error) -> throw error
            )

      scope.patchValidateur = (key) ->
        payload =
          validateur_taxon: scope.donnee.observations[key].validateur_taxon
          validateur_probabilite: scope.donnee.observations[key].validateur_probabilite
        Backend.all('donnees/'+scope.donnee._id+'/observations/'+key).patch(payload).then(
          (success) -> $route.reload()
          (error) -> scope.patchError = true
        )
      scope.patchObservateur = (key) ->
        payload =
          observateur_taxon: scope.donnee.observations[key].observateur_taxon
          observateur_probabilite: scope.donnee.observations[key].observateur_probabilite
        Backend.all('donnees/'+scope.donnee._id+'/observations/'+key).patch(payload).then(
          (success) -> $route.reload()
          (error) -> scope.patchError = true
        )

      scope.CopyToClipboard = (text) ->
        textToClipboard = text
        success = true
        # If IE
        if (window.clipboardData)
          window.clipboardData.setData("Text", textToClipboard)
        # Else create a temporary element for the execCommand method
        else
          forExecElement = CreateElementForExecCommand(textToClipboard)
          # Select the contents of the element
          # (the execCommand for 'copy' method works on the selection)
          SelectContent(forExecElement)
          supported = true
          # UniversalXPConnect privilege is required for clipboard access
          # in Firefox
          try
            if (window.netscape and netscape.security)
              netscape.security.PrivilegeManager.enablePrivilege ("UniversalXPConnect");

            # Copy the selected content to the clipboard
            # Works in Firefox and in Safari before version 5
            success = document.execCommand("copy", false, null)
          catch e
            success = false
          # remove the temporary element
          document.body.removeChild(forExecElement)
        if success
          scope.copySuccess = true
        else
          window.prompt("Copier vers le presse-papiers: Ctrl+C, Entrer", text)

      CreateElementForExecCommand = (textToClipboard) ->
        forExecElement = document.createElement("div")
        # place outside the visible area
        forExecElement.style.position = "absolute"
        forExecElement.style.left = "-10000px"
        forExecElement.style.top = "-10000px"
        # write the necessary text into the element and append to the document
        forExecElement.textContent = textToClipboard
        document.body.appendChild(forExecElement)
        # the contentEditable mode is necessary for the execCommand method
        # in Firefox
        forExecElement.contentEditable = true
        return forExecElement

      SelectContent = (element) ->
        # first create a range
        rangeToSelect = document.createRange()
        rangeToSelect.selectNodeContents(element)

        # select the contents
        selection = window.getSelection()
        selection.removeAllRanges()
        selection.addRange(rangeToSelect)


  .controller 'ModalInstanceController', ($scope, $modalInstance, donnee) ->
    $scope.donnee = donnee
    $scope.done = (done) ->
      if !done
        $modalInstance.dismiss("cancel")
      else
        $modalInstance.close(
          commentaire: $scope.donnee.commentaire
          probleme: $scope.donnee.probleme
        )
