'use strict'


angular.module('xin_listResource', ['ngRoute', 'angularUtils.directives.dirPagination', 'xin_session'])
  .config (paginationTemplateProvider) ->
    paginationTemplateProvider.setPath('scripts/xin/list_resource_drt/dirPagination.tpl.html')

  .controller 'ListResourceCtrl', ($scope, $location, session, resourceBackend) ->
    resourceName = resourceBackend.route
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    $scope[resourceName] = []
    $scope.loading = true
    # Pagination
    params = $location.search()
    $scope.itemsPerPage = parseInt(params.items) or 20
    $scope.totalItems = 0
    $scope.currentPage = parseInt(params.page) or 1

    $scope.$watch 'filter', (filterValue) ->
      if not filterValue
        return
      $scope.loading = true
      where = JSON.stringify(
        $text:
          $search: filterValue
      )
      params =
        where: where
      resourceBackend.getList(params).then (items) ->
        $scope[resourceName] = items.plain()
        $scope.totalItems = items._meta.total
        $scope.loading = false

    $scope.pageChanged = (newPage) ->
      $scope.currentPage = newPage
      $scope.loading = true
      # Update the url's params
      $location.search('items', $scope.itemsPerPage)
      $location.search('page', newPage)
      # Query & load the results
      params =
        page: newPage
        max_results: $scope.itemsPerPage
      resourceBackend.getList(params).then (items) ->
        $scope[resourceName] = items.plain()
        $scope.totalItems = items._meta.total
        $scope.loading = false
    $scope.pageChanged($scope.currentPage)
