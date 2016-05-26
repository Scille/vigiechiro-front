'use strict'


angular.module('xin_uploadFile', ['appSettings', 'xin.fileUploader'])
  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileController'
    scope:
      lienParticipation: '@'
      regex: '=?'
      warningFiles: '=?'
      errorFiles: '=?'
      refresh: '=?'
    link: (scope, elem, attrs) ->
      scope.elem = elem


  .controller 'UploadFileController', ($scope, SETTINGS, Backend, Uploader) ->
      # 5Mo
      sliceSize = 5 * 1024 * 1024

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
            if $scope.warningFiles?
              $scope.warningFiles.push("Sous-dossier : #{file.fullPath}")
              $scope.refresh?()
            return done("Erreur : sous-dossier")
        # test regex
        if file.type not in ['image/png', 'image/png', 'image/jpeg']
          if not $scope.regex.test(file.name)
            if $scope.warningFiles?
              $scope.warningFiles.push("Nom de fichier invalide : #{file.name}")
              $scope.refresh?()
            return done("Erreur : mauvais nom de fichier #{file.name}")
        # test empty file
        if file.size == 0
          if $scope.errorFiles?
            $scope.errorFiles.push("#{file.name} : Fichier vide")
            $scope.refresh?()
          return done("Erreur : fichier vide")
        # Compression
        createGZipFile(file).then(
          (blob) ->
            console.log(file)
            console.log(blob)
            file.postData = []
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
              else if tac.test(payload.titre)
                payload.mime = 'application/tac'

            Backend.all('fichiers').post(payload).then(
              (response) ->
                  file.custom_status = 'ready'
                  file.postData = response
                  # $(file.previewTemplate).addClass('uploading')
                  done()
              (error) ->
                file.custom_status = 'rejected'
                msg = JSON.stringify(error.data)
                if $scope.errorFiles?
                  $scope.errorFiles.push(msg)
                  $scope.refresh?()
                done("Erreur a l'upload : #{msg}")
            )
          (error) ->
            if $scope.errorFiles?
              $scope.errorFiles.push(error)
              $scope.refresh?()
            done(error)
        )


      onSending = (file, xhr, formData) ->
        console.log(file, xhr, formData)
        formData.append('key', file.postData.s3_id)
        formData.append('acl', 'private')
        formData.append('AWSAccessKeyId', file.postData.s3_aws_access_key_id)
        formData.append('Policy', file.postData.s3_policy)
        formData.append('Signature', file.postData.s3_signature)

      onComplete = (file) ->
        if file.postData?
          Backend.one('fichiers', file.postData._id).post().then(
            (response) ->
              console.log(response)
            (error) ->
              file.custom_status = 'rejected'
              throw error
          )
        dropzone.removeFile(file)

      uploaderConfig =
        url: SETTINGS.S3_BUCKET_URL
        method: "post"
        parallelUploads: 5
        accept: onAccept
        sending: onSending
        complete: onComplete

      $scope.$watch 'elem', (value) ->
        $scope.uploader = uploader = new Uploader($scope.elem[0].children[0], uploaderConfig)
