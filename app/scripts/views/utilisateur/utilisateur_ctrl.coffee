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
  ListUtilisateursCtrl = ($scope, Datasource) =>
    columns =
      [
        field: "pseudo"
        title: "Pseudo"
        template: '<a href=\"\\#/utilisateurs/#: _id #\"> #: pseudo # </a>'
      ,
        field: "role"
        title: "Role"
      ]
    fields =
      pseudo:
        type: "string"
      role:
        type: "string"
    $scope.gridOptions =  Datasource.getGridReadOption('/utilisateurs', fields, columns)


  ### @ngInject ###
  ShowUtilisateurCtrl = ($scope, $route, $routeParams, Backend, Session, breadcrumbs, SessionTools) =>
    $scope.utilisateur = {}
    $scope.readOnly = false
    if $routeParams.userId is 'moi'
      $scope.userBackend = Backend.one('moi')
    else
      $scope.userBackend = Backend.one('utilisateurs', $routeParams.userId)

    $scope.userBackend.get().then (utilisateur) ->
      $scope.utilisateur = utilisateur.plain()
      breadcrumbs.options =
        'Pseudo': $scope.utilisateur.pseudo
      $scope.readOnly = (not Session.isAdmin() and Session.getUser()._id isnt $scope.utilisateur._id)
      $(window).trigger('resize')

    $scope.save = =>
      payload = SessionTools.getModifiedRessource( $scope, $scope.utilisateur)
      if (payload?)
        $scope.userBackend.patch( payload).then(
          -> $route.reload()
          (error) -> throw "Error " + error
        )

  angular.module('utilisateurViews', [])
  .config( config)
  .controller( 'Edit', ShowUtilisateurCtrl)
  .controller( 'Display', ShowUtilisateurCtrl)
  .controller( 'List', ListUtilisateursCtrl)
