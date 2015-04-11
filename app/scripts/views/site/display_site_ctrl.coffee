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
      $scope.site = site
      $scope.typeSite = site.protocole.type_site
      session.getUserPromise().then (user) ->
        $scope.userId = user._id
        for protocole in user.protocoles
          if protocole.protocole._id == $scope.site.protocole._id
            if protocole.valide?
              $scope.isProtocoleValid = true
            break
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin


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
          mapProtocole = protocolesFactory(scope.site, scope.typeSite,
                                           mapDiv)
          mapProtocole.loadMap()
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
      scope.loading = true
      session.getUserPromise().then (user) ->
        scope.userId = user._id
      attrs.$observe 'typeSite', (typeSite) ->
        if typeSite
          Backend.all('protocoles/'+scope.protocoleId+'/sites').getList().then (sites) ->
            scope.sites = sites.plain()
            mapDiv = elem.find('.g-maps')[0]
            mapProtocole = protocolesFactory(scope.sites, "ALL_"+scope.typeSite,
                                             mapDiv)
            mapProtocole.loadMap()
            scope.loading = false


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
