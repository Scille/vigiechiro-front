'use strict'


###*
 # @ngdoc overview
 # @name vigiechiroApp
 # @description
 # # vigiechiroApp
 #
 # Main module of the application.
###

angular
.module('vigiechiroApp', [
    'ngAnimate',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'flow',
    'appSettings',
    'xin_login',
    'xin_editor',
    'xin_tools',
    'xin_content',
    'xin_footer',
    'xin_input',
    'xin_email',
    'xin_checkbox',
    'xin_number',
    'xin_textarea',
    'xin_session',
    'xin_backend',
    'xin_navbar',
    'xin_editor',
    'xin_datasource',
#    'xin_google_maps',
    "xin_create",
    "xin_update",
    "xin_submit",
    'settingsViews',
    'accueilViews',
    'utilisateurViews',
    'taxonViews',
    'protocoleViews',
    'participationViews',
    'actualiteViews',
    'donneeViews'
  ])

.run (Backend, SETTINGS) ->
  Backend.setBaseUrl(SETTINGS.API_DOMAIN)

.config ($routeProvider, RestangularProvider) ->
  $routeProvider
  .when '/',
    redirectTo: '/accueil'
  .when '/403',
    templateUrl: '403.html'
  .when '/404',
    templateUrl: '404.html'
  .otherwise
      redirectTo: '/404'
