'use strict'


angular.module('xin.dropzone', ['appSettings', 'xin_backend'])

  .directive 'xinDropzone', ($q, SETTINGS, Backend) ->
    # Inspired by https://github.com/sandbochs/angular-dropzone
    restrict: 'AE'
    template: '<form class="dropzone"></form>'
    scope:
      lienParticipation: "@"
      regex: "=?"
      warningFiles: "=?"
      errorFiles: "=?"
      refresh: "=?"
    link: (scope, elem, attrs) ->
      # 5Mo
      sliceSize = 5 * 1024 * 1024
      scope.lienParticipation = attrs.lienParticipation


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
            if scope.warningFiles?
              scope.warningFiles.push("Sous-dossier : #{file.fullPath}")
              scope.refresh?()
            return done("Erreur : sous-dossier")
        # test regex
        if file.type not in ['image/png', 'image/png', 'image/jpeg']
          if not scope.regex.test(file.name)
            if scope.warningFiles?
              scope.warningFiles.push("Nom de fichier invalide : #{file.name}")
              scope.refresh?()
            return done("Erreur : mauvais nom de fichier #{file.name}")
        # test empty file
        if file.size == 0
          if scope.errorFiles?
            scope.errorFiles.push("#{file.name} : Fichier vide")
            scope.refresh?()
          return done("Erreur : fichier vide")

        compressed = $q.defer()
        registered = $q.defer()
        # Register the file to the backend
        file.postData = null
        payload =
          mime: file.type
          titre: file.name
          multipart: false
        if scope.lienParticipation?
          payload.lien_participation = scope.lienParticipation
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
              registered.resolve()
          (error) ->
            file.custom_status = 'rejected'
            msg = JSON.stringify(error.data)
            if scope.errorFiles?
              scope.errorFiles.push(msg)
              scope.refresh?()
            registered.reject("Erreur a l'upload : #{msg}")
        )
        # Compress the file
        createGZipFile(file).then(
          (blob) ->
            file.data = blob
            compressed.resolve()
          (error) ->
            if scope.errorFiles?
              scope.errorFiles.push(error)
              scope.refresh?()
            compressed.reject(error)
        )
        $q.all([compressed.promise, registered.promise]).then(
          (results) -> done()
          (error) -> done(error)
        )


      onSending = (file, xhr, formData) ->
        formData.append('key', file.postData.s3_id)
        formData.append('acl', 'private')
        formData.append('AWSAccessKeyId', file.postData.s3_aws_access_key_id)
        formData.append('Policy', file.postData.s3_policy)
        formData.append('Signature', file.postData.s3_signature)
        formData.append('Content-Encoding', 'gzip')


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


      scope.dropzoneConfig =
        url: SETTINGS.S3_BUCKET_URL
        method: "post"
        autoProcessQueue: true
        clickable: true
        # maxfiles: 5
        parallelUploads: 5
        # maxFilesize: 10 # in m
        maxThumbnailFilesize: 8 # 3M
        # thumbnailWidth: 300
        # thumbnailHeight: 100
        # acceptedMimeTypes: "image/bmp,image/gif,image/jpg,image/jpeg,image/png"
        accept: onAccept
        sending: onSending
        complete: onComplete

      dropzone = new Dropzone(elem[0].children[0], scope.dropzoneConfig)
      if scope.eventHandlers
        for eventName of scope.eventHandlers
          dropzone.on(eventName, scope.eventHandlers[eventName])

      scope.dropzone = dropzone
