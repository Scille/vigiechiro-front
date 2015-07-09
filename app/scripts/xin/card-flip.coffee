app.directive "cardFlip", ->
  restrict: "C"
  link: (scope, element, attrs) ->
    element.find(".btn-flip, .card-image").on "click", ->
      element.find(".card-reveal").toggleClass "active"
