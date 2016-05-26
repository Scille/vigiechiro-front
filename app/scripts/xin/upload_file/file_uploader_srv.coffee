'use strict'


angular.module('xin.fileUploader', [])
  .factory 'Uploader', ($interval, $http, Backend) ->
    class Uploader
      constructor: (elem, config) ->
        self = this
        # dragzone
        overClass = "drag-over"
        elem.addEventListener('dragover',
          (e) ->
            e.preventDefault()
            elem.classList.add(overClass)
          false
        )
        elem.addEventListener('dragleave',
          (e) ->
            e.preventDefault()
            elem.classList.remove(overClass)
          false
        )
        onDrop = (e) =>
          e.preventDefault()
          elem.classList.remove(overClass)
          files = e.dataTransfer.files
          if files.length
            items = e.dataTransfer.items
            if items and items.length and (items[0].webkitGetAsEntry?)
              # The browser supports dropping of folders, so handle items instead of files
              @_addFilesFromItems items
            else
              @addFiles files
        elem.addEventListener('drop', onDrop)

        # input
        input = elem.children[0]
        onClick = ->
          input.click()
        elem.addEventListener("click", onClick)
        onChange = ->
          self.addFiles(this.files)
        input.addEventListener("change", onChange)

        # configuration
        @status = "inactive"
        @url = config.url
        @method = config.method or "post"
        @parallelUploads = config.parallelUploads or 5
        @accept = config.accept or null
        @sending = config.sending or null
        @complete = config.complete or null
        @queuedFiles = []
        @processingFiles = []
        @speed = 0
        # @_init()


      _addFilesFromItems: (items) ->
        for item in items
          if item.webkitGetAsEntry? and entry = item.webkitGetAsEntry()
            if entry.isFile
              @addFile item.getAsFile()
            else if entry.isDirectory
              # Append all files from that directory to files
              @_addFilesFromDirectory entry, entry.name
          else if item.getAsFile?
            if not item.kind? or item.kind == "file"
              @addFile item.getAsFile()


      _addFilesFromDirectory: (directory, path) ->
        dirReader = directory.createReader()
        errorHandler = (error) -> console.log(error)
        readEntries = =>
          dirReader.readEntries (entries) =>
            if entries.length > 0
              for entry in entries
                if entry.isFile
                  entry.file (file) =>
                    file.fullPath = "#{path}/#{file.name}"
                    @addFile file
                else if entry.isDirectory
                  @_addFilesFromDirectory entry, "#{path}/#{entry.name}"
              readEntries()
            return
          , errorHandler
        readEntries()


      addFiles: (files) ->
        for file in files
          @addFile(file)

      addFile: (file) ->
        @status = 'active'
        @queuedFiles.push(file)
        @_checkQueuedFiles()

      _checkQueuedFiles: ->
        if not @queuedFiles.length and not @processingFiles.length
          @status = 'inactive'
        else
          while @queuedFiles.length and @processingFiles.length < @parallelUploads
            file = @queuedFiles.shift()
            file =
              data: file
              type: file.type
              name: file.name
              fullPath: file.fullPath
              status: "accepting"
            @processingFiles.push(file)
            @_accept(file)

      _accept: (file) ->
        _acceptCallback = (error = null) =>
          if error?
            for processFile, i in @processingFiles
              if file.fullPath == processFile.fullPath
                @processingFiles.splice(i, 1)
                break
            @_checkQueuedFiles()
          else
            @_sending(file)
        @accept(file, _acceptCallback)


      _sending: (file) ->
        formData = new FormData()
        @sending(file, formData)
        xhr = new XMLHttpRequest()
        xhr.open(@method, @url, true)
        xhr.onload = ->
          if xhr.status == 200
            console.log("Success", xhr)
            # callbacks.onSuccess?(xhr)
          else
            console.log("Error", xhr)
            # callbacks.onError?('Upload error: ' + xhr.status)
        xhr.onerror = ->
          console.log("Error")
          # callbacks.onError?('XHR error.')
        # Some browser do not have the .upload property
        progressObj = xhr.upload ? xhr
        progressObj.onprogress = (e) ->
          console.log("onprogress", e)
          # if e.lengthComputable
          #   callbacks.onProgress?(e.loaded, e.total)
        # for key, value of headers
        #   xhr.setRequestHeader(key, value)
        formData.append('file', file.data, file.name)
        xhr.send(formData)


      # _checkUploader: =>
      #   if @status in ['pause', 'cancel']
      #     return
      #   @_uploadStart()
      #   @_computeSize()
      #   @_computeSpeed()
      #
      # _checkWaiting: ->
      #   if @_isCheckingWaiting or @status in ['pause']
      #     return
      #   @_isCheckingWaiting = true
      #   count = @itemsWaitingFilters.length
      #   for i in [0..count-1] when count > 0
      #     file = @itemsWaitingFilters.shift()
      #     if @_checkFilters(file)
      #       if @gzip
      #         @itemsReadyToCompress.push(file)
      #       else
      #         @_createS3File(file)
      #   @_isCheckingWaiting = false
      #
      #
      # _computeSize: ->
      #   if @_isCheckingSize
      #     return
      #   @_isCheckingSize = true
      #   size = @_sizeUpload
      #   for file in @itemsUploading
      #     size += file.file.size
      #   for file in @itemsWaitingUpload
      #     size += file.file.size
      #   @size = size
      #   @_isCheckingSize = false
      #
      #
      # _computeSpeed: ->
      #   time = new Date()
      #   diffTime = (time - @_startTime) / 1000
      #   @_startTime = time
      #   @speed = @_transmitted_size / diffTime
      #   @_transmitted_size = 0
      #
      #
      # _createGZipFile: (file, callback) ->
      #   @itemsCompressing++
      #   arrayBuffer = null
      #   fileReader = new FileReader()
      #   fileReader.onload = (e) =>
      #     arrayBuffer = e.target.result
      #     gzipFile = pako.gzip(arrayBuffer)
      #     blob = new Blob([gzipFile], {type: file.type})
      #     blob.name = file.name
      #     if blob.size == 0
      #       callback?(file)
      #     else
      #       callback?({file: blob, gzip: true})
      #   fileReader.readAsArrayBuffer(file)
      #
      #
      # _createS3File: (file, gzip, multipart, sliceSize) =>
      #   file.transmitted_size = 0
      #   file.sendingTryS3 = 0
      #   file.status = "ready"
      #   file = new S3FileUploader(file,
      #     onStart: (s3File) =>
      #       s3File.file.status = 'progress'
      #     onProgress: (s3File, transmitted_size) =>
      #       @_transmitted_size += (transmitted_size - s3File.file.transmitted_size)
      #       s3File.file.transmitted_size = transmitted_size
      #     onPause: (s3File) =>
      #       s3File.file.status = 'pause'
      #     onSuccess: (s3File) =>
      #       @_transmitted_size += (s3File.file.size - s3File.file.transmitted_size)
      #       Backend.one('fichiers', s3File.file.id).get().then (fileBackend) =>
      #         fileBackend.post().then () =>
      #           fileArray = @_removeFileUploading(s3File)
      #           if fileArray?
      #             @itemsUploaded.push(fileArray.file.name)
      #           @_uploadStart()
      #     onErrorBack: (s3File, status) =>
      #       s3File.file.status = 'failure'
      #       @_retryBackSending(s3File, status)
      #     onErrorXhr: (s3File, status) =>
      #       s3File.file.status = 'failure'
      #       @_retryS3Sending(s3File, status)
      #     onCancel: (s3File) =>
      #       @_removeFileUploading(s3File)
      #       @itemsCanceled.push({name: s3File.file.name})
      #     , gzip
      #   )
      #   file.multipart = multipart
      #   file.sliceSize = sliceSize
      #   return file
      #
      #
      # _filter: ->
      #   @status = "Vérification du format des noms de fichier."
      #   @refresh?()
      #   while @itemsWaitingFilters.length
      #     file = @itemsWaitingFilters.pop()
      #     pass = true
      #     for filter in @filters
      #       if not filter.fn(file)
      #         @_onFilterError(file, filter)
      #         pass = false
      #     if pass
      #       @itemsFiltered.push(file)
      #   @_compress()
      #
      #
      # _start: ->
      #   @_filter()
      #
      # _startUpload: (file) ->
      #   file.start()
      #   @itemsUploading.push(file)
      #
      #
      # _removeFileUploading: (file) ->
      #   for item, index in @itemsUploading
      #     if item.file.name == file.file.name
      #       return @itemsUploading.splice(index, 1)[0]
      #
      #
      # _retryS3Sending: (s3File, status) ->
      #   if s3File.file.sendingTryS3 < 2
      #     s3File.file.sendingTryS3++
      #     @_checkWarningUpload(s3File.file.name, s3File.file.sendingTryS3)
      #     s3File.file.status = 'ready'
      #     s3File.file.transmitted_size = 0
      #     s3File.start()
      #   else
      #     @_onError(s3File)
      #
      # _onError: (item) ->
      #   @_checkWarningUpload(item.file.name)
      #   item = @_removeFileUploading(item)
      #   if item? and item.length
      #     @itemsFailedUpload.push(item[0])
      #   @_checkReadyToCompress()
      #   @_uploadWaiting()
      #
      # _checkWarningUpload: (name, count = 0) ->
      #   warning =
      #     name: name
      #     count: count
      #   length = @warningsXfails.length-1
      #   for i in [0..length] when length >= 0
      #     item = @warningsXfails[i]
      #     if item.name == name
      #       @warningsXfails.splice(i, 1)
      #       break
      #   if count
      #     @warningsXfails.push(warning)
      #
      #
      # pauseAll: ->
      #   @status = 'pause'
      #   for file in @itemsUploading
      #     file.pause()
      #
      # cancelAll: ->
      #   @status = 'cancel'
      #   for file in @itemsUploading
      #     if file?
      #       file.cancel()
      #   @init()
      #   @onCancelAllComplete?()
      #
      # clearErrors: ->
      #   @itemsFailed = []
      #
      #
      # _onFilterError: (item, filter) ->
      #   if filter.name == "Sous-dossiers ignorés."
      #     split = item.webkitRelativePath.split("/")
      #     nameDirectory = "."
      #     for i in [0..split.length-2]
      #       nameDirectory += "/"+split[i]
      #     text = "Le dossier "+nameDirectory+" a été ignoré. "+
      #            filter.name
      #   else
      #     text = "Le fichier "+item.name+" n'a pas pu être ajouté à la liste. "+
      #            filter.name
      #   @itemsFailed.push(text)
      #   @refresh?()
      #
      #
      # retryErrors: ->
      #   for item in @itemsFailedUpload or []
      #     item.file.sendingTryS3 = 0
      #   @itemsReadyToUp = @itemsReadyToUp.concat(@itemsFailedUpload)
      #   @itemsFailedUpload = []
      #   @_uploadWaiting()
      #
      #
      # startAll: ->
      #   @status = 'progress'
      #   for file in @itemsUploading
      #     file.start()
      #   @_checkUploader()
      #
      #
      # _upload: ->
      #   @status = "Upload des fichiers en cours."
      #   @refresh?()
      #   @itemsWaitingUpload = @itemsCompressed
      #   @itemsWaitingUploadLength = @itemsWaitingUpload.length
      #   @interval = $interval(@_checkUploader, 10000)
      #   @_uploadStart()
      #
      #
      # _uploadStart: ->
      #   while @itemsWaitingUpload.length and @itemsUploading.length < @connectionSpeed
      #     @_uploadBackend(@itemsWaitingUpload.pop())
      #   if not @itemsWaitingUpload.length and not @itemsUploading.length
      #     @status = "inactive"
      #     $interval.cancel(@interval)
      #     @allComplete?()
      #
      #
      # _uploadBackend: (file) ->
      #   if not file?
      #     return
      #   gzip = false
      #   if file.gzip? and file.gzip
      #     gzip = true
      #     file = file.file
      #   # 5Mo
      #   sliceSize = 5 * 1024 * 1024
      #   payload =
      #     mime: file.type
      #     titre: file.name
      #     multipart: false
      #     lien_participation: @lien_participation
      #   if file.size > sliceSize
      #     payload.multipart = true
      #   if payload.mime == ''
      #     ta = /\.ta$/
      #     tac = /\.tac$/
      #     if ta.test(payload.titre)
      #       payload.mime = 'application/ta'
      #     else if tac.test(payload.titre)
      #       payload.mime = 'application/tac'
      #
      #   s3File = @_createS3File(file, gzip, payload.multipart, sliceSize)
      #   @itemsUploading.push(s3File)
      #   Backend.all('fichiers').post(payload).then(
      #     (response) =>
      #       s3File.file.id = response._id
      #       s3File.file.etag = response._etag
      #       s3File.s3_signed_url = response.s3_signed_url
      #       s3File.start()
      #     (error) =>
      #       fileArray = @_removeFileUploading(s3File)
      #       if error.status == 422
      #         if error.data? and error.data._errors? and error.data._errors.s3_id?
      #           if error.data._errors.s3_id.search("is not unique") != -1
      #             @itemsWarning.push("Le fichier #{fileArray.file.name} existe déjà dans cette participation.")
      #             @_uploadStart()
      #             return
      #       @itemsFailed.push("Echec de l'insertion en base du fichier #{fileArray.file.name}.")
      #       @_uploadStart()
      #   )
