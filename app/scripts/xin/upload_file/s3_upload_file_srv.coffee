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
      constructor: (file, @userCallbacks, @_gzip = false) ->
        @file = file
        @_pause = $q.defer()
        @_context = null
        @multipart = false
        @sliceSize = 0
        @s3_signed_url = ""

      _onSuccess: () ->
        @userCallbacks.onSuccess?(this)
      _onProgress: (loaded, total) ->
        @_pause.promise.then =>
          @userCallbacks.onProgress?(this, loaded)
      cancel: ->
        @_pause = $q.defer()
# TODO
#        if @_context
          # Call backend to delete the corresponding resource
#          Backend.all('fichiers').one(@_context.id).customDELETE('multipart/annuler').then(
#            -> @userCallbacks.cancel?(this)
#            (error) -> throw error
#          )
#          Backend.all('fichiers').one(@_context.id).remove().then(
#            -> @userCallbacks.cancel?(this)
#            (error) -> console.log(error)
#          )
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
          @_onProgress(0, @file.size)
          # Call the backend to get back a signed S3 url
          if @multipart
            @file._context =
              id: @file.id
              part_number: 1
              transmitted_size: 0
              file: @file
              parts: []
            @_startMultiPartUpload()
          else
            @_startSingleUpload()
          @userCallbacks.onStart?(this)


      _startMultiPartUpload: () ->
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
                onError: (error) => @_onErrorXhr(error)
              headers = {}
              if @_gzip
                headers["Content-Encoding"] = "gzip"
              uploadToS3(callbacks, 'PUT', slice, response.s3_signed_url, headers)
            (error) -> throw error
          )

      _startSingleUpload: ->
        callbacks =
          onError: (error) => @userCallbacks.onErrorXhr?(this, error)
          onProgress: (loaded, total) => @userCallbacks.onProgress?(this, loaded)
          onSuccess: => @userCallbacks.onSuccess?(this)

        contentType = @file.type
        if contentType == ''
          ta = /\.ta$/
          tac = /\.tac$/
          if ta.test(@file.name)
            contentType = 'application/ta'
          else if tac.test(@file.name)
            contentType = 'application/tac'
        headers =
          'Content-Type': contentType
        if @_gzip
          headers["Content-Encoding"] = "gzip"
        uploadToS3(callbacks, 'PUT', @file, @s3_signed_url, headers)
