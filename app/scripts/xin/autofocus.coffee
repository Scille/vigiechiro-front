app.directive "autofocus", [ "$timeout", ($timeout) ->
  restrict: "A"
  link: ($scope, $element) ->
    $timeout ->
      $element[0].focus()

]
