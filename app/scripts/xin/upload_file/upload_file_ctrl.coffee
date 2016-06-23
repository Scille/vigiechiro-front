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
              reject("#{file.name} : Fichier vide arpès compression")
            else if blob.size > sliceSize
              reject("#{file.name} : Fichier compressé de taille > 5Mo")
            else
              resolve(blob)
          fileReader.readAsArrayBuffer(file)


      onAccept = (file, done) ->
        # test fullPath for subdirectory
        if file.fullPath?
          split = file.fullPath.split("/")
          if split.length > 2
            done("warning", "Sous-dossier : #{file.fullPath}")
            $scope.refresh?()
            return
        # test regex
        if file.type not in ['image/png', 'image/png', 'image/jpeg']
          if not $scope.regex.test(file.name)
            done("warning", "Nom de fichier invalide : #{file.name}")
            $scope.refresh?()
            return
        # test empty file
        if file.size == 0
          done("error", "#{file.name} : Fichier vide")
          $scope.refresh?()
          return

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
            msg = JSON.stringify(error.data)
            registered.reject("Erreur a l'upload : #{msg}")
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
            done()
          (error) ->
            done("error", error)
            $scope.refresh?()
        )


      onSending = (file, formData) ->
        formData.append('key', file.postData.s3_id)
        formData.append('acl', 'private')
        formData.append('AWSAccessKeyId', file.postData.s3_aws_access_key_id)
        formData.append('Policy', file.postData.s3_policy)
        formData.append('Signature', file.postData.s3_signature)
        formData.append('Content-Encoding', 'gzip')


      onProgress = ->
        $scope.refresh?()


      onComplete = (file) ->
        if file.postData?
          Backend.one('fichiers', file.postData._id).post().then(
            (response) ->
              uploader.removeFile(file)
              $scope.refresh?()
            (error) ->
              uploader.removeFile(file, "Erreur finition fichier : #{file.name}")
              $scope.refresh?()
          )


      uploaderConfig =
        url: SETTINGS.S3_BUCKET_URL
        method: "post"
        parallelUploads: 10
        accept: onAccept
        sending: onSending
        progressing: onProgress
        complete: onComplete

      $scope.$watch 'elem', (value) ->
        uploader = new Uploader($scope.elem[0].children[0], uploaderConfig)
        $scope.uploader = uploader
