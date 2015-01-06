'use strict'

###*
 # @ngdoc function
 # @name xin.controller:UserStatusCtrl
 # @description
 # # UserStatusCtrl
 # Controller of the xin
###
angular.module('xin_user_status', ['restangular', 'xin_session'])
  .controller 'UserStatusCtrl', ($scope, Restangular, xin_session) ->
    update_user = ->
      user_id = xin_session.get_user_id()
      $scope.user = {}
      if user_id
        Restangular.one('users', user_id).get().then (user) ->
          $scope.user = user
    update_user()
    $scope.$on 'event:auth-loginConfirmed', ->
      update_user()
    $scope.logout = ->
      Restangular.one('logout').post().then ->
        xin_session.logout()
