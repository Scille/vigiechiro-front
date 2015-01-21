"use strict"

exports.baseUrl = 'http://localhost:9000/#'
exports.observateurToken = "26GLD0MWB2ISABOQN2F5K1JNKVZNLOOT"
exports.observateurId = "54ba464f1d41c83768e76fbf"
exports.adminToken = "SQIWJ0GLDKI2001GA03M9P5QYMY7SV8M"
exports.validateurToken = "HKTG700ROM0TFNHFQZX0IQK53DU6ZY4W"
exports.validateurId = "54ba5dfd1d41c83768e76fc2"

exports.login = (userRole) ->
  if userRole == 'Administrateur'
    token = exports.adminToken
  else if userRole == 'Validateur'
    token = exports.validateurToken
  else
    token = exports.observateurToken
  pageReady = false
  browser.get(exports.baseUrl).then ->
    browser.executeScript("window.localStorage.setItem('auth-session-token', '#{token}')").then ->
      browser.refresh().then ->
        pageReady = true
  browser.wait -> pageReady
