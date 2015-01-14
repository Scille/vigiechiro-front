'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ShowSiteCtrl
 # @description
 # # ShowSiteCtrl
 # Controller of the vigiechiroApp
###
angular.module('viewSite', ['ngRoute', 'textAngular', 'xin_backend'])
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
  .controller 'CreateSiteCtrl', ($routeParams, $scope, Backend, GoogleMaps) ->
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
        ->
#          window.location = '#/sites'
        ->
          return
      )
  .directive 'viewSiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/view_site/view_site.html'
    controller: 'CreateSiteCtrl'
    link: (scope, elem, attrs) ->
      attrs.$observe('protocoleId', (value) ->
        if value
          scope.protocoleId = value
      )
