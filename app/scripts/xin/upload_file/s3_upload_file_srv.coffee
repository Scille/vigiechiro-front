'use strict'


angular.module('xin_s3uploadFile', ['appSettings'])

  .directive 'accessFileDirective', (SETTINGS, Backend) ->
    restrict: 'E'
    template: '<button class="btn btn-primary" ng-click="accessFile()">{{file.titre}}</button>'
    scope:
      file: '='
    link: (scope, elem, attrs) ->
      if scope.file? and scope.file.disponible? and scope.file.s3_id?
        scope.fileLink = "#{SETTINGS.API_DOMAIN}/fichiers/#{scope.file._id}/acces"
        scope.accessFile = () ->
          Backend.all('fichiers').one(scope.file._id).customGET('acces').then(
            (response) -> window.open(response.s3_signed_url)
            (error) ->
              if error.status == 410
              else
                throw error
          )
      else
        # File is not available, notify it to the user
        btn = elem.find('button')
        btn.removeClass('btn-primary', '')
        btn.addClass('btn-warning', '')
        btn.attr('data-toggle', 'tooltip')
        btn.attr('data-placement', 'top')
        btn.attr('title', "Ce fichier n'est pas disponible en ligne")
        btn.tooltip()



  .directive 'accessPhotoDirective', (SETTINGS, Backend) ->
    restrict: 'E'
    template: '<img ng-src="{{s3_signed_url}}"</img><span ng-show="onError">{{error}}</span>'
    scope:
      file: '='
    link: (scope, elem, attrs) ->
      if scope.file.disponible? and scope.file.s3_id?
        scope.fileLink = "#{SETTINGS.API_DOMAIN}/fichiers/#{scope.file._id}/acces"
        Backend.all('fichiers').one(scope.file._id).customGET('acces').then(
          (response) -> scope.s3_signed_url = response.s3_signed_url
          (error) ->
            if error.status == 410
            else
              throw error
        )
      else
        # Photo is not available, notify it to the user
        scope.onError = true
        scope.error = "Cette image n'est pas disponible en ligne"
