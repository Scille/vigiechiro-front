'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ListSitesCtrl
 # @description
 # # ListSitesCtrl
 # Controller of the vigiechiroApp
###
angular.module('listSites', ['ngRoute', 'textAngular', 'xin_backend'])
  .controller 'ListSitesCtrl', ($routeParams, $scope, Backend) ->
    $scope.loading = true
    params = {}
    Backend.all('sites', params).getList().then (sites) ->
      $scope.sites = sites.plain()
      $scope.loading = false
  .directive 'listSitesDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/list_sites/list_sites.html'
    controller: 'ListSitesCtrl'
