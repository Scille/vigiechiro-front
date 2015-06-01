'use strict'


angular.module('xin_uploadFile', ['appSettings', 'xin_s3uploadFile'])
  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileController'
    scope:
      multiple: '@'
      uploaders: '=?'
    link: (scope, elem, attrs) ->
      scope.dragOverClass = ''
      if not attrs.uploaders?
        scope.uploaders = []
      else
        if not scope[attrs.uploaders]?
          scope[attrs.uploaders] = []
        scope.uploaders = scope[attrs.uploaders]
      drop = elem.find('.drop')
      input = drop.find('input')
      if attrs.multiple?
        input.attr('multiple', '')
        scope.multipleSelect = true
      else
        scope.multipleSelect = false
      scope.clickFileInput = ->
        input.click()
#        _.defer(-> input.click())
        return
      cancel = (e) ->
        e.stopPropagation()
        e.preventDefault()
      drop[0].addEventListener("dragover",
        (e) ->
          cancel(e)
          scope.dragOverClass = 'drag-over'
          _.defer(-> scope.$apply())
        false)
      drop[0].addEventListener("dragleave",
        (e) ->
          cancel(e)
          scope.dragOverClass = ''
          _.defer(-> scope.$apply())
        false)
      drop[0].addEventListener('drop',
        (e) ->
          cancel(e)
          scope.dragOverClass = ''
          _.defer(-> scope.$apply())
          scope.uploadFiles(e.dataTransfer.files)
        false
      )
      scope.fileInput = elem.find('.files-input')[0]


  .controller 'UploadFileController', ($scope, Backend, S3FileUploader) ->
    resetFileInput = ->
      elem = $($scope.fileInput)
      elem.wrap('<form>').closest('form').get(0).reset()
      elem.unwrap()
    $scope.stopUploader = (uploader) ->
      uploader.stop()
      _.remove($scope.uploaders, (up) -> up == uploader)
    $scope.fileInputUploadFiles = () ->
      $scope.uploadFiles($scope.fileInput.files)
    $scope.uploadFiles = (files) ->
      files = files or $scope.fileInput.files
      if not $scope.multipleSelect and $scope.uploaders.length > 0
        return
      for file in files
        uploader = new S3FileUploader(file,
          onProgress: -> _.defer(-> $scope.$apply())
          onFinished: -> _.defer(-> $scope.$apply())
          onError: (status) ->
            if status?
              console.log(status)
            _.defer(-> $scope.$apply())
        )
        $scope.uploaders.push(uploader)
        uploader.start()
      resetFileInput()
