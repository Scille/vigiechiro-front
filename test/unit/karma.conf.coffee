# Karma configuration
# http://karma-runner.github.io/0.12/config/configuration-file.html
# Generated on 2014-10-22 using
# generator-karma 0.8.3

module.exports = (config) ->
  config.set
    # base path, that will be used to resolve files and exclude
    basePath: '../..'

    # testing framework to use (jasmine/mocha/qunit/...)
    frameworks: ['jasmine']

    # list of files / patterns to load in the browser
    files: [
      "bower_components/jquery/dist/jquery.js"
      "bower_components/angular/angular.js"
      "bower_components/json3/lib/json3.min.js"
      "bower_components/bootstrap/dist/js/bootstrap.js"
      "bower_components/angular-sanitize/angular-sanitize.js"
      "bower_components/angular-animate/angular-animate.js"
      "bower_components/angular-touch/angular-touch.js"
      "bower_components/angular-route/angular-route.js"
      "bower_components/lodash/lodash.js"
      "bower_components/restangular/dist/restangular.js"
      "bower_components/flow.js/dist/flow.js"
      "bower_components/ng-flow/dist/ng-flow.js"
      "bower_components/angular-utils-pagination/dirPagination.js"
      "bower_components/rangy-official/rangy-core.js"
      "bower_components/rangy-official/rangy-classapplier.js"
      "bower_components/rangy-official/rangy-highlighter.js"
      "bower_components/rangy-official/rangy-selectionsaverestore.js"
      "bower_components/rangy-official/rangy-serializer.js"
      "bower_components/rangy-official/rangy-serializer.js"
      "bower_components/rangy-official/rangy-serializer.js"
      "bower_components/rangy-official/rangy-serializer.js"
      "bower_components/rangy-official/rangy-serializer.js"
      "bower_components/rangy-official/rangy-serializer.js"
      "bower_components/rangy-official/rangy-serializer.js"
      "bower_components/rangy-official/rangy-textrange.js"
      "bower_components/textAngular/src/textAngular.js"
      "bower_components/textAngular/src/textAngular.js"
      "bower_components/textAngular/src/textAngular-sanitize.js"
      "bower_components/textAngular/src/textAngularSetup.js"
      "bower_components/rangy-official/rangy-selectionsaverestore.js"
      "bower_components/angular-ui-select/dist/select.js"
      "bower_components/angular-bootstrap/ui-bootstrap-tpls.js"
      "bower_components/angular-translate/angular-translate.js"
      "bower_components/angular-dialog-service/dist/dialogs.min.js"
      "bower_components/angular-dialog-service/dist/dialogs-default-translations.min.js"
      "bower_components/pako/dist/pako.js"
      "bower_components/datatables/media/js/jquery.dataTables.js"
      "bower_components/angular-datatables/dist/angular-datatables.js"
      "bower_components/angular-datatables/dist/plugins/bootstrap/angular-datatables.bootstrap.js"
      "bower_components/angular-datatables/dist/plugins/colreorder/angular-datatables.colreorder.js"
      "bower_components/angular-datatables/dist/plugins/columnfilter/angular-datatables.columnfilter.js"
      "bower_components/angular-datatables/dist/plugins/colvis/angular-datatables.colvis.js"
      "bower_components/angular-datatables/dist/plugins/fixedcolumns/angular-datatables.fixedcolumns.js"
      "bower_components/angular-datatables/dist/plugins/fixedheader/angular-datatables.fixedheader.js"
      "bower_components/angular-datatables/dist/plugins/scroller/angular-datatables.scroller.js"
      "bower_components/angular-datatables/dist/plugins/tabletools/angular-datatables.tabletools.js"
      "bower_components/bootstrap-switch/dist/js/bootstrap-switch.js"
      "bower_components/angular-bootstrap-switch/dist/angular-bootstrap-switch.js"
      "bower_components/moment/moment.js"
      "bower_components/angular-moment/angular-moment.js"
      "bower_components/sc-toggle-switch/release/scripts/toggle_switch.js"
      "bower_components/sc-toggle-switch/release/scripts/populate_template_cache.js"
      "bower_components/angularjs-slider/dist/rzslider.js"
      "bower_components/moment/locale/fr.js"
      "bower_components/angular-mocks/angular-mocks.js"
      'app/**/*.coffee'
      'test/unit/mock/**/*.coffee'
      'test/unit/spec/**/*.coffee'
    ],

    # list of files / patterns to exclude
    exclude: []

    # web server port
    port: 8080

    # level of logging
    # possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
    logLevel: config.LOG_INFO

    # Start these browsers, currently available:
    # - Chrome
    # - ChromeCanary
    # - Firefox
    # - Opera
    # - Safari (only Mac)
    # - PhantomJS
    # - IE (only Windows)
    browsers: [
      'PhantomJS'
    ]

    # Which plugins to enable
    plugins: [
      'karma-phantomjs-launcher'
      'karma-jasmine'
      'karma-coffee-preprocessor'
    ]

    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: true

    # Continuous Integration mode
    # if true, it capture browsers, run tests and exit
    singleRun: false

    colors: true

    preprocessors: '**/*.coffee': ['coffee']

    # Uncomment the following lines if you are using grunt's server to run the tests
    # proxies: '/': 'http://localhost:9000/'
    # URL root prevent conflicts with the site root
    # urlRoot: '_karma_'
