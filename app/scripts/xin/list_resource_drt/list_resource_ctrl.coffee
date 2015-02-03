'use strict'


angular.module('xin_listResource', ['ngRoute', 'angularUtils.directives.dirPagination', 'xin_session'])

  .config ($compileProvider, paginationTemplateProvider) ->
    paginationTemplateProvider.setPath('scripts/xin/list_resource_drt/dirPagination.tpl.html')
    # Directive used to inject dynamic html node in the template
    $compileProvider.directive 'compile', ($compile) ->
      return (scope, element, attrs) ->
        scope.$watch(
          (scope) ->
            return scope.$eval(attrs.compile)
          (value) ->
            element.html(value)
            $compile(element.contents())(scope)
        )

  .service 'DelayedEvent', ($timeout) ->
    class DelayedEvent
      constructor: (@timer) ->
        @eventCount = 0
      triggerEvent: (action) ->
        @eventCount += 1
        eventCurrent = @eventCount
        $timeout(
          =>
            if eventCurrent == @eventCount
              action()
          @timer
        )

  .controller 'ListResourceCtrl', ($scope, $timeout, session) ->
    $scope.resources = []
    $scope.loading = true
    updateResourcesList = (lookup) ->
      $scope.loading = true
      $scope.resourceBackend.getList(lookup).then (items) ->
        $scope.resources = items
        $scope.loading = false
    $scope.$watch('lookup', updateResourcesList, true)
    $scope.pageChange = (newPage) ->
      $scope.lookup.page = newPage
      updateResourcesList($scope.lookup)
    updateResourcesList($scope.lookup)

  .directive 'listResourceDirective', (session, Backend) ->
    restrict: 'E'
    transclude: true
    templateUrl: 'scripts/xin/list_resource_drt/list_resource.html'
    controller: 'ListResourceCtrl'
    scope:
      resourceBackend: '='
      lookup: '=?'
    link: (scope, elem, attrs, ctrl, transclude) ->
      if not attrs.lookup?
        scope.lookup = {}
      scope.lookup.page = scope.lookup.page or 1
      scope.lookup.max_results = scope.lookup.max_results or 10
      if !transclude
        throw "Illegal use of lgTranscludeReplace directive in the template," +
              " no parent directive that requires a transclusion found."
        return
      transclude (clone) ->
        scope.resourceTemplate = ''
        clone.each (index, node) ->
          if node.outerHTML?
            scope.resourceTemplate += node.outerHTML
