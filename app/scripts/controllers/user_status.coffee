'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:UserStatusCtrl
 # @description
 # # UserStatusCtrl
 # Controller of the vigiechiroApp
###
angular.module('vigiechiroApp')
  .controller 'UserStatusCtrl', ($scope, Restangular, session) ->
    update_user = ->
      user_id = session.get_user_id()
      $scope.user = {}
      if user_id
        Restangular.one('users', user_id).get().then (user) ->
          $scope.user = user
    update_user()
    $scope.$on 'event:auth-loginConfirmed', ->
      update_user()
    $scope.logout = ->
      Restangular.one('logout').post().then ->
        session.logout()
