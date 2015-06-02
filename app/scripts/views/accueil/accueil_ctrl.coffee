do =>

  ### @ngInject ###
  config = ($routeProvider) ->
    $routeProvider
    .when '/accueil',
      templateUrl: 'scripts/views/accueil/accueil.html'
      controller: AccueilCtrl
      label: 'Accueil'

  #### @ngInject ###
  AccueilCtrl = ($scope, Datasource) ->
    columns =
      [
        field: "titre"
        title: "Titre"
        template: '<a href=\"\\#/sites/#: _id #\"> #: pseudo # </a>'
      ]
    fields =
      titre:
        type: "string"

    $scope.gridOptions =  Datasource.getGridReadOption('/sites', fields, columns)

    columns =
      [
        field: "titre"
        title: "Titre"
        template: '<a href=\"\\#/moi/sites/#: _id #\"> #: pseudo # </a>'
      ]
    fields =
      titre:
        type: "string"

    $scope.gridMesOptions =  Datasource.getGridReadOption('/moi/sites', fields, columns)

  angular.module('accueilViews', [])
  .config(config)
  .controller('AccueilCtrl', AccueilCtrl)
