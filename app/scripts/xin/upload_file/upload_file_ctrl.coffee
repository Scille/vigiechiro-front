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

      scope.$watch 'regexp', (regexp) ->
        if regexp? and regexp.length
          scope.addRegExpFilter(regexp)

      scope.clickFileInput = ->
        input.click()
        return


  .controller 'UploadFileController', ($scope, Backend, S3FileUploader, FileUploader) ->
    $scope.warnings = []
    $scope.errors =
      filters: []
      back: []
      xhr: []
    uploader = $scope.uploader = new FileUploader()

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
      if regexp? and regexp.length
        uploader.filters.push(
          name: "Format incorrect."
          fn: (item) ->
            if item.type in ['image/png', 'image/png', 'image/jpeg']
              return true
            for reg in regexp
              if reg.test(item.name)
                return true
            return false
        )

    uploader.displayError = (error, type, limit = 0) ->
      if type == 'back'
        $scope.errors.back.push(error)
      else if type == 'xhr'
        $scope.errors.xhr.push(error)

    uploader.onAddingComplete = ->
      if uploader.status in ['ready', 'progress']
        uploader.startAll()

    uploader.onWhenAddingFileFailed = (item, filter) ->
      if filter.name == "Sous-dossiers ignorés."
        split = item.webkitRelativePath.split("/")
        nameDirectory = "."
        for i in [0..split.length-2]
          nameDirectory += "/"+split[i]
        text = "Le dossier "+nameDirectory+" a été ignoré. "+
               filter.name
        if $scope.errors.filters.indexOf(text) == -1
          $scope.errors.filters.push(text)
      else
        text = "Le fichier "+item.name+" n'a pas pu être ajouté à la liste. "+
               filter.name
        $scope.errors.filters.push(text)
      $scope.$apply()

    uploader.onAddingWarningsComplete = ->
      for warning in @warnings
        if $scope.directory?
          $scope.warnings.push(warning.name+" n'est pas un dossier.")
        else
          $scope.warnings.push(warning.name+" n'est pas un fichier.")
      $scope.$apply()

    uploader.onCancelAllComplete = ->
      $scope.warnings = []
      $scope.errors =
        filters: []
        back: []
        xhr: []
