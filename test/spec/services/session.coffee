'use strict'


class AuthServiceMock
  constructor: ->
  loginConfirmed: jasmine.createSpy()
  loginCancelled: jasmine.createSpy()


class StorageMock
  constructor: ->
    @_listener = null
    @_storage = {}
  setItem: (key, value) ->
    e =
      key: key
      newValue: value
      oldValue: null
    @_storage[key] = value
    if @_listener?
      @_listener(e)
  getItem: (key) ->
    if @_storage[key]?
      @_storage[key]
    else
      null
  removeItem: (key) ->
    e =
      key: key
      newValue: null
      oldValue: @_storage[key]
    delete @_storage[key]
    if @_listener?
      @_listener(e)
  clear: -> @_storage = {}
  addEventListener: (@_listener) ->


describe 'Service: session', ->

  $rootScope = null
  authService = null
  storage = null
  test_token = "C8Y1VMEKHOIT3F1GU9HI16FNNHB7QFKJ"
  test_user_id = "123456789"
  test_authorization_header = "Basic QzhZMVZNRUtIT0lUM0YxR1U5SEkxNkZOTkhCN1FGS0o6"

  beforeEach module 'vigiechiroApp'

  # load the service's module
  beforeEach module ($provide)->
    authService = new AuthServiceMock()
    storage = new StorageMock()
    $provide.value('authService', authService)
    $provide.value('storage', storage)
    return null

  beforeEach inject (_$rootScope_) ->
    $rootScope = _$rootScope_
    spyOn($rootScope, '$broadcast')

  it 'Test basic login', inject (session) ->
    session.login(test_user_id, test_token)
    expect(authService.loginConfirmed).toHaveBeenCalled()
    expect(session.get_token()).toEqual(test_token)
    expect(session.get_user_id()).toEqual(test_user_id)
    expect(session.get_authorization_header()).toEqual(test_authorization_header)

  it 'Test basic logout', inject (session) ->
    session.logout()
    expect($rootScope.$broadcast).toHaveBeenCalledWith('event:auth-loginRequired')
    $rootScope.$broadcast.calls.reset()
    expect(session.get_token()).toBe(null)
    expect(session.get_user_id()).toBe(null)
    expect(session.get_authorization_header()).toBe(null)
    expect($rootScope.$broadcast.calls.allArgs()).toEqual(['event:auth-loginRequired'] for _ in [1..3])

  describe 'Test login & logout from another tab', ->

    beforeEach inject ($rootScope) ->
      storage.setItem 'auth-session', JSON.stringify
        user_id: test_user_id
        token: test_token

    it 'Test successful login', inject (session) ->
      expect(authService.loginConfirmed).toHaveBeenCalled()
      expect(session.get_user_id()).toEqual(test_user_id)
      expect(session.get_token()).toEqual(test_token)

    it 'Test logout', inject (session, $rootScope) ->
      storage.removeItem('auth-session')
      expect($rootScope.$broadcast).toHaveBeenCalledWith('event:auth-loginRequired')
      expect(session.get_user_id()).toBe(null)
      expect(session.get_token()).toBe(null)

    it 'Test updating token', inject (session, $rootScope) ->
      new_token = "RFQNHVDZAN8LHD5F1C7AJSNMYN0UXU90"
      storage.setItem 'auth-session', JSON.stringify
        user_id: test_user_id
        token: new_token
      expect(session.get_user_id()).toEqual(test_user_id)
      expect(session.get_token()).toEqual(new_token)
      expect(authService.loginConfirmed).toHaveBeenCalled()

    it 'Test changing user', inject (session, $rootScope) ->
      new_user_id = 7777777
      new_token = "RFQNHVDZAN8LHD5F1C7AJSNMYN0UXU90"
      storage.setItem 'auth-session', JSON.stringify
        user_id: new_user_id
        token: new_token
      expect(session.get_user_id()).toEqual(new_user_id)
      expect(session.get_token()).toEqual(new_token)
      expect(authService.loginConfirmed).toHaveBeenCalled()
