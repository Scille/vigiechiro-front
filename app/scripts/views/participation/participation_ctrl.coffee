'use strict'


angular.module('participationViews', ['ngRoute', 'textAngular', 'xin_listResource',
                                      'xin_backend', 'xin_session', 'siteViews'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/participations',
        templateUrl: 'scripts/views/participation/list_participations.html'
        controller: 'ListResourceCtrl'
        resolve: {resourceBackend: (Backend) -> Backend.all('participations')}
