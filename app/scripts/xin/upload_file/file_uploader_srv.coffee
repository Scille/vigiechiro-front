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
        @parallelUploads = config.parallelUploads or 5
        @checkFile = config.checkFile or null
        @nb_success = 0 # used by progressbar
        @nb_warning = 0 # used by progressbar
        @nb_failure = 0 # used by progressbar
        @nb_waiting = 0 # used by progressbar
        @nb_total = 0 # used by progressbar
        @nb_not_unique = 0 # used by message warning
        @queuedFiles = [] # waiting files
        @processingFiles = [] # files uploading
        @warningFiles = []
        @errorFiles = []
        @start_time = 0
        @transmitted_size = 0
        @speed = 0

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
        @nb_total++
        @nb_waiting++
        @_checkQueuedFiles()

      _checkQueuedFiles: ->
        if not @queuedFiles.length and not @processingFiles.length
          @status = 'finish'
        else
          while @queuedFiles.length and
                (@processingFiles.length) < @parallelUploads
            file = @queuedFiles.shift()
            file =
              data: file
              type: file.type
              name: file.name
              fullPath: file.fullPath
              status: "accepting"
              bytesSent: 0
            @checkFile(file)


      startAll: ->
        console.log("TODO")


      pauseAll: ->
        console.log("TODO")


      cancelAll: ->
        console.log("TODO")
