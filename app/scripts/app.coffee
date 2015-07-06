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
  AppCtrl = ($scope, PubSub, Session, localStorageService) =>
    PubSub.subscribe 'user', (user) =>
      $scope.isLogged = Session.isLogged()

#    $(document).arrive('.navbar-toggle', () =>
#      $(this).sideNav({menuWidth: 260, closeOnClick: true}))

    theme = localStorageService.get("theme")

    if (not theme?)
      theme =
        color: "theme-pink"
        template: "theme-template-dark"

    $scope.theme = theme

    $scope.theme_colors = [
      'pink', 'red', 'purple', 'indigo', 'blue',
      'light-blue', 'cyan', 'teal', 'green', 'light-green',
      'lime', 'yellow', 'amber', 'orange', 'deep-orange'
    ]

    $scope.fillinContent = =>
      $scope.htmlContent = 'content content'

    #theme changing
    $scope.changeColorTheme = (cls) =>
      $scope.theme.color = cls

    $scope.changeTemplateTheme = (cls) =>
      $scope.theme.template = cls

    localStorageService.set "theme", theme
    localStorageService.bind $scope, "theme"


  ### @ngInject ###
  run = (Session) =>
    Session.init()


  window.app = angular
  .module('vigiechiroApp', ['angular-loading-bar',
                            'LocalStorageModule',
                            'jcs-autoValidate',
                            'ngAnimate',
                            'ngRoute',
                            'ngAside',
                            'ngSanitize',
                            'ng-breadcrumbs',
                            'ui.select',
                            'ui.bootstrap',
                            'flow',
                            'form-control',
                            'kendo.directives',
                            'xin_google_maps',
                            'appSettings',
                            'xin_tag',
                            'xin_login',
                            'xin_editor',
                            'xin_pubsub',
                            'xin_tools',
                            'xin_content',
                            'xin_footer',
                            'xin.fileUploader',
                            'xin_input',
                            'xin_session',
                            'xin_session_tools',
                            'xin_backend',
                            'xin_navbar',
                            'xin_editor',
                            'xin_datasource',
                            'xin_pubsub',
                            'xin_google_maps',
                            "xin_action",
                            "xin_sidebar",
                            'accueilViews',
                            'utilisateurViews',
                            'taxonViews',
                            'protocoleViews',
                            'participationViews',
                            'actualiteViews',
                            'mgcrea.ngStrap',
                            'smoothScroll',
                            'monospaced.elastic', # resizable textarea
                            'donneeViews'])
  .config (config)
  .controller('AppCtrl', AppCtrl)
  .run (run)

