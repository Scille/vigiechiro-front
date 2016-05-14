'use strict'


angular.module('xin_uploadFile', ['appSettings', 'xin_s3uploadFile', 'xin.fileUploader'])
  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileController'
    scope:
      uploader: '=?'
    link: (scope, elem, attrs) ->
      scope.dragOverClass = ''
      scope.multiple = false
      scope.directory = false

      drop = elem.find('.drop')
      input = drop.find('input')
      if attrs.multiple?
        scope.multiple = true
        input[0].setAttribute('multiple', '')
      if attrs.directory?
        scope.directory = true
        input[0].setAttribute('directory', '')
        input[0].setAttribute('webkitdirectory', '')
        input[0].setAttribute('mozdirectory', '')


  .controller 'UploadFileController', ($scope, Backend, S3FileUploader, FileUploader, guid) ->
    $scope.dropError = []
    $scope.date_id = guid()
    $scope.warnings = []
    $scope.errors =
      filters: []
      back: []
      xhr: []
    uploader = $scope.uploader = new FileUploader()
    uploader.refresh = ->
      $scope.$apply()

    # Remove sub-directories
    uploader.filters.push(
      name: "Sous-dossiers ignorés."
      fn: (item) ->
        if item.webkitRelativePath? and item.webkitRelativePath != ''
          split = item.webkitRelativePath.split("/")
          if split.length > 2
            return false
        return true
    )
