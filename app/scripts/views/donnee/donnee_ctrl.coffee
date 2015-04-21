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


  .controller 'ListDonneesController', ($scope, $routeParams, Backend) ->
    $scope.participation = {}
    $scope.donnees = []
    Backend.one('participations', $routeParams.participationId).get()
      .then (participation) ->
        $scope.participation = participation.plain()
        if breadcrumbsGetParticipationDefer?
          breadcrumbsGetParticipationDefer.resolve(participation)
          breadcrumbsGetParticipationDefer = undefined
    Backend.all('participations/'+$routeParams.participationId+'/donnees')
      .getList().then (donnees) ->
        $scope.donnees = donnees.plain()


  .directive 'displayDonneeDirective', ($route, $modal, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/donnee/display_donnee_drt.html'
    scope:
      donnee: '='
    link: (scope, elem, attrs) ->
      scope.addPost = (index, post) ->
        payload =
          message: post
        scope.post = ''
        Backend.one('donnees', scope.donnee._id).get().then (donnee) ->
          donnee.customPUT(payload,
                           'observations/'+index+'/messages')
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

        if (!success)
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
