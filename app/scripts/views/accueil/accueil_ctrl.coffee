do =>

  ### @ngInject ###
  config = ($routeProvider) ->
    $routeProvider
    .when '/accueil',
      templateUrl: 'scripts/views/accueil/accueil.html'
      controller: AccueilCtrl
      label: 'Accueil'

  #### @ngInject ###
  AccueilCtrl = ($scope, Backend) ->
    Backend.all('moi/sites').getList().then (sites) ->
      $scope.userSites = sites.plain()


  angular.module('accueilViews', [])
  .config(config)
  .controller('AccueilCtrl', AccueilCtrl)
