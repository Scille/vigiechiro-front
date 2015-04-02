'use strict'


angular.module('donneeViews', ['xin_backend'])
  .directive 'displayDonneeDirective', (Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/donnee/display_donnee.html'
    link: (scope, elem, attrs) ->
      Backend.one('donnee', 0).get().then (donnee) ->

      attrs.$observe 'typeSite', (typeSite) ->
        console.log("")
