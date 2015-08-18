'use strict'


angular.module('xin.fileUploader', ['xin_s3uploadFile'])
  .directive 'fileOver', () ->
    restrict: 'A'
    scope:
      uploader: '=?'
      directory: '='
    link: (scope, elem, attrs) ->
      scope.$watch 'directory', (directory) ->
        if directory?
          elem[0].removeEventListener('dragover')
          elem[0].removeEventListener('dragleave')
        else
          if attrs.overClass? and attrs.overClass != ''
            elem[0].addEventListener('dragover',
              (e) ->
                e.preventDefault()
                elem.addClass(attrs.overClass)
              false
            )
            elem[0].addEventListener('dragleave',
              (e) ->
                elem.removeClass(attrs.overClass)
              false
            )

      elem[0].addEventListener('drop',
        (e) ->
          e.preventDefault()
          elem.removeClass(attrs.overClass)
          # Check if inputs are files or directories
          if not scope.uploader?
            console.log("Uploader not available")
            return
          files = []
          warnings = []
          length = e.dataTransfer.items.length
          for i in [0..length-1]
            entry = e.dataTransfer.items[i].webkitGetAsEntry()
            if (entry.isFile and not scope.directory?)
              files.push(e.dataTransfer.files[i])
            else if (entry.isDirectory and scope.directory?)
              console.log("Drop doesn't work for directories")
            else
              warnings.push(e.dataTransfer.files[i])
          scope.uploader.addFiles(files)
          scope.uploader.addWarnings(warnings)
        false
      )


  .directive 'fileSelect', () ->
    restrict: 'A'
    scope:
      uploader: '=?'
    link: (scope, elem, attrs) ->
      onChange = ->
        if not scope.uploader?
          console.log("Uploader not available")
          return
        files = []
        for file in this.files or []
          files.push(file)
        scope.uploader.addFiles(files)
        elem[0].value = ''
      elem.bind('change', onChange)


  .factory 'FileUploader', ($interval, S3FileUploader) ->
    class FileUploader
      constructor: (@_parallelUpload = 3) ->
        @filters = []
        @_parallelGZip = 4
        @_gzip = false
        @init()
        @interval = $interval(@_checkUploader, 5000)
        @status = 'ready'

      init: ->
        @directories = []
        @warnings = []
        @itemsTotal = 0
        @itemsCompleted = []
        @itemsUploading = []
        @itemsReadyToUp = []
        @itemsCompressing = 0
        @itemsReadyToCompress = []
        @itemsWaiting = []
        @itemsFailedFilters = []
        @itemsFailedUpload = []
        @itemsCanceled = []
        @warningsXfailsBack = []
        @warningsXfailsS3 = []
        @_isCheckingUploader = false
        @_isCheckingWaiting = false
        @_isCheckingReadyToCompress = false
        @_isCheckingReadyToUp = false
        @_isCheckingTransmittedSize = false
        @_isCheckingSize = false
        @_isCheckingItemsCount = false
        @size = 0
        @transmitted_size = 0
        @_transmittedSizePrevious = 0
        @speed = 0
        @_startTime = 0

      setGzip: ->
        @_gzip = true

      addFiles: (files) ->
        @status = 'progress'
        if files.length
          @itemsWaiting = @itemsWaiting.concat(files)
          @_checkUploader()

      _checkUploader: =>
        if @_isCheckingUploader or @status in ['pause', 'cancel']
          return
        @_isCheckingUploader = true
        @_checkWaiting()
        @_checkReadyToCompress()
        @_checkReadyToUp()
        @_checkUploading()
        @_computeItems()
        @_computeSize()
        @_computeSpeed()
        @_isCheckingUploader = false

      _computeSpeed: ->
        time = new Date()
        diffTime = (time - @_startTime) / 1000
        diffSize = @transmitted_size - @_transmittedSizePrevious
        @_startTime = time
        @_transmittedSizePrevious = @transmitted_size
        @speed = diffSize / diffTime

      _checkWaiting: ->
        if @_isCheckingWaiting or @status in ['pause']
          return
        @_isCheckingWaiting = true
        count = @itemsWaiting.length
        for i in [0..count-1] when count > 0
          file = @itemsWaiting.shift()
          if @_checkFilters(file)
            if @_gzip
              @itemsReadyToCompress.push(file)
            else
              @_createS3File(file)
        @_isCheckingWaiting = false

      _checkReadyToCompress: ->
        if @_isCheckingReadyToCompress or @status in ['pause']
          return
        @_isCheckingReadyToCompress = true
        count = @itemsReadyToCompress.length
        for i in [0..count-1] when count > 0
          if @itemsCompressing < @_parallelGZip
            file = @itemsReadyToCompress.shift()
            @_createGZipFile(file)
          else
            break
        @_isCheckingReadyToCompress = false

      _checkReadyToUp: ->
        if @_isCheckingReadyToUp or @status in ['pause']
          return
        @_isCheckingReadyToUp = true
        count = @itemsReadyToUp.length
        for i in [0..count-1] when count > 0
          if @itemsUploading.length < @_parallelUpload
            file = @itemsReadyToUp.shift()
            @_startUpload(file)
          else
            break
        @_isCheckingReadyToUp = false

      _checkUploading: ->
        count = @itemsUploading.length
        for i in [count-1..0] when count > 0
          item = @itemsUploading[i]
          if item.file.transmitted_size == item.file.size
            FileArray = @_removeFileUploading(item)
            if not FileArray?
              continue
            FileArray[0].file.status = 'success'
            @itemsCompleted.push(FileArray[0])
            @_checkReadyToUp()

      _checkFilters: (file) ->
        result = true
        for filter in @filters
          if not filter.fn(file)
            @_onWhenAddingFileFailed(file, filter)
            result = false
        return result

      _createGZipFile: (file) ->
        @itemsCompressing++
        arrayBuffer = null
        fileReader = new FileReader()
        fileReader.onload = (e) =>
          arrayBuffer = e.target.result
          gzipFile = pako.gzip(arrayBuffer)
          blob = new Blob([gzipFile], {type: file.type})
          blob.name = file.name
          @itemsCompressing--
          if @status in ['cancel']
            return
          else
            @_createS3File(blob)
            @_checkReadyToCompress()
            @_computeSize()
        fileReader.readAsArrayBuffer(file)

      _createS3File: (file) =>
        file.status = 'ready'
        file.transmitted_size = 0
        file.sendingTryS3 = 0
        file.sendingTryBack = 0
        file = new S3FileUploader(file,
          onStart: (s3File) =>
            s3File.file.status = 'progress'
            @_checkWarningUploadBack(s3File.file.name)
          onProgress: (s3File, transmitted_size) =>
            s3File.file.transmitted_size = transmitted_size
            @_computeTransmittedSize()
          onPause: (s3File) =>
            s3File.file.status = 'pause'
          onSuccess: (s3File) =>
            fileArray = @_removeFileUploading(s3File)
            if not fileArray?
              return
            fileArray[0].file.status = 'success'
            fileArray[0].file.transmitted_size = fileArray[0].file.size
            @itemsCompleted.push(fileArray[0])
            @_checkWarningUploadS3(s3File.file.name)
            @_checkReadyToUp()
          onErrorBack: (s3File, status) =>
            s3File.file.status = 'failure'
            @_retryBackSending(s3File, status)
          onErrorXhr: (s3File, status) =>
            s3File.file.status = 'failure'
            @_retryS3Sending(s3File, status)
          onCancel: (s3File) =>
            s3File.file.status = 'cancel'
            @_removeFileUploading(s3File)
            @itemsCanceled.push(s3File)
          , @_gzip
        )
        @itemsReadyToUp.push(file)

      _startUpload: (file) ->
        file.start()
        @itemsUploading.push(file)

      _removeFileUploading: (file) ->
        for item, index in @itemsUploading
          if item == file
            return @itemsUploading.splice(index, 1)

      _computeItems: ->
        if @_isCheckingItemsCount
          return
        @_isCheckingItemsCount = true
        total = 0
        total += @itemsCompleted.length
        total += @itemsUploading.length
        total += @itemsReadyToUp.length
        total += @itemsCompressing
        total += @itemsReadyToCompress.length
        total += @itemsWaiting.length
        total += @itemsFailedFilters.length
        total += @itemsFailedUpload.length
        @itemsTotal = total
        @_isCheckingItemsCount = false

      _computeSize: ->
        if @_isCheckingSize
          return
        @_isCheckingSize = true
        size = 0
        for file in @itemsCompleted
          size += file.file.size
        for file in @itemsUploading
          size += file.file.size
        for file in @itemsReadyToUp
          size += file.file.size
        @size = size
        @_isCheckingSize = false

      _computeTransmittedSize: ->
        if @_isCheckingTransmittedSize
          return
        @_isCheckingTransmittedSize = true
        transmitted_size = 0
        for file in @itemsCompleted
          transmitted_size += file.file.transmitted_size
        for file in @itemsUploading
          transmitted_size += file.file.transmitted_size
        @transmitted_size = transmitted_size
        @_isCheckingTransmittedSize = false

      _retryBackSending: (s3File, status) ->
        if s3File.file.sendingTryBack < 3
          s3File.file.sendingTryBack++
          @_checkWarningUploadBack(s3File.file.name, s3File.file.sendingTryBack)
          s3File.file.status = 'ready'
          s3File.file.transmitted_size = 0
          s3File.start()
        else
          @_checkWarningUploadBack(s3File.file.name)
          @_removeFileUploading(s3File)
          @itemsFailedUpload.push(s3File)
          @_checkReadyToUp()

      _retryS3Sending: (s3File, status) ->
        if s3File.file.sendingTryS3 < 3
          s3File.file.sendingTryS3++
          @_checkWarningUploadS3(s3File.file.name, s3File.file.sendingTryS3)
          s3File.file.status = 'ready'
          s3File.file.transmitted_size = 0
          s3File.start()
        else
          @_checkWarningUploadS3(s3File.file.name)
          @_removeFileUploading(s3File)
          @itemsFailedUpload.push(s3File)
          @_checkReadyToUp()

      _checkWarningUploadS3: (name, count = 0) ->
        @_checkWarningUpload(@warningsXfailsS3, name, count)

      _checkWarningUploadBack: (name, count = 0) ->
        @_checkWarningUpload(@warningsXfailsBack, name, count)

      _checkWarningUpload: (dest, name, count) ->
        find = false
        warning =
          name: name
          count: count
        for item, key in dest
          console.log("item :", item)
          console.log("key :", key)
          if item.name == name
            dest.splice(key, 1)
            break
        if count
          dest.push(warning)

      addWarnings: (warnings) ->
        @warnings = warnings
        @onAddingWarningsComplete?()

      startAll: ->
        @status = 'progress'
        for file in @itemsUploading
          file.start()
        @_checkUploader()

      pauseAll: ->
        @status = 'pause'
        for file in @itemsUploading
          file.pause()

      cancelAll: ->
        @status = 'cancel'
        for file in @itemsUploading
          if file?
            file.cancel()
        for file in @itemsCompleted
          file.cancel()
        @init()
        @onCancelAllComplete?()

      clearErrors: ->
        @itemsFailedFilters = []
        @itemsFailedUpload = []
        @itemsCanceled = []
        @warningsXfailsBack = []
        @warningsXfailsS3 = []
        @_computeItems()

      isAllComplete: ->
        count = @itemsCompleted.length + @itemsFailedUpload.length + @itemsFailedFilters.length
        if count == @itemsTotal
          return true
        else
          return false

      _onWhenAddingFileFailed: (item, filter) ->
        if filter.name == "Sous-dossiers ignorés."
          split = item.webkitRelativePath.split("/")
          nameDirectory = "."
          for i in [0..split.length-2]
            nameDirectory += "/"+split[i]
          text = "Le dossier "+nameDirectory+" a été ignoré. "+
                 filter.name
        else
          text = "Le fichier "+item.name+" n'a pas pu être ajouté à la liste. "+
                 filter.name
        if @itemsFailedFilters.indexOf(text) == -1
          @itemsFailedFilters.push(text)
