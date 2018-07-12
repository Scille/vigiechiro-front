'use strict'


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
      scope.elem = elem
      # if attrs.directory?
      #   scope.directory = true
      #   input[0].setAttribute('directory', '')
      #   input[0].setAttribute('webkitdirectory', '')
      #   input[0].setAttribute('mozdirectory', '')


  .controller 'UploadFileController', ($scope, Backend, S3FileUploader, Uploader, guid) ->

    createGZipFile = (file) ->
      return new Promise((resolve, reject) ->
        arrayBuffer = null
        fileReader = new FileReader()
        fileReader.onload = (e) =>
          arrayBuffer = e.target.result
          gzipFile = pako.gzip(arrayBuffer)
          blob = new Blob([gzipFile], {type: file.type})
          blob.name = file.name
          if blob.size == 0
            resolve({file: file, gzip: false})
          else
            resolve({file: blob, gzip: true})
        fileReader.readAsArrayBuffer(file)
      )

    refreshScope = ->
      $scope.$apply();

    onAccept = (file, done) ->
      # test fullPath for subdirectory
      if file.fullPath?
        split = file.fullPath.split("/")
        if split.length > 2
          $scope.uploader.warnings.push("Sous-dossier : #{file.fullPath}")
          done("Erreur : sous-dossier")
          $scope.$apply()
          return
      # test regex
      if file.type not in ['image/png', 'image/png', 'image/jpeg']
        if not $scope.regex.test(file.name)
          $scope.uploader.warnings.push("Nom de fichier invalide : #{file.name}")
          done("Erreur : mauvais nom de fichier #{file.name}")
          $scope.$apply()
          return
      # test empty file
      if file.size == 0
        $scope.uploader.warnings.push("#{file.name} : Fichier vide")
        done("Erreur : fichier vide")
        $scope.$apply()
        return

      createGZipFile(file.data).then(
        (result) ->
          file.data = result.file
          file.gzip = result.gzip
          $scope.$apply()
          done()
        (error) ->
          $scope.uploader.errors.push(error)
          console.error(error)
          $scope.$apply()
          done(error)
      )

    onComplete = (file) ->
      console.log('onComplete')

    uploaderConfig = {
      participationId: $scope.lienParticipation
      parallelUploads: 5,
      refreshScope: refreshScope,
      accept: onAccept,
      # sending: onSending,
      complete: onComplete
    }
    $scope.$watch 'elem', (value) ->
      $scope.uploader = uploader = new Uploader($scope.elem[0].children[0], uploaderConfig)

    # uploader.displayError = (error, type, limit = 0) ->
    #   if type == 'back'
    #     $scope.errors.back.push(error)
    #   else if type == 'xhr'
    #     $scope.errors.xhr.push(error)
    #   $scope.$apply()

    # uploader.onAddingWarningsComplete = ->
    #   $scope.warnings = @warnings

    # uploader.onCancelAllComplete = ->
    #   $scope.warnings = []
