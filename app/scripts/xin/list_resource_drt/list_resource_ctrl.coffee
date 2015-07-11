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


  .controller 'ListResourceController', ($scope, $timeout, $location, Session) ->
    $scope.user = Session.getUser()
    $scope.resources = []
    updateResourcesList = ->
      if $scope.resourceBackend?
        $scope.resourceBackend.getList($scope.lookup).then (items) ->
          $scope.resources = items
    $scope.$watch(
      'lookup'
      ->
        updateResourcesList()
      true
    )
    $scope.pageChange = (newPage) ->
      if $scope.lookup.page is newPage
        return
      $scope.lookup.page = newPage


  .directive 'listResourceDirective', (Session, Backend) ->
    restrict: 'E'
    transclude: true
    templateUrl: 'scripts/xin/list_resource_drt/list_resource.html'
    controller: 'ListResourceController'
    scope:
      resourceBackend: '='
      lookup: '=?'
    link: (scope, elem, attrs, ctrl, transclude) ->
      if not attrs.lookup?
        scope.lookup = {}
      scope.$watch 'lookup', (lookup) ->
        if lookup?
          scope.lookup.page = scope.lookup.page or 1
          scope.lookup.max_results = scope.lookup.max_results or 20
          if !transclude
            throw "Illegal use of lgTranscludeReplace directive in the template," +
                  " no parent directive that requires a transclusion found."
            return
          transclude (clone) ->
            scope.resourceTemplate = ''
            clone.each (index, node) ->
              if node.outerHTML?
                scope.resourceTemplate += node.outerHTML
