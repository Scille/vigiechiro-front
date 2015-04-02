'use strict'


angular.module('xin_uploadFolder', ['appSettings', 'xin_s3uploadFile'])
  .directive 'uploadFolderDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_folder.html'
    controller: 'UploadFolderController'
    scope:
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


  .controller 'UploadFolderController', ($scope, Backend, S3FileUploader) ->
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
      # Set folder uploader
      folderUploader =
        length: files.length
        name: files.item(0).webkitRelativePath.split("/", 1)[0]
        filesUploaded: 0
        uploaders: []
        progress: 0
        size: 0
        status: 'stalled'
        stop: ->
          @status = 'dead'
          for uploader in @uploaders
            if uploader.status in ['stalled', 'started', 'pause']
              uploader.stop()
        pause: ->
          @status = 'pause'
          for uploader in @uploaders
            if uploader.status == "started"
              uploader.pause()
        start: ->
          @status = 'started'
          for uploader in @uploaders
            if uploader.status in ['stalled', 'pause']
              uploader.start()
      for i in [0..files.length-1]
        file = files.item(i)
        uploader = new S3FileUploader(file,
          onProgress: () ->
            transmitted_size = 0
            for uploader in folderUploader.uploaders
              transmitted_size += uploader.transmitted_size
            percentLoaded = Math.round (transmitted_size / folderUploader.size) * 100
            folderUploader.progress = percentLoaded
            _.defer(-> $scope.$apply())
          onFinished: ->
            folderUploader.filesUploaded++
            if folderUploader.filesUploaded == folderUploader.length
              folderUploader.status = 'done'
            _.defer(-> $scope.$apply())
          onError: -> _.defer(-> $scope.$apply())
        )
        folderUploader.size += uploader.file.size
        folderUploader.uploaders.push(uploader)
      folderUploader.start()
      $scope.uploaders.push(folderUploader)
      resetFileInput()
