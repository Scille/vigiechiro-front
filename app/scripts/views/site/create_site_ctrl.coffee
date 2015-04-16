'use strict'

breadcrumbsGetProtocoleDefer = undefined


angular.module('createSiteViews', ['textAngular', 'ui.bootstrap',
                                   'dialogs.main',
                                   'protocole_map', 'modalSiteViews'])
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
                                       $modal,
                                       session, Backend, protocolesFactory) ->
    # map variables
    mapProtocole = null
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
    $scope.justification_non_aleatoire = []

    Backend.one('protocoles', $routeParams.protocoleId).get()
      .then (protocole) ->
        if breadcrumbsGetProtocoleDefer?
          breadcrumbsGetProtocoleDefer.resolve(protocole)
          breadcrumbsGetProtocoleDefer = undefined
        $scope.protocole = protocole
        initSiteCreation()
        createMap(angular.element('.g-maps')[0])

    initSiteCreation = ->
      if $scope.protocole.type_site in ['CARRE', 'POINT_FIXE']
        $scope.site.generee_aleatoirement = false
        $scope.randomSelectionAllowed = true
      else
        $scope.validTracetAllowed = true
        $scope.displaySteps = true

    createMap = (mapDiv) ->
      mapProtocole = protocolesFactory(mapDiv, $scope.protocole.type_site,
                                       siteCallback)
      if $scope.protocole.type_site in ['CARRE', 'POINT_FIXE']
        Backend.all('protocoles/'+$scope.protocole._id+'/sites').getList().then (sites) ->
          mapProtocole.displaySites(sites.plain())

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
      displayError: (error) ->
        $scope.mapError =
          message: error
      updateSteps: (steps) ->
        $scope.mapError = undefined
        $scope.steps = steps.steps
        $scope.stepId = steps.step
        if $scope.protocole.type_site in ['CARRE', 'POINT_FIXE']
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
        else if $scope.protocole.type_site == 'ROUTIER'
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
      if $scope.protocole.type_site in ['CARRE', 'POINT_FIXE']
        $scope.randomSelectionAllowed = true
      $scope.validOriginAllowed = false
      $scope.retrySelectionAllowed = false
      $scope.validLocalitesAllowed = false
      $scope.editLocalitesAllowed = false
      $scope.validTracetAllowed = false
      $scope.editTracetAllowed = false
      $scope.validSegmentsAllowed = false
      $scope.editSegmentsAllowed = false
      # random selection
      $scope.listGrilleStocOrigin = []
      $scope.listNumberUsed = []

    siteValidated = ->
      if !mapProtocole
        return false
      return mapProtocole.mapValidated()

    $scope.validLocalites = ->
      mapProtocole.validLocalites()
      $scope.siteForm.$pristine = false
      $scope.siteForm.$dirty = true

    $scope.editLocalites = ->
      mapProtocole.editLocalites()
      $scope.siteForm.$pristine = true
      $scope.siteForm.$dirty = false

    # Tracet
    $scope.validTracet = ->
      if mapProtocole.validTracet()
        $scope.validTracetAllowed = false
        $scope.editTracetAllowed = true
        $scope.siteForm.$pristine = false
        $scope.siteForm.$dirty = true
    $scope.editTracet = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/site/modal/edit_tracet.html'
        controller: 'ModalInstanceEditTracetController'
      )
      modalInstance.result.then(
        (valid) ->
          if valid
            if mapProtocole.editTracet()
              $scope.validTracetAllowed = true
              $scope.editTracetAllowed = false
              $scope.validSegmentsAllowed = false
      )

    # Troncons
    $scope.validSegments = ->
      if mapProtocole.validSegments()
        $scope.validSegmentsAllowed = false
        $scope.editSegmentsAllowed = true
        $scope.siteForm.$pristine = false
        $scope.siteForm.$dirty = true

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
#      dlg = dialogs.create('/dialogs/custom.html', 'customDialogController',
#                           $scope.justification_non_aleatoire)
#      dlg.result.then (data) ->
#        if not data.valid
#          return
#        else
#          # no more cell to pick
#          if $scope.listNumberUsed.length == $scope.listGrilleStocOrigin.length
#            throw "Error: All cells picked"
#          # add motif
#          grille_stoc = $scope.listGrilleStocOrigin[$scope.listNumberUsed[$scope.listNumberUsed.length-1]]
#          $scope.justification_non_aleatoire.push(grille_stoc.numero+' : '+data.motif)
#          # empty map
#          mapProtocole.emptyMap()
#          mapProtocole.deleteValidCell()
#          number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
#          while (number in $scope.listNumberUsed)
#            number = Math.floor(Math.random() * $scope.listGrilleStocOrigin.length)
#          $scope.listNumberUsed.push(number)
#          mapProtocole.validOrigin($scope.listGrilleStocOrigin[number])

    $scope.saveSite = ->
      # Form
      $scope.submitted = true
      if (not $scope.siteForm.$valid or
          not $scope.siteForm.$dirty)
        return
      # Common payload
      payload =
        'titre': $scope.protocoleTitre
        'protocole': $scope.protocole._id
        'commentaire': $scope.siteForm.commentaire.$modelValue
      # If random grille stoc
      if $scope.justification_non_aleatoire.length > 0
        payload.generee_aleatoirement = true
        payload.justification_non_aleatoire = ''
        for justification in $scope.justification_non_aleatoire
          payload.justification_non_aleatoire += justification+'\n'
      # If grille stoc
      if $scope.protocole.type_site in ['POINT_FIXE', 'CARRE']
        payload.grille_stoc = mapProtocole.getIdGrilleStoc()
      # If tracet
      if $scope.protocole.type_site == 'ROUTIER'
        payload.tracet = mapProtocole.getGeoJsonTrace()
      Backend.all('sites').post(payload).then(
        (site) ->
          localites = mapProtocole.saveMap()
          # If localites to save
          if localites.length
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
          # If verrouille
          if $scope.site.verrouille
            site.patch({'verrouille': true}).then(
              ->
              (error) -> throw error
            )
          # redirect to display site
          window.location = '#/sites/'+site._id
        (error) -> throw "error " + error
      )
