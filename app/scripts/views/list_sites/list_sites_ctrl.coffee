'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ListSitesCtrl
 # @description
 # # ListSitesCtrl
 # Controller of the vigiechiroApp
###
angular.module('listSites', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'ListSitesCtrl', ($routeParams, $scope, Backend, GoogleMaps) ->
    $scope.loading = true
    params = {}
    googles_maps = []
    Backend.all('sites', params).getList().then (sites) ->
      $scope.sites = sites.plain()
      $scope.loading = false
      setTimeout( ->
        for key, site of $scope.sites
          console.log('key: '+key)
          console.log(site)
          console.log(angular.element('#map-canvas-'+key)[0])
          googles_maps[key] = new GoogleMaps(angular.element('#map-canvas-'+key)[0])
          googles_maps[key].loadMap(site.commentaire)
      , 1000)
  .directive 'listSitesDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/list_sites/list_sites.html'
    controller: 'ListSitesCtrl'
    link: (scope, elem, attrs) ->
      attrs.$observe('protocoleId', (value) ->
        if value
          scope.protocoleId = value
      )
