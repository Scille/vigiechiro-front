'use strict'


angular.module('xin_s3uploadFile', ['appSettings'])
  .directive 'customOnChange', () ->
    restrict: "A"
    link: (scope, element, attrs) ->
      onChangeFunc = element.scope()[attrs.customOnChange]
      element.bind('change', onChangeFunc)


  .directive 'accessFileDirective', (SETTINGS, Backend) ->
    restrict: 'E'
    template: '<button class="btn btn-primary" ng-click="accessFile()">{{file.titre}}</button>'
    scope:
      file: '='
    link: (scope, elem, attrs) ->
      if scope.file.disponible? and scope.file.s3_id?
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
          callbacks.onProgress?(e.loaded, e.total)
      for key, value of headers or {}
        xhr.setRequestHeader(key, value)
      xhr.send(file)

    class S3FileUploader
      # 5Mo
      sliceSize: 5 * 1024 * 1024
      constructor: (file, @userCallbacks) ->
        @status = 'stalled'
        @file = file
        @id = undefined
        @progress = 0
        @transmitted_size = 0
        @_pause = $q.defer()
        @_bootstraped = false
        @_context = undefined
      _onFinished: () ->
        @progress = 100
        @status = 'done'
        @userCallbacks.onFinished?()
      _onProgress: (loaded, total) ->
        @_pause.promise.then =>
          @transmitted_size = loaded
          @progress = Math.round (loaded / total) * 100
          @userCallbacks.onProgress?(loaded, total)
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
          multipart: true
        # Create the file in the backend
        Backend.all('fichiers').post(payload).then(
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
            payload =
              parts: @_context.parts
            fileBackend.customPOST(payload).then(
              => @_onFinished()
              (e) => @_onError(e)
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
                onFinished: (request) =>
                  @_context.parts.push(
                    part_number: @_context.part_number
                    etag: request.getResponseHeader("ETag")
                  )
                  @_context.part_number += 1
                  @_continueMultiPartUpload(@_context)
              uploadToS3(callbacks, 'PUT', slice, response.s3_signed_url)
            (error) -> throw error
          )
      _startSingleUpload: () ->
        payload =
          mime: @file.type
          titre: @file.name
          multipart: false
        callbacks =
          onError: (error) => @_onError(error)
          onProgress: (percent) => @_onProgress(percent)
          onFinished: =>
            Backend.one('fichiers', @id).get().then (fileBackend) =>
              fileBackend.post().then(
                =>  @_onFinished()
                (error) -> throw error
              )
        Backend.all('fichiers').post(payload).then(
          (response) =>
            etag = response._etag
            @id = response._id
            uploadToS3(callbacks, 'PUT', @file, response.s3_signed_url, {'Content-Type': @file.type})
          (error) -> throw error
        )
