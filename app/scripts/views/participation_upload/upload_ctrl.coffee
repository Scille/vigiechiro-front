'use strict'

breadcrumbsGetParticipationDefer = undefined


makeRegExp = ($scope, type_site) ->
  patt =
    'CARRE': /^Cir.+-\d{4}-Pass\d{1,2}-Tron\d{1,2}-Chiro_([01]_)?\d+_\d{3}\.(wav|ta|tac)(.zip)?$/
    'POINT_FIXE': /^Car.+-\d{4}-Pass\d{1,2}-([A-H][12]|Z[1-9][0-9]*)-.*_\d{8}_\d{6}_\d{3}\.(wav|ta|tac)(.zip)?$/
    'ROUTIER': /^Cir.+-\d{4}-Pass\d{1,2}-Tron\d{1,2}-Chiro_([01]_)?\d+_\d{3}\.(wav|ta|tac)(.zip)?$/
  exemples =
    'CARRE': 'Cir270-2009-Pass1-Tron1-Chiro_0_00265_000.wav, batch-01.wav.zip'
    'POINT_FIXE': 'Car170517-2014-Pass1-C1-OB-1_20140702_224038_761.wav, batch-01.wav.zip'
    'ROUTIER': 'Cir270-2009-Pass1-Tron1-Chiro_0_00265_000.wav, batch-01.wav.zip'
  $scope.regexp = patt[type_site]
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


  .controller 'AddParticipationFilesController', ($scope, $routeParams, Backend,
                                                  session) ->
    participationResource = null
    $scope.participation = null
    $scope.participationId = $routeParams.participationId

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

      (error) -> window.location = "#/404"
    )

    $scope.computeDone = {}
    $scope.compute = ->
      $scope.computeInfo = {}
      participationResource.post('compute', {}).then(
        (result) -> window.location = "#/participations/#{participationResource._id}"
        (error) ->
          $scope.computeInfo.error = true
          $scope.computeDone.end?()
      )
