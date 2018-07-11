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
          callbacks.onSuccess?(xhr)
        else
          callbacks.onError?('Upload error: ' + xhr.status)
      xhr.onerror = ->
        callbacks.onError?('XHR error.')
      xhr.upload.onprogress = (e) ->
        if e.lengthComputable
          callbacks.onProgress?(e.loaded, e.total)
      for key, value of headers or {}
        xhr.setRequestHeader(key, value)
      xhr.send(file)


    class S3FileUploader
      # 50 Mo
      sliceSize: 50 * 1024 * 1024
      constructor: (@participationId, file, @userCallbacks) ->
        @file = file
        @_pause = $q.defer()
        @_context = undefined

      _onSuccess: () ->
        @userCallbacks.onSuccess?(this)
      _onProgress: (loaded, total) ->
        @_pause.promise.then =>
          @userCallbacks.onProgress?(this, loaded)
      _onErrorBack: (status) ->
        @userCallbacks.onErrorBack?(this, status)
      _onErrorS3: (status) ->
        @userCallbacks.onErrorXhr?(this, status)
      cancel: ->
        @_pause = $q.defer()
        @userCallbacks.onCancel?(this)
      pause: ->
        @userCallbacks.onPause?(this)
        @_pause = $q.defer()

      retry: ->
        @file.status == 'ready'
        @file.transmitted_size = 0
        @start()

      start: ->
        @_pause.resolve()
        if @file.status == 'ready'
          # Call the backend to get back a signed S3 url
          if @file.data.size < @sliceSize
            @_startSingleUpload()
          else
            @_startMultiPartUpload()
          @userCallbacks.onStart?(this)
      _startMultiPartUpload: () ->
        payload =
          mime: @file.type
          titre: @file.name
          multipart: true
        # Create the file in the backend
        Backend.all('fichiers').post(payload).then(
          (response) =>
            @file.id = response._id
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
            payload =
              parts: @_context.parts
            fileBackend.customPOST(payload).then(
              => @_onSuccess()
              (e) => @_onErrorBack(e)
            )
            return
          # Call backend to get signed part request
          fileBackend.oneUrl('multipart').customPUT({part_number: @_context.part_number}).then(
            (response) =>
              lastSlicePercent = 0
              callbacks =
                onProgress: (loaded, total) =>
                  if not total?
                    return
                  slicePercent = Math.round (loaded / total) * 100
                  @_context.transmitted_size += slice.size * (slicePercent - lastSlicePercent) / 100
                  lastSlicePercent = slicePercent
                  @_onProgress?(@_context.transmitted_size, @_context.file.size)
                onSuccess: (request) =>
                  @_context.parts.push(
                    part_number: @_context.part_number
                    etag: request.getResponseHeader("ETag")
                  )
                  @_context.part_number += 1
                  @_continueMultiPartUpload(@_context)
                onError: (error) => @_onErrorS3(error)
              headers = {}
              if @_gzip
                headers["Content-Encoding"] = "gzip"
              uploadToS3(callbacks, 'PUT', slice, response.s3_signed_url, headers)
            (error) -> throw error
          )

      _startSingleUpload: () ->
        payload =
          mime: @file.type
          titre: @file.name
          multipart: false
          lien_participation: @participationId
        if payload.mime == ''
          if payload.titre.endsWith('.ta')
            payload.mime = 'application/ta'
          else if payload.titre.endsWith('.tac')
            payload.mime = 'application/tac'
        callbacks =
          onError: (error) => @_onErrorS3(error)
          onProgress: (loaded, total) => @_onProgress(loaded, total)
          onSuccess: =>
            Backend.one('fichiers', @file.id).get().then (fileBackend) =>
              fileBackend.post().then(
                =>  @_onSuccess()
                (error) => @_onErrorBack(error)
              )
        Backend.all('fichiers').post(payload).then(
          (response) =>
            # etag = response._etag
            @file.id = response._id
            contentType = @file.type
            if contentType == ''
              if @file.name.endsWith('.ta')
                contentType = 'application/ta'
              else if @file.name.endsWith('.tac')
                contentType = 'application/tac'
            headers =
              'Content-Type': contentType
            if @file.gzip
              headers["Content-Encoding"] = "gzip"
            console.log(response)
            uploadToS3(callbacks, 'PUT', @file, response.s3_signed_url, headers)
          (error) => @_onErrorBack(error)
        )

    # onSending = (file, formData) ->
    #   console.log(file)
    #   console.log(file.postData)
    #   formData.append('key', file.postData.s3_id)
    #   formData.append('acl', 'private')
    #   formData.append('AWSAccessKeyId', file.postData.s3_aws_access_key_id)
    #   formData.append('Policy', file.postData.s3_policy)
    #   formData.append('Signature', file.postData.s3_signature)
    #   formData.append('Content-Encoding', 'gzip')
    #   formData.append('Content-Type', file.type)

        # formData = new FormData()
        # # @sending(file, formData)
        # xhr = new XMLHttpRequest()
        # xhr.open(@method, @url, true)
        # xhr.onload = ->
        #   if xhr.status == 200
        #     console.log("Success", xhr)
        #     # callbacks.onSuccess?(xhr)
        #   else
        #     console.log("Error", xhr)
        #     # callbacks.onError?('Upload error: ' + xhr.status)
        # xhr.onerror = ->
        #   console.log("Error")
        #   # callbacks.onError?('XHR error.')
        # # Some browser do not have the .upload property
        # progressObj = xhr.upload ? xhr
        # progressObj.onprogress = (e) ->
        #   console.log("onprogress", e)
        #   # if e.lengthComputable
        #   #   callbacks.onProgress?(e.loaded, e.total)
        #   # for key, value of headers
        #   #   xhr.setRequestHeader(key, value)
        # formData.append('file', file.data, file.name)
        # xhr.send(formData)
