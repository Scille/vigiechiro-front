'use strict'


angular.module('xin_listResource', ['ngRoute', 'angularUtils.directives.dirPagination', 'xin_session'])
  .config (paginationTemplateProvider) ->
    paginationTemplateProvider.setPath('scripts/xin/list_resource_drt/dirPagination.tpl.html')

  .controller 'ListResourceCtrl', ($scope, $timeout, $location, session, resourceBackend) ->
    resourceName = resourceBackend.route
    session.getIsAdminPromise().then (isAdmin) ->
      $scope.isAdmin = isAdmin
    $scope[resourceName] = []
    $scope.loading = true
    $scope.filter = undefined
    # Pagination
    params = $location.search()
    $scope.itemsPerPage = parseInt(params.items) or 20
    $scope.totalItems = 0
    $scope.currentPage = parseInt(params.page) or 1
    typingCount = 0

    $scope.$watch 'filter', (filterValue) ->
      triggerSearch = ->
        if filterValue
          params =
            where: JSON.stringify(
              $text:
                $search: filterValue
            )
        else
          params = undefined
        resourceBackend.getList(params).then (items) ->
          $scope[resourceName] = items.plain()
          $scope.totalItems = items._meta.total
          $scope.loading = false
      # Delay the request not to flood while the user is typing
      typingCount += 1
      currTyping = typingCount
      $timeout(
        ->
          if currTyping == typingCount
            triggerSearch()
        500
      )

    $scope.pageChanged = (newPage) ->
      $scope.currentPage = newPage
      $scope.loading = true
      # Query & load the results
      params =
        page: newPage
        max_results: $scope.itemsPerPage
      resourceBackend.getList(params).then (items) ->
        $scope[resourceName] = items.plain()
        $scope.totalItems = items._meta.total
        # Finally update the url's params and disable loading spinner
        $location.search('items', $scope.itemsPerPage)
        $location.search('page', newPage)
        $scope.loading = false
    $scope.pageChanged($scope.currentPage)
