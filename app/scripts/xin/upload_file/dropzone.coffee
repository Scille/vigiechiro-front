'use strict'


angular.module('xin.dropzone', ['appSettings', 'xin_backend'])

  .directive 'xinDropzone', (SETTINGS, Backend) ->
    # Inspired by https://github.com/sandbochs/angular-dropzone
    restrict: 'AE'
    template: '<form class="dropzone"></form>'
    scope:
      lienParticipation: "@"
    link: (scope, elem, attrs) ->
      scope.lienParticipation = attrs.lienParticipation

      onAccept = (file, done) ->
        file.postData = []
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
              # $(file.previewTemplate).addClass('uploading')
              done()
          (error) ->
            file.custom_status = 'rejected'
            msg = JSON.stringify(error.data)
            done("Erreur a l'upload : #{msg}")
        )

      onSending = (file, xhr, formData) ->
        console.log(file, xhr, formData)
        formData.append('key', file.postData.s3_id)
        formData.append('acl', 'private')
        formData.append('AWSAccessKeyId', file.postData.s3_aws_access_key_id)
        formData.append('Policy', file.postData.s3_policy)
        formData.append('Signature', file.postData.s3_signature)

      onComplete = (file) ->
        Backend.one('fichiers', file.postData._id).post().then(
          (response) ->
            console.log(response)
          (error) ->
            file.custom_status = 'rejected'
            throw error
        )

      scope.dropzoneConfig =
        url: 'https://vigiechiro.s3.amazonaws.com/'
        method: "post"
        autoProcessQueue: true
        clickable: true
        maxfiles: 5
        parallelUploads: 3
        maxFilesize: 10 # in m
        maxThumbnailFilesize: 8 # 3M
        thumbnailWidth: 150
        thumbnailHeight: 150
        # acceptedMimeTypes: "image/bmp,image/gif,image/jpg,image/jpeg,image/png"
        accept: onAccept
        sending: onSending
        complete: onComplete

      dropzone = new Dropzone(elem[0].children[0], scope.dropzoneConfig)
      if scope.eventHandlers
        for eventName of scope.eventHandlers
          dropzone.on(eventName, scope.eventHandlers[eventName])

      scope.dropzone = dropzone
