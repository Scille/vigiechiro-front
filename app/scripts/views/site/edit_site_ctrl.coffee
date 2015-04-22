'use strict'

breadcrumbsGetSiteDefer = undefined


angular.module('editSiteViews', ['ngRoute', 'textAngular', 'xin_backend',
                                 'protocole_map'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/sites/:siteId/edition',
        templateUrl: 'scripts/views/site/edit_site.html'
        controller: 'EditSiteController'
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetSiteDefer = $q.defer()
          breadcrumbsGetSiteDefer.promise.then (site) ->
            breadcrumbsDefer.resolve([
              ['Sites', '#/sites']
              [site.titre, '#/sites/' + site._id]
              ['Édition', '#/sites/' + site._id + '/edition']
            ])
          return breadcrumbsDefer.promise

  .controller 'EditSiteController', ($timeout, $route, $routeParams, $scope,
                                     session, Backend, protocolesFactory) ->
    # map variables
    mapProtocole = undefined
    mapLoaded = false
    # random selection buttons and steps
    $scope.displaySteps = false
    $scope.validLocalitesAllowed = false
    $scope.editLocalitesAllowed = false
    $scope.validTracetAllowed = false
    $scope.validSegmentsAllowed = false
    $scope.editSegmentsAllowed = false
    #
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    # user select in field observateur
    $scope.observateur = {}

    # site
    Backend.one('sites', $routeParams.siteId).get().then(
      (site) ->
        if breadcrumbsGetSiteDefer?
          breadcrumbsGetSiteDefer.resolve(site)
          breadcrumbsGetSiteDefer = undefined
        $scope.site = site
        loadMap(angular.element($('.g-maps'))[0])
        $scope.observateur._id = site.observateur._id
        $scope.observateur.pseudo = site.observateur.pseudo
      (error) -> window.location = '#/404'
    )
    # users list
    $scope.users = []
    Backend.all('utilisateurs').getList().then (users) ->
      $scope.users = users.plain()
      refreshObservateur($scope.siteForm.observateur.$modelValue)

    $scope.$watch('siteForm.observateur.$modelValue', (id) -> refreshObservateur(id))

    $scope.$watch('siteForm.$pristine', (value) ->
      valid = siteValidated()
      if !value && !valid
        $scope.siteForm.$pristine = true
        $scope.siteForm.$dirty = false
        $timeout(-> $scope.$apply())
    )

    refreshObservateur = (id) ->
      if !id
        return
      for user in $scope.users or []
        if user._id == id
          $scope.observateur.pseudo = user.pseudo
          for protocole in user.protocoles or []
            if protocole.protocole._id == $scope.site.protocole._id
              if protocole.valide
                $scope.observateur.registered = true
                return
              else
                break
          $scope.observateur.registered = false
          return

    siteCallback =
      updateSteps: (steps) ->
        $scope.steps = steps.steps
        $scope.stepId = steps.step
        $scope.displaySteps = true
        if $scope.site.protocole.type_site in ['CARRE', 'POINT_FIXE']
          if $scope.stepId == 2
            $scope.validLocalitesAllowed = false
          if $scope.stepId == 3
            $scope.retrySelectionAllowed = false
            $scope.validLocalitesAllowed = true
            $scope.editLocalitesAllowed = false
          else if $scope.stepId == 4
            $scope.validLocalitesAllowed = false
            $scope.editLocalitesAllowed = true
        else if $scope.site.protocole.type_site == 'ROUTIER'
          if mapProtocole?
            $scope.tracetLength = mapProtocole.getTracetLength()
          if $scope.stepId == 2
            $scope.validSegmentsAllowed = true
          if $scope.stepId == 4
            $scope.validSegmentsAllowed = false
            $scope.editSegmentsAllowed = true
        $timeout(-> $scope.$apply())

    siteValidated = ->
      if !mapProtocole
        return
      return mapProtocole.mapValidated()

    $scope.initSiteCreation = ->
      $scope.displaySteps = true

    loadMap = (mapDiv) ->
      mapProtocole = protocolesFactory($scope.site,
                                       $scope.site.protocole.type_site,
                                       mapDiv, siteCallback)
      mapProtocole.loadMap()

    $scope.validLocalites = ->
      mapProtocole.validLocalites()
      $scope.siteForm.$pristine = false
      $scope.siteForm.$dirty = true

    $scope.editLocalites = ->
      mapProtocole.editLocalites()
      $scope.siteForm.$pristine = true
      $scope.siteForm.$dirty = false

    $scope.validTracet = ->
      if mapProtocole.validTracet()
        $scope.validTracetAllowed = false
      else
        throw "Error : tracet can not be validated"

    $scope.validSegments = ->
      if mapProtocole.validSegments()
        $scope.validSegmentsAllowed = false
        $scope.editSegmentsAllowed = true
        $scope.siteForm.$pristine = false
        $scope.siteForm.$dirty = true
      else
        throw "Error : segments can not be validated"

    $scope.editSegments = ->
      mapProtocole.editSegments()
      $scope.validSegmentsAllowed = true
      $scope.editSegmentsAllowed = false
      $scope.siteForm.$pristine = true
      $scope.siteForm.$dirty = false
      $timeout(-> $scope.$apply())

    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty)
        return
      payload =
        'observateur': $scope.observateur._id
        'commentaire': $scope.siteForm.commentaire.$modelValue
        'verrouille': $scope.site.verrouille
      $scope.site.patch(payload).then(
        (site) ->
          site.customDELETE('localites').then(
            ->
              localites = mapProtocole.saveMap()
              payload =
                localites: []
              for localite in localites
                tmp =
                  nom: localite.name
    #              coordonnee: localite.geometries.geometries[0]
                  geometries: localite.geometries
                  representatif: false
                payload.localites.push(tmp)
                site.customPUT(payload, "localites").then(
                  ->
                  (error) -> throw error
                )
              $route.reload()
            (error) -> throw "Error " + error
          )
        (error) -> throw "error " + error
      )
