'use strict'

guid = ->
  s4 = ->
    Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
  s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()


angular.module('xin.form', ['ui.bootstrap.datetimepicker', 'angularMoment'])
  .directive 'dateTextInputDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/form/date_text_input.html'
    controller: 'DateTextInputController'
    scope:
      label: '=?'
      model: '=?'
      error: '=?'
    link: (scope, elem, attrs) ->
      scope.today = false
      if attrs.today?
        scope.today = true

  .controller 'DateTextInputController', ($scope) ->
    $scope.date_id = guid()
    $scope.textDate = ""
    $scope.originTextDate = ""
    firstChange = false

    $scope.$watch 'model', (value) ->
      $scope.textDate = ''
      date = null
      if value? and value != ""
        date = moment(value)
      else if $scope.today and not firstChange
        date = moment()
        $scope.model = date._d
      else
        firstChange = true
        return
      $scope.textDate = date.format('DD/MM/YYYY HH:mm')
      if not firstChange
        firstChange = true
        $scope.originTextDate = $scope.textDate

    $scope.handleInputDate = ->
      $scope.error = ""
      if $scope.textDate? and $scope.textDate != ""
        testDate = moment($scope.textDate, "DD/MM/YYYY HH:mm", true)
        if testDate.isValid()
          $scope.model = testDate._d
        else
          $scope.error = $scope.textDate + " n'est pas une date valide (jj/mm/aaaa hh:mm)."
      else
        $scope.model = null

    $scope.$watch 'error', (value) ->
      if Array.isArray(value)
        error_text = ""
        for errorString in value
          if errorString.indexOf("Could not deserialize") > -1
            error_text += "Date invalide "
          else
            error_text += errorString
        $scope.error = error_text
    , true


  # <span ng-show="submitted && participationForm.date_fin.$error.$invalid"
  #       class="help-block has-error">
  #   Date invalide
  # </span>
