'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the vigiechiroApp
###
angular.module('vigiechiroApp')
  .controller 'ListEntriesCtrl', ($scope, Restangular) ->
    $scope.entries = []
    Restangular.all('entries').getList({sort:'-_created'}).then (entries) ->
      $scope.entries = entries
