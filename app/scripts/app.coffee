'use strict'

###*
 # @ngdoc overview
 # @name vigiechiroApp
 # @description
 # # vigiechiroApp
 #
 # Main module of the application.
###
angular
  .module('vigiechiroApp', [
    'ngAnimate',
    'ngCookies',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'ngResource',
    'restangular',
    'http-auth-interceptor',
    'flow',
    'xin_session',
    'xin_geolocation',
    'xin_login',
    'xin_user_status'
  ])
  .constant 'RESOURCES',
    API_DOMAIN: 'http://api.lvh.me:8080'
    FRONT_DOMAIN: 'http://www.lvh.me:9000'
  .run (Restangular, RESOURCES, session) ->
    Restangular.setBaseUrl(RESOURCES.API_DOMAIN)
      .setDefaultHeaders
        Authorization: session.get_authorization_header
      .setRestangularFields
        id: "_id"
        etag: "_etag"
      .addResponseInterceptor (data, operation, what, url, response, deferred) ->
        if operation == "getList"
          extractedData = data._items
          extractedData._meta = data._meta
          extractedData._links = data._links
          extractedData.self = data.self
        else
          extractedData = data
        return extractedData
  .config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'scripts/views/list_entries/list_entries.html'
        controller: 'ListEntriesCtrl'
      .when '/post',
        templateUrl: 'scripts/views/new_entry/new_entry.html'
        controller: 'NewEntryCtrl'
      .when '/404',
        templateUrl: '404.html'
      .otherwise
        redirectTo: '/404'
  .directive 'loginDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/login_drt/login.html'
    controller: 'LoginCtrl'
  .directive 'contentDirective', (session) ->
    restrict: 'E'
    link: (scope, elem, attrs) ->
      if session.get_user_id()?
        elem.show()
      else
        elem.hide()
      scope.$on 'event:auth-loginRequired', ->
        elem.hide()
      scope.$on 'event:auth-loginConfirmed', ->
        elem.show()
  .directive 'userStatus', ->
    restrict: 'E'
    controller: 'UserStatusCtrl'
    templateUrl: 'scripts/xin/user_status_drt/user_status.html'
