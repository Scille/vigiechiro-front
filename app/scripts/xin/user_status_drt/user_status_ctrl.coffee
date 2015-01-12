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
    $scope.user = session.getProfile()
    $scope.$on 'event:auth-loginConfirmed', ->
      $scope.user = session.getProfile()
    $scope.logout = ->
      session.logout()
  .directive 'userStatus', ->
    restrict: 'E'
    controller: 'UserStatusCtrl'
    templateUrl: 'scripts/xin/user_status_drt/user_status.html'
