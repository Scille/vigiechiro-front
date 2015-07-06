'use strict'


class StorageMock
  constructor: ->
    @_storage = {}
  setItem: (key, value) ->
    @_storage[key] = value
  getItem: (key) ->
    if @_storage[key]?
      @_storage[key]
    else
      null
  removeItem: (key) ->
    delete @_storage[key]
  clear: -> @_storage = {}
  _eventListener: undefined
  addEventListener: (@_eventListener) ->

test_token = "C8Y1VMEKHOIT3F1GU9HI16FNNHB7QFKJ"
test_authorization_header = "Basic QzhZMVZNRUtIT0lUM0YxR1U5SEkxNkZOTkhCN1FGS0o6"

describe 'Service: session', ->

  $rootScope = null
  $httpBackend = null
  storage = null
  Backend = null

  beforeEach module 'xin_session'
  beforeEach module 'xin_session_tools'

  # load the service's module
  beforeEach module ($provide)->
    storage = new StorageMock()
    Backend = new BackendMock()
    $provide.value('storage', storage)
    $provide.value('Backend', Backend)
    return null

  beforeEach inject (_$rootScope_, _$httpBackend_, $q) ->
    Backend._q = $q
    $rootScope = _$rootScope_
    $httpBackend = _$httpBackend_

  it 'Test trigger login', inject ($window, session, SessionTools) ->
    spyOn($window.location, 'reload').and.callThrough()
    session.login(test_token)
    expect($window.location.reload).toHaveBeenCalled()
    expect(SessionTools.getAuthorizationHeader()).toEqual(test_authorization_header)

  it 'Test login from another tab', inject ($window, storage, session, SessionTools) ->
    spyOn($window.location, 'reload').and.callThrough()
    storage.setItem('auth-session-token', test_token)
    # Send a fake event to simulate the other tab
    storage._eventListener(
      "key": 'auth-session-token'
      "oldValue": null
      "newValue": test_token
    )
    $rootScope.$digest() # Trigger promises
    expect($window.location.reload).toHaveBeenCalled()
    expect(SessionTools.getAuthorizationHeader()).toEqual(test_authorization_header)

  describe 'Once logged in', ->

    beforeEach inject (session) ->
      session.login(test_token)

    it 'Test logout', inject ($window, session, SessionTools) ->
      spyOn($window.location, 'reload').and.callThrough()
      $httpBackend.expectPOST('/logout').respond(200)
      session.logout()
      $rootScope.$digest() # Trigger promises
      expect($window.location.reload).toHaveBeenCalled()
      expect(SessionTools.getAuthorizationHeader()).toBeUndefined()

    it 'Test logout from another tab', inject ($window, session, SessionTools) ->
      spyOn($window.location, 'reload').and.callThrough()
      storage.removeItem('auth-session-token')
      # Send a fake event to simulate the other tab
      storage._eventListener(
        "key": 'auth-session-token'
        "oldValue": test_token
        "newValue": null
      )
      $rootScope.$digest() # Trigger promises
      expect($window.location.reload).toHaveBeenCalled()
      expect(SessionTools.getAuthorizationHeader()).toBeUndefined()


describe 'Outdated token', ->

  $rootScope = null
  $httpBackend = null
  storage = null

  beforeEach module 'xin_session'
  beforeEach module 'xin_session_tools'

  beforeEach module ($provide)->
    storage = new StorageMock()
    $provide.value('storage', storage)
    return null

  beforeEach inject (_$rootScope_, _$httpBackend_, session) ->
    $rootScope = _$rootScope_
    $httpBackend = _$httpBackend_
    session.login(test_token)

  it 'Test outdated token', inject ($rootScope, Backend) ->
    $httpBackend.expectGET('/utilisateurs/123456789').respond(401, {})
    result = undefined
    Backend.one('utilisateurs', '123456789').get().then(
      -> result = 'Bad success'
      -> result = 'True error'
    )
    $httpBackend.flush();
    $rootScope.$digest() # Trigger promises
    expect(result).toEqual('True error')
