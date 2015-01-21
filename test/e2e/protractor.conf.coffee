# Protractor configuration

exports.config =
  seleniumAddress: 'http://localhost:4444/wd/hub',
  specs: [
    'spec/login.coffee'
    'spec/taxon.coffee'
    'spec/utilisateur.coffee'
  ]
  capabilities:
    'browserName': 'chrome'
  jasmineNodeOpts:
    showColors: true,
    defaultTimeoutInterval: 30000,
    isVerbose : true,
    includeStackTrace : true
