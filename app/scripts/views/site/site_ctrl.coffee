'use strict'

breadcrumbsGetSiteDefer = undefined


angular.module('siteViews', ['ngRoute', 'textAngular', 'xin_backend', 'protocole_map'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/sites',
        templateUrl: 'scripts/views/site/list_sites.html'
        controller: 'ListSitesController'
        breadcrumbs: 'Sites'
      .when '/sites/mes-sites',
        templateUrl: 'scripts/views/site/list_sites.html'
        controller: 'ListMesSitesController'
        breadcrumbs: 'Mes Sites'
      .when '/sites/:siteId',
        templateUrl: 'scripts/views/site/display_site.html'
        controller: 'DisplaySiteController'
        breadcrumbs: ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetSiteDefer = $q.defer()
          breadcrumbsGetSiteDefer.promise.then (site) ->
            breadcrumbsDefer.resolve([
              ['Sites', '#/sites']
              [site.titre, '#/sites/' + site._id]
            ])
          return breadcrumbsDefer.promise
      .when '/sites/:siteId/edition',
        templateUrl: 'scripts/views/site/edit_site.html'
        controller: 'EditSiteController'
        breadcrumbs: ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetSiteDefer = $q.defer()
          breadcrumbsGetSiteDefer.promise.then (site) ->
            breadcrumbsDefer.resolve([
              ['Sites', '#/sites']
              [site.titre, '#/sites/' + site._id]
              ['Édition', '#/sites/' + site._id + '/edition']
            ])
          return breadcrumbsDefer.promise

  .controller 'ListSitesController', ($scope, Backend, session, DelayedEvent) ->
    $scope.title = "Tous les sites"
    $scope.swap =
      title: "Voir mes sites"
      value: "/mes-sites"
    $scope.lookup = {}
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('sites')

  .controller 'ListMesSitesController', ($scope, Backend, session, DelayedEvent) ->
    $scope.title = "Mes sites"
    $scope.swap =
      title: "Voir tous les sites"
      value: ""
    $scope.lookup = {}
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('moi/sites')

  .controller 'DisplaySiteController', ($routeParams, $scope
                                        Backend, session) ->
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      if breadcrumbsGetSiteDefer?
        breadcrumbsGetSiteDefer.resolve(site)
        breadcrumbsGetSiteDefer = undefined
      $scope.site = site.plain()
      $scope.typeSite = site.protocole.type_site
      session.getUserPromise().then (user) ->
        for protocole in user.protocoles
          if protocole.protocole._id == $scope.site.protocole._id
            if protocole.valide?
              $scope.isProtocoleValid = true
            break
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin

  .directive 'displaySiteDirective', (protocolesFactory) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/display_site_drt.html'
    scope:
      site: '='
      typeSite: '@'
      isAdmin: '@'
    link: (scope, elem, attrs) ->
      attrs.$observe 'typeSite', (typeSite) ->
        if typeSite
          mapDiv = elem.find('.g-maps')[0]
          mapProtocole = protocolesFactory(scope.site, scope.typeSite,
                                           mapDiv, false)
          mapProtocole.loadMap()

  .directive 'listSitesDirective', (session, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/list_sites_drt.html'
    scope:
      protocoleId: '@'
    link: (scope, elem, attrs) ->
      scope.loading = true
      session.getUserPromise().then (user) ->
        scope.userId = user._id
      attrs.$observe 'protocoleId', (protocoleId) ->
        if protocoleId
          Backend.all('protocoles/'+scope.protocoleId+'/sites').getList().then (sites) ->
            scope.sites = sites.plain()
            scope.loading = false

  .directive 'createSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/new_site.html'
    controller: 'CreateSiteController'
    scope:
      protocoleId: '@'
      typeSite: '@'
      userRegistered: '@'
    link: (scope, elem, attrs) ->
      scope.collapsed = true
      scope.title = 'Nouveau site'
      attrs.$observe('protocoleId', (protocoleId) ->
        scope.protocoleId = protocoleId
      )
      $(elem).on('shown.bs.collapse', ->
        scope.loadMap(elem.find('.g-maps')[0])
        return
      )
      attrs.$observe('typeSite', (value) ->
        if value
          scope.typeSite = value
          scope.initSiteCreation()
      )

  .controller 'CreateSiteController', ($timeout, $route, $scope, session,
                                       Backend, protocolesFactory) ->
    # map variables
    mapProtocole = undefined
    mapLoaded = false
    # random selection buttons and steps
    $scope.randomSelectionAllowed = false
    $scope.validOriginAllowed = false
    $scope.retrySelectionAllowed = false
    $scope.displaySteps = false
    $scope.validTracetAllowed = false
    $scope.validSegmentsAllowed = false
    # random selection
    $scope.listGrilleStocOrigin = []
    $scope.listNumberUsed = []
    #
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    # site
    $scope.site = {}
    $scope.site.titre = "Nouveau site"

    $scope.$watch('siteForm.$pristine', (value) ->
      valid = siteValidated()
      if valid
        $scope.retrySelectionAllowed = false
      if !value && !valid
        $scope.siteForm.$pristine = true
        $scope.siteForm.$dirty = false
        $timeout(-> $scope.$apply())
    )

    siteCallback =
      updateForm: ->
        $scope.siteForm.$pristine = false
        $scope.siteForm.$dirty = true
        $timeout(-> $scope.$apply())
      updateSteps: (steps) ->
        $scope.steps = steps.steps
        $scope.stepId = steps.step
        if $scope.typeSite == 'ROUTIER'
          if $scope.stepId == 2
            $scope.validSegmentsAllowed = true
        $timeout(-> $scope.$apply())

    siteValidated = ->
      if !mapProtocole
        return
      return mapProtocole.mapValidated()

    $scope.initSiteCreation = ->
      if $scope.typeSite in ['CARRE', 'POINT_FIXE']
        $scope.randomSelectionAllowed = true
      else
        $scope.validTracetAllowed = true
        $scope.displaySteps = true

    $scope.loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        mapProtocole = protocolesFactory($scope.site, $scope.typeSite,
                                         mapDiv, true, siteCallback)

    $scope.validTracet = ->
      if mapProtocole.validTracet()
        $scope.validTracetAllowed = false
      else
        throw "Error : tracet can not be validated"

    $scope.validSegments = ->
      console.log("validSegment")

    $scope.randomSelection = (random) ->
      $scope.displaySteps = true
      $scope.randomSelectionAllowed = false
      if random
        mapProtocole.createOriginPoint()
        $scope.validOriginAllowed = true
      else
        mapProtocole.selectGrilleStoc()

    $scope.validOrigin = ->
      $scope.validOriginAllowed = false
      $scope.retrySelectionAllowed = true
      origin = mapProtocole.getOrigin()
      parameters =
        lat: origin.getCenter().lat()
        lng: origin.getCenter().lng()
        r: origin.getRadius()
      Backend.all('grille_stoc/cercle').getList(parameters).then (grille_stoc) ->
        $scope.listGrilleStocOrigin = grille_stoc.plain()
        number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
        $scope.listNumberUsed.push(number)
        mapProtocole.validOrigin($scope.listGrilleStocOrigin[number])

    $scope.retrySelection = ->
      if $scope.listNumberUsed.length == $scope.listGrilleStocOrigin.length
        throw "Error: All cells picked"
        return
      mapProtocole.emptyMap()
      mapProtocole.deleteValidCell()
      number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
      while (number in $scope.listNumberUsed)
        number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
      $scope.listNumberUsed.push(number)
      mapProtocole.validOrigin($scope.listGrilleStocOrigin[number])

    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty)
        return
      payload =
        'titre': $scope.protocoleTitre
        'protocole': $scope.protocoleId
        'commentaire': $scope.siteForm.commentaire.$modelValue
      grille_stoc = mapProtocole.getIdGrilleStoc()
      if grille_stoc != ''
        payload.grille_stoc = grille_stoc
      Backend.all('sites').post(payload).then(
        (site) ->
          localites = mapProtocole.saveMap()
          for localite in localites
            payload =
              nom: localite.name
#              coordonnee: localite.geometries.geometries[0]
              geometries: localite.geometries
              representatif: false
            site.customPUT(payload, "localites").then(
              ->
              (error) -> throw error
            )
          if $scope.site.verrouille
            site.patch({'verrouille': true}).then(
              ->
              (error) -> throw error
            )
          $route.reload()
        (error) -> throw "error " + error
      )


  .controller 'EditSiteController', ($timeout, $route, $routeParams, $scope,
                                     session, Backend, protocolesFactory) ->
    # map variables
    mapProtocole = undefined
    mapLoaded = false
    # random selection buttons and steps
    $scope.randomSelectionAllowed = false
    $scope.validOriginAllowed = false
    $scope.retrySelectionAllowed = false
    $scope.displaySteps = false
    # random selection
    $scope.listGrilleStocOrigin = []
    $scope.listNumberUsed = []
    #
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    # user select in field observateur
    $scope.observateur = {}
    # site
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      if breadcrumbsGetSiteDefer?
        breadcrumbsGetSiteDefer.resolve(site)
        breadcrumbsGetSiteDefer = undefined
      $scope.site = site
      loadMap(angular.element($('.g-maps'))[0])
      $scope.observateur._id = site.observateur._id
      $scope.observateur.pseudo = site.observateur.pseudo
    # users list
    $scope.users = []
    Backend.all('utilisateurs').getList().then (users) ->
      $scope.users = users.plain()
      refreshObservateur($scope.siteForm.observateur.$modelValue)

    $scope.$watch('siteForm.observateur.$modelValue', (id) -> refreshObservateur(id))

    $scope.$watch('siteForm.$pristine', (value) ->
      valid = siteValidated()
      if valid
        $scope.retrySelectionAllowed = false
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
      updateForm: ->
        $scope.siteForm.$pristine = false
        $scope.siteForm.$dirty = true
        $timeout(-> $scope.$apply())
      updateSteps: (steps) ->
        $scope.steps = steps.steps
        $scope.stepId = steps.step
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
                                       mapDiv, true, siteCallback)
      mapProtocole.loadMap()

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
#          localites = mapProtocole.saveMap()
#          for localite in localites
#            payload =
#              nom: localite.name
##              coordonnee: localite.geometries.geometries[0]
#              geometries: localite.geometries
#              representatif: false
#            site.customPUT(payload, "localites").then(
#              ->
#              (error) -> throw error
#            )
          $route.reload()
        (error) -> throw "error " + error
      )
