'use strict'

describe 'Controller: ListUtilisateursCtrl', ->

  # load the controller's module
  beforeEach module 'restangular'
  beforeEach module 'listUtilisateurs'

  scope = {}
  Restangular = undefined
  httpBackend = undefined

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope, _Restangular_, _$httpBackend_) ->
    Restangular = _Restangular_
    httpBackend = _$httpBackend_
    spyOn(Restangular, 'all').and.callThrough()
    scope = $rootScope.$new()
    $controller 'ListUtilisateursCtrl',
      $scope: scope
      Restangular: Restangular

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
    expect(Restangular.all).toHaveBeenCalledWith('utilisateurs')
    expect(scope.utilisateurs).toEqual(mockToReturn)
