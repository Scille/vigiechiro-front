'use strict'

breadcrumbsGetSiteDefer = undefined


angular.module('displaySiteViews', ['ngRoute', 'textAngular', 'xin_backend',
                                    'protocole_map'])
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
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetSiteDefer = $q.defer()
          breadcrumbsGetSiteDefer.promise.then (site) ->
            breadcrumbsDefer.resolve([
              ['Sites', '#/sites']
              [site.titre, '#/sites/' + site._id]
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


  .controller 'DisplaySiteController', ($routeParams, $scope, $modal,
                                        Backend, session) ->
    Backend.one('sites', $routeParams.siteId).get().then(
      (site) ->
        if breadcrumbsGetSiteDefer?
          breadcrumbsGetSiteDefer.resolve(site)
          breadcrumbsGetSiteDefer = undefined
        $scope.site = site
        $scope.typeSite = site.protocole.type_site
        session.getUserPromise().then (user) ->
          $scope.userId = user._id
          for protocole in user.protocoles or []
            if protocole.protocole._id == $scope.site.protocole._id
              if protocole.valide?
                $scope.isProtocoleValid = true
              break
      (error) -> window.location = '#/404'
    )

    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin

    $scope.delete = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/site/modal/delete.html'
        controller: 'ModalDeleteSiteController'
        resolve:
          site: ->
            return $scope.site
      )
      modalInstance.result.then () ->
        $scope.site.remove().then(
          () -> window.location = '#/sites'
          (error) -> throw error
        )



  .directive 'displaySiteDirective', ($route, session, protocolesFactory) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/display_site_drt.html'
    scope:
      site: '='
      typeSite: '@'
    link: (scope, elem, attrs) ->
      attrs.$observe 'typeSite', (typeSite) ->
        if typeSite
          mapDiv = elem.find('.g-maps')[0]
          map = protocolesFactory(mapDiv, scope.typeSite)
          map.loadMapDisplay(scope.site.plain())
      scope.lockSite = (lock) ->
        scope.site.patch({'verrouille': lock}).then(
          ->
          (error) -> throw error
        )
        $route.reload()
      session.getIsAdminPromise().then (isAdmin) ->
        scope.isAdmin = isAdmin


  .directive 'displaySitesDirective', (session, Backend, protocolesFactory) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/display_sites_drt.html'
    scope:
      protocoleId: '@'
      typeSite: '@'
    link: (scope, elem, attrs) ->
      session.getUserPromise().then (user) ->
        scope.userId = user._id
      attrs.$observe 'typeSite', (typeSite) ->
        if typeSite?
          makeRequest()
      attrs.$observe 'protocoleId', (protocoleId) ->
        if protocoleId?
          makeRequest()
      makeRequest = ->
        if scope.typeSite == '' or scope.protocoleId == ''
          return
        sitesPromise = null
        if scope.typeSite in ["CARRE", "POINT_FIXE"]
          sitesPromise = Backend.all('protocoles/'+scope.protocoleId+'/sites').all('grille_stoc')
        else if scope.typeSite == "ROUTIER"
          sitesPromise = Backend.all('protocoles/'+scope.protocoleId+'/sites').all('tracet')
        if sitesPromise
          sitesPromise.getList().then (sites) ->
              scope.sites = sites.plain()
              mapDiv = elem.find('.g-maps')[0]
              map = protocolesFactory(mapDiv, "ALL_"+scope.typeSite)
              map.loadMap(sites.plain())



  .directive 'listSitesDirective', (session, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/list_sites_drt.html'
    scope:
      protocoleId: '@'
    link: (scope, elem, attrs) ->
      session.getUserPromise().then (user) ->
        scope.userId = user._id

      scope.$watch('protocoleId', (value) ->
        if value != ''
          scope.resourceBackend = Backend.all('protocoles/'+value+'/sites')
      )
