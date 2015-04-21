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

  .controller 'ListResourceController', ($scope, $timeout, $location, session) ->
    # Load lookup pagination from $location
    # params = $location.search()
    # if params.page?
    #   $scope.lookup.page = parseInt(params.page)
    # if params.items?
    #   $scope.lookup.max_results = parseInt(params.items)
    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
    $scope.resources = []
    $scope.loading = true
    updateResourcesList = () ->
      $scope.loading = true
      if $scope.resourceBackend?
        $scope.resourceBackend.getList($scope.lookup).then (items) ->
          $scope.resources = items
          $scope.loading = false
    $scope.$watch(
      'lookup'
      ->
        updateResourcesList()
        # Save pagination in $location
        # params = $location.search()
        # if $scope.lookup.max_results != params.max_results
        #   $location.search('items', $scope.lookup.max_results)
        # if $scope.lookup.page != params.page
        #   $location.search('page', $scope.lookup.page)
      true
    )
    $scope.$watch(
      'resourceBackend'
      ->
        updateResourcesList()
        # Save pagination in $location
        # params = $location.search()
        # if $scope.lookup.max_results != params.max_results
        #   $location.search('items', $scope.lookup.max_results)
        # if $scope.lookup.page != params.page
        #   $location.search('page', $scope.lookup.page)
      true
    )
    $scope.pageChange = (newPage) ->
      $scope.lookup.page = newPage
      updateResourcesList()

  .directive 'listResourceDirective', (session, Backend) ->
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
