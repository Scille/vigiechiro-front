'use strict'


angular.module('actualiteViews', ['xin_backend', 'xin_session'])
#  .config ($routeProvider) ->
#    $routeProvider
#      .when '/actualites',
#        templateUrl: 'scripts/views/actualite/list_actualites.html'
#        controller: 'ListActualitesCtrl'#

#  .controller 'ListActualitesCtrl', ($scope, $q, Backend, DelayedEvent) ->
#    $scope.lookup = {}
#    # Filter field is trigger after 500ms of inactivity
#    delayedFilter = new DelayedEvent(500)
#    # params = $location.search()
#    # if params.where?
#    #   $scope.filterField = JSON.parse(params.where).$text.$search
#    # else
#    $scope.filterField = ''
#    $scope.$watch 'filterField', (filterValue) ->
#      delayedFilter.triggerEvent ->
#        if filterValue? and filterValue != ''
#          $scope.lookup.q = filterValue
#        else if $scope.lookup.q?
#          delete $scope.lookup.q
#        # TODO : fix reloadOnSearch: true
#        # $location.search('where', $scope.lookup.where)
#    $scope.resourceBackend = Backend.all('actualites')

  .directive 'listMesActualitesDirective', (Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/actualite/list_actualites_drt.html'
    scope:
      isAdmin: '@'
    link: (scope, elem, attrs) ->
      scope.loading = true
      scope.actualites = []
      Backend.all('moi/actualites').getList().then (actualites) ->
        scope.actualites = actualites.plain()
        scope.loading = false

  .directive 'displayActualiteDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/actualite/display_actualite_drt.html'
    controller: 'DisplayActualiteDirectiveCtrl'
    scope:
      actualite: '='
      isAdmin: '@'
    link: (scope, elem, attrs) ->
      attrs.$observe('isAdmin', (value) ->
        scope.isAdmin = (value == 'true')
      )


  .controller 'DisplayActualiteDirectiveCtrl', ($scope, $q, $route, Backend) ->
    if $scope.actualite.action == 'INSCRIPTION_PROTOCOLE'
      $scope.validated = false
      protocolFound = false
      for protocole in $scope.actualite.sujet.protocoles
        if protocole.protocole == $scope.actualite.protocole._id
          protocolFound = true
          if protocole.valide
            $scope.validated = true
          break
      if !protocolFound
        $scope.validated = true

    $scope.validInscription = (valid) ->
      Backend.one('protocoles', $scope.actualite.protocole._id).get()
        .then (protocole) ->
          if valid
            protocole.customPUT(null, 'observateurs/' + $scope.actualite.sujet._id)
              .then(
                -> $route.reload()
                -> throw "Error validation inscription"
              )
          else
            protocole.customDELETE('observateurs/' + $scope.actualite.sujet._id)
              .then(
                -> $route.reload()
                -> throw "Error validation inscription"
              )
