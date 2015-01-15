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

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ListSitesCtrl
 # @description
 # # ListSitesCtrl
 # Controller of the vigiechiroApp
###
angular.module('listSites', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'ListSitesCtrl', ($routeParams, $scope, Backend, GoogleMaps) ->
    $scope.backend = Backend
    $scope.loading = true
    $scope.googles_maps = []
    $scope.GoogleMaps = GoogleMaps
    getList($scope, {})

  .directive 'listSitesDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/list_sites/list_sites.html'
    controller: 'ListSitesCtrl'
    link: (scope, elem, attrs) ->
      attrs.$observe('protocoleId', (value) ->
        if value
          scope.protocoleId = value
          filter = {where: {protocole: scope.protocoleId}}
          getList(scope, filter)
      )
