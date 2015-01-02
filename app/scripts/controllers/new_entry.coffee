'use strict'

###*
 # @ngdoc function
 # @name vigiechiroApp.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the vigiechiroApp
###
angular.module('vigiechiroApp')
  .directive 'photoPreviewDirective', ->
    restrict: 'E'
    scope:
      file_input: '=input'
      picture_output: '=output'
    template: "<canvas></canvas>"
    link: (scope, elem, attrs) ->
      canvas = elem.children("canvas")[0]
      elem.hide()
      MAX_WIDTH = attrs.width or 640
      MAX_HEIGHT = attrs.height or 480
      load_and_resize = (file) ->
        reader = new FileReader();
        reader.onerror = (e) ->
          console.log "Error with FileReader : #{e}"
        reader.onload = (e) ->
          context = canvas.getContext('2d')
          imageObj = new Image()
          imageObj.onload = ->
            width = this.width
            height = this.height
            if width > height
              if width > MAX_WIDTH
                height *= MAX_WIDTH / width
                width = MAX_WIDTH
            else
              if height > MAX_HEIGHT
                width *= MAX_HEIGHT / height
                height = MAX_HEIGHT
            canvas.width = width;
            canvas.height = height;
            context.drawImage(this, 0, 0, width, height);
            scope.$apply ->
              scope.picture_output = canvas.toDataURL()
            elem.show()
          imageObj.src = e.target.result
        reader.readAsDataURL(file)
      scope.$watch 'file_input', (file) ->
        if file instanceof Blob
          load_and_resize(file)
        else
          elem.hide()
  .controller 'NewEntryCtrl', ($scope, Restangular, Geolocation) ->
    $scope.input_file = null
    $scope.fileAdded = ($file) ->
      $scope.input_file = $file.file
    $scope.entry =
      picture: null
    $scope.sendEntry = ->
      $scope.entry.date = (new Date()).toUTCString()
      entry = $scope.entry
      $scope.entry =
        picture: null
      Geolocation.getCurrentPosition (location) ->
        $scope.input_file = null
        entry.location = {'type': 'Point', 'coordinates': [location.coords.longitude, location.coords.latitude]}
        Restangular.all('entries').post(entry)
