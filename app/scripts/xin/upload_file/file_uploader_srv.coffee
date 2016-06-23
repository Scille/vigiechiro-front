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
        @nb_success = 0
        @validating = 0
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
        if not @queuedFiles.length and not @processingFiles.length and not @validating
          @status = 'finish'
        else
          while @queuedFiles.length and
                (@processingFiles.length+@validating) < @parallelUploads
            @validating += 1
            file = @queuedFiles.shift()
            file =
              data: file
              type: file.type
              name: file.name
              fullPath: file.fullPath
              status: "accepting"
              bytesSent: 0
            @_accept(file)

      _accept: (file) ->
        _acceptCallback = (error_type = null, error = null) =>
          if error?
            file.message = error
            if error_type == "error"
              @errorFiles.push(file)
            else
              @warningFiles.push(file)
            @validating += -1
            @_checkQueuedFiles()
          else
            @processingFiles.push(file)
            @validating += -1
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
        @complete?(file)


      _errorProcessing: (file, xhr) ->
        error = xhr
        @removeFile(file, error)


      _onProgress: (file, e) ->
        @transmitted_size += e.loaded - file.bytesSent
        file.bytesSent = e.loaded
        @_computeSpeed()
        @progressing?()


      _computeSpeed: ->
        time = new Date()
        diffTime = (time - @start_time) / 1000
        if diffTime < 4
          return
        @start_time = time
        @speed = @transmitted_size / diffTime
        @transmitted_size = 0


      removeFile: (file, error = null) ->
        for processFile, i in @processingFiles
          if processFile? and file.fullPath == processFile.fullPath
            @processingFiles.splice(i, 1)
        if error?
          @errorFiles.push(file)
        else
          @nb_success += 1
        @_checkQueuedFiles()


      getNbFiles: ->
        result = @nb_success +
                 @validating +
                 @queuedFiles.length +
                 @processingFiles.length +
                 @warningFiles.length +
                 @errorFiles.length
        return result


      startAll: ->
        console.log("TODO")


      pauseAll: ->
        console.log("TODO")


      cancelAll: ->
        console.log("TODO")
