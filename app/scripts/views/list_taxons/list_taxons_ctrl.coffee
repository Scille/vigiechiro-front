'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:ListTaxonsCtrl
 # @description
 # # ListTaxonsCtrl
 # Controller of the vigiechiroApp
###
angular.module('listTaxons', ['xin_backend'])
  .controller 'ListTaxonsCtrl', ($scope, Backend) ->
    $scope.taxons = []
    $scope.loading = true
    Backend.all('taxons').getList().then (taxons) ->
      $scope.taxons = taxons.plain()
      $scope.loading = false
