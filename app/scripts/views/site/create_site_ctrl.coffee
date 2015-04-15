'use strict'

breadcrumbsGetProtocoleDefer = undefined


angular.module('createSiteViews', ['ngRoute', 'textAngular', 'ui.bootstrap',
                                   'dialogs.main', 'xin_backend', 'protocole_map'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/protocoles/:protocoleId/nouveau-site',
        templateUrl: 'scripts/views/site/new_site.html'
        controller: 'CreateSiteController'
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetProtocoleDefer = $q.defer()
          breadcrumbsGetProtocoleDefer.promise.then (protocole) ->
            breadcrumbsDefer.resolve([
              ['Protocoles', '#/protocoles']
              [protocole.titre, '#/protocoles/' + protocole._id]
              ['Nouveau Site', '#/protocoles/' + protocole._id + '/nouveau-site']
            ])
          return breadcrumbsDefer.promise

#  .run(($templateCache) ->
#    html = '<div class="modal-header">'+
#      '<h4 class="modal-title">Motif</h4>'+
#      '</div>'+
#      '<div class="modal-body">'+
#      '<p>Motifs précédents :</p>'+
#      '<div ng-repeat="motif in motifs">'+
#      '<div>{{motif}}</div>'+
#      '</div>'+
#      '<p class="input-group">'+
#      '<input type="text" class="form-control" ng-model="motif" is-open="opened" show-button-bar="false">'+
#      '</p>'+
#      '<p ng-show="onError">Aucun motif inscrit.</p>'+
#      '</div>'+
#      '<div class="modal-footer">'+
#      '<button class="btn btn-primary" ng-click="done(true)">Valider</button>'+
#      '<button class="btn btn-danger" ng-click="done(false)">Annuler</button>'+
#      '</div>'
#    $templateCache.put('/dialogs/custom.html', html)
#  )

#  .controller 'customDialogController', ($log, $scope, $modalInstance, data) ->
#    $scope.motifs = data
#    $scope.motif = ""
#    $scope.opened = false
#    $scope.onError = false
#    
#    $scope.$watch('data', (val, old) ->
#      $scope.opened = false
#    )#

#    $scope.done = (valid) ->
#      if not valid
#        $modalInstance.close({valid: false, motif: ''})
#      else if $scope.motif == ''
#        $scope.onError = true
#        return
#      else
#        $modalInstance.close({valid: true, motif: $scope.motif})


  .controller 'CreateSiteController', ($timeout, $route, $scope, $routeParams,
                                       session, Backend, protocolesFactory) ->
    # map variables
    mapProtocole = null
    mapLoaded = false
    # random selection buttons and steps
    $scope.displaySteps = false
    $scope.randomSelectionAllowed = false
    $scope.resetFormAllowed = false
    $scope.validOriginAllowed = false
    $scope.retrySelectionAllowed = false
    $scope.validLocalitesAllowed = false
    $scope.editLocalitesAllowed = false
    $scope.validTracetAllowed = false
    $scope.validSegmentsAllowed = false
    $scope.editSegmentsAllowed = false
    # random selection
    $scope.listGrilleStocOrigin = []
    $scope.listNumberUsed = []
    #
    $scope.submitted = false
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    # site
    $scope.site = {}
    $scope.site.titre = ""
    $scope.site.justification_non_aleatoire = ''
    $scope.justification_non_aleatoire = []

    Backend.one('protocoles', $routeParams.protocoleId).get()
      .then (protocole) ->
        if breadcrumbsGetProtocoleDefer?
          breadcrumbsGetProtocoleDefer.resolve(protocole)
          breadcrumbsGetProtocoleDefer = undefined
        $scope.protocole = protocole
        initSiteCreation()
        loadMap(angular.element('.g-maps')[0])

    $scope.$watch('siteForm.$pristine', (value) ->
      valid = siteValidated()
      if valid
        $scope.retrySelectionAllowed = false
      if !value && !valid
        $scope.siteForm.$pristine = true
        $scope.siteForm.$dirty = false
        $timeout(-> $scope.$apply())
    )

    siteCallback =
      updateSteps: (steps) ->
        $scope.steps = steps.steps
        $scope.stepId = steps.step
        if $scope.typeSite in ['CARRE', 'POINT_FIXE']
          if $scope.stepId == 0
            $scope.validLocalitesAllowed = false
          if $scope.stepId == 2
            $scope.validLocalitesAllowed = false
          if $scope.stepId == 3
            $scope.retrySelectionAllowed = false
            $scope.validLocalitesAllowed = true
            $scope.editLocalitesAllowed = false
          else if $scope.stepId == 4
            $scope.validLocalitesAllowed = false
            $scope.editLocalitesAllowed = true
        else if $scope.typeSite == 'ROUTIER'
          if mapProtocole?
            $scope.tracetLength = mapProtocole.getTracetLength()
          if $scope.stepId == 2
            $scope.validSegmentsAllowed = true
        $timeout(-> $scope.$apply())

    $scope.resetForm = ->
      if not confirm("Cette opération supprimera toute la carte.")
        return
      # clear map
      mapProtocole.clearMap()
      # random selection buttons and steps
      $scope.resetFormAllowed = false
      $scope.displaySteps = false
      if $scope.typeSite in ['CARRE', 'POINT_FIXE']
        $scope.randomSelectionAllowed = true
      $scope.validOriginAllowed = false
      $scope.retrySelectionAllowed = false
      $scope.validLocalitesAllowed = false
      $scope.editLocalitesAllowed = false
      $scope.validTracetAllowed = false
      $scope.validSegmentsAllowed = false
      $scope.editSegmentsAllowed = false
      # random selection
      $scope.listGrilleStocOrigin = []
      $scope.listNumberUsed = []

    siteValidated = ->
      if !mapProtocole
        return
      return mapProtocole.mapValidated()

    initSiteCreation = ->
      if $scope.typeSite in ['CARRE', 'POINT_FIXE']
        $scope.randomSelectionAllowed = true
      else
        $scope.validTracetAllowed = true
        $scope.displaySteps = true

    loadMap = (mapDiv) ->
      if not mapLoaded
        mapLoaded = true
        mapProtocole = protocolesFactory($scope.site, $scope.protocole.type_site,
                                         mapDiv, siteCallback)
        if $scope.typeSite in ['CARRE', 'POINT_FIXE']
          Backend.all('protocoles/'+$scope.protocoleId+'/sites').getList().then (sites) ->
            mapProtocole.displaySites(sites.plain())

    $scope.validLocalites = ->
      mapProtocole.validLocalites()
      $scope.siteForm.$pristine = false
      $scope.siteForm.$dirty = true

    $scope.editLocalites = ->
      mapProtocole.editLocalites()
      $scope.siteForm.$pristine = true
      $scope.siteForm.$dirty = false

    $scope.validTracet = ->
      if mapProtocole.validTracet()
        $scope.validTracetAllowed = false
      else
        throw "Error : tracet can not be validated"

    $scope.validSegments = ->
      if mapProtocole.validSegments()
        $scope.validSegmentsAllowed = false
        $scope.editSegmentsAllowed = true
        $scope.siteForm.$pristine = false
        $scope.siteForm.$dirty = true
      else
        throw "Error : segments can not be validated"

    $scope.editSegments = ->
      mapProtocole.editSegments()
      $scope.validSegmentsAllowed = true
      $scope.editSegmentsAllowed = false
      $scope.siteForm.$pristine = true
      $scope.siteForm.$dirty = false
      $timeout(-> $scope.$apply())

    $scope.randomSelection = (random) ->
      $scope.resetFormAllowed = true
      $scope.displaySteps = true
      $scope.randomSelectionAllowed = false
      if random
        mapProtocole.createOriginPoint()
        $scope.validOriginAllowed = true
      else
        mapProtocole.selectGrilleStoc()

    $scope.validOrigin = ->
      $scope.validOriginAllowed = false
      $scope.retrySelectionAllowed = true
      origin = mapProtocole.getOrigin()
      parameters =
        lat: origin.getCenter().lat()
        lng: origin.getCenter().lng()
        r: origin.getRadius()
      Backend.all('grille_stoc/cercle').getList(parameters).then (grille_stoc) ->
        $scope.listGrilleStocOrigin = grille_stoc.plain()
        number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
        $scope.listNumberUsed.push(number)
        mapProtocole.validOrigin($scope.listGrilleStocOrigin[number])

    $scope.retrySelection = ->
      dlg = dialogs.create('/dialogs/custom.html', 'customDialogController',
                           $scope.justification_non_aleatoire)
      dlg.result.then (data) ->
        if not data.valid
          return
        else
          # no more cell to pick
          if $scope.listNumberUsed.length == $scope.listGrilleStocOrigin.length
            throw "Error: All cells picked"
          # add motif
          grille_stoc = $scope.listGrilleStocOrigin[$scope.listNumberUsed[$scope.listNumberUsed.length-1]]
          $scope.justification_non_aleatoire.push(grille_stoc.numero+' : '+data.motif)
          # empty map
          mapProtocole.emptyMap()
          mapProtocole.deleteValidCell()
          number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
          while (number in $scope.listNumberUsed)
            number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
          $scope.listNumberUsed.push(number)
          mapProtocole.validOrigin($scope.listGrilleStocOrigin[number])

    $scope.saveSite = ->
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty)
        return
      payload =
        'titre': $scope.protocoleTitre
        'protocole': $scope.protocoleId
        'commentaire': $scope.siteForm.commentaire.$modelValue
      if $scope.site.justification_non_aleatoire != ''
        payload.justification_non_aleatoire = $scope.site.justification_non_aleatoire
      if $scope.typeSite == 'POINT_FIXE' || $scope.typeSite == 'CARRE'
        grille_stoc = mapProtocole.getIdGrilleStoc()
        if grille_stoc != ''
          payload.grille_stoc = grille_stoc
      Backend.all('sites').post(payload).then(
        (site) ->
          localites = mapProtocole.saveMap()
          payload =
            localites: []
          for localite in localites
            tmp =
              nom: localite.name
#              coordonnee: localite.geometries.geometries[0]
              geometries: localite.geometries
              representatif: false
            payload.localites.push(tmp)
          site.customPUT(payload, "localites").then(
            ->
            (error) -> throw error
          )
          if $scope.site.verrouille
            site.patch({'verrouille': true}).then(
              ->
              (error) -> throw error
            )
          $route.reload()
        (error) -> throw "error " + error
      )
