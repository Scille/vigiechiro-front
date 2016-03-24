"use strict"


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


utilisateurs_builder = (href) ->
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
          'href': href or "utilisateurs/#{id}"


class BackendResourceMock
  constructor: (@route, @_itemBuilder, @_q) ->
  _generateMockList: (page, maxResults, total) ->
    if page * maxResults <= total
      itemsCount = maxResults
    else
      itemsCount = total - (page - 1) * maxResults
    list = (@_itemBuilder() for _ in [1..itemsCount])
    list._links =
      'self':
        'title': @route
        'href': @route
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

class BackendItemMock
  constructor: (@_resource, @_item, @_itemBuilder, @_q) ->
  get: ->
    deferred = @_q.defer()
    deferred.resolve(@_itemBuilder("#{@_resource}/#{@_item}"))
    return deferred.promise
  post: (subElement, elementToPost, queryParams, headers) ->
    deferred = @_q.defer()
    deferred.resolve()
    return deferred.promise


class BackendMock
  constructor: (@_q, builders) ->
    @_resources = {}
    @_items = {}
    @_builders = builders or {'utilisateurs': utilisateurs_builder}
  setCustomToken: (token) ->
  resetCustomToken: ->
  all: (resource) ->
    if not @_resources[resource]?
      @_resources[resource] = new BackendResourceMock(resource, @_q)
    return @_resources[resource]
  one: (resource, item) ->
    if not @_items["#{resource}/#{item}"]?
      @_items["#{resource}/#{item}"] = new BackendItemMock(resource, item, @_builders[resource], @_q)
    return @_items["#{resource}/#{item}"]
