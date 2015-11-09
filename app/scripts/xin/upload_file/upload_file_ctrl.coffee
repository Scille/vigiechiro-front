'use strict'


angular.module('xin_uploadFile', ['appSettings', 'xin_s3uploadFile', 'xin.fileUploader'])
  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileController'
    scope:
      uploader: '=?'
      regexp: '=?'
    link: (scope, elem, attrs) ->
      scope.dragOverClass = ''
      scope.multiple = false
      scope.directory = false
      scope.gzip = false
      drop = elem.find('.drop')
      input = drop.find('input')
      if attrs.multiple?
        scope.multiple = true
        input[0].setAttribute('multiple', '')
      if attrs.directory?
        scope.directory = true
        input[0].setAttribute('directory', '')
        input[0].setAttribute('webkitdirectory', '')
        input[0].setAttribute('mozdirectory', '')
      if attrs.gzip?
        scope.gzip = true

      scope.$watch 'regexp', (regexp) ->
        if regexp? and regexp.length
          scope.addRegExpFilter(regexp)



  .controller 'UploadFileController', ($scope, Backend, S3FileUploader, FileUploader, guid) ->
    $scope.date_id = guid()
    $scope.warnings = []
    $scope.errors =
      filters: []
      back: []
      xhr: []
    uploader = $scope.uploader = new FileUploader()

    $scope.$watch 'gzip', (gzip) ->
      if gzip
        uploader.setGzip()
    , true

    # Remove sub-directories
    uploader.filters.push(
      name: "Sous-dossiers ignorés."
      fn: (item) ->
        if item.webkitRelativePath? and item.webkitRelativePath != ''
          split = item.webkitRelativePath.split("/")
          if split.length > 2
            return false
          else
            nameDirectory = split[0]
            if uploader.directories.indexOf(nameDirectory) == -1
              uploader.directories.push(nameDirectory)
        return true
    )

    $scope.addRegExpFilter = (regexp) ->
      if regexp? and regexp.length > 0
        uploader.filters.push(
          name: "Format incorrect."
          fn: (item) ->
            if item.type in ['image/png', 'image/png', 'image/jpeg']
              return true
            for reg in regexp or []
              if reg? and reg.test(item.name)
                return true
            return false
        )

    uploader.displayError = (error, type, limit = 0) ->
      if type == 'back'
        $scope.errors.back.push(error)
      else if type == 'xhr'
        $scope.errors.xhr.push(error)
      $scope.$apply()

    uploader.onAddingWarningsComplete = ->
      for warning in @warnings
        if $scope.directory
          $scope.warnings.push(warning.name+" n'est pas un dossier.")
        else
          $scope.warnings.push(warning.name+" n'est pas un fichier.")
      $scope.$apply()

    uploader.onCancelAllComplete = ->
      $scope.warnings = []
