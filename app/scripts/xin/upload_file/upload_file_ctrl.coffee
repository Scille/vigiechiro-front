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
    link: (scope, elem, attrs) ->
      form_elem = elem.find('.selectors-form')[0]

      # File form
      file_selector_elem = elem.find('.file-selector')[0]
      file_selector_elem.addEventListener 'change', ->
        for file in file_selector_elem.files
          scope.newUpload(file)

        form_elem.reset()

      # Folder form
      folder_selector_elem = elem.find('.folder-selector')[0]
      folder_selector_elem.addEventListener 'change', ->
        for file in folder_selector_elem.files
          scope.newUpload(file)

        form_elem.reset()

  .controller 'UploadFileController', ($scope, $http, Backend) ->

    $scope.upload_stats =
      success: 0
      errors: 0
      ignored: 0
      total: 0

    max_concurrent_uploads = 5
    current_uploads_count = 0
    waiting_uploads = []
    already_uploaded_file_names = []

    Backend.all('participations').one($scope.lienParticipation, 'pieces_jointes').get().then(
      (response) ->
        for file in response._items
          already_uploaded_file_names.push(file.titre)

      (error) ->
        console.log('Error fectching participation info', error)
    )

    registerUpload = (file) ->
      upload = new Upload(file)
      if upload.file.name in already_uploaded_file_names
        upload.setAlreadyUploaded()
        teardownUpload(upload)
      else if current_uploads_count < max_concurrent_uploads
        startUpload(upload)
        current_uploads_count += 1
      else
        waiting_uploads.push(upload)
      return upload

    teardownUpload = (upload) ->
      $scope.upload_stats.total += 1
      if upload.status == 'success'
        already_uploaded_file_names.push(upload.file.name)
        $scope.upload_stats.success += 1
      else if upload.status == 'already_uploaded'
        $scope.upload_stats.ignored += 1
      else
        $scope.upload_stats.errors += 1

      current_uploads_count -= 1
      upload = waiting_uploads.pop()
      if upload
        startUpload(upload)
        current_uploads_count += 1

    startUpload = (upload) ->
      upload.setBootstrap()

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
            teardownUpload(upload)
          else
            console.log('Upload bootstrap error', error)
            upload.setError("Erreur à l'initialisation de l'upload.")
            teardownUpload(upload)
      )

    s3Upload = (upload, s3_signed_url, mime) ->
      upload.setS3Upload()
      req =
        method: 'PUT',
        url: s3_signed_url,
        withCredentials: true
        uploadEventHandlers:
          progress: (e) ->
            if e.lengthComputable
              upload.progress(e.loaded, e.total)
        headers:
          'Content-Type': mime
        data: upload.file

      $http(req)
      .success (data) ->
        finalizeUpload(upload)
      .error (data, status) ->
        console.log('Upload S3 unknown error', data, status)
        upload.setError("Erreur lors de l'upload vers S3.")
        teardownUpload(upload)

    finalizeUpload = (upload) ->
      upload.setFinalize()
      Backend.one('fichiers', upload.id).post().then(
        (response) ->
          upload.setSuccess()
          teardownUpload(upload)

        (error) ->
          console.log('Upload finalize error', error)
          upload.setError("Erreur à la finalisation de l'upload.")
          teardownUpload(upload)
      )

    $scope.uploads = []
    $scope.newUpload = (file) =>
      console.log('New upload', file.name)
      upload = registerUpload(file)
      $scope.uploads.push(upload)
