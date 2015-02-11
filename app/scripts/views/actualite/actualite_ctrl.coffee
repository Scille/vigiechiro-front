'use strict'


angular.module('actualiteViews', ['ngRoute', 'xin_backend', 'xin_session'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/actualites',
        templateUrl: 'scripts/views/actualite/list_actualites.html'
        controller: 'ListActualitesCtrl'

  .controller 'ListActualitesCtrl', ($scope, $q, Backend, DelayedEvent) ->
    $scope.lookup = {}
    $scope.lookup.embedded =
      sujet: 1
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    # params = $location.search()
    # if params.where?
    #   $scope.filterField = JSON.parse(params.where).$text.$search
    # else
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.where = JSON.stringify(
              $text:
                $search: filterValue
          )
        else if $scope.lookup.where?
          delete $scope.lookup.where
        # TODO : fix reloadOnSearch: true
        # $location.search('where', $scope.lookup.where)
    $scope.resourceBackend = Backend.all('actualites')
    # Wrap protocole backend to check if the user is registered (see _status_*)
    resourceBackend_getList = $scope.resourceBackend.getList
    sitesDictDefer = $q.defer()
    protocolesDictDefer = $q.defer()
    participationsDictDefer = $q.defer()
    Backend.all('sites').getList().then (sites) ->
      sitesDict = {}
      for site in sites or []
        sitesDict[site._id] = site
      sitesDictDefer.resolve(sitesDict)
    Backend.all('protocoles').getList().then (protocoles) ->
      protocolesDict = {}
      for protocole in protocoles or []
        protocolesDict[protocole._id] = protocole
      protocolesDictDefer.resolve(protocolesDict)
    Backend.all('participations').getList().then (participations) ->
      participationsDict = {}
      for participation in participations or []
        participationsDict[participation._id] = participation
      participationsDictDefer.resolve(participationsDict)

    $scope.resourceBackend.getList = (lookup) ->
      deferred = $q.defer()
      sitesDictDefer.promise.then (sitesDict) ->
        protocolesDictDefer.promise.then (protocolesDict) ->
          participationsDictDefer.promise.then (participationsDict) ->
            resourceBackend_getList(lookup).then (actualites) ->
              for actualite in actualites
                if actualite.action == "INSCRIPTION_PROTOCOLE"
                  actualite.objet = protocolesDict[actualite.objet]
                else if actualite.action == "NOUVEAU_SITE"
                  actualite.objet = sitesDict[actualite.objet]
                else if actualite.action == "NOUVELLE_PARTICIPATION"
                  actualite.objet = participationsDict[actualite.objet]
                else
                  throw "Error : unknow action "+actualite.action
              deferred.resolve(actualites)
      return deferred.promise
