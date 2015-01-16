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
  addEventListener: ->


describe 'Service: session', ->

  $rootScope = null
  authService = null
  storage = null
  Backend = null
  test_token = "C8Y1VMEKHOIT3F1GU9HI16FNNHB7QFKJ"
  test_user_id = "123456789"
  test_authorization_header = "Basic QzhZMVZNRUtIT0lUM0YxR1U5SEkxNkZOTkhCN1FGS0o6"

  beforeEach module 'xin_session'
  beforeEach module 'xin_session_tools'

  # load the service's module
  beforeEach module ($provide)->
    storage = new StorageMock()
    Backend = new BackendMock()
    $provide.value('storage', storage)
    $provide.value('Backend', Backend)
    return null

  beforeEach inject (_$rootScope_, $q) ->
    Backend._q = $q
    $rootScope = _$rootScope_

  it 'Test basic login', inject ($window, session, SessionTools) ->
    spyOn($window.location, 'reload').and.callThrough()
    session.login(test_token)
    $rootScope.$digest() # Trigger promises
    expect($window.location.reload).toHaveBeenCalled()
    expect(SessionTools.getAuthorizationHeader()).toEqual(test_authorization_header)

  # it 'Test token loading', inject () ->


    # Backend._builders['utilisateurs'] = (href) ->
    #   user = utilisateurs_builder(href)
    #   user._id = test_user_id
    #   return user
    # user = undefined
    # session.getUserPromise().then(
    #   (_user_) ->
    #     console.log(user)
    #     user = _user_
    #   (e) ->
    #     console.log('error')
    #     console.log(e)
    # )
    # expect(user).toEqual({'touille': 1})
    # expect(session.getToken()).toEqual(test_token)
    # expect(session.getUserId()).toEqual(test_user_id)

  # it 'Test basic logout', inject (session, SessionTools) ->
  #   session.logout()
  #   $rootScope.$digest() # Trigger promises
  #   expect($rootScope.$broadcast).toHaveBeenCalledWith('event:auth-loginRequired')
  #   $rootScope.$broadcast.calls.reset()
  #   # expect(session.getToken()).toBe(undefined)
  #   expect(session.getUserId()).toBe(undefined)
  #   expect(SessionTools.getAuthorizationHeader()).toBe(undefined)

  # describe 'Test login & logout from another tab', ->

  #   beforeEach inject ($rootScope) ->
  #     user = utilisateurs_builder('/utilisateurs/moi')
  #     user._id = test_user_id
  #     user.token = test_token
  #     storage.setItem('auth-session', JSON.stringify(user))

  #   it 'Test successful login', inject (session) ->
  #     expect(authService.loginConfirmed).toHaveBeenCalled()
  #     expect(session.getUserId()).toEqual(test_user_id)
  #     # expect(session.getToken()).toEqual(test_token)

  #   it 'Test logout', inject (session, $rootScope) ->
  #     storage.removeItem('auth-session')
  #     expect($rootScope.$broadcast).toHaveBeenCalledWith('event:auth-loginRequired')
  #     expect(session.getUserId()).toBe(undefined)
  #     # expect(session.getToken()).toBe(undefined)

  #   it 'Test updating token', inject (session, $rootScope) ->
  #     new_token = "RFQNHVDZAN8LHD5F1C7AJSNMYN0UXU90"
  #     user = utilisateurs_builder('/utilisateurs/moi')
  #     user._id = test_user_id
  #     user.token = new_token
  #     storage.setItem('auth-session', JSON.stringify(user))
  #     expect(session.getUserId()).toEqual(test_user_id)
  #     # expect(session.getToken()).toEqual(new_token)
  #     expect(authService.loginConfirmed).toHaveBeenCalled()

  #   it 'Test changing user', inject (session, $rootScope) ->
  #     new_user_id = 7777777
  #     new_token = "RFQNHVDZAN8LHD5F1C7AJSNMYN0UXU90"
  #     user = utilisateurs_builder('/utilisateurs/moi')
  #     user._id = new_user_id
  #     user.token = new_token
  #     storage.setItem('auth-session', JSON.stringify(user))
  #     expect(session.getUserId()).toEqual(new_user_id)
  #     # expect(session.getToken()).toEqual(new_token)
  #     expect(authService.loginConfirmed).toHaveBeenCalled()
