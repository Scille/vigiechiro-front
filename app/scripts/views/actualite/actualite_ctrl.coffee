'use strict'


angular.module('actualiteViews', ['xin_backend', 'xin_session'])
#  .config ($routeProvider) ->
#    $routeProvider
#      .when '/actualites',
#        templateUrl: 'scripts/views/actualite/list_actualites.html'
#        controller: 'ListActualitesCtrl'

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
#        # $location.search('where', $scope.lookup.where)
#    $scope.resourceBackend = Backend.all('actualites')

  .directive 'listMesActualitesDirective', (Backend, session) ->
    restrict: 'E'
    templateUrl: 'scripts/views/actualite/list_actualites_drt.html'
    link: (scope, elem, attrs) ->
      scope.loading = true
      session.getIsAdminPromise().then (isAdmin) ->
        scope.isAdmin = isAdmin
      scope.actualites = []
      Backend.all('moi/actualites').getList().then (actualites) ->
        scope.actualites = actualites.plain()
        scope.loading = false

  .directive 'displayActualiteDirective', ($route, Backend, session) ->
    restrict: 'E'
    templateUrl: 'scripts/views/actualite/display_actualite_drt.html'
    scope:
      actualite: '='
      isAdmin: '='
    link: (scope, elem, attrs) ->
      session.getUserPromise().then (user) ->
        scope.user = user.plain()
      scope.validInscription = (valid) ->
        Backend.one('protocoles', scope.actualite.protocole._id).get()
          .then (protocole) ->
            if valid
              protocole.customPUT(null, 'observateurs/' + scope.actualite.sujet._id)
                .then(
                  ->
                    session.refreshPromise()
                    $route.reload()
                  -> throw "Error validation inscription"
                )
            else
              protocole.customDELETE('observateurs/' + scope.actualite.sujet._id)
                .then(
                  ->
                    session.refreshPromise()
                    $route.reload()
                  -> throw "Error validation inscription"
                )


  .directive 'listActualitesValidationsDirective', (session) ->
    restrict: 'E'
    templateUrl: 'scripts/views/actualite/list_actualites_validations.html'
    controller: 'listActualitesValidationsController'
    scope:
      type: '@'
      protocoleId: '@'
    link: (scope, elem, attrs) ->
      session.getIsAdminPromise().then (isAdmin) ->
        scope.isAdmin = isAdmin

  .controller 'listActualitesValidationsController', ($scope, $route,
                                                      Backend, session) ->
    $scope.$watch(
      'protocoleId'
      (value) ->
        if value
          payload =
            protocole: value
            type: $scope.type
          Backend.all('actualites/validations').getList(payload)
            .then (actualites) ->
              $scope.actualites = actualites.plain()
    )
    $scope.validInscription = (valid) ->
      Backend.one('protocoles', $scope.actualite.protocole._id).get()
        .then (protocole) ->
          if valid
            protocole.customPUT(null, 'observateurs/' + $scope.actualite.sujet._id)
              .then(
                ->
                  session.refreshPromise()
                  $route.reload()
                -> throw "Error validation inscription"
              )
          else
            protocole.customDELETE('observateurs/' + $scope.actualite.sujet._id)
              .then(
                ->
                  session.refreshPromise()
                  $route.reload()
                -> throw "Error validation inscription"
              )
