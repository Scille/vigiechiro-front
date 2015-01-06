'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the vigiechiroApp
###
angular.module('vigiechiroApp')
  .controller 'ListEntriesCtrl', ($scope, Backend) ->
    $scope.entries = []
    Backend.all('entries').getList({sort:'-_created'}).then (entries) ->
      $scope.entries = entries
