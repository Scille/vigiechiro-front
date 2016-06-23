'use strict'


angular.module('appSettings', [])
  .constant 'SETTINGS',
    API_DOMAIN: 'http://localhost:8080'
    FRONT_DOMAIN: 'http://localhost:9000'
    S3_BUCKET_URL: 'https://vigiechiro.s3.amazonaws.com/'
    BASE_TITLE: 'Vigiechiro'
