'use strict'

breadcrumbsGetParticipationDefer = undefined


makeRegExp = ($scope, type_site) ->
  patt =
    'CARRE': /^Cir.+-\d+-Pass\d+-Tron\d+-Chiro_[01]_\d+_\d{3}\.(wav|ta|tac)$/
    'POINT_FIXE': /^Car.+-\d+-Pass\d+-([A-H][12]|Z[1-9][0-9]*)-.*[01]_\d+_\d+_\d+\.(wav|ta|tac)$/
    'ROUTIER': /^Cir.+-\d+-Pass\d+-Tron\d+-Chiro_[01]_\d+_\d{3}\.(wav|ta|tac)$/
  exemples =
    'CARRE': 'Cir270-2009-Pass1-Tron1-Chiro_0_00265_000.wav'
    'POINT_FIXE': 'Car170517-2014-Pass1-C1-OB-1_20140702_224038_761.wav'
    'ROUTIER': 'Cir270-2009-Pass1-Tron1-Chiro_0_00265_000.wav'
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



  .controller 'AddParticipationFilesController', ($scope, $routeParams, $timeout,
                                                  Backend, session) ->
    participationResource = null
    $scope.participation = null
    # $scope.connectionSpeed = 2

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

    # $scope.$watch 'connectionSpeed', (value) ->
    #   if value? and value >= 2 and value <= 20
    #     $scope.fileUploader.connectionSpeed = value
    #     $scope.folderUploader.connectionSpeed = value

    $scope.refresh = ->
      $timeout(->
        $scope.$apply()
      )

    $scope.compute = ->
      participationResource.post('compute', {}).then(
        (result) -> window.location = "#/participations/#{participationResource._id}"
        (error) -> window.location = "#/participations/#{participationResource._id}"
      )
