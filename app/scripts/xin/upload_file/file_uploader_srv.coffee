'use strict'


angular.module('xin.fileUploader', ['xin_s3uploadFile', 'appSettings'])
  .factory 'Uploader', ($interval, $http, Backend, S3FileUploader, SETTINGS) ->
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
            elem.removeClass(attrs.overClass)
          false
        )
        onDrop: (e) ->
          e.preventDefault()
          elem.removeClass(attrs.overClass)
          files = e.dataTransfer.files
          if files.length
            items = e.dataTransfer.items
            if items and items.length and (items[0].webkitGetAsEntry?)
              # The browser supports dropping of folders, so handle items instead of files
              @_addFilesFromItems(items)
            else
              @_addFiles(files)
        elem.addEventListener('drop', this.onDrop)

        # input
        input = elem.children[0]
        # onClick = ->
        #   input.click()
        onChange = ->
          self._addFiles(this.files)
        input.addEventListener('change', onChange)

        # configuration
        @status = 'inactive'
        @parallelUploads = config.parallelUploads or 5
        @accept = config.accept
        @sending = config.sending
        @complete = config.complete
        @refreshScope = config.refreshScope
        @participationId = config.participationId
        @queuedFiles = []
        @processingFiles = {}
        @speed = 0
        @warnings = []
        @errors = []
        @_isCheckingTransmittedSize = false
        # @filters = []
        # @init()
        # @interval = $interval(@_checkUploader, 10000)
        # @status = 'progress'

      init: ->
      #   # list of uploaded directories
      #   @directories = []
      #   # list of warning texts
      #   @warnings = []
      #   # Number of total item
      #   @itemsTotal = 0
      #   # list of files id completed
      #   @itemsCompleted = []
      #   # list of files uploading
      #   @itemsUploading = []
      #   # list of file waiting to upload
      #   @itemsReadyToUp = []
      #   # Number of files compressing
      #   @itemsCompressing = 0
      #   # list of files waiting to compress
      #   @itemsReadyToCompress = []
      #   # list of item waiting to filter
      #   @_isCheckingUploader = false
      #   @_isCheckingWaiting = false
      #   @_isCheckingReadyToCompress = false
      #   @_isCheckingReadyToUp = false
        # @_isCheckingTransmittedSize = false
      #   @_isCheckingSize = false
      #   @_isCheckingItemsCount = false
      #   @size = 0
      #   @_sizeUpload = 0
      #   @transmitted_size = 0
      #   @_transmittedSizePrevious = 0
      #   @speed = 0
      #   @_startTime = 0

      _addFilesFromItems: (items) ->
        for item in items
          if item.webkitGetAsEntry? and entry = item.webkitGetAsEntry()
            if entry.isFile
              @_addFile(item.getAsFile())
            else if entry.isDirectory
              # Append all files from that directory to files
              @_addFilesFromDirectory(entry, entry.name)
          else if item.getAsFile?
            if not item.kind? or item.kind == "file"
              @_addFile(item.getAsFile())

      _addFilesFromDirectory: (directory, path) ->
        dirReader = directory.createReader()
        errorHandler = (error) -> console.log(error)
        readEntries = =>
          dirReader.readEntries(
            (entries) =>
              if entries.length > 0
                for entry in entries
                  if entry.isFile
                    entry.file(
                      (file) =>
                        file.fullPath = "#{path}/#{file.name}"
                        @_addFile(file)
                    )
                  else if entry.isDirectory
                    @_addFilesFromDirectory(entry, "#{path}/#{entry.name}")
                readEntries()
              # return
            errorHandler
          )
        readEntries()

      _addFiles: (files) ->
        for file in files
          @_addFile(file)

      _addFile: (file) ->
        @status = 'active'
        @queuedFiles.push(file)
        @_checkQueuedFiles()

      _checkQueuedFiles: ->
        if not @queuedFiles.length and not Object.keys(@processingFiles).length
          @status = 'inactive'
        else
          while @queuedFiles.length and Object.keys(@processingFiles).length < @parallelUploads
            file = @queuedFiles.shift()
            file =
              data: file
              type: file.type
              name: file.name
              fullPath: file.fullPath
              status: "ready"
              gzip: true
              transmittedSize: 0
            @processingFiles[file.fullPath || file.name] = file
            @refreshScope()
            @_accept(file)

      _accept: (file) ->
        _acceptCallback = (error = null) =>
          if error?
            delete @processingFiles[file.fullPath || file.name]
            @refreshScope()
            @_checkQueuedFiles()
          else
            @_sending(file)
        @accept(file, _acceptCallback)

      _sending: (file) ->
        file = new S3FileUploader(@participationId, file, {
          onStart: (s3File) =>
            s3File.file.status = 'progress'
          onProgress: (s3File, transmittedSize) =>
            s3File.file.transmittedSize = transmittedSize
            @_computeTransmittedSize()
          onPause: (s3File) =>
            s3File.file.status = 'pause'
          onSuccess: (s3File) =>
            @_onSuccess(s3File)
          onErrorBack: (s3File, status) =>
            s3File.file.status = 'failure'
            @_retryBackSending(s3File, status)
          onErrorS3: (s3File, status) =>
            s3File.file.status = 'failure'
            @_retryS3Sending(s3File, status)
          onCancel: (s3File) =>
            @_removeFileUploading(s3File)
            @itemsCanceled.push({name: s3File.file.name})
        })
        file.start()



      # _checkUploader: =>
      #   if @_isCheckingUploader or @status in ['pause', 'cancel']
      #     return
      #   @_isCheckingUploader = true
      #   @_checkWaiting()
      #   @_checkReadyToCompress()
      #   @_checkReadyToUp()
      #   @_computeItems()
      #   @_computeSize()
      #   @_computeSpeed()
      #   @_isCheckingUploader = false

      # _computeSpeed: ->
      #   time = new Date()
      #   diffTime = (time - @_startTime) / 1000
      #   diffSize = @transmitted_size - @_transmittedSizePrevious
      #   @_startTime = time
      #   @_transmittedSizePrevious = @transmitted_size
      #   @speed = diffSize / diffTime

      # _checkWaiting: ->
      #   if @_isCheckingWaiting or @status in ['pause']
      #     return
      #   @_isCheckingWaiting = true
      #   count = @itemsWaiting.length
      #   for i in [0..count-1] when count > 0
      #     file = @itemsWaiting.shift()
      #     if @_checkFilters(file)
      #       @itemsReadyToCompress.push(file)
      #   @_isCheckingWaiting = false

      # _createS3File: (file, gzip = false) =>
      #   if file.size == 0
      #     @itemsFailedCompress.push(file.name)
      #     return
      #   file.status = 'ready'
      #   file.transmitted_size = 0
      #   file.sendingTryS3 = 0
      #   file.sendingTryBack = 0
      #   file = new S3FileUploader(file,
      #     onStart: (s3File) =>
      #       s3File.file.status = 'progress'
      #     onProgress: (s3File, transmitted_size) =>
      #       s3File.file.transmitted_size = transmitted_size
      #       @_computeTransmittedSize()
      #     onPause: (s3File) =>
      #       s3File.file.status = 'pause'
      #     onSuccess: (s3File) =>
      #       @_onSuccess(s3File)
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
      #   @itemsReadyToUp.push(file)

      # _onSuccess: (item) ->
      #   fileArray = @_removeFileUploading(item)
      #   if not fileArray?
      #     return
      #   @_sizeUpload += item.file.size
      #   @itemsCompleted.push(item.file.id)
      #   @_checkReadyToCompress()
      #   @_checkReadyToUp()

      # _startUpload: (file) ->
      #   file.start()
      #   @itemsUploading.push(file)

      # _removeFileUploading: (file) ->
      #   for item, index in @itemsUploading
      #     if item.file.name == file.file.name
      #       return @itemsUploading.splice(index, 1)

      # _computeItems: ->
      #   if @_isCheckingItemsCount
      #     return
      #   @_isCheckingItemsCount = true
      #   total = 0
      #   total += @itemsCompleted.length
      #   total += @itemsUploading.length
      #   total += @itemsReadyToUp.length
      #   total += @itemsCompressing
      #   total += @itemsReadyToCompress.length
      #   total += @itemsWaiting.length
      #   total += @itemsFailedFilters.length
      #   total += @itemsFailedUpload.length
      #   @itemsTotal = total
      #   @_isCheckingItemsCount = false

      # _computeSize: ->
      #   if @_isCheckingSize
      #     return
      #   @_isCheckingSize = true
      #   size = @_sizeUpload
      #   for file in @itemsUploading
      #     size += file.file.size
      #   for file in @itemsReadyToUp
      #     size += file.file.size
      #   @size = size
      #   @_isCheckingSize = false

      # _computeTransmittedSize: ->
      #   if @_isCheckingTransmittedSize
      #     return
      #   @_isCheckingTransmittedSize = true
      #   transmitted_size = @_sizeUpload
      #   for file in @itemsUploading
      #     transmitted_size += file.file.transmitted_size
      #   @transmitted_size = transmitted_size
      #   @_isCheckingTransmittedSize = false

      # _retryBackSending: (s3File, status) ->
      #   if s3File.file.sendingTryBack < 2
      #     s3File.file.sendingTryBack++
      #     s3File.file.status = 'ready'
      #     s3File.file.transmitted_size = 0
      #     s3File.start()
      #   else
      #     @_onError(s3File)

      # _retryS3Sending: (s3File, status) ->
      #   if s3File.file.sendingTryS3 < 2
      #     s3File.file.sendingTryS3++
      #     s3File.file.status = 'ready'
      #     s3File.file.transmitted_size = 0
      #     s3File.start()
      #   else
      #     @_onError(s3File)

      # _onError: (item) ->
      #   item = @_removeFileUploading(item)
      #   if item? and item.length
      #     @itemsFailedUpload.push(item[0])
      #   @_checkReadyToCompress()
      #   @_checkReadyToUp()

      # startAll: ->
      #   @status = 'progress'
      #   for file in @itemsUploading
      #     file.start()
      #   @_checkUploader()

      # pauseAll: ->
      #   @status = 'pause'
      #   for file in @itemsUploading
      #     file.pause()

      # cancelAll: ->
      #   @status = 'cancel'
      #   for file in @itemsUploading
      #     if file?
      #       file.cancel()
      #   @init()
      #   @onCancelAllComplete?()

      # clearErrors: ->
      #   @itemsFailedFilters = []
      #   @itemsFailedCompress = []
      #   @itemsFailedUpload = []
      #   @itemsCanceled = []
      #   @warningsXfails = []
      #   @_computeItems()

      # retryErrors: ->
      #   for item in @itemsFailedUpload or []
      #     item.file.sendingTryBack = 0
      #     item.file.sendingTryS3 = 0
      #   @itemsReadyToUp = @itemsReadyToUp.concat(@itemsFailedUpload)
      #   @itemsFailedUpload = []
      #   @_checkReadyToUp()

      # isAllComplete: ->
      #   count = @itemsCompleted.length + @itemsFailedUpload.length + @itemsFailedCompress.length + @itemsFailedFilters.length
      #   if count == @itemsTotal
      #     return true
      #   else
      #     return false

      # _onWhenAddingFileFailed: (item, filter) ->
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
      #   if @itemsFailedFilters.indexOf(text) == -1
      #     @itemsFailedFilters.push(text)
