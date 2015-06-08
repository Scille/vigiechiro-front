angular.module('xin.fileUploader', ['xin_s3uploadFile'])
  .directive 'fileOver', () ->
    restrict: 'A'
    scope:
      uploader: '=?'
    link: (scope, elem, attrs) ->
      if attrs.overClass? and attrs.overClass != ''
        elem[0].addEventListener('dragover',
          (e) ->
            e.preventDefault()
            elem.addClass(attrs.overClass)
          false)
        elem[0].addEventListener('dragleave',
          (e) ->
            elem.removeClass(attrs.overClass)
          false)

      elem[0].addEventListener('drop',
        (e) ->
          e.preventDefault()
          elem.removeClass(attrs.overClass)
          # Check if inputs are files
          if not scope.uploader?
            console.log("Uploader not available")
            return
          files = []
          warnins = []
          length = e.dataTransfer.items.length
          for i in [0..length-1]
            entry = e.dataTransfer.items[i].webkitGetAsEntry()
            if (entry.isFile)
              files.push(e.dataTransfer.files[i])
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
      elem[0].onchange = (e) ->
        if not scope.uploader?
          console.log("Uploader not available")
          return
        files = []
        for file in this.files or []
          files.push(file)
        scope.uploader.addFiles(files)


  .factory 'FileUploader', (S3FileUploader) ->
    class FileUploader
      constructor: () ->
        @queue = []
        @filters = []
        @warnings = []
        @maxParallelUpload = 5
        @itemsCompleted = 0
        @fileOnProgress = 0
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

      addFiles: (files) ->
        length = files.length
        for i in [0..length-1]
          file = files.pop()
          if not @checkFilters(file)
            continue
          file.status = 'ready'
          file.transmitted_size = 0
          # TODO check filters
          file = new S3FileUploader(file,
            onProgress: (file, transmitted_size) =>
              file.transmitted_size = transmitted_size
              @computeTransmittedSize()
            onSuccess: (file) =>
              @fileOnProgress--
              @itemsCompleted++
              file.status = 'success'
              @startOne()
            onError: (status) ->
              console.log("Error")
              if status?
                console.log(status)
            onCancel: ->
              console.log("onCancel")
          )
          @queue.push(file)
        @computeSize()
        @onAddingComplete?()

      addWarnings: (warnings) ->
        console.log(warnings)

      checkFilters: (file) ->
        result = true
        for filter in @filters
          if not filter.fn(file)
            @onWhenAddingFileFailed(file, filter)
            result = false
        return result

      startAll: ->
        for i in [1..@maxParallelUpload-@fileOnProgress]
          @startOne()

      startOne: ->
        if @fileOnProgress < @maxParallelUpload
          i = @itemsCompleted + @fileOnProgress
          if i < @queue.length
            @fileOnProgress++
            @queue[i].start()

      isAllComplete: ->
        for file in @queue
          if not file.status == 'done'
            return false
        return true


#    uploader.onAfterAddingFile = (fileItem) ->
#      console.info('onAfterAddingFile', fileItem)
#    uploader.onAfterAddingAll = (addedFileItems) ->
#      console.info('onAfterAddingAll', addedFileItems)
#    uploader.onBeforeUploadItem = (item) ->
#      console.info('onBeforeUploadItem', item)
#    uploader.onProgressItem = (fileItem, progress) ->
#      console.info('onProgressItem', fileItem, progress)
#    uploader.onProgressAll = (progress) ->
#      console.info('onProgressAll', progress)
#    uploader.onSuccessItem = (fileItem, response, status, headers) ->
#      fileItem.id = response.id
#      fileItem._links =
#        data: response._links.data
#      console.info('onSuccessItem', fileItem, response, status, headers)
#    uploader.onErrorItem = (fileItem, response, status, headers) ->
#      console.info('onErrorItem', fileItem, response, status, headers)
#    uploader.onCancelItem = (fileItem, response, status, headers) ->
#      console.info('onCancelItem', fileItem, response, status, headers)
#    uploader.onCompleteItem = (fileItem, response, status, headers) ->
#      console.info('onCompleteItem', fileItem, response, status, headers)
#    uploader.onCompleteAll = () ->
#      console.info('onCompleteAll')
