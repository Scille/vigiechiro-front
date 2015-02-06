'use strict'


angular.module('xin_uploadFile', [])
  .directive 'customOnChange', () ->
    restrict: "A"
    link: (scope, element, attrs) ->
      onChangeFunc = element.scope()[attrs.customOnChange]
      element.bind('change', onChangeFunc)

  .controller 'UploadFileCtrl', ($scope, Backend, S3FileUploader) ->
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
      if not $scope.multiple and $scope.uploaders.length > 0
        return
      for file in files
        uploader = new S3FileUploader(file,
          onProgress: -> _.defer(-> $scope.$apply())
          onFinished: -> _.defer(-> $scope.$apply())
          onError: -> _.defer(-> $scope.$apply())
        )
        $scope.uploaders.push(uploader)
        uploader.start()
      resetFileInput()

  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileCtrl'
    scope:
      multiple: '@'
      uploaders: '=?'
    link: (scope, elem, attrs) ->
      scope.dragOverClass = ''
      if not attrs.uploaders?
        scope.uploaders = []
      drop = elem.find('.drop')
      input = drop.find('input')
      if attrs.multiple?
        input.attr('multiple', '')
        scope.multiple = true
      else
        scope.multiple = false
      scope.clickFileInput = ->
        _.defer(-> input.click())
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

  .service 'S3FileUploader', ($q, Backend) ->
    # Use a CORS call to upload the given file to S3. Assumes the url
    # parameter has been signed and is accessible for upload.
    uploadToS3 = (callbacks, verb, file, url, headers) ->
      xhr = new XMLHttpRequest()
      if xhr.withCredentials?
        xhr.open(verb, url, true)
      else if typeof XDomainRequest != "undefined"
        xhr = new XDomainRequest()
        xhr.open(verb, url)
      else
        callbacks.onError?('CORS not supported')
        return
      xhr.onload = ->
        if xhr.status == 200
          callbacks.onProgress?(100)
          callbacks.onFinished?(xhr)
        else
          callbacks.onError?('Upload error: ' + xhr.status)
      xhr.onerror = ->
        callbacks.onError?('XHR error.')
      xhr.upload.onprogress = (e) ->
        if e.lengthComputable
          percentLoaded = Math.round (e.loaded / e.total) * 100
          callbacks.onProgress?(percentLoaded)
      for key, value of headers or {}
        xhr.setRequestHeader(key, value)
      xhr.send(file)

    class S3FileUploader
      sliceSize: 5 * 1024 * 1024
      constructor: (file, @userCallbacks) ->
        @status = 'stalled'
        @file = file
        @id = undefined
        @progress = 0
        @_pause = $q.defer()
        @_bootstraped = false
        @_context = undefined
      _onFinished: () ->
        @progress = 100
        @status = 'done'
        @userCallbacks.onFinished?()
      _onProgress: (percent) ->
        @_pause.promise.then =>
          @progress = percent
          @userCallbacks.onProgress?(percent)
      _onError: (status) ->
        @userCallbacks.onError?(status)
      stop: ->
        @status = 'dead'
        @_pause = $q.defer()
        if @_context
          # Call backend to delete the corresponding resource
          Backend.all('fichiers').one(@_context.id).customDELETE('multipart/annuler').then(
            ->
            (error) -> throw error
          )
      pause: ->
        @status = 'pause'
        @_pause = $q.defer()
      start: () ->
        @status = 'started'
        @_pause.resolve()
        if not @_bootstraped
          @_bootstraped = true
          @_onProgress(0)
          # Call the backend to get back a signed S3 url
          if @file.size < @sliceSize
            @_startSingleUpload()
          else
            @_startMultiPartUpload()
      _startMultiPartUpload: () ->
        payload =
          mime: @file.type
          titre: @file.name
        # Create the file in the backend
        Backend.one('fichiers').post('s3/multipart', payload).then(
          (response) =>
            @id = response._id
            @_context =
              id: response._id
              part_number: 1
              transmitted_size: 0
              file: @file
              parts: []
            @_continueMultiPartUpload()
          (error) -> throw error
        )
      _continueMultiPartUpload: () ->
        @_pause.promise.then =>
          fileBackend = Backend.all('fichiers').one(@_context.id)
          start = (@_context.part_number - 1) * @sliceSize
          end = start + @sliceSize
          slice = @_context.file.slice(start, end)
          if slice.size == 0
            # No more elements to send, finalize the upload
            fileBackend.one('multipart', 'terminer').customPUT({parts: @_context.parts}).then(
              => @_onFinished()
              (e) => @_onError(e)
            )
            return
          # Call backend to get signed part request
          fileBackend.oneUrl('multipart/continue').customPUT({part_number: @_context.part_number}).then(
            (response) =>
              lastSlicePercent = 0
              callbacks =
                onProgress: (slicePercent) =>
                  @_context.transmitted_size += slice.size * (slicePercent - lastSlicePercent) / 100
                  lastSlicePercent = slicePercent
                  percentLoaded = Math.round(@_context.transmitted_size / @_context.file.size * 100)
                  @_onProgress?(percentLoaded)
                onFinished: (request) =>
                  @_context.parts.push(
                    part_number: @_context.part_number
                    etag: request.getResponseHeader("ETag")
                  )
                  @_context.part_number += 1
                  @_continueMultiPartUpload(@_context)
              uploadToS3(callbacks, 'PUT', slice, response.signed_request)
            (error) -> throw error
          )
      _startSingleUpload: () ->
        payload =
          mime: @file.type
          titre: @file.name
        callbacks =
          onError: (error) => @_onError(error)
          onProgress: (percent) => @_onProgress(percent)
          onFinished: => @_onFinished()
        Backend.one('fichiers').post('s3', payload).then(
          (response) =>
            @id = response._id
            uploadToS3(callbacks, 'PUT', @file, response.signed_request, {'Content-Type': @file.type})
          (error) -> throw error
        )
