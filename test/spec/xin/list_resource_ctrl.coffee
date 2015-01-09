'use strict'


stringGen = (len, type="alpha") ->
  text = ""
  if type == 'num'
    charset = "0123456789"
  else if type == 'hex'
    charset = "abcdef0123456789"
  else
    charset = "abcdefghijklmnopqrstuvwxyz0123456789"
    for _ in [1..len]
      text += charset.charAt(Math.floor(Math.random() * charset.length))
  return text


class MockBackend
  constructor: (@route, @_q) ->
  _generateMockItem: ->
    pseudo = 'id_' + stringGen(8)
    id = stringGen(24, 'hex')
    mockItem =
      'pseudo': pseudo
      'email': pseudo + '@test.com'
      '_id': id
      'role': 'Observateur'
      '_links':
        'self':
          'title': 'utilisateur'
          'href': 'utilisateurs/id'
  _generateMockList: (page, maxResults, total) ->
    if page * maxResults <= total
      itemsCount = maxResults
    else
      itemsCount = total - (page - 1) * maxResults
    list = (@_generateMockItem() for _ in [1..itemsCount])
    list._links =
      'self':
        'title': 'utilisateurs'
        'href': 'utilisateurs'
      'parent':
        'title': 'home'
        'href': '/'
    list._meta =
      'total': total
      'max_results': maxResults
      'page': page
    return list
  getList: (attr) ->
    @deferred = @_q.defer()
    @_deferredResolver = (totalItems) ->
      list = @_generateMockList(attr.page, attr.max_results, totalItems)
      list.plain = -> list
      return list
    return @deferred.promise
  _resolveGetList: (totalItems) ->
    @deferred.resolve(@_deferredResolver(totalItems))
    @deferred.promise


describe 'Controller: ListResourceCtrl', ->

  # load the controller's module
  beforeEach module 'xin_listResource'

  scope = undefined
  resourceBackend = undefined
  httpBackend = undefined

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope, _$httpBackend_, $q) ->
    httpBackend = _$httpBackend_
    resourceBackend = new MockBackend('utilisateurs', $q)
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
