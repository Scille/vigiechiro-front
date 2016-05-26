'use strict'


angular.module('appSettings', [])
  .constant 'SETTINGS',
    API_DOMAIN: 'http://localhost:8080'
    FRONT_DOMAIN: 'http://localhost:9000'
    S3_BUCKET_URL: 'https://vigiechiro.s3.amazonaws.com/'
    BASE_TITLE: 'Vigiechiro'
    USER_FIELDS: [
      "pseudo",
      "email",
      "nom",
      "prenom",
      "telephone",
      "adresse",
      "commentaire",
      "organisation",
      "professionnel",
      "donnees_publiques",
      "role",
      "vitesse_connexion"
    ]
