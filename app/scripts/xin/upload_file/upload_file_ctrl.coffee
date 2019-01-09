'use strict'

class Upload
  constructor: (file) ->
    this.name = file.name
    this.file = file
    this.status = 'stalled'
    this.transmittedSize = 0
    this.totalSize = file.size
    this.id = null

  isFinished: =>
    return (
      this.status == 'error' or
      this.status == 'success' or
      this.status == 'already_uploaded'
    )

  getTransmittedPercent: =>
    this.transmittedSize * 100 / this.totalSize

  progress: (transmitted, total) =>
    this.transmittedSize = transmitted
    this.totalSize = total

  setBootstrap: =>
    this.status = 'bootstrap'

  setFinalize: () =>
    this.status = 'finalize'

  setS3Upload: () =>
    this.status = 's3_upload'

  setAlreadyUploaded: () =>
    this.status = 'already_uploaded'

  setError: (error) =>
    this.status = 'error'
    this.error = error

  setSuccess: () =>
    this.status = 'success'


angular.module('xin_uploadFile', ['appSettings', 'xin_s3uploadFile', 'xin.fileUploader'])
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
      form_elem = elem.children()[0]
      input_elem = form_elem.children[0]
      input_elem.addEventListener 'change', ->
        for file in input_elem.files
          scope.newUpload(file)

        form_elem.reset()

  .controller 'UploadFileController', ($scope, Backend) ->
    $scope.changeBeacon = 0
    refreshView = ->
      $scope.changeBeacon += 1
      if!$scope.$$phase
        try
          $scope.$apply()
        catch e
          # Fuck you angular
          console.log('fuck', e)

    registerUpload = (file) ->
      upload = new Upload(file)
      # TODO: add semaphore here for concurrent upload
      startUpload(upload)

    startUpload = (upload) ->
      upload.setBootstrap()
      refreshView()

      payload =
        titre: upload.file.name
        multipart: false
        lien_participation: $scope.lienParticipation

      Backend.all('fichiers').post(payload).then(
        (response) ->
          upload.id = response._id
          s3Upload(upload, response.s3_signed_url, response.mime)

        (error) ->
          if error.status == 409
            upload.setAlreadyUploaded()
          else
            console.log('Upload bootstrap error', error)
            upload.setError("Erreur à l'initialisation de l'upload.")
          refreshView()
      )
      return upload

    s3Upload = (upload, s3_signed_url, mime) ->
      upload.setS3Upload()
      refreshView()

      xhr = new XMLHttpRequest()
      if xhr.withCredentials?
        xhr.withCredentials = true
        xhr.open('PUT', s3_signed_url, true)
      else
        upload.setError('CORS non supporté sur ce navigateur')
        refreshView()
        return

      xhr.onload = ->
        if xhr.status == 200
          finalizeUpload(upload)
        else
          console.log('Upload S3 error', xhr)
          upload.setError("Erreur lors de l'upload vers S3: #{xhr.status}")
          refreshView()

      xhr.onerror = ->
        console.log('Upload S3 unknown error', xhr)
        upload.setError("Erreur lors de l'upload vers S3.")
        refreshView()

      xhr.upload.onprogress = (e) ->
        console.log('progress', e)

        if e.lengthComputable
          upload.progress(e.loaded, e.total)
        refreshView()

      xhr.setRequestHeader('Content-Type', mime)

      xhr.send(upload.file)

    finalizeUpload = (upload) ->
      upload.setFinalize()
      refreshView()
      Backend.one('fichiers', upload.id).post().then(
        (response) ->
          upload.setSuccess()
          refreshView()

        (error) ->
          console.log('Upload finalize error', error)
          upload.setError("Erreur à la finilisation de l'upload.")
          refreshView()
      )

    $scope.uploads = []
    $scope.newUpload = (file) =>
      console.log('New upload', file.name)
      upload = registerUpload(file)
      $scope.uploads.push(upload)
