'use strict'

class RestangularMock
  constructor: -> @_spies = {}
  one: jasmine.createSpy()
  all: (resource) ->
    if not @_spies[resource]?
      @_spies[resource] =
        post: jasmine.createSpy('post'),
        get: jasmine.createSpy('get')
    return @_spies[resource]

class GeolocationMock
  constructor: ->
    @_timestamp = Date.now()
    @_utc_date = new Date(@_timestamp).toUTCString()
    @_latitude = 48.023400
    @_longitude = 2.038094
  getCurrentPosition: (callback) ->
    callback
      timestamp: @_timestamp
      coords:
        latitude: @_latitude
        longitude: @_longitude
        accuracy: 3588
        speed: null
        altitude: null
        altitudeAccuracy: null
        heading: null
    return undefined


describe 'Controller: NewEntryCtrl', ->

  # load the controller's module
  beforeEach module 'vigiechiroApp'

  scope = {}
  Restangular = new RestangularMock()
  geolocation = new GeolocationMock()

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    $controller 'NewEntryCtrl',
      $scope: scope
      Restangular: Restangular
      geolocation: geolocation

  it 'Test entry form submit & reset', ->
    scope.entry.comment = 'test'
    scope.entry.picture = 'picture data'
    scope.sendEntry()
    expect(scope.entry).toEqual {picture: null}
    expect(Restangular.all('entries').post.calls.count()).toEqual(1)
    expect(Restangular.all('entries').post).toHaveBeenCalledWith
      picture: 'picture data'
      comment: 'test'
      date: geolocation._utc_date
      location:
        type: 'Point'
        coordinates: [geolocation._longitude, geolocation._latitude]
