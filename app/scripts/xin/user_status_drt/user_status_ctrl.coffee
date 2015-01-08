'use strict'

###*
 # @ngdoc function
 # @name xin.controller:UserStatusCtrl
 # @description
 # # UserStatusCtrl
 # Controller of the xin
###
angular.module('xin_user_status', ['xin_session'])
  .controller 'UserStatusCtrl', ($scope, session) ->
    $scope.user = {}
    update_user = ->
      session.get_user_status (user_status) ->
        $scope.user = user_status
    update_user()
    $scope.$on 'event:auth-loginConfirmed', ->
      update_user()
    $scope.logout = ->
      session.logout()
  .directive 'userStatus', ->
    restrict: 'E'
    controller: 'UserStatusCtrl'
    templateUrl: 'scripts/xin/user_status_drt/user_status.html'
