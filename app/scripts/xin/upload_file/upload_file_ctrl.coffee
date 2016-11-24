'use strict'


angular.module('xin_uploadFile', ['appSettings', 'xin.fileUploader'])
  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileController'
    scope:
      lienParticipation: '@'
      regex: '=?'
      refresh: '=?'
    link: (scope, elem, attrs) ->
      scope.elem = elem


  .controller 'UploadFileController', ($q, $scope, SETTINGS,
                                       Backend, Uploader) ->
      # 5Mo
      sliceSize = 5 * 1024 * 1024
      uploader = null

      checkFile = (file) ->
        # test fullPath for subdirectory
        if file.fullPath?
          split = file.fullPath.split("/")
          if split.length > 2
            uploader.nb_waiting--
            uploader.nb_warning++
            uploader.warningFiles.push("Sous-dossier : #{file.fullPath}")
            file = null
            uploader._checkQueuedFiles()
            return
        # test regex
        if file.type not in ['image/png', 'image/png', 'image/jpeg']
          if not $scope.regex.test(file.name)
            uploader.nb_waiting--
            uploader.nb_warning++
            uploader.warningFiles.push("Nom de fichier invalide : #{file.name}")
            file = null
            uploader._checkQueuedFiles()
            return
        # test empty file
        if file.size == 0
          uploader.nb_waiting--
          uploader.nb_warning++
          uploader.warningFiles.push("#{file.name} : Fichier vide")
          file = null
          uploader._checkQueuedFiles()
          return
        if not file.fullPath? or file.fullPath == ""
          file.fullPath = file.name
        uploader.processingFiles.push(file)
        compressAndRegister(file.fullPath)

      compressAndRegister = (file_path) ->
        file = null
        for file_i in uploader.processingFiles when file_i.fullPath == file_path
          file = file_i
        compressed = $q.defer()
        registered = $q.defer()
        # Register the file to the backend
        file.postData = null
        payload =
          mime: file.type
          titre: file.name
          multipart: false
        if $scope.lienParticipation?
          payload.lien_participation = $scope.lienParticipation
        if payload.mime == ''
          ta = /\.ta$/
          tac = /\.tac$/
          if ta.test(payload.titre)
            payload.mime = 'application/ta'
            file.type = 'application/ta'
          else if tac.test(payload.titre)
            payload.mime = 'application/tac'
            file.type = 'application/tac'
        Backend.all('fichiers').post(payload).then(
          (response) ->
            file.custom_status = 'ready'
            file.postData = response
            registered.resolve()
          (error) ->
            file.custom_status = 'rejected'
            registered.reject(error)
        )
        # Compress the file
        createGZipFile(file.data).then(
          (blob) ->
            file.data = blob
            compressed.resolve()
          (error) ->
            compressed.reject(error)
        )
        $q.all([compressed.promise, registered.promise]).then(
          (results) ->
            sendFile(file_path)
          (error) ->
            index = null
            for file_i, i in uploader.processingFiles when file_i.fullPath == file_path
              file = uploader.processingFiles.splice(i, 1)[0]
              break
            uploader.nb_waiting--
            if file.custom_status? and file.custom_status == "rejected"
              uploader.nb_warning++
              uploader.nb_not_unique++
            else
              uploader.nb_error++
              uploader.errorFiles.push({motif: error, file: file})
            uploader._checkQueuedFiles()
            return
        )

      createGZipFile = (file) ->
        $q (resolve, reject) ->
          arrayBuffer = null
          fileReader = new FileReader()
          fileReader.onload = (e) =>
            arrayBuffer = e.target.result
            gzipFile = pako.gzip(arrayBuffer)
            blob = new Blob([gzipFile], {type: file.type})
            blob.name = file.name
            if blob.size == 0
              reject("#{file.name} : Fichier vide après compression")
            else if blob.size > sliceSize
              reject("#{file.name} : Fichier compressé de taille > 5Mo")
            else
              resolve(blob)
          fileReader.readAsArrayBuffer(file)

      sendFile = (file_path) ->
        file = null
        for file_i in uploader.processingFiles when file_i.fullPath == file_path
          file = file_i
        formData = new FormData()
        formData.append('key', file.postData.s3_id)
        formData.append('acl', 'private')
        formData.append('AWSAccessKeyId', file.postData.s3_aws_access_key_id)
        formData.append('Policy', file.postData.s3_policy)
        formData.append('Signature', file.postData.s3_signature)
        formData.append('Content-Encoding', 'gzip')
        xhr = new XMLHttpRequest()
        xhr.open("post", SETTINGS.S3_BUCKET_URL, true)
        xhr.onload = (e) =>
          return unless xhr.readyState is 4
          if xhr.status in [200, 204]
            uploadedOnS3(file_path)
          else
            errorUploadOnS3(file_path, xhr)
        xhr.onerror = ->
          errorUploadOnS3(file_path, xhr)
        # Some browser do not have the .upload property
        progressObj = xhr.upload ? xhr
        progressObj.onprogress = (e) =>
          onProgress(file_path, e)
        # xhr.setRequestHeader('Content-Encoding', 'gzip')
        formData.append('file', file.data, file.name)
        xhr.send(formData)

      onProgress = (file_path, e) ->
        file = null
        for file_i in uploader.processingFiles when file_i.fullPath == file_path
          file = file_i
        uploader.transmitted_size += e.loaded - file.bytesSent
        file.bytesSent = e.loaded
        computeSpeed()
        $scope.refresh?()

      computeSpeed = ->
        time = new Date()
        diffTime = (time - uploader.start_time) / 1000
        if diffTime < 4
          return
        uploader.start_time = time
        uploader.speed = uploader.transmitted_size / diffTime
        uploader.transmitted_size = 0

      uploadedOnS3 = (file_path) ->
        file = null
        for file_i in uploader.processingFiles when file_i.fullPath == file_path
          file = file_i
        if file.postData?
          Backend.one('fichiers', file.postData._id).post().then(
            (response) ->
              uploader.nb_success++
              uploader.nb_waiting--
              for file_i, i in uploader.processingFiles when file_i.fullPath == file_path
                uploader.processingFiles.splice(i, 1)
                break
              uploader._checkQueuedFiles()
              # $scope.refresh?()
            (error) ->
              uploader.nb_failure++
              uploader.nb_waiting--
              for file_i, i in uploader.processingFiles when file_i.fullPath == file_path
                file = uploader.processingFiles.splice(i, 1)[0]
                break
              uploader.errorFiles.push({
                motif: "Erreur finition fichier : #{file.name}"
                file: file
              })
              uploader._checkQueuedFiles()
              # $scope.refresh?()
          )

      errorUploadOnS3 = (file_path, xhr) ->
        uploader.nb_failure++
        uploader.nb_waiting--
        for file_i, i in uploader.processingFiles when file_i.fullPath == file_path
          file = uploader.processingFiles.splice(i, 1)[0]
          break
        uploader.errorFiles.push({
          motif: "Erreur upload fichier sur S3 : #{file.name}"
          file: file
        })
        uploader._checkQueuedFiles()

      uploaderConfig =
        parallelUploads: 10
        checkFile: checkFile

      $scope.$watch 'elem', (value) ->
        uploader = new Uploader($scope.elem[0].children[0], uploaderConfig)
        $scope.uploader = uploader
