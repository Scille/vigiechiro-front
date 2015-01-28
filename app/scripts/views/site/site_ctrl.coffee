'use strict'

angular.module('siteViews', ['ngRoute', 'textAngular', 'xin_backend'])
  .directive 'listSitesDirective', (session, Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/list_sites.html'
    scope:
      protocoleId: '@'
      protocoleAlgoSite: '='
    link: (scope, elem, attrs) ->
      scope.loading = true
      scope.sites = []
      scope.loadSites = (lookup) ->
        Backend.all('sites').getList(lookup).then (sites) ->
          scope.sites = sites.plain()
          scope.loading = false
      attrs.$observe 'protocoleId', (protocoleId) ->
        if protocoleId
          session.getUserPromise().then (user) ->
            scope.loadSites(
              where:
                protocole: protocoleId
                observateur: user._id
            )

  .controller 'ShowSiteCtrl', ($timeout, $route, $routeParams,
    $scope, session, Backend,
    ProtocoleRoutier, ProtocoleCarre, ProtocolePointFixe) ->
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
        if $scope.protocoleAlgoSite == 'ROUTIER'
          mapProtocole = new ProtocoleRoutier($scope, mapDiv)
        else if $scope.protocoleAlgoSite == 'CARRE'
          mapProtocole = new ProtocoleCarre($scope, mapDiv)
        else if $scope.protocoleAlgoSite == 'POINT_FIXE'
          mapProtocole = new ProtocolePointFixe($scope, mapDiv)
        else
          throw "Error : unknown protocole #{$scope.protocoleAlgoSite}"
        mapProtocole.loadMap($scope.site.localites)
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty)
        return
      mapDump = mapProtocole.saveMap()
      localites = []
      for shape in mapDump
        geometries =
          geometries: [shape]
        localites.push(geometries)
      payload =
        'protocole': $scope.protocoleId
        'localites': localites
        'commentaire': $scope.siteForm.commentaire.$modelValue
      siteResource.patch(payload).then(
        -> $scope.siteForm.$setPristine()
        (error) -> console.log("error", error)
      )

  .directive 'showSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/show_site.html'
    controller: 'ShowSiteCtrl'
    scope:
      site: '='
      title: '@'
      collapsed: '@'
      protocoleAlgoSite: '='
    link: (scope, elem, attrs) ->
      # Wait for the collapse to be opened before load the google map
      if not attrs.collapsed?
        scope.loadMap(elem.find('.g-maps')[0])
      else
        $(elem).on('shown.bs.collapse', ->
          scope.numero_grille_stoc = elem.find('.numero_grille_stoc')[0]
          scope.loadMap(elem.find('.g-maps')[0])
          return
        )

  .controller 'CreateSiteCtrl', ($timeout, $route, $routeParams, $scope,
    session, Backend,
    ProtocoleRoutier, ProtocoleCarre, ProtocolePointFixe) ->
    mapProtocole = undefined
    mapLoaded = false
    $scope.submitted = false
    $scope.isAdmin = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    $scope.site = {}
    $scope.loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        if $scope.protocoleAlgoSite == 'ROUTIER'
          mapProtocole = new ProtocoleRoutier($scope, mapDiv)
        else if $scope.protocoleAlgoSite == 'CARRE'
          mapProtocole = new ProtocoleCarre($scope, mapDiv)
        else if $scope.protocoleAlgoSite == 'POINT_FIXE'
          mapProtocole = new ProtocolePointFixe($scope, mapDiv)
        else
          throw "Error : unknown protocole #{$scope.protocoleAlgoSite}"
        mapProtocole.loadMap($scope.site.localites)
    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty)
        return
      mapDump = mapProtocole.saveMap()
      localites = []
      for shape in mapDump
        geometries =
          geometries: [shape]
        localites.push(geometries)
      payload =
        'protocole': $scope.protocoleId
        'localites': localites
# TODO : use coordonnee to center the map
#        'coordonnee':
#          'type': 'Point'
#          'coordinates': [mapDump[0].lng, mapDump[0].lat]
#        'numero_grille_stoc': 
        'commentaire': $scope.siteForm.commentaire.$modelValue
      Backend.all('sites').post(payload).then(
        -> $route.reload()
        (error) -> console.log("error", error)
      )

  .directive 'createSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/site/create_site.html'
    controller: 'CreateSiteCtrl'
    link: (scope, elem, attrs) ->
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
