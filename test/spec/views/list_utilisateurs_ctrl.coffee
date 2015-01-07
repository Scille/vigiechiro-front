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
    mockToReturn =
      '_items': [
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
        ,
          'pseudo': 'visitor'
          'nom': 'Doe'
          'prenom': 'John'
          'email': 'john.doe@gmail.com'
          '_etag': 'f47127f2392bfc4f0bd6aae28835e8763c98b737'
          '_id': '54949c201d41c868777dd6d4'
          'role': 'Observateur'
          '_links':
            'self':
              'title': 'utilisateur'
              'href': 'utilisateurs/54949c201d41c868777dd6d4'
      ]
      '_links':
        'self':
          'title': 'utilisateurs'
          'href': 'utilisateurs'
        'parent':
          'title': 'home'
          'href': '/'
      '_meta':
        'total': 1
        'max_results': 25
        'page': 1
    httpBackend.expectGET('/utilisateurs').respond(mockToReturn)
    expect(scope.utilisateurs).toEqual([])
    httpBackend.flush()
    expect(Backend.all).toHaveBeenCalledWith('utilisateurs')
    expect(scope.utilisateurs).toEqual([
        nom : 'Doe'
        prenom : 'John'
        pseudo : 'n00b'
        email : 'john.doe@gmail.com'
        _id : '54949c201d41c868777dd6d4'
        role : 'Observateur'
        _links :
          self :
            title : 'utilisateur',
            href : 'utilisateurs/54949c201d41c868777dd6d4'
      ,
        pseudo : 'visitor'
        nom : 'Doe'
        prenom : 'John'
        email : 'john.doe@gmail.com'
        _id : '54949c201d41c868777dd6d4'
        role : 'Observateur'
        _links :
          self :
            title : 'utilisateur'
            href : 'utilisateurs/54949c201d41c868777dd6d4'
    ])
