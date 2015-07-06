'use strict'


angular.module('displaySiteViews', ['ngRoute', 'ng-breadcrumbs', 'textAngular', 'xin_backend',
                                    'protocole_map'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/sites',
        templateUrl: 'scripts/views/site/list_sites.html'
        controller: 'ListSitesController'
        label: 'Sites'
      .when '/sites/mes-sites',
        templateUrl: 'scripts/views/site/list_sites.html'
        controller: 'ListMesSitesController'
        label: 'Mes Sites'
      .when '/sites/:siteId',
        templateUrl: 'scripts/views/site/display_site.html'
        controller: 'DisplaySiteController'

  .controller 'ListSitesController', ($scope, Backend, Session, DelayedEvent) ->
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


  .controller 'ListMesSitesController', ($scope, Backend, Session, DelayedEvent) ->
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


  .controller 'DisplaySiteController', ($routeParams, $scope, breadcrumbs, Backend, Session) ->
    breadcrumbs.options =
      'Libelle': $routeParams.siteId
    Backend.one('sites', $routeParams.siteId).get().then(
      (site) ->
        $scope.site = site
        $scope.typeSite = site.protocole.type_site
        user = Session.getUser()
        $scope.userId = user._id
        for protocole in user.protocoles
          if protocole.protocole._id is $scope.site.protocole._id
            if protocole.valide?
              $scope.isProtocoleValid = true
            break
      (error) -> window.location = '#/404'
    )
    $scope.isAdmin = Session.isAdmin()


  .directive 'displaySiteDirective', ($route, Session, protocolesFactory) ->
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
      scope.isAdmin = Session.isAdmin()


  .directive 'displaySitesDirective', (Session, Backend, protocolesFactory) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/display_sites_drt.html'
    scope:
      protocoleId: '@'
      typeSite: '@'
    link: (scope, elem, attrs) ->
      scope.userId = Session.getUser()._id
      attrs.$observe 'typeSite', (typeSite) ->
        if typeSite
          sitesPromise = null
          if typeSite in ["CARRE", "POINT_FIXE"]
            sitesPromise = Backend.all('protocoles/'+scope.protocoleId+'/sites').all('grille_stoc')
          else if typeSite == "ROUTIER"
            sitesPromise = Backend.all('protocoles/'+scope.protocoleId+'/sites').all('tracet')
          if sitesPromise
            sitesPromise.getList().then (sites) ->
                scope.sites = sites.plain()
                mapDiv = elem.find('.g-maps')[0]
                map = protocolesFactory(mapDiv, "ALL_"+scope.typeSite)
                map.loadMap(sites.plain())


  .directive 'listSitesDirective', (Session, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/list_sites_drt.html'
    controller: 'listSitesDrtController'
    scope:
      protocoleId: '@'
    link: (scope, elem, attrs) ->
      scope.userId = Session.getUser()._id


  .controller 'listSitesDrtController', ($scope, Backend) ->
    $scope.$watch(
      'protocoleId'
      (value) ->
        if value? and value != ''
          $scope.resourceBackend = Backend.all('protocoles/'+value+'/sites')
    )
