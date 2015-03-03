'use strict'


angular.module('siteViews', ['ngRoute', 'textAngular', 'xin_backend', 'protocole_map'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/sites',
        templateUrl: 'scripts/views/site/list_sites.html'
        controller: 'ListSitesCtrl'
      .when '/sites/mes-sites',
        templateUrl: 'scripts/views/site/list_sites.html'
        controller: 'ListMesSitesCtrl'
      .when '/sites/:siteId',
        templateUrl: 'scripts/views/site/display_site.html'
        controller: 'DisplaySiteCtrl'

  .controller 'ListSitesCtrl', ($scope, Backend, session, DelayedEvent) ->
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

  .controller 'ListMesSitesCtrl', ($scope, Backend, session, DelayedEvent) ->
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

  .controller 'DisplaySiteCtrl', ($routeParams, $scope
                                  Backend, session) ->
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      $scope.site = site.plain()
      $scope.protocoleAlgoSite = $scope.site.protocole.algo_tirage_site
      session.getUserPromise().then (user) ->
        for protocole in user.protocoles
          if protocole.protocole._id == $scope.site.protocole._id
            if protocole.valide?
              $scope.isProtocoleValid = true
            break
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin

  .directive 'displaySiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/display_site_drt.html'
    controller: 'DisplaySiteDirectiveCtrl'
    scope:
      site: '='
      protocoleAlgoSite: '@'
      isAdmin: '@'
    link: (scope, elem, attrs) ->
      attrs.$observe 'protocoleAlgoSite', (protocoleAlgoSite) ->
        if protocoleAlgoSite
          scope.loadMap(elem.find('.g-maps')[0])

  .controller 'DisplaySiteDirectiveCtrl', ($scope, Backend, protocolesFactory) ->
    $scope.loadMap = (mapDiv) ->
      mapProtocole = protocolesFactory($scope.site, $scope.protocoleAlgoSite,
                                       mapDiv, false)
      mapProtocole.loadMap()

  .directive 'listSitesDirective', (session, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/list_sites_drt.html'
    scope:
      protocoleId: '@'
      protocoleAlgoSite: '@'
    link: (scope, elem, attrs) ->
      scope.loading = true
      scope.sites = []
      scope.loadSites = ->
        Backend.all('protocoles/'+scope.protocoleId+'/sites').getList().then (sites) ->
          scope.sites = sites.plain()
          scope.loading = false
      attrs.$observe 'protocoleId', (protocoleId) ->
        if protocoleId
          session.getUserPromise().then (user) ->
            scope.userId = user._id
            scope.loadSites()

  .directive 'showSiteDirective', ($timeout) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/show_site.html'
    controller: 'ShowSiteCtrl'
    scope:
      site: '='
      collapsed: '@'
      protocoleAlgoSite: '@'
      userId: '@'
    link: (scope, elem, attrs) ->
      scope.openCollapse = (id) ->
        $timeout(-> scope.loadMap(elem.find('.g-maps')[0]))
      # Wait for the collapse to be opened before load the google map
#      if not attrs.collapsed?
        # Use $timeout to load google map at the end of the stack
        # to prevent display issues
#        $timeout(-> scope.loadMap(elem.find('.g-maps')[0]))
#      else
#        $(elem).on('shown.bs.collapse', ->
#          scope.numero_grille_stoc = elem.find('.numero_grille_stoc')[0]
#          scope.loadMap(elem.find('.g-maps')[0])
#          return
#        )

  .controller 'ShowSiteCtrl', ($timeout, $route, $routeParams, $scope
                               session, Backend, protocolesFactory) ->
    mapProtocole = undefined
    siteResource = undefined
    mapLoaded = false
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    Backend.one('sites', $scope.site._id).get().then (site) ->
      siteResource = site
    $scope.loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        mapProtocole = protocolesFactory($scope.site, $scope.protocoleAlgoSite,
                                         mapDiv, !$scope.site.verrouille,
                                         siteCallback)
        mapProtocole.loadMap()

    siteCallback =
      updateForm: ->
        $scope.siteForm.$pristine = false
        $scope.siteForm.$dirty = true
        $timeout(-> $scope.$apply())
      updateSteps: (steps) ->
        $scope.steps = steps.steps
        $scope.stepId = steps.step
        $timeout(-> $scope.$apply())
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty)
        return
      payload =
#        'localites': mapProtocole.saveMap()
        'commentaire': $scope.siteForm.commentaire.$modelValue
      if $scope.isAdmin
        payload.verrouille = $scope.site.verrouille
      siteResource.patch(payload).then(
        -> $scope.siteForm.$setPristine()
        (error) -> console.log("error", error)
      )

  .directive 'createSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/show_site.html'
    controller: 'CreateSiteCtrl'
    scope:
      protocoleId: '@'
      protocoleAlgoSite: '@'
    link: (scope, elem, attrs) ->
      scope.collapsed = true
      scope.title = 'Nouveau site'
      attrs.$observe('protocoleId', (protocoleId) ->
        scope.protocoleId = protocoleId
      )
      $(elem).on('shown.bs.collapse', ->
        scope.numero_grille_stoc = elem.find('.numero_grille_stoc')[0]
        scope.loadMap(elem.find('.g-maps')[0])
        return
      )
      attrs.$observe('protocoleAlgoSite', (value) ->
        if value
          scope.protocoleAlgoSite = value
      )

  .controller 'CreateSiteCtrl', ($timeout, $route, $routeParams, $scope,
                                 session, Backend, protocolesFactory) ->
    mapProtocole = undefined
    mapLoaded = false
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    $scope.site = {}
    $scope.site.titre = "Nouveau site"
    $scope.listGrilleStocOrigin = []
    $scope.listNumberUsed = []

    siteCallback =
      updateForm: ->
        $scope.siteForm.$pristine = false
        $scope.siteForm.$dirty = true
        $timeout(-> $scope.$apply())
      updateSteps: (steps) ->
        $scope.steps = steps.steps
        $scope.stepId = steps.step
        $timeout(-> $scope.$apply())

    $scope.loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        randomSelection = false
        if $scope.protocoleAlgoSite == 'CARRE' or
           $scope.protocoleAlgoSite == 'POINT_FIXE'
          if confirm("Voulez-vous un tirage aléatoire ?")
            randomSelection = true

        mapProtocole = protocolesFactory($scope.site, $scope.protocoleAlgoSite,
                                         mapDiv, true, siteCallback)
        if randomSelection
          mapProtocole.createOriginPoint()
        else if $scope.protocoleAlgoSite == 'CARRE' or
                $scope.protocoleAlgoSite == 'POINT_FIXE'
          mapProtocole.selectGrilleStoc()

    $scope.validOrigin = ->
      parameters =
        lat: mapProtocole.getOrigin().getPosition().lat()
        lng: mapProtocole.getOrigin().getPosition().lng()
        r: 10000
      Backend.all('grille_stoc/cercle').getList(parameters).then (grille_stoc) ->
        $scope.listGrilleStocOrigin = grille_stoc.plain()
        number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
        $scope.listNumberUsed.push(number)
        mapProtocole.validOrigin($scope.listGrilleStocOrigin[number])

    $scope.newSelection = ->
      if $scope.listNumberUsed.length == $scope.listGrilleStocOrigin.length
        throw "Error: All cells picked"
        return
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
              -> console.log("ok")
              (error) -> throw "Error : "+error
            )
          $route.reload()
        (error) -> throw "error " + error
      )
