'use strict'


angular.module('appSettings', [])
  .constant 'SETTINGS',
    API_DOMAIN: 'http://localhost:8080'
    FRONT_DOMAIN: 'http://localhost:9000'
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
      "connection_rapide"
    ]
