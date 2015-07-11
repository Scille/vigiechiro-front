do =>
  ### @ngInject ###
  xinActions = (Session, PubSub) =>
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/action_drt/action.html'
    link: (scope) ->
      scope.hrefValue = window.location.href + "/nouveau"
      scope.isSelected = false
      PubSub.subscribe 'grid', (select) =>
        scope.$apply =>
          scope.isSelected = select.length > 0 and Session.isAdmin()
      scope.createItem = =>
        window.location = scope.hrefValue
      scope.deleteItem = =>
        # pas implemente
        t = 1



  xinSubmit = ->
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/action_drt/submit.html'

  xinUpdate = ->
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/action_drt/update.html'
    link: (scope) ->
      scope.hrefValue = window.location.href + "/edition"
      scope.updateItem = =>
        window.location = scope.hrefValue

  xinRegister = ->
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/action_drt/register.html'


  angular.module('xin_action', [])
  .directive('xinActions', xinActions)
  .directive('xinSubmit', xinSubmit)
  .directive('xinUpdate', xinUpdate)
  .directive('xinRegister', xinRegister)
