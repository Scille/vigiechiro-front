'use strict'

breadcrumbsGetSiteDefer = undefined

map = null

initEnv = ($scope, $modal, session) ->
  $scope.saveDone = {}
  $scope.resetFormAllowed = false
  # site
  $scope.site =
    titre: "Nouveau site"
  $scope.displaySteps = false
  # when grille stoc
  $scope.randomSelectionAllowed = false
  $scope.validOriginAllowed = false
  $scope.retrySelectionAllowed = false
  $scope.isRandom = false
  # random selection
  $scope.listGrilleStocOrigin = []
  $scope.listNumberUsed = []
  # tracé
  $scope.validTraceAllowed = false
  $scope.validSegmentsAllowed = false
  $scope.editSegmentsAllowed = false
  $scope.routeLength = 0
  # all
  $scope.validLocalitesAllowed = false
  $scope.editLocalitesAllowed = false
  $scope.mapWarnings = []
  # form
  $scope.isAdmin = false
  session.getIsAdminPromise().then (isAdmin) ->
    $scope.isAdmin = isAdmin

  $scope.validLocalities = ->
    map.validLocalities()
  $scope.editLocalities = ->
    map.editLocalities()
  $scope.validRoute = ->
    map.validRoute()
    map.validBounds()
  $scope.editRoute = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/views/site/modal/edit_route.html'
      controller: 'ModalInstanceEditRouteController'
    )
    modalInstance.result.then(
      (valid) ->
        if valid
          map.editRoute()
    )
  $scope.extendRouteTo = 'END'
  $scope.$watch 'extendRouteTo', (value) ->
    if value? and map?
      map.extendRouteTo = value
  $scope.validSections = ->
    map.validSections()
  $scope.editSections = ->
    map.editSections()
  $scope.strikeStep = (index, stepId, steps) ->
    for i in [0..index]
      if stepId == steps[i].id
        return false
    return true

siteCallbacks = ($scope, $timeout) ->
  return {
    displayError: (error) ->
      $scope.mapError =
        message: error
      $timeout(-> $scope.$apply())
    displayWarning: (warning, type = '') ->
      exist = false
      newWarning =
        message: warning
        type: type
      for warning in $scope.mapWarnings
        if warning.message == newWarning.message
          exist = true
          break
      if not exist
        $scope.mapWarnings.push(newWarning)
      $timeout(-> $scope.$apply())
    hideWarning: (type) ->
      for i in [$scope.mapWarnings.length-1..0] when $scope.mapWarnings.length > 0
        if $scope.mapWarnings[i].type == type
          $scope.mapWarnings.splice(i, 1)
      $timeout(-> $scope.$apply())
    updateSteps: (steps, isOpportuniste) ->
      $scope.mapError = null
      $scope.steps = steps.steps
      $scope.stepId = steps.step
      if $scope.protocole.type_site in ['CARRE', 'POINT_FIXE']
        if $scope.stepId == 'start'
          $scope.validLocalitiesAllowed = false
        if $scope.stepId == 'editLocalities'
          if isOpportuniste or not $scope.isRandom
            $scope.retrySelectionAllowed = false
          else
            $scope.retrySelectionAllowed = true
          $scope.editLocalitiesAllowed = false
          $scope.validLocalitiesAllowed = false
        if $scope.stepId == 'validLocalities'
          $scope.retrySelectionAllowed = false
          $scope.validLocalitiesAllowed = true
          $scope.editLocalitiesAllowed = false
        else if $scope.stepId == 'end'
          $scope.validLocalitiesAllowed = false
          $scope.editLocalitiesAllowed = true
      else if $scope.protocole.type_site == 'ROUTIER'
        if $scope.stepId == 'start'
          if map.hasRoute()
            $scope.validRouteAllowed = true
          else
            $scope.validRouteAllowed = false
          $scope.editRouteAllowed = false
          $scope.validSectionsAllowed = false
          $scope.editSectionsAllowed = false
        if $scope.stepId == 'selectOrigin'
          $scope.validRouteAllowed = false
          $scope.editRouteAllowed = true
        if $scope.stepId == 'editSections'
          $scope.validSectionsAllowed = true
          $scope.editSectionsAllowed = false
        if $scope.stepId == 'end'
          $scope.validSectionsAllowed = false
          $scope.editSectionsAllowed = true
      $timeout(-> $scope.$apply())
    updateLength: (length) ->
      $scope.routeLength = length
      $timeout(-> $scope.$apply())
  }

