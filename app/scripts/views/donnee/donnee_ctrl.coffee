'use strict'


angular.module('donneeViews', ['xin_backend'])
  .directive 'listDonneesDirective', (Backend) ->
    restrict: 'E'
    templateUrl: 'scripts/views/donnee/list_donnees.html'
    scope:
      participationId: '@'
    link: (scope, elem, attrs) ->
      attrs.$observe 'participationId', (participationId) ->
        if participationId? && participationId != ''
          Backend.all('participations/'+participationId+'/donnees').getList().then (donnees) ->
            scope.donnees = donnees.plain()
