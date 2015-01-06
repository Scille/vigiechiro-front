'use strict'

###*
 # @ngdoc function
 # @name xin.controller:UserStatusCtrl
 # @description
 # # UserStatusCtrl
 # Controller of the xin
###
angular.module('xin_user_status', ['xin_backend', 'xin_session'])
  .controller 'UserStatusCtrl', ($scope, Backend, session) ->
    update_user = ->
      user_id = session.get_user_id()
      $scope.user = {}
      if user_id
        Backend.one('users', user_id).get().then (user) ->
          $scope.user = user
    update_user()
    $scope.$on 'event:auth-loginConfirmed', ->
      update_user()
    $scope.logout = ->
      Backend.one('logout').post().then ->
        session.logout()
