'use strict'

breadcrumbsGetParticipationDefer = undefined


makeRegExp = ($scope, type_site) ->
  patt =
    'CARRE': /^Cir.+-\d+-Pass\d+-Tron\d+-Chiro_[01]_\d+_000\.(wav|ta|tac)$/
    'POINT_FIXE': /^Car.+-\d+-Pass\d+-([A-H][12]|Z[1-9][0-9]*)-.*[01]_\d+_\d+_\d+\.(wav|ta|tac)$/
    'ROUTIER': /^Cir.+-\d+-Pass\d+-Tron\d+-Chiro_[01]_\d+_\d{3}\.(wav|ta|tac)$/
  exemples =
    'CARRE': 'Cir270-2009-Pass1-Tron1-Chiro_0_00265_000.wav'
    'POINT_FIXE': 'Car170517-2014-Pass1-C1-OB-1_20140702_224038_761.wav'
    'ROUTIER': 'Cir270-2009-Pass1-Tron1-Chiro_0_00265_000.wav'
  $scope.regexp = [patt[type_site]]
  $scope.fileFormatExemple = exemples[type_site]



angular.module('uploadParticipationViews', ['ngRoute', 'xin_listResource',
                                            'xin_backend', 'xin_session', 'xin_tools',
                                            'xin_uploadFile'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/participations/:participationId/telechargement',
        templateUrl: 'scripts/views/upload/upload.html'
        controller: 'AddParticipationFilesController'
        breadcrumbs: ngInject ($q, $filter) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetParticipationDefer = $q.defer()
          breadcrumbsGetParticipationDefer.promise.then (participation) ->
            breadcrumbsDefer.resolve([
              ['Participations', '#/participations']
              ['Participation du ' + $filter('date')(participation.date_debut, 'medium'), '#/participations/' + participation._id]
              ['Téléchargement', '#/participations/' + participation._id + '/edition']
            ])
          return breadcrumbsDefer.promise



  .controller 'AddParticipationFilesController', ($scope, $routeParams, Backend, session) ->
    participationResource = null
    $scope.participation = null
    $scope.fileUploader = {}
    $scope.folderUploader = {}
    # for upload
    $scope.connection_fast = 0

    $scope.folderAllowed = true
    # firefox and IE don't support folder upload
    if navigator.userAgent.search("Firefox") != -1
      $scope.folderAllowed = false
    else if navigator.userAgent.search("Edge") != -1
      $scope.folderAllowed = false
    else if navigator.userAgent.search("MSIE") != -1
      $scope.folderAllowed = false

    # user for web connection fast
    session.getUserPromise().then (user) ->
      $scope.connection_fast = user.vitesse_connexion or 0
      console.log("TODO : check user right for this participation")

    # get participation
    Backend.one("participations", $routeParams.participationId).get().then(
      (participation) ->
        if breadcrumbsGetParticipationDefer?
          breadcrumbsGetParticipationDefer.resolve(participation)
          breadcrumbsGetParticipationDefer = undefined

        participationResource = participation
        $scope.participation = participation.plain()

        makeRegExp($scope, participation.protocole.type_site)

      (error) -> window.location = "#/404"
    )


    $scope.redirect = ->
      # Check files
      if not $scope.fileUploader.isAllComplete() or
         not $scope.folderUploader.isAllComplete()
        $scope.participationForm.pieces_jointes = {$error: {uploading: true}}
        error = true

      window.location = "#/participations/#{participationResource._id}"


    sendFiles = (participation) ->
      participationCreated = true
      payload =
        pieces_jointes: $scope.fileUploader.itemsCompleted.concat($scope.folderUploader.itemsCompleted)

      if not payload.pieces_jointes.length
        window.location = '#/participations/'+participationResource._id
      else
        participationResource.customPUT(payload, 'pieces_jointes').then(
          -> window.location = '#/participations/'+participationResource._id
          ->
            $scope.participation._errors.participation = "Echec de l'enregistrement des pièces jointes."
            $scope.endSave.deferred()
        )
