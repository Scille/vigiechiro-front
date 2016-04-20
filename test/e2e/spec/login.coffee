"use strict"

helper = require('../helper')


check_logout_state = ->
  # Find back login button and make sure it is visible
  browser.executeScript('return localStorage.getItem("auth-session-token")').then (token) ->
    expect(token).toBe(null)
  buttonsLogin = element.all(`by`.css('.btn-login'))
  expect(buttonsLogin.count()).toBeGreaterThan(0)
  buttonLogin = buttonsLogin.get(0)
  expect(buttonLogin.isDisplayed()).toBe(true)
  # On the other hand, content page should be hidden
  expect(element(`by`.css("content-directive")).isDisplayed()).toBe(false)


describe 'Test manual login', ->

  beforeEach ->
    browser.get(helper.baseUrl)

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  it 'Test title', ->
    expect(browser.getTitle()).toEqual('Vigiechiro')

  it 'Test login page', ->
    check_logout_state()
    # Now process to login
    browser.ignoreSynchronization = true
    element.all(`by`.css('.btn-login')).get(0).click().then ->
      browser.ignoreSynchronization = false
      # Login should be complete, retrieve the element and check their visibility
      buttonsLogin = $('.btn-login')
      element.all(`by`.css('.btn-login')).each (element) ->
        expect(element.isDisplayed()).toBe(false)
      content = $("content-directive")
      expect(content.isDisplayed()).toBe(true)

  it 'Test redirection relog', ->
    # Manual login
    browser.ignoreSynchronization = true
    element.all(`by`.css('.btn-login')).get(0).click().then ->
      browser.ignoreSynchronization = false
      element(`by`.binding("user.pseudo")).getText().then (name) ->
        # Make sure the user is logged as John Doe
        expect(name).toBe('John Doe')
        # Now manually change token
        browser.get("#{helper.baseUrl}?token=#{helper.observateurToken}")
        browser.sleep(1000).then ->
          # Wait for the login to complete and make sure the user has changed
          element(`by`.binding("user.pseudo")).getText().then (name) ->
            expect(name).toBe('Observateur Name')

  it 'Test token invalidation relog', ->
    # Manual login
    browser.ignoreSynchronization = true
    element.all(`by`.css('.btn-login')).get(0).click().then ->
      browser.ignoreSynchronization = false
      element(`by`.binding("user.pseudo")).getText().then (name) ->
        # Make sure the user is logged as John Doe
        expect(name).toBe('John Doe')
        # Now manually change token
        browser.executeScript("window.localStorage.setItem('auth-session-token', '#{helper.observateurToken}')").then ->
          browser.refresh().then ->
            # Check the user has changed
            element(`by`.binding("user.pseudo")).getText().then (name) ->
              expect(name).toBe('Observateur Name')

  it 'Test logout', ->
    # Manual login
    browser.ignoreSynchronization = true
    element.all(`by`.css('.btn-login')).get(0).click().then ->
      browser.ignoreSynchronization = false
      expect($('.user-status').isDisplayed()).toBe(true)
      $('.user-status').click().then ->
        expect($('.button-logout').isDisplayed()).toBe(true)
        $('.button-logout').click().then ->
          check_logout_state()


describe 'Test once logged', ->

  beforeEach ->
    helper.login()

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  # it 'Test token login', ->
  #   buttonsLogin = $('.btn-login')
  #   $$('.btn-login').each (element) ->
  #     expect(element.isDisplayed()).toBe(false)
  #   content = $("content-directive")
  #   expect(content.isDisplayed()).toBe(true)
  #   browser.executeScript('return localStorage.getItem("auth-session-token")').then (token) ->
  #     expect(token).toBe(helper.observateurToken)
  #   userStatus = $('.user-status')
  #   userStatus.element(`by`.binding("user.pseudo")).getText().then (name) ->
  #     expect(name).toBe('Observateur Name')

  # it 'Test history', ->
  #   browser.setLocation('/taxons').then ->
  #     browser.getLocationAbsUrl().then (url) -> expect(url).toBe("/taxons")
  #     taxons = element.all(`by`.repeater('resource in resources'))
  #     taxons.get(0).element(`by`.css('a')).click().then ->
  #       browser.setLocation('/protocoles').then ->
  #         expect(browser.getLocationAbsUrl()).toBe("/protocoles")
  #         browser.navigate().back().then ->
  #           browser.navigate().back().then ->
  #             expect(browser.getLocationAbsUrl()).toBe("/taxons")
  #             browser.navigate().back().then ->
  #               expect(browser.getLocationAbsUrl()).toBe("/accueil")
