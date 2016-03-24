'use strict'

breadcrumbsGetParticipationDefer = undefined


traitement_is_timeout = (participation) ->
  if not participation.traitement
    return
  now = new Date().getTime()
  timeout = 24 * 3600 * 1000
  if participation.traitement.etat == 'PLANIFIE'
    participation.traitement.timeout = (
      (now - new Date(participation.traitement.date_planification).getTime()) > timeout)
  else if participation.traitement.etat == 'EN_COURS'
    participation.traitement.timeout = (
      (now - new Date(participation.traitement.date_debut).getTime()) > timeout)
  else
    participation.traitement.timeout = false



angular.module('participationViews', ['ngRoute', 'textAngular', 'xin_listResource',
                                      'xin_backend', 'xin_session', 'xin_tools',
                                      'xin_uploadFile', 'xin.form', 'modalParticipationViews',
                                      'sc-button'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/participations',
        templateUrl: 'scripts/views/participation/list_participations.html'
        controller: 'ListParticipationsController'
        breadcrumbs: 'Participations'
      .when '/participations/mes-participations',
        templateUrl: 'scripts/views/participation/list_participations.html'
        controller: 'ListMesParticipationsController'
        breadcrumbs: 'Mes Participations'
      .when '/sites/:siteId/nouvelle-participation',
        templateUrl: 'scripts/views/participation/edit_participation.html'
        controller: 'EditParticipationController'
        breadcrumbs: ngInject ($q, $filter) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetParticipationDefer = $q.defer()
          breadcrumbsGetParticipationDefer.promise.then (site) ->
            breadcrumbsDefer.resolve([
              ["Site #{site.titre}", "#/sites/#{site._id}"]
              ["Nouvelle Participation"]
            ])
          return breadcrumbsDefer.promise
      .when '/participations/:participationId',
        templateUrl: 'scripts/views/participation/display_participation.html'
        controller: 'DisplayParticipationController'
        breadcrumbs: ngInject ($q, $filter) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetParticipationDefer = $q.defer()
          breadcrumbsGetParticipationDefer.promise.then (participation) ->
            breadcrumbsDefer.resolve([
              ['Participations', '#/participations']
              ['Participation du ' + $filter('date')(participation.date_debut, 'medium'), '#/participations/' + participation._id]
            ])
          return breadcrumbsDefer.promise
      .when '/participations/:participationId/edition',
        templateUrl: 'scripts/views/participation/edit_participation.html'
        controller: 'EditParticipationController'
        breadcrumbs: ngInject ($q, $filter) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetParticipationDefer = $q.defer()
          breadcrumbsGetParticipationDefer.promise.then (participation) ->
            breadcrumbsDefer.resolve([
              ['Participations', '#/participations']
              ['Participation du ' + $filter('date')(participation.date_debut, 'medium'), '#/participations/' + participation._id]
              ['Édition', '#/participations/' + participation._id + '/edition']
            ])
          return breadcrumbsDefer.promise


  .controller 'ListParticipationsController', ($scope, Backend, DelayedEvent, session) ->
    $scope.title = "Toutes les participations"
    $scope.swap =
      title: "Voir mes participations"
      value: "/mes-participations"
    $scope.lookup =
      sort: "-date_debut"
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('participations')


  .controller 'ListMesParticipationsController', ($scope, Backend, DelayedEvent, session) ->
    $scope.title = "Mes participations"
    $scope.swap =
      title: "Voir toutes les participations"
      value: ""
    $scope.lookup =
      sort: "-date_debut"
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('moi/participations')


  .directive 'listParticipationsDirective', (session, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/list_participations_drt.html'
    scope:
      siteId: '@'
    link: (scope, elem, attrs) ->
      scope.loading = true
      attrs.$observe 'siteId', (siteId) ->
        if siteId
          Backend.all('sites/'+siteId+'/participations').getList()
            .then (participations) ->
              scope.participations = participations.plain()
              scope.loading = false



  .controller 'DisplayParticipationController', ($scope, $route, $routeParams,
                                                 $modal, Backend, session) ->
    $scope.isCsvPost = null
    participationResource = null

    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    Backend.one('participations', $routeParams.participationId).get().then(
      (participation) ->
        if breadcrumbsGetParticipationDefer?
          breadcrumbsGetParticipationDefer.resolve(participation)
          breadcrumbsGetParticipationDefer = undefined

        participationResource = participation

        $scope.participation = participation.plain()
        traitement_is_timeout($scope.participation)
        if $scope.participation.bilan?
          if $scope.participation.bilan.chiropteres?
            $scope.participation.bilan.chiropteres.sort(sortByLibelle)
          if $scope.participation.bilan.orthopteres?
            $scope.participation.bilan.orthopteres.sort(sortByLibelle)
          if $scope.participation.bilan.autre?
            $scope.participation.bilan.autre.sort(sortByLibelle)
      (error) -> window.location = '#/404'
    )

    sortByLibelle = (a, b) ->
      taxonA = a.taxon.libelle_long
      taxonB = b.taxon.libelle_long
      return taxonA.localeCompare(taxonB)

    $scope.addPost = ->
      payload =
        message: $scope.post
      participationResource.customPUT(payload, 'messages').then(
        -> $route.reload()
        (error) -> throw error
      )

    $scope.compute = ->
      $scope.computeInfo = {}
      participationResource.post('compute', {}).then(
        (result) -> $route.reload()
        (error) -> $scope.computeInfo.error = true
      )

    $scope.delete = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/participation/modal/delete.html'
        controller: 'ModalDeleteParticipationController'
      )
      modalInstance.result.then () ->
        participationResource.remove().then(
          () -> window.location = '#/participations'
          (error) -> throw error
        )

    $scope.getDonnees = ->
      participationResource.post('csv').then(
        () -> $scope.isCsvPost = true
        (error) -> $scope.isCsvPost = false
      )



  .directive 'displayParticipationDirective', (Backend) ->
    restrict: 'E'
    controller: 'displayParticipationDrtController'
    templateUrl: 'scripts/views/participation/display_participation_drt.html'
    scope:
      participation: '='
    link: (scope, elem, attrs) ->
      # test if an object is empty
      scope.isObjectEmpty = (obj) ->
        if !obj
          return false
        length = Object.keys(obj).length
        if length
          return false
        return true


  .controller 'displayParticipationDrtController', ($scope, Backend) ->
    $scope.$watch('participation', (participation) ->
      if participation?
        # display images
        Backend.all('participations/'+$scope.participation._id+'/pieces_jointes')
          .getList({photos: true}).then (photos) ->
            $scope.photos = photos.plain()
    )
    $scope.displayWavFiles = ->
      if not $scope.wavBackend?
        $scope.wavBackend = Backend.all('participations/'+$scope.participation._id+'/pieces_jointes')
      if not $scope.wav_lookup?
        $scope.wav_lookup =
          wav: true
    $scope.displayTaFiles = ->
      if not $scope.taBackend?
        $scope.taBackend = Backend.all('participations/'+$scope.participation._id+'/pieces_jointes')
      if not $scope.ta_lookup?
        $scope.ta_lookup =
          ta: true
    $scope.displayTcFiles = ->
      if not $scope.tcBackend?
        $scope.tcBackend = Backend.all('participations/'+$scope.participation._id+'/pieces_jointes')
      if not $scope.tc_lookup?
        $scope.tc_lookup =
          tc: true



  .controller 'EditParticipationController', ($scope, $routeParams, Backend) ->
    participationResource = null
    siteResource = null
    $scope.participation = null
    $scope.site = null
    $scope.protocole = null
    # for spinner btn
    $scope.saveDone = {}

    # Nouvelle participation
    if $routeParams.siteId?
      Backend.one('sites', $routeParams.siteId).get().then(
        (site) ->
          if breadcrumbsGetParticipationDefer?
            breadcrumbsGetParticipationDefer.resolve(site)
            breadcrumbsGetParticipationDefer = undefined
          siteResource = site
          $scope.site = site.plain()
          $scope.protocole = $scope.site.protocole
          $scope.participation =
            meteo: makeMeteo()
            configuration: makeConfiguration($scope.protocole.type_site)
        (error) -> window.location = '#/404'
      )
    # Edition participation
    else if $routeParams.participationId?
      Backend.one('participations', $routeParams.participationId).get().then(
        (participation) ->
          if breadcrumbsGetParticipationDefer?
            breadcrumbsGetParticipationDefer.resolve(participation)
            breadcrumbsGetParticipationDefer = undefined
          participationResource = participation
          $scope.participation = participation.plain()
          traitement_is_timeout($scope.participation)
          $scope.participation.meteo = makeMeteo($scope.participation.meteo)
          $scope.site = $scope.participation.site
          Backend.one('protocoles', $scope.site.protocole).get().then (protocole) ->
            $scope.protocole = protocole.plain()
            $scope.participation["configuration"] = makeConfiguration(protocole.type_site, $scope.participation.configuration)
        (error) -> window.location = '#/404'
      )

    makeMeteo = (meteo = {}) ->
      meteo.temperature_debut = meteo.temperature_debut
      meteo.temperature_fin = meteo.temperature_fin
      meteo.vent = meteo.vent
      meteo.couverture = meteo.couverture
      return meteo

    makeConfiguration = (type_site, configuration = {}) ->
      configuration.detecteur_enregistreur_numero_serie = configuration.detecteur_enregistreur_numero_serie
      configuration.detecteur_enregistreur_type = configuration.detecteur_enregistreur_type
      if type_site in ['ROUTIER', 'CARRE']
        configuration.micro_numero_serie = configuration.micro_numero_serie
        configuration.micro_type = configuration.micro_type
        configuration.canal_expansion_temps = configuration.canal_expansion_temps
        configuration.canal_enregistrement_direct = configuration.canal_enregistrement_direct
      else if type_site in ['POINT_FIXE']
        configuration.micro0_position = configuration.micro0_position
        configuration.micro0_numero_serie = configuration.micro0_numero_serie
        configuration.micro0_type = configuration.micro0_type
        configuration.micro0_hauteur = configuration.micro0_hauteur
        configuration.micro1_position = configuration.micro1_position
        configuration.micro1_numero_serie = configuration.micro1_numero_serie
        configuration.micro1_type = configuration.micro1_type
        configuration.micro1_hauteur = configuration.micro1_hauteur
      return configuration


    $scope.save = ->
      $scope.participation._errors = {}
      error = false
      payload = {}
      # date début
      if $scope.participation.date_debut?
        date_debut = new Date($scope.participation.date_debut)
        payload.date_debut = date_debut.toGMTString()
      else
        error = true
        $scope.participation._errors.date_debut = "La date de début est obligatoire. "
      # date fin
      if $scope.participation.date_fin?
        date_fin = new Date($scope.participation.date_fin)
        if date_fin < date_debut
          error = true
          $scope.participation._errors.date_fin = "La date de fin ne peut pas être plus récente que celle de début."
        else
          payload.date_fin = date_fin.toGMTString()
      # commentaire
      payload.commentaire = $scope.participation.commentaire
      # météo
      payload.meteo = $scope.participation.meteo
      # configuration
      payload.configuration = $scope.participation.configuration

      # Check canal_expansion_temps with canal_enregistrement_direct
      if payload.configuration.canal_expansion_temps? and payload.configuration.canal_expansion_temps != ''
        if not payload.configuration.canal_enregistrement_direct or payload.configuration.canal_enregistrement_direct == ''
          $scope.canal_enregistrement_direct_error = true
          error = true
      else
        if payload.configuration.canal_enregistrement_direct and payload.configuration.canal_enregistrement_direct != ''
          $scope.canal_enregistrement_direct_error = true
          error = true

      if not error
        if $scope.participation._id?
          # patch participation
          participationResource.patch(payload).then(
            (participation) -> console.log("OK")
            (error) ->
              console.log("Error : participation save "+error)
              $scope.saveDone.end?()
          )
        else
          # Post new participation
          siteResource.post('participations', payload).then(
            (participation) ->
              window.location = "#/participations/#{participation._id}"
            (error) ->
              $scope.saveDone.end?()
              $scope.submitError = true
          )
      else
        $scope.saveDone.end?()



  .directive 'editParticipationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/participation/edit_participation_drt.html'
    scope:
      participation: '='
      typeSite: '='
