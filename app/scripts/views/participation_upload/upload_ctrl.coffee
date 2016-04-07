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
        templateUrl: 'scripts/views/participation_upload/upload.html'
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
    $scope.participationWaiting = true

    user = null
    participationResource = null
    $scope.participation = null
    $scope.fileUploader = {}
    $scope.folderUploader = {}

    # waiting env
    waitingSession = true
    waitingParticipation = true
    waitingFileUploader = true
    waitingFolderUploader = true

    # summary
    $scope.success = []
    $scope.warning = []
    $scope.danger = []

    $scope.folderAllowed = true
    # firefox and IE don't support folder upload
    if navigator.userAgent.search("Firefox") != -1
      $scope.folderAllowed = false
    else if navigator.userAgent.search("Edge") != -1
      $scope.folderAllowed = false
    else if navigator.userAgent.search("MSIE") != -1
      $scope.folderAllowed = false

    # user for web connection fast
    session.getUserPromise().then (userPromise) ->
      user = userPromise
      waitingSession = false
      checkEnv()

    # get participation
    Backend.one("participations", $routeParams.participationId).get().then(
      (participation) ->
        $scope.participationWaiting = false

        if breadcrumbsGetParticipationDefer?
          breadcrumbsGetParticipationDefer.resolve(participation)
          breadcrumbsGetParticipationDefer = undefined

        participationResource = participation
        $scope.participation = participation.plain()

        makeRegExp($scope, participation.protocole.type_site)
        waitingParticipation = false
        checkEnv()

      (error) -> window.location = "#/404"
    )


    $scope.$watch 'fileUploader', (value) ->
      if not waitingFileUploader
        return
      if value.constructor.name == "FileUploader"
        waitingFileUploader = false
        checkEnv()

    $scope.$watch 'folderUploader', (value) ->
      if not waitingFolderUploader
        return
      if value.constructor.name == "FileUploader"
        waitingFolderUploader = false
        checkEnv()

    checkEnv = ->
      if not waitingSession and not waitingParticipation and
         not waitingFileUploader and not waitingFolderUploader
        $scope.fileUploader.lien_participation = $scope.participation._id
        $scope.fileUploader.gzip = true
        $scope.fileUploader.autostart = true
        $scope.fileUploader.connectionSpeed = user.vitesse_connexion or 0
        $scope.folderUploader.lien_participation = $scope.participation._id
        $scope.folderUploader.gzip = true
        $scope.folderUploader.autostart = true
        $scope.folderUploader.connectionSpeed = user.vitesse_connexion or 0
        addRegExpFilter($scope.fileUploader, $scope.regexp)
        addRegExpFilter($scope.folderUploader, $scope.regexp)


    addRegExpFilter = (uploader, regexp) ->
      for filter in uploader.filters when filter.name == "Format incorrect."
        return
      uploader.filters.push(
        name: "Format incorrect."
        fn: (item) ->
          if item.type in ['image/png', 'image/png', 'image/jpeg']
            return true
          for reg in regexp
            if reg.test(item.name)
              return true
          return false
      )

    $scope.backendSuccess = ->
      console.log("backendSuccess")


    $scope.backendError = ->
      console.log("backendError")


    $scope.redirect = ->
      # Check files
      if not $scope.fileUploader.isAllComplete() or
         not $scope.folderUploader.isAllComplete()
        $scope.participationForm.pieces_jointes = {$error: {uploading: true}}
        error = true
      else
        window.location = "#/participations/#{participationResource._id}"


    compute = ->
      $scope.computeInfo = {}
      participationResource.post('compute', {}).then(
        (result) -> $route.reload()
        (error) -> $scope.computeInfo.error = true
      )
