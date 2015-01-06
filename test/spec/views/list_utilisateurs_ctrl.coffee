'use strict'

describe 'Controller: ListUtilisateursCtrl', ->

  # load the controller's module
  beforeEach module 'xin_backend'
  beforeEach module 'listUtilisateurs'

  scope = undefined
  Backend = undefined
  httpBackend = undefined

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope, _Backend_, _$httpBackend_) ->
    Backend = _Backend_
    httpBackend = _$httpBackend_
    spyOn(Backend, 'all').and.callThrough()
    scope = $rootScope.$new()
    $controller 'ListUtilisateursCtrl',
      $scope: scope
      Backend: Backend

  it 'Test entry form submit & reset', ->
    mockToReturn = [
        'nom': 'Doe'
        'prenom': 'John'
        'pseudo': 'n00b'
        'telephone': '01 23 45 67 89'
        'donnees_publiques': false
        'email': 'john.doe@gmail.com'
        'role': 'Observateur'
      ,
        'nom': 'van rossum'
        'prenom': 'guido'
        'pseudo': 'gr0k'
        'email': 'guido@python.org'
        'donnees_publiques': true
        'tags': ['Python', 'BDFL']
        'organisation': 'Python fundation'
        'role': 'Administrateur'
    ]
    httpBackend.expectGET('/utilisateurs').respond(mockToReturn)
    expect(scope.utilisateurs).toEqual([])
    httpBackend.flush()
    expect(Backend.all).toHaveBeenCalledWith('utilisateurs')
    expect(scope.utilisateurs).toEqual(mockToReturn)
