'use strict'


angular.module('xin.fileUploader', ['xin_s3uploadFile'])
  .directive 'fileOver', () ->
    restrict: 'A'
    scope:
      uploader: '=?'
      directory: '='
    link: (scope, elem, attrs) ->
      scope.$watch 'directory', (directory) ->
        if directory? and not directory
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
          # chrome
          if e.dataTransfer.items?
            length = e.dataTransfer.items.length
            for i in [0..length-1]
              entry = e.dataTransfer.items[i].webkitGetAsEntry()
              if (entry.isFile and not scope.directory)
                files.push(e.dataTransfer.files[i])
              else
                warnings.push("L'élément #{e.dataTransfer.files[i].name} ne peut pas être déposé ici.")
          # firefox
          else if e.dataTransfer.types?
            for file in e.dataTransfer.files or []
              if file.size
                files.push(file)
              else
                warnings.push("L'élément #{file.name} ne peut pas être déposé ici.")
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
      constructor: ->
        @filters = []
        @_gzip = false
        @_parallelUpload = 2
        @_parallelGZip = 4
        @_waitingGZip = 8
        @init()
        @interval = $interval(@_checkUploader, 10000)
        @status = 'progress'

      init: ->
        # list of uploaded directories
        @directories = []
        # list of warning texts
        @warnings = []
        # Number of total item
        @itemsTotal = 0
        # list of files id completed
        @itemsCompleted = []
        # list of files uploading
        @itemsUploading = []
        # list of file waiting to upload
        @itemsReadyToUp = []
        # Number of files compressing
        @itemsCompressing = 0
        # list of files waiting to compress
        @itemsReadyToCompress = []
        # list of item waiting to filter
        @itemsWaiting = []
        #
        @itemsFailedFilters = []
        #
        @itemsFailedCompress = []
        #
        @itemsFailedUpload = []
        #
        @itemsCanceled = []
        #
        @warningsXfails = []
        #
        @_isCheckingUploader = false
        @_isCheckingWaiting = false
        @_isCheckingReadyToCompress = false
        @_isCheckingReadyToUp = false
        @_isCheckingTransmittedSize = false
        @_isCheckingSize = false
        @_isCheckingItemsCount = false
        @size = 0
        @_sizeUpload = 0
        @transmitted_size = 0
        @_transmittedSizePrevious = 0
        @speed = 0
        @_startTime = 0

      setGzip: ->
        @_gzip = true

      addFiles: (files) ->
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
          if @itemsReadyToUp.length >= @_waitingGZip or @itemsCompressing >= @_parallelGZip
            break
          file = @itemsReadyToCompress.shift()
          @_createGZipFile(file)
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
            if blob.size == 0
              @_createS3File(file)
            else
              @_createS3File(blob, true)
            @_computeSize()
        fileReader.readAsArrayBuffer(file)

      _createS3File: (file, gzip = false) =>
        if file.size == 0
          @itemsFailedCompress.push(file.name)
          return
        file.status = 'ready'
        file.transmitted_size = 0
        file.sendingTryS3 = 0
        file.sendingTryBack = 0
        file = new S3FileUploader(file,
          onStart: (s3File) =>
            s3File.file.status = 'progress'
            @_checkWarningUpload(s3File.file.name)
          onProgress: (s3File, transmitted_size) =>
            s3File.file.transmitted_size = transmitted_size
            @_computeTransmittedSize()
          onPause: (s3File) =>
            s3File.file.status = 'pause'
          onSuccess: (s3File) =>
            @_onSuccess(s3File)
          onErrorBack: (s3File, status) =>
            s3File.file.status = 'failure'
            @_retryBackSending(s3File, status)
          onErrorXhr: (s3File, status) =>
            s3File.file.status = 'failure'
            @_retryS3Sending(s3File, status)
          onCancel: (s3File) =>
            @_removeFileUploading(s3File)
            @itemsCanceled.push({name: s3File.file.name})
          , gzip
        )
        @itemsReadyToUp.push(file)

      _onSuccess: (item) ->
        fileArray = @_removeFileUploading(item)
        if not fileArray?
          return
        @_sizeUpload += item.file.size
        @itemsCompleted.push(item.file.id)
        @_checkWarningUpload(item.file.name)
        @_checkReadyToCompress()
        @_checkReadyToUp()

      _startUpload: (file) ->
        file.start()
        @itemsUploading.push(file)

      _removeFileUploading: (file) ->
        for item, index in @itemsUploading
          if item.file.name == file.file.name
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
        size = @_sizeUpload
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
        transmitted_size = @_sizeUpload
        for file in @itemsUploading
          transmitted_size += file.file.transmitted_size
        @transmitted_size = transmitted_size
        @_isCheckingTransmittedSize = false

      _retryBackSending: (s3File, status) ->
        if s3File.file.sendingTryBack < 2
          s3File.file.sendingTryBack++
          @_checkWarningUpload(s3File.file.name, s3File.file.sendingTryBack)
          s3File.file.status = 'ready'
          s3File.file.transmitted_size = 0
          s3File.start()
        else
          @_onError(s3File)

      _retryS3Sending: (s3File, status) ->
        if s3File.file.sendingTryS3 < 2
          s3File.file.sendingTryS3++
          @_checkWarningUpload(s3File.file.name, s3File.file.sendingTryS3)
          s3File.file.status = 'ready'
          s3File.file.transmitted_size = 0
          s3File.start()
        else
          @_onError(s3File)

      _onError: (item) ->
        @_checkWarningUpload(item.file.name)
        item = @_removeFileUploading(item)
        if item? and item.length
          @itemsFailedUpload.push(item[0])
        @_checkReadyToCompress()
        @_checkReadyToUp()

      _checkWarningUpload: (name, count = 0) ->
        warning =
          name: name
          count: count
        length = @warningsXfails.length-1
        for i in [0..length] when length >= 0
          item = @warningsXfails[i]
          if item.name == name
            @warningsXfails.splice(i, 1)
            break
        if count
          @warningsXfails.push(warning)

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
        @init()
        @onCancelAllComplete?()

      clearErrors: ->
        @itemsFailedFilters = []
        @itemsFailedCompress = []
        @itemsFailedUpload = []
        @itemsCanceled = []
        @warningsXfails = []
        @_computeItems()

      retryErrors: ->
        for item in @itemsFailedUpload or []
          item.file.sendingTryBack = 0
          item.file.sendingTryS3 = 0
        @itemsReadyToUp = @itemsReadyToUp.concat(@itemsFailedUpload)
        @itemsFailedUpload = []
        @_checkReadyToUp()

      isAllComplete: ->
        count = @itemsCompleted.length + @itemsFailedUpload.length + @itemsFailedCompress.length + @itemsFailedFilters.length
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
