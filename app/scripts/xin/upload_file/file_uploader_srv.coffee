'use strict'


angular.module('xin.fileUploader', ['xin_s3uploadFile'])
  .directive 'fileOver', () ->
    restrict: 'A'
    scope:
      uploader: '=?'
      directory: '='
      dropError: '=?'
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
          scope.dropError.length = 0
          # Check if inputs are files or directories
          if not scope.uploader?
            console.log("Uploader not available")
            return
          files = []
          # chrome
          if e.dataTransfer.items?
            length = e.dataTransfer.items.length
            for i in [0..length-1]
              entry = e.dataTransfer.items[i].webkitGetAsEntry()
              if (entry.isFile and not scope.directory)
                files.push(e.dataTransfer.files[i])
              else
                scope.dropError.push("L'élément #{e.dataTransfer.files[i].name} ne peut pas être déposé ici.")
          # firefox
          else if e.dataTransfer.types?
            for file in e.dataTransfer.files or []
              if file.size
                files.push(file)
              else
                warnings.push("L'élément #{file.name} ne peut pas être déposé ici.")
          scope.uploader.addFiles(files)
          scope.$apply()
        false
      )


  .directive 'fileSelect', () ->
    restrict: 'A'
    scope:
      uploader: '=?'
      dropError: '=?'
    link: (scope, elem, attrs) ->
      onChange = ->
        scope.dropError.length = 0
        if not scope.uploader?
          console.log("Uploader not available")
          return
        files = []
        for file in this.files or []
          files.push(file)
        scope.uploader.addFiles(files)
        elem[0].value = ''
      elem.bind('change', onChange)


  .factory 'FileUploader', ($interval, $http, S3FileUploader, Backend) ->
    class FileUploader
      constructor: ->
        @filters = []
        @gzip = false
        @interval = null
        @status = 'inactive'
        @connectionSpeed = 2
        @lien_participation = ""
        @_init()

      _init: ->
        # list for filtering
        @itemsWaitingFilters = []
        @itemsFiltered = []
        # list for compressing
        @itemsToCompress = 0
        @itemsWaitingCompressLength = 0
        @itemsWaitingCompress = []
        @itemsCompressed = []
        # list for uploading
        @itemsWaitingUploadLength = 0
        @itemsWaitingUpload = []
        @itemsUploading = []
        # list of point end
        @itemsUploaded = []
        @itemsWarning = []
        @itemsFailed = []
        #
        @itemsCanceled = []
        #
        @warningsXfails = []
        #
        @size = 0
        @_sizeUpload = 0
        @_transmitted_size = 0
        @_transmittedSizePrevious = 0
        @speed = 0
        @_startTime = 0


      addFiles: (files) ->
        @_init()
        if files.length
          @itemsWaitingFilters = files
          @_start()


      _checkUploader: =>
        if @status in ['pause', 'cancel']
          return
        @_uploadStart()
        @_computeSize()
        @_computeSpeed()

      _checkWaiting: ->
        if @_isCheckingWaiting or @status in ['pause']
          return
        @_isCheckingWaiting = true
        count = @itemsWaitingFilters.length
        for i in [0..count-1] when count > 0
          file = @itemsWaitingFilters.shift()
          if @_checkFilters(file)
            if @gzip
              @itemsReadyToCompress.push(file)
            else
              @_createS3File(file)
        @_isCheckingWaiting = false


      _compress: ->
        if @gzip
          @itemsWaitingCompress = @itemsFiltered
          @itemsToCompress = @itemsWaitingCompress.length
          @itemsWaitingCompressLength = @itemsToCompress
          @status = "Compression des fichiers en cours."
          @refresh?()
          @_compressProceed(@itemsWaitingCompress.pop())
        else
          @itemsCompressed = @itemsFiltered
          @_upload()

      _compressFileComplete: (file) =>
        @itemsWaitingCompressLength--
        @itemsCompressed.push(file)
        @refresh?()
        @_compressProceed(@itemsWaitingCompress.pop())

      _compressProceed: (file) ->
        if file?
          if file.size == 0
            @itemsFailed.push("Le fichier #{file.name} est vide.")
            @_compressProceed(@itemsWaitingCompress.pop())
          else
            @_createGZipFile(file, @_compressFileComplete)
        else
          @_upload()


      _computeSize: ->
        if @_isCheckingSize
          return
        @_isCheckingSize = true
        size = @_sizeUpload
        for file in @itemsUploading
          size += file.file.size
        for file in @itemsWaitingUpload
          size += file.file.size
        @size = size
        @_isCheckingSize = false


      _computeSpeed: ->
        time = new Date()
        diffTime = (time - @_startTime) / 1000
        @_startTime = time
        @speed = @_transmitted_size / diffTime
        @_transmitted_size = 0


      _createGZipFile: (file, callback) ->
        @itemsCompressing++
        arrayBuffer = null
        fileReader = new FileReader()
        fileReader.onload = (e) =>
          arrayBuffer = e.target.result
          gzipFile = pako.gzip(arrayBuffer)
          blob = new Blob([gzipFile], {type: file.type})
          blob.name = file.name
          if blob.size == 0
            callback?(file)
          else
            callback?({file: blob, gzip: true})
        fileReader.readAsArrayBuffer(file)


      _createS3File: (file, gzip, multipart, sliceSize) =>
        file.transmitted_size = 0
        file.sendingTryS3 = 0
        file.status = "ready"
        file = new S3FileUploader(file,
          onStart: (s3File) =>
            s3File.file.status = 'progress'
          onProgress: (s3File, transmitted_size) =>
            @_transmitted_size += (transmitted_size - s3File.file.transmitted_size)
            s3File.file.transmitted_size = transmitted_size
          onPause: (s3File) =>
            s3File.file.status = 'pause'
          onSuccess: (s3File) =>
            @_transmitted_size += (s3File.file.size - s3File.file.transmitted_size)
            Backend.one('fichiers', s3File.file.id).get().then (fileBackend) =>
              fileBackend.post().then () =>
                fileArray = @_removeFileUploading(s3File)
                if fileArray?
                  @itemsUploaded.push(fileArray.file.name)
                @_uploadStart()
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
        file.multipart = multipart
        file.sliceSize = sliceSize
        return file


      _filter: ->
        @status = "Vérification du format des noms de fichier."
        @refresh?()
        while @itemsWaitingFilters.length
          file = @itemsWaitingFilters.pop()
          pass = true
          for filter in @filters
            if not filter.fn(file)
              @_onFilterError(file, filter)
              pass = false
          if pass
            @itemsFiltered.push(file)
        @_compress()


      _start: ->
        @_filter()

      _startUpload: (file) ->
        file.start()
        @itemsUploading.push(file)


      _removeFileUploading: (file) ->
        for item, index in @itemsUploading
          if item.file.name == file.file.name
            return @itemsUploading.splice(index, 1)[0]


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
        @_uploadWaiting()

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
        @itemsFailed = []


      _onFilterError: (item, filter) ->
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
        @itemsFailed.push(text)
        @refresh?()


      retryErrors: ->
        for item in @itemsFailedUpload or []
          item.file.sendingTryS3 = 0
        @itemsReadyToUp = @itemsReadyToUp.concat(@itemsFailedUpload)
        @itemsFailedUpload = []
        @_uploadWaiting()


      startAll: ->
        @status = 'progress'
        for file in @itemsUploading
          file.start()
        @_checkUploader()


      _upload: ->
        @status = "Upload des fichiers en cours."
        @refresh?()
        @itemsWaitingUpload = @itemsCompressed
        @itemsWaitingUploadLength = @itemsWaitingUpload.length
        @interval = $interval(@_checkUploader, 10000)
        @_uploadStart()


      _uploadStart: ->
        while @itemsWaitingUpload.length and @itemsUploading.length < @connectionSpeed
          @_uploadBackend(@itemsWaitingUpload.pop())
        if not @itemsWaitingUpload.length and not @itemsUploading.length
          @status = "inactive"
          $interval.cancel(@interval)
          @allComplete?()


      _uploadBackend: (file) ->
        if not file?
          return
        gzip = false
        if file.gzip? and file.gzip
          gzip = true
          file = file.file
        # 5Mo
        sliceSize = 5 * 1024 * 1024
        payload =
          mime: file.type
          titre: file.name
          multipart: false
          lien_participation: @lien_participation
        if file.size > sliceSize
          payload.multipart = true
        if payload.mime == ''
          ta = /\.ta$/
          tac = /\.tac$/
          if ta.test(payload.titre)
            payload.mime = 'application/ta'
          else if tac.test(payload.titre)
            payload.mime = 'application/tac'

        s3File = @_createS3File(file, gzip, payload.multipart, sliceSize)
        @itemsUploading.push(s3File)
        Backend.all('fichiers').post(payload).then(
          (response) =>
            s3File.file.id = response._id
            s3File.file.etag = response._etag
            s3File.s3_signed_url = response.s3_signed_url
            s3File.start()
          (error) =>
            fileArray = @_removeFileUploading(s3File)
            if error.status == 422
              if error.data? and error.data._errors? and error.data._errors.s3_id?
                if error.data._errors.s3_id.search("is not unique") != -1
                  @itemsWarning.push("Le fichier #{fileArray.file.name} existe déjà dans cette participation.")
                  @_uploadStart()
                  return
            @itemsFailed.push("Echec de l'insertion en base du fichier #{fileArray.file.name}.")
            @_uploadStart()
        )
