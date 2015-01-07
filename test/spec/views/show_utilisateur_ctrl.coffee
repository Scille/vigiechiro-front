'use strict'

describe 'Controller: ShowUtilisateurCtrl', ->

  # load the controller's module
  beforeEach module 'xin_backend'
  beforeEach module 'showUtilisateur'

  stateParams = { id: '54949c201d41c868777dd6d4' }
  scope = undefined
  Backend = undefined
  httpBackend = undefined

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope, _Backend_, _$httpBackend_) ->
    Backend = _Backend_
    httpBackend = _$httpBackend_
    spyOn(Backend, 'one').and.callThrough()
    scope = $rootScope.$new()
    $controller 'ShowUtilisateurCtrl',
      $stateParams: stateParams
      $scope: scope
      Backend: Backend

  it 'Test entry form submit & reset', ->
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
