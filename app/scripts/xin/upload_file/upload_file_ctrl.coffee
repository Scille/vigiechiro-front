'use strict'


angular.module('xin_uploadFile', [])
  .controller 'UploadFileCtrl', ($scope, $timeout, Backend, S3FileUploader) ->
    $scope.uploaders = []
    $scope.s3Upload = ->
      for file in $scope.fileInput.files
        s3Upload = new S3FileUploader()
        s3Upload.onProgress = (percent, status) ->
          $timeout(-> $scope.$apply())
        $scope.uploaders.push(s3Upload)
        s3Upload.start(file)

  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileCtrl'
    link: (scope, elem, attrs) ->
      scope.fileInput = elem.find('.files-input')[0]

  .directive 'customOnChange', () ->
    restrict: "A"
    link: (scope, element, attrs) ->
      onChangeFunc = element.scope()[attrs.customOnChange]
      element.bind('change', onChangeFunc)

  .service 'S3FileUploader', (Backend) ->
    class S3FileUploader
      constructor: () ->
        @fileName = undefined
        @progress = 0
      onFinished: () ->
        console.log 'base.onFinished()'
      _onProgress: (percent, status) ->
        @progress = percent
        console.log 'base.onProgress()', percent, status
        if @onProgress?
          @onProgress(percent, status)
      onError: (status) ->
        console.log 'base.onError()', status
      stop: ->
      pause: ->
      restart: ->
      start: (file) ->
        @fileName = file.name
        @_onProgress(0, 'Upload started.')
        # Call the backend to get back a signed S3 url
        payload =
          mime: file.type
        Backend.one('fichiers').post('s3', payload).then(
          (response) =>
            console.log(response)
            @uploadToS3(file,response.signed_request)
          (error) -> throw error
        )

      # Use a CORS call to upload the given file to S3. Assumes the url
      # parameter has been signed and is accessible for upload.
      uploadToS3: (file, url) ->
        this_s3upload = this
        xhr = @createCORSRequest('PUT', url)
        if !xhr
          @onError 'CORS not supported'
        else
          xhr.onload = ->
            if xhr.status == 200
              this_s3upload._onProgress 100, 'Upload completed.'
              this_s3upload.onFinished()
            else
              this_s3upload.onError 'Upload error: ' + xhr.status
          xhr.onerror = ->
            this_s3upload.onError 'XHR error.'
          xhr.upload.onprogress = (e) ->
            if e.lengthComputable
              percentLoaded = Math.round (e.loaded / e.total) * 100
              this_s3upload._onProgress percentLoaded, if percentLoaded == 100 then 'Finalizing.' else 'Uploading.'
        xhr.setRequestHeader('Content-Type', file.type)
        xhr.setRequestHeader('x-amz-acl', 'public-read')
        xhr.send(file)

      createCORSRequest: (method, url) ->
        xhr = new XMLHttpRequest()
        if xhr.withCredentials?
          xhr.open method, url, true
        else if typeof XDomainRequest != "undefined"
          xhr = new XDomainRequest()
          xhr.open method, url
        else
          xhr = null
        xhr
