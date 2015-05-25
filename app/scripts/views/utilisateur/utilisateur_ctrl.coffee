do =>

  ### @ngInject ###
  config = ($routeProvider) =>
    $routeProvider
    .when '/profil',
      templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
      controller: ShowUtilisateurCtrl
      resolve: {$routeParams: -> return {'userId': 'moi'}}
      label: 'Profil Utilisateur'
    .when '/utilisateurs',
      templateUrl: 'scripts/views/utilisateur/list_utilisateurs.html'
      controller: ListUtilisateursCtrl
      label: 'Utilisateurs'
    .when '/utilisateurs/:userId',
      templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
      controller: ShowUtilisateurCtrl
      label: 'Pseudo'

  ### @ngInject ###
  ListUtilisateursCtrl = ($scope, Backend, DelayedEvent) =>
    $scope.lookup = {}
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('utilisateurs')

  ### @ngInject ###
  ShowUtilisateurCtrl = ($scope, $route, $routeParams, Backend, Session, breadcrumbs) =>
    $scope.submitted = false
    $scope.utilisateur = {}
    $scope.readOnly = false
    origin_role = undefined
    userBackend = undefined
    if $routeParams.userId == 'moi'
      userBackend = Backend.one('moi')
    else
      userBackend = Backend.one('utilisateurs', $routeParams.userId)
    userBackend.get().then (utilisateur) ->
      $scope.utilisateur = utilisateur.plain()
      origin_role = $scope.utilisateur.role
      breadcrumbs.options =
        'Pseudo': $scope.utilisateur.pseudo
      $scope.readOnly = (not Session.isAdmin() and Session.getUser()._id != $scope.utilisateur._id)

    $scope.saveUser = ->
      $scope.submitted = true
      if (not $scope.xinForm.$valid or not $scope.xinForm.$dirty or not $scope.utilisateur.role)
        return
      userBackend.patch($scope.utilisateur).then(
        -> $route.reload()
        (error) -> throw "Error " + error
      )

  angular.module('utilisateurViews', [])
  .config( config)
  .controller( 'Edit', ShowUtilisateurCtrl)
  .controller( 'Display', ShowUtilisateurCtrl)
  .controller( 'List', ListUtilisateursCtrl)
