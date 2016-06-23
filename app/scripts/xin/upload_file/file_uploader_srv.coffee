'use strict'


angular.module('xin.fileUploader', [])
  .factory 'Uploader', ($http, Backend) ->
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
        @progressing = config.progressing or null
        @complete = config.complete or null
        @queuedFiles = []
        @processingFiles = []
        @warningFiles = []
        @errorFiles = []
        @start_time = 0
        @transmitted_size = 0
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
              bytesSent: 0
            @processingFiles.push(file)
            @_accept(file)

      _accept: (file) ->
        _acceptCallback = (error_type = null, error = null) =>
          if error?
            for processFile, i in @processingFiles
              if file.fullPath == processFile.fullPath
                @processingFiles.splice(i, 1)
                file.message = error
                if error_type == "error"
                  @errorFiles.push(file)
                else
                  @warningFiles.push(file)
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
        xhr.onload = (e) =>
          return unless xhr.readyState is 4
          if xhr.status in [200, 204]
            @_finished file, xhr
          else
            @_errorProcessing file, xhr
        xhr.onerror = ->
          @_errorProcessing file
        # Some browser do not have the .upload property
        progressObj = xhr.upload ? xhr
        progressObj.onprogress = (e) =>
          @_onProgress file, e
        xhr.setRequestHeader('Content-Encoding', 'gzip')
        formData.append('file', file.data, file.name)
        xhr.send(formData)


      _finished: (file, xhr) ->
        for processFile, i in @processingFiles
          if file.fullPath == processFile.fullPath
            @processingFiles.splice(i, 1)
        @_checkQueuedFiles()
        @complete?(file)


      _errorProcessing: (file, xhr) ->
        console.log("TODO")
        console.log(file)
        @_checkQueuedFiles()


      _onProgress: (file, e) ->
        @transmitted_size = e.loaded - file.bytesSent
        file.bytesSent = e.loaded
        @_computeSpeed()


      _computeSpeed: ->
        time = new Date()
        diffTime = (time - @start_time) / 1000
        if diffTime < 2
          return
        @_startTime = time
        @speed = @transmitted_size / diffTime
        @transmitted_size = 0
        @progressing?()


      startAll: ->
        console.log("TODO")


      pauseAll: ->
        console.log("TODO")


      cancelAll: ->
        console.log("TODO")

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
