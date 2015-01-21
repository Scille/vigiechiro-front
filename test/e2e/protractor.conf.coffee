# Protractor configuration

exports.config =
  seleniumAddress: 'http://localhost:4444/wd/hub',
  specs: ['spec/*']
  capabilities:
    'browserName': 'chrome'
  jasmineNodeOpts:
    showColors: true,
    defaultTimeoutInterval: 30000,
    isVerbose : true,
    includeStackTrace : true
