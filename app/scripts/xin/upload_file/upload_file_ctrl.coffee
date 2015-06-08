'use strict'


angular.module('xin_uploadFile', ['appSettings', 'xin_s3uploadFile', 'xin.fileUploader'])
  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileController'
    scope:
      multiple: '@'
      uploader: '=?'
      regexp: '=?'
    link: (scope, elem, attrs) ->
      scope.dragOverClass = ''
      drop = elem.find('.drop')
      input = drop.find('input')
      if attrs.multiple?
        input.attr('multiple', '')
        scope.multipleSelect = true
      else
        scope.multipleSelect = false

      scope.$watch 'regexp', (regexp) ->
        if regexp? and regexp.length
          scope.addRegExpFilter(regexp)

      scope.clickFileInput = ->
        input.click()
        return

      scope.fileInput = elem.find('.files-input')[0]


  .controller 'UploadFileController', ($scope, Backend, S3FileUploader, FileUploader) ->
    $scope.warnings = []
    uploader = $scope.uploader = new FileUploader()
    $scope.errorCount = 0

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

    $scope.pauseAll = ->
      console.log("pause")
      uploader.pauseAll()

    $scope.stopUploader = (uploader) ->
      uploader.stop()
      _.remove($scope.uploader, (up) -> up == uploader)

    uploader.onAddingComplete = ->
      uploader.startAll()
      $scope.$apply()

    uploader.onWhenAddingFileFailed = (item, filter) ->
      text = "Le fichier "+item.name+" n'a pas pu être ajouté à la liste. "+
             filter.name
      $scope.error =
        text: text
