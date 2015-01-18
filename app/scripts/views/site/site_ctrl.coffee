'use strict'


getList = (scope, filter) ->
  scope.backend.all('sites').getList(filter).then (sites) ->
    scope.sites = sites.plain()
    scope.loading = false
    setTimeout( ->
      for key, site of scope.sites
        scope.googles_maps[key] = new scope.GoogleMaps(angular.element('#map-canvas-'+key)[0])
        scope.googles_maps[key].loadMap(site.commentaire)
    , 1000)


angular.module('siteViews', ['ngRoute', 'textAngular', 'xin_backend'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/sites',
        templateUrl: 'scripts/views/sites/list_sites.html'
        controller: 'ListSitesCtrl'
      .when '/sites/nouveau',
        templateUrl: 'scripts/views/site/show_site.html'
        controller: 'CreateSiteCtrl'
      .when '/sites/:siteId',
        templateUrl: 'scripts/views/site/show_site.html'
        controller: 'ShowSiteCtrl'

  .controller 'ListSitesCtrl', ($routeParams, $scope, Backend, GoogleMaps) ->
    $scope.backend = Backend
    $scope.loading = true
    $scope.googles_maps = []
    $scope.GoogleMaps = GoogleMaps
    getList($scope, {})

  .directive 'listSitesDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/list_sites.html'
    controller: 'ListSitesCtrl'
    link: (scope, elem, attrs) ->
      attrs.$observe('protocoleId', (value) ->
        if value
          scope.protocoleId = value
          filter = {where: {protocole: scope.protocoleId}}
          getList(scope, filter)
      )

  .controller 'ShowSiteCtrl', ($routeParams, $scope, Backend, GoogleMaps) ->
    orig_site = undefined
    google_maps = new GoogleMaps(angular.element('#map-canvas')[0])
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      orig_site = site
      $scope.site = site.plain()
      google_maps.loadMap($scope.site.commentaire)

    $scope.saveSite = ->
      if not $scope.siteForm.$valid
        return
      if not orig_site
        return
      modif_site = {}
      if not $scope.siteForm.$dirty
        return
#        if $scope.siteForm.titre.$dirty
#          modif_site.titre = $scope.site.titre
      orig_site.patch(modif_site).then(
        ->
          $scope.siteForm.$setPristine()
        ->
          return
      )

    $scope.verrouiller = ->
      orig_site.patch({ verrouille: true }).then (
        -> console.log("Verrou ok")
        -> console.log('echec verrou')
      )

  .controller 'CreateSiteCtrl', ($route, $routeParams, $scope, Backend, GoogleMaps) ->
    orig_site = undefined
    google_maps = new GoogleMaps(angular.element('#map-canvas')[0])
    Backend.one('sites', $routeParams.siteId).get().then (site) ->
      orig_site = site
      $scope.site = site.plain()
      google_maps.loadMap($scope.site.commentaire)

    $scope.saveSite = ->
      if not $scope.siteForm.$valid
        return
      site =
        'protocole': $scope.protocoleId
        'commentaire': google_maps.saveMap()
        #'commentaire': $scope.siteForm.commentaire.$modelValue
      Backend.all('sites').post(site).then(
        -> $route.reload()
        (error) -> console.log("error", error)
      )

  .directive 'createSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/show_site.html'
    controller: 'CreateSiteCtrl'
    link: (scope, elem, attrs) ->
      attrs.$observe('protocoleId', (value) ->
        if value
          scope.protocoleId = value
      )
