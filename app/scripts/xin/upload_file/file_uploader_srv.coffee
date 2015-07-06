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


  .factory 'FileUploader', (S3FileUploader) ->
    class FileUploader
      constructor: () ->
        @filters = []
        @parallelUpload = 8
        @init()

      init: ->
        @queue = []
        @onProgress = []
        @directories = []
        @warnings = []
        @itemsCompleted = 0
        @itemsFailed = 0
        @size = 0
        @transmitted_size = 0
        @status = 'ready'

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
            break

      addFiles: (files) ->
        if not files.length
          return
        length = files.length
        for i in [0..length-1]
          file = files.pop()
          if not @checkFilters(file)
            continue
          file.status = 'ready'
          file.transmitted_size = 0
          file = new S3FileUploader(file,
            onStart: (s3File) =>
              s3File.file.status = 'progress'
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
              @startOne()
            onErrorBack: (s3File, status) =>
              s3File.file.status = 'failure'
              @removeFileOnProgress(s3File)
              @itemsFailed++
              if status?
                console.log(status)
            onErrorXhr: (s3File, status) =>
              s3File.file.status = 'failure'
              @removeFileOnProgress(s3File)
              @itemsFailed++
              if status?
                console.log(status)
            onCancel: (s3File) =>
              s3File.file.status = 'cancel'
              @removeFileOnProgress(s3File)
              @itemsFailed++
          )
          @queue.push(file)
        @computeSize()
        @onAddingComplete?()

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
        for file in @onProgress
          file.start()
        for i in [1..@parallelUpload]
          @startOne()

      startOne: ->
        if @status == 'pause'
          return
        onProgress = @onProgress.length
        if onProgress < @parallelUpload
          i = @itemsCompleted + onProgress
          if i < @queue.length
            @queue[i].start()

      pauseAll: ->
        @status = 'pause'
        for file in @onProgress
          file.pause()

      cancelOne: (item) ->
        for file, index in @queue
          if file == item
            item.cancel()
            return

      cancelAll: ->
        for file in @queue
          if file.file.status not in ['ready', 'failure']
            file.cancel()
        @init()
        @onCancelAllComplete?()

      isAllComplete: ->
        for file in @queue
          if not (file.file.status in ['success', 'failure', 'cancel'])
            return false
        return true
