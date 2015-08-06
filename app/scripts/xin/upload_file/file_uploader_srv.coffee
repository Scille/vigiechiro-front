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
      constructor: () ->
        @filters = []
        @parallelUpload = 8
        @_gzip = false
        @init()

      init: ->
        @interval = null
        @previousProgress = []
        @queue = []
        @onProgress = []
        @directories = []
        @warnings = []
        @itemsCompleted = 0
        @itemsFailed = 0
        @size = 0
        @transmitted_size = 0
        @status = 'ready'

      setGzip: ->
        @_gzip = true

      computeSize: ->
        @size = 0
        for file in @queue
          @size += file.file.size

      computeTransmittedSize: ->
        @transmitted_size = 0
        for file in @queue
          @transmitted_size += file.file.transmitted_size

      removeFileOnProgress: (file) ->
        for item, index in @onProgress
          if item == file
            @onProgress.splice(index, 1)
            return

      _createZipFile: (file) ->
        zip = new JSZip()
        arrayBuffer = null
        fileReader = new FileReader()
        fileReader.onload = (e) =>
          arrayBuffer = e.target.result
          zip.file(file.name, arrayBuffer)
          blob = zip.generate({compression: "DEFLATE", compressionOptions: {level: 1} , type: "blob", mimeType: file.type})
          blob.name = file.name
          @_addFilesNext(blob)
        fileReader.readAsArrayBuffer(file)

      addFiles: (files) ->
        filesLength = files.length or 0
        if not filesLength
          return
        for i in [0..filesLength-1]
          file = files.pop()
          if not @checkFilters(file)
            continue
          if @_gzip
            @_createZipFile(file)
          else
            @_addFilesNext(file)

      _addFilesNext: (file) =>
        file.status = 'ready'
        file.transmitted_size = 0
        file.sendingTry = 0
        file = new S3FileUploader(file,
          onStart: (s3File) =>
            s3File.file.status = 'progress'
            if not (s3File in @onProgress)
              @onProgress.push(s3File)
          onProgress: (s3File, transmitted_size) =>
            s3File.file.transmitted_size = transmitted_size
            @computeTransmittedSize()
          onPause: (s3File) =>
            s3File.file.status = 'pause'
          onSuccess: (s3File) =>
            @removeFileOnProgress(s3File)
            @itemsCompleted++
            s3File.file.status = 'success'
            @startNext()
          onErrorBack: (s3File, status) =>
            console.log("errorBack", s3File.file)
            s3File.file.status = 'failure'
            @removeFileOnProgress(s3File)
            @startNext()
            @itemsFailed++
            @displayError?(s3File.file.name+' '+status, 'back')
          onErrorXhr: (s3File, status) =>
            console.log("onErrorXhr", s3File.file)
            s3File.file.status = 'failure'
            @retrySending(s3File, status)
          onCancel: (s3File) =>
            s3File.file.status = 'cancel'
            @removeFileOnProgress(s3File)
            @itemsFailed++
          , @_gzip
        )
        @queue.push(file)
        @computeSize()
        @onAddingComplete?()

      retrySending: (s3File) ->
        if s3File.file.sendingTry < 3
          s3File.file.sendingTry++
          @displayError?("Echec de l'essai n°"+s3File.file.sendingTry+" du téléchargement du fichier "+s3File.file.name, 'xhr', 3)
          s3File.file.status = 'ready'
          s3File.file.transmitted_size = 0
          s3File.start()
        else
          @displayError?("Fichier annulé (3 essais passés) : "+s3File.file.name, 'xhr')
          @removeFileOnProgress(s3File)
          @itemsFailed++
          @startNext()

      addWarnings: (warnings) ->
        @warnings = warnings
        @onAddingWarningsComplete?()

      checkFilters: (file) ->
        result = true
        for filter in @filters
          if not filter.fn(file)
            @onWhenAddingFileFailed(file, filter)
            result = false
        return result

      startAll: ->
        @status = 'progress'
        @interval = $interval(@checkUploader, 2000)
        for file in @onProgress
          file.start()
        for i in [1..@parallelUpload]
          @startNext()

      checkUploader: =>
        for item, index in @onProgress
          if item in @previousProgress
            if item.file.status == 'success'
              @removeFileOnProgress(item)
              @startNext()
        @previousProgress = @onProgress.slice()

      startNext: ->
        if @status == 'pause' or @onProgress.length >= @parallelUpload
          return
        for file, i in @queue
          if file.file.status == 'ready'
            @queue[i].start()
            return

      pauseAll: ->
        @status = 'pause'
        $interval.cancel(@interval)
        for file in @onProgress
          file.pause()

      cancelOne: (item) ->
        for file, index in @queue
          if file == item
            item.cancel()
            return

      cancelAll: ->
        $interval.cancel(@interval)
        for file in @queue
          if file.file.status not in ['ready', 'failure']
            file.cancel()
        @init()
        @onCancelAllComplete?()

      isAllComplete: ->
        for file in @queue
          if file.file.status in ['ready', 'progress']
            return false
        $interval.cancel(@interval)
        return true
