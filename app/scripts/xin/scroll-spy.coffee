app.directive "scrollSpy", [ "$window", ($window) ->
  link: (scope, element, attrs) ->
    angular.element($window).bind "scroll", ->
      scope.scroll = @pageYOffset
      scope.$apply()  unless scope.$$phase
]
