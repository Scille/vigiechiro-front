'use strict'

describe 'Controller: ShowUtilisateurCtrl', ->

  # load the controller's module
  beforeEach module 'xin_backend'
  beforeEach module 'utilisateurViews'

  routeParams = {userId: '54949c201d41c868777dd6d4'}
  scope = undefined
  Backend = undefined
  httpBackend = undefined

  # Initialize the controller and a mock scope
  beforeEach inject ($q, $controller, $rootScope, _Backend_, _$httpBackend_) ->

    Backend = _Backend_
    httpBackend = _$httpBackend_
    spyOn(Backend, 'one').and.callThrough()
    scope = $rootScope.$new()
    session =
      getUserPromise: ->
        deferred = $q.defer()
        deferred.resolve(utilisateurs_builder('utilisateurs/moi'))
        return deferred.promise
    $controller 'ShowUtilisateurCtrl',
      $routeParams: routeParams
      $scope: scope
      Backend: Backend
      session: session

  it 'Test show utilisateur', ->
    mockToReturn =
      'nom': 'Doe'
      'prenom': 'John'
      'pseudo': 'n00b'
      'email': 'john.doe@gmail.com'
      '_etag': 'f47127f2392bfc4f0bd6aae28835e8763c98b737'
      '_id': '54949c201d41c868777dd6d4'
      'role': 'Observateur'
      '_links':
        'self':
          'title': 'utilisateur'
          'href': 'utilisateurs/54949c201d41c868777dd6d4'
    httpBackend.expectGET('/utilisateurs/54949c201d41c868777dd6d4').respond(mockToReturn)
    expect(scope.utilisateur).toEqual({})
    httpBackend.flush()
    expect(Backend.one).toHaveBeenCalledWith('utilisateurs', '54949c201d41c868777dd6d4')
    delete mockToReturn._etag
    expect(scope.utilisateur).toEqual(mockToReturn)

  it 'Test save utilisateur', ->
    mockToReturn =
      'pseudo': 'n00b'
      'email': 'john.doe@gmail.com'
      '_etag': 'f47127f2392bfc4f0bd6aae28835e8763c98b737'
      '_id': '54949c201d41c868777dd6d4'
      'role': 'Observateur'
      '_links':
        'self':
          'title': 'utilisateur'
          'href': 'utilisateurs/54949c201d41c868777dd6d4'
    scope.userForm =
      '$dirty': false
      '$setPristine': ->
      'prenom': {'$dirty': true}
      'nom': {'$dirty': false}
      'email': {'$dirty': true}
      'pseudo': {'$dirty': false}
      'telephone': {'$dirty': false}
      'adresse': {'$dirty': false}
      'commentaire': {'$dirty': false}
      'organisation': {'$dirty': false}
    httpBackend.expectGET('/utilisateurs/54949c201d41c868777dd6d4').respond(mockToReturn)
    expect(scope.utilisateur).toEqual({})
    httpBackend.flush()
    expect(Backend.one).toHaveBeenCalledWith('utilisateurs', '54949c201d41c868777dd6d4')
    spyOn(scope.userForm, '$dirty').and.returnValue(true)
    spyOn(scope.userForm, '$setPristine')
    delete mockToReturn._etag
    expect(scope.utilisateur).toEqual(mockToReturn)
    scope.utilisateur.email = 'john.irondick@gmail.com'
    scope.utilisateur.prenom = 'John'
    scope.saveUser()
    httpBackend.expectPATCH(
      '/utilisateurs/54949c201d41c868777dd6d4'
        'email': 'john.irondick@gmail.com'
        'prenom': 'John'
    ).respond(201)
    httpBackend.flush()
