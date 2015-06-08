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
      elem.bind('change', onChange)


  .factory 'FileUploader', (S3FileUploader) ->
    class FileUploader
      constructor: () ->
        @queue = []
        @ready = []
        @onProgress = []
        @filters = []
        @warnings = []
        @directories = []
        @maxParallelUpload = 5
        @itemsCompleted = 0
        @itemsFailed = 0
        @nbFileOnProgress = 0
        @size = 0
        @transmitted_size = 0

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
          # check if directory
          if file.webkitRelativePath? and file.webkitRelativePath != ''
            split = file.webkitRelativePath.split("/")
            fullName = '.'
            for i in [0..split.length-2]
              fullName += '/'+split[i]
            if @directories.indexOf(fullName) == -1
              @directories.push(fullName)
          #
          if not @checkFilters(file)
            continue
          file.status = 'ready'
          file.transmitted_size = 0
          file = new S3FileUploader(file,
            onStart: (file) =>
              @onProgress.push(file)
            onProgress: (file, transmitted_size) =>
              file.transmitted_size = transmitted_size
              @computeTransmittedSize()
            onSuccess: (file) =>
              @removeFileOnProgress(file)
              @nbFileOnProgress--
              @itemsCompleted++
              file.status = 'success'
              @startOne()
            onError: (status) ->
              @removeFileOnProgress(file)
              @nbFileOnProgress--
              @itemsFailed++
              if status?
                console.log(status)
            onCancel: ->
              console.log("onCancel")
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
        for i in [1..@maxParallelUpload-@nbFileOnProgress]
          @startOne()

      startOne: ->
        if @nbFileOnProgress < @maxParallelUpload
          i = @itemsCompleted + @nbFileOnProgress
          if i < @queue.length
            @nbFileOnProgress++
            @queue[i].start()

      isAllComplete: ->
        for file in @queue
          if not (file.file.status == 'success')
            return false
        return true
