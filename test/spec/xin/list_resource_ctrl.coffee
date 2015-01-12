'use strict'


describe 'Controller: ListResourceCtrl', ->

  # load the controller's module
  beforeEach module 'xin_listResource'

  scope = undefined
  resourceBackend = undefined
  httpBackend = undefined

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope, _$httpBackend_, $q) ->
    httpBackend = _$httpBackend_
    # resourceBackend = new BackendResourceMock('utilisateurs', $q)
    resourceBackend = new BackendResourceMock('utilisateurs', utilisateurs_builder, $q)
    spyOn(resourceBackend, 'getList').and.callThrough()
    scope = $rootScope.$new()
    $controller 'ListResourceCtrl',
      $scope: scope
      $routeParams: {}
      resourceBackend: resourceBackend

  it 'Test basic list', ->
    items = undefined
    resourceBackend._resolveGetList(10).then (result) -> items = result
    expect(resourceBackend.getList).toHaveBeenCalledWith({page: 1, max_results: 20})
    expect(scope.loading).toBe(true)
    scope.$apply()
    expect(scope.loading).toBe(false)
    expect(scope.utilisateurs.length).toEqual(10)
    expect(scope.utilisateurs).toEqual(items)
    expect(scope.currentPage).toEqual(1)
    expect(scope.totalItems).toEqual(10)

  it 'Test pagination', ->
    resourceBackend._resolveGetList(35)
    expect(resourceBackend.getList).toHaveBeenCalledWith({page: 1, max_results: 20})
    scope.$apply()
    expect(scope.utilisateurs.length).toEqual(20)
    scope.pageChanged(2)
    resourceBackend._resolveGetList(35)
    expect(resourceBackend.getList).toHaveBeenCalledWith({page: 2, max_results: 20})
    expect(scope.loading).toBe(true)
    scope.$apply()
    expect(scope.loading).toBe(false)
    expect(scope.utilisateurs.length).toEqual(15)