saveLocalities = (site, callbacks = {}) ->
  if map.isOpportuniste()
    localities = map.saveMap()
    payload =
      localites: []
    for localite in localities
      tmp =
        nom: localite.name
        geometries: localite.geometries
        representatif: false
      payload.localites.push(tmp)
    site.customPUT(payload, "localites").then(
      -> callbacks.onSaveLocalitiesSuccess?()
      (error) -> callbacks.onSaveLocalitiesFail?(error)
    )
  else
    site.customDELETE('localites').then(
      ->
        localities = map.saveMap()
        payload =
          localites: []
        for localite in localities
          tmp =
            nom: localite.name
            geometries: localite.geometries
            representatif: false
          payload.localites.push(tmp)
        site.customPUT(payload, "localites").then(
          -> callbacks.onSaveLocalitiesSuccess?()
          (error) -> callbacks.onSaveLocalitiesFail?(error)
        )
      (error) -> console.log(error)
    )

lock = (site, callbacks = {}) ->
  site.patch({'verrouille': true}).then(
    -> callbacks.onLockSuccess?()
    (error) -> console.log(error)
  )



angular.module('siteViews', ['ngRoute',
                             'textAngular', 'ui.bootstrap',
                             'protocole_map', 'modalSiteViews',
                             'frapontillo.bootstrap-switch'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/protocoles/:protocoleId/nouveau-site',
        templateUrl: 'scripts/views/site/edit_site.html'
        controller: 'CreateSiteController'
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetSiteDefer = $q.defer()
          breadcrumbsGetSiteDefer.promise.then (protocole) ->
            breadcrumbsDefer.resolve([
              ['Protocoles', '#/protocoles']
              [protocole.titre, '#/protocoles/' + protocole._id]
              ['Nouveau Site', '#/protocoles/' + protocole._id + '/nouveau-site']
            ])
          return breadcrumbsDefer.promise
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


  .controller 'CreateSiteController', ($timeout, $route, $scope, $routeParams,
                                       $modal,
                                       session, Backend, protocolesFactory) ->
    initEnv($scope, $modal, session)
    $scope.creation = true
    # map variables
    sites = []
    justification_non_aleatoire = []

    Backend.one('protocoles', $routeParams.protocoleId).get().then(
      (protocole) ->
        if breadcrumbsGetSiteDefer?
          breadcrumbsGetSiteDefer.resolve(protocole)
          breadcrumbsGetSiteDefer = undefined
        $scope.protocole = protocole.plain()
        initSiteCreation()
        createMap(angular.element('.g-maps')[0])
      (error) -> window.location = '#/404'
    )

    initSiteCreation = ->
      if $scope.protocole.type_site in ['CARRE', 'POINT_FIXE']
        $scope.site.generee_aleatoirement = false
        $scope.randomSelectionAllowed = true
      else
        $scope.displaySteps = true

    createMap = (mapDiv) ->
      map = protocolesFactory(mapDiv, $scope.protocole.type_site,
                              siteCallbacks($scope, $timeout))
      map.updateSite()
      # If CARRE or POINT_FIXE, display all sites already followed
      if $scope.protocole.type_site in ['CARRE', 'POINT_FIXE']
        Backend.all('protocoles/'+$scope.protocole._id+'/sites').all('grille_stoc')
          .getList().then (sitesResult) ->
            sites = sitesResult.plain()
            map.displaySites(sites)

    $scope.resetForm = ->
      if not confirm("Cette opération supprimera toute la carte.")
        return
      # clear map
      map.clear()
      # random selection buttons and steps
      $scope.resetFormAllowed = false
      $scope.displaySteps = false
      if $scope.protocole.type_site in ['CARRE', 'POINT_FIXE']
        $scope.randomSelectionAllowed = true
      $scope.validOriginAllowed = false
      $scope.retrySelectionAllowed = false
      $scope.validLocalitiesAllowed = false
      $scope.editLocalitiesAllowed = false
      $scope.validRouteAllowed = false
      $scope.editRouteAllowed = false
      $scope.validSectionsAllowed = false
      $scope.editSectionsAllowed = false
      # random selection
      $scope.listGrilleStocOrigin = []
      $scope.listNumberUsed = []

    # grille stoc
    $scope.randomSelection = (random) ->
      $scope.resetFormAllowed = true
      $scope.displaySteps = true
      $scope.randomSelectionAllowed = false
      if random
        $scope.isRandom = true
        map.createOriginPoint()
        $scope.validOriginAllowed = true
      else
        $scope.isRandom = false
        map.selectGrilleStoc()

    $scope.validOrigin = ->
      $scope.validOriginAllowed = false
      $scope.retrySelectionAllowed = true
      origin = map.getOrigin()
      parameters =
        lat: origin.getCenter().lat()
        lng: origin.getCenter().lng()
        r: origin.getRadius()
      Backend.all('grille_stoc/cercle').getList(parameters).then (grille_stoc) ->
        $scope.listGrilleStocOrigin = grille_stoc.plain()
        Backend.all('protocoles/'+$scope.protocole._id+'/sites').all('grille_stoc')
          .getList().then (grille_stoc) ->
            if $scope.listGrilleStocOrigin and sites
              for index in [$scope.listGrilleStocOrigin.length-1..0]
                for site in sites or []
                  cell = $scope.listGrilleStocOrigin[index]
                  if cell.numero == site.grille_stoc.numero
                    $scope.listGrilleStocOrigin.splice(index, 1)
                    break
            firstSelection()

    firstSelection = ->
      number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
      $scope.listNumberUsed.push(number)
      map.validOrigin($scope.listGrilleStocOrigin[number])

    $scope.retrySelection = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/site/modal/retry_selection.html'
        controller: 'ModalInstanceRetrySelectionController'
        resolve:
          justification_non_aleatoire: ->
            return justification_non_aleatoire
      )
      modalInstance.result.then(
        (motif) ->
          if motif and motif != ''
            # no more cell to pick
            if $scope.listNumberUsed.length == $scope.listGrilleStocOrigin.length
              $scope.randomSelectionAllowed = false
              $scope.mapError =
                message: "Plus de grille_stoc disponible."
              $timeout(-> $scope.$apply())
              return
            # add motif
            grille_stoc = $scope.listGrilleStocOrigin[$scope.listNumberUsed[$scope.listNumberUsed.length-1]]
            justification_non_aleatoire.push(grille_stoc.numero+' : '+motif)
            # empty map
            map.emptyMap()
            map.deleteGrilleStoc()
            number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
            while (number in $scope.listNumberUsed)
              number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
            $scope.listNumberUsed.push(number)
            map.validOrigin($scope.listGrilleStocOrigin[number])
      )

    $scope.save = ->
      if not map.isValid()
        $scope.saveDone.end?()
        return
      payload =
        'titre': undefined
        'protocole': $scope.protocole._id
        'commentaire': $scope.site.commentaire
      # If random grille stoc
      if justification_non_aleatoire.length > 0
        payload.generee_aleatoirement = true
        payload.justification_non_aleatoire = ''
        for justification in justification_non_aleatoire
          payload.justification_non_aleatoire += justification+'\n'
      callback_factory = (site) ->
        onSaveLocalitiesSuccess: ->
          window.location = '#/sites/'+site._id
        onSaveLocalitiesFail: ->
          $scope.saveLocalitiesError = true
          $scope.saveDone.end?()
      # If grille stoc
      if $scope.protocole.type_site in ['POINT_FIXE', 'CARRE']
        payload.grille_stoc = map.getIdGrilleStoc()
        check =
          protocole: $scope.protocole._id
          grille_stoc: map.getIdGrilleStoc()
        Backend.all('sites').getList(check).then (sites) ->
          if sites.plain().length
            saveLocalities(sites[0], callback_factory(sites[0]))
          else
            # Set up title
            numGrilleStoc = map.getNumGrilleStoc()
            sixDigitGrilleStoc = '000000'.substring(0, 6-numGrilleStoc.length) + numGrilleStoc
            payload.titre = $scope.protocole.titre+"-"+sixDigitGrilleStoc
            # POST site
            Backend.all('sites').post(payload).then(
              (site) ->
                # If verrouille
                if $scope.site.verrouille
                  lock(site)
                saveLocalities(site, callback_factory(site))
              (error) -> throw error
            )
      # If tracé
      else if $scope.protocole.type_site == 'ROUTIER'
        payload.tracet = map.getGeoJsonRoute()
        if $scope.site.numeroSite? and $scope.site.numeroSite in [0..599]
          payload.titre = $scope.protocole.titre+"-"+$scope.site.numeroSite
          # Check if site doesn't exist
          Backend.all('sites').getList({protocole: $routeParams.protocoleId})
            .then (sites) ->
              exist = false
              for site in sites.plain() or []
                if site.titre == payload.titre
                  exist = true
                  break
              if exist
                $scope.numeroError = true
              else
                saveSiteRoutier(payload, callback_factory)
        else
          saveSiteRoutier(payload, callback_factory)

    saveSiteRoutier = (payload, callback_factory) ->
      Backend.all('sites').post(payload).then(
        (site) ->
          saveLocalities(site, callback_factory(site))
        (error) ->
          $scope.saveDone.end?()
          throw error
      )



  .controller 'EditSiteController', ($timeout, $route, $routeParams, $scope, $modal,
                                     session, Backend, protocolesFactory) ->
    initEnv($scope, $modal, session)
    $scope.creation = false
    $scope.site_orig = {}
    site = null

    $scope.users = []
    Backend.all('utilisateurs').getList().then (users) ->
      $scope.users = users.plain()

    Backend.one('sites', $routeParams.siteId).get().then(
      (siteResult) ->
        site = siteResult
        $scope.site = site.plain()
        if breadcrumbsGetSiteDefer?
          breadcrumbsGetSiteDefer.resolve($scope.site)
          breadcrumbsGetSiteDefer = undefined

        angular.copy($scope.site, $scope.site_orig)

        $scope.protocole = site.protocole
        initSiteCreation()
        loadMap(angular.element($('.g-maps'))[0])
      (error) -> window.location = '#/404'
    )

    initSiteCreation = ->
      $scope.displaySteps = true

    loadMap = (mapDiv) ->
      map = protocolesFactory(mapDiv,
                              $scope.site.protocole.type_site,
                              siteCallbacks($scope, $timeout))
      map.loadMapEdit($scope.site)

    $scope.save = ->
      if not map.isValid()
        $scope.saveDone.end?()
        return
      payload =
        'commentaire': $scope.site.commentaire
        'verrouille': $scope.site.verrouille
      if $scope.site.titre != $scope.site_orig.titre
        payload.titre = $scope.site.titre
      if $scope.protocole.type_site == 'ROUTIER'
        payload.tracet = map.getGeoJsonRoute()
      if $scope.isAdmin
        payload.observateur = $scope.site.observateur._id
      site.patch(payload).then(
        (site) ->
          callbacks =
            onSaveLocalitiesSuccess: ->
              window.location = '#/sites/'+site._id
            onSaveLocalitiesFail: ->
              $scope.saveLocalitiesError = true
              $scope.saveDone.end?()
          saveLocalities(site, callbacks)
        (error) ->
          $scope.mapError =
            message: error
          $scope.saveDone.end?()
      )
