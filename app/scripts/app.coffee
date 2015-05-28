###*
 # @ngdoc overview
 # @name vigiechiroApp
 # @description
 # # vigiechiroApp
 #
 # Main module of the application.
###

do ->

  ### @ngInject ###
  config = ($routeProvider) =>
    $routeProvider
    .when '/',
      redirectTo: '/accueil'
#      resolve:
#        # @ngInject
#        initSession: ( Session) =>
#          return  Session.init()
    .when '/403',
      templateUrl: '403.html'
    .when '/404',
      templateUrl: '404.html'
    .otherwise
      redirectTo: '/404'


  ### @ngInject ###
  AppCtrl = ($scope, PubSub, Session) =>
    PubSub.subscribe 'user', (user) =>
      $scope.isLogged = Session.isLogged()


  ### @ngInject ###
  run = (Session) =>
    Session.init()


  angular
  .module('vigiechiroApp', ['ngAnimate',
                            'ngRoute',
                            'ngMessages',
                            'ngSanitize',
                            'ngTouch',
                            'ng-breadcrumbs',
                            'flow',
      			                'kendo.directives',
                            'xin_google_maps',
                            'appSettings',
                            'xin_login',
                            'xin_editor',
                            'xin_pubsub',
                            'xin_tools',
                            'xin_content',
                            'xin_footer',
                            'xin_input',
                            'xin_session',
                            'xin_session_tools',
                            'xin_backend',
                            'xin_navbar',
                            'xin_editor',
                            'xin_datasource',
                            'xin_pubsub',
#    'xin_google_maps',
                            "xin_action",
                            "xin_storage",
                            'settingsViews',
                            'accueilViews',
                            'utilisateurViews',
                            'taxonViews',
                            'protocoleViews',
                            'participationViews',
                            'actualiteViews',
                            'donneeViews'])
  .config (config)
  .controller( 'AppCtrl', AppCtrl)
  .run (run)

