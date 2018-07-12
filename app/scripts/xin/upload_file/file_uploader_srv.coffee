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
            elem.classList.remove(overClass)
          false
        )
        onDrop = (e) ->
          e.preventDefault()
          elem.classList.remove(overClass)
          files = e.dataTransfer.files
          if files.length
            items = e.dataTransfer.items
            if items and items.length and (items[0].webkitGetAsEntry?)
              # The browser supports dropping of folders, so handle items instead of files
              self._addFilesFromItems(items)
            else
              self._addFiles(files)
        elem.addEventListener('drop', onDrop)

        # input
        input = elem.children[0]
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
        @successes = []
        @warnings = []
        @errors = []
        @_isCheckingTransmittedSize = false
        @transmittedSize = 0
        @_startTime = new Date()
        @_interval = $interval(@_computeSpeed, 3000)

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
            @transmittedSize += transmittedSize - s3File.file.transmittedSize
            s3File.file.transmittedSize = transmittedSize
          onPause: (s3File) =>
            s3File.file.status = 'pause'
          onSuccess: (s3File) =>
            @transmittedSize += s3File.file.data.size - s3File.file.transmittedSize
            @successes.push(s3File.file.name)
            delete @processingFiles[s3File.file.fullPath || s3File.file.name]
            @_checkQueuedFiles()
          onErrorBack: (s3File, status) =>
            @errors.push("#{s3File.file.name} : #{JSON.stringify(status.data._errors)}")
            delete @processingFiles[s3File.file.fullPath || s3File.file.name]
            @_checkQueuedFiles()
          onErrorS3: (s3File, status) =>
            console.error(status)
            @errors.push("#{s3File.file.name} : #{JSON.stringify(status.data._errors)}")
            delete @processingFiles[s3File.file.fullPath || s3File.file.name]
            @_checkQueuedFiles()
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

      _computeSpeed: =>
        now = new Date()
        diffTime = (now - @_startTime) / 1000
        @_startTime = now
        @speed = @transmittedSize / diffTime
        @transmittedSize = 0


      # _startUpload: (file) ->
      #   file.start()
      #   @itemsUploading.push(file)

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

      clearErrors: ->
        @warnings = []
        @errors = []

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
