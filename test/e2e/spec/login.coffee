"use strict"

# by is a keyword in coffescript, must rename it
_by_ = `by`

check_logout_state = ->
  content = $("content-directive")
  # Find back login button and make sure it is visible
  expect(browser.executeScript('localStorage.getItem("auth-session");')).toBe(null)
  buttonsLogin = $$('.btn-login')
  expect(buttonsLogin.count()).toBeGreaterThan(0)
  buttonLogin = buttonsLogin.get(0)
  expect(buttonLogin.isDisplayed()).toBe(true)
  # On the other hand, content page should be hidden
  expect(content.isDisplayed()).toBe(false)


describe 'E2e login', ->

  beforeEach ->
    browser.get('http://localhost:9001')

  it 'Test title', ->
    expect(browser.getTitle()).toEqual('Vigiechiro')

  it 'Test login page', ->
    check_logout_state()
    # Now process to login
    browser.waitForAngular()
    element.all(_by_.css('.btn-login')).get(0).click().then ->
    # buttonLogin.click().then ->
      # Login should be complete, retrieve the element and check their visibility
      buttonsLogin = $('.btn-login')
      element.all(_by_.css('.btn-login')).each (element) ->
        expect(element.isDisplayed()).toBe(false)
      content = $("content-directive")
      expect(content.isDisplayed()).toBe(true)


describe 'E2e test once logged', ->

  beforeEach ->
    browser.get('http://localhost:9001')
    element.all(_by_.css('.btn-login')).get(0).click()

  it 'Test get user profile', ->
    browser.debugger()
    userStatus = element('user-status')
    expect(userStatus.getText()).toEqual('John Doe')
    userStatus.element('a').click().then ->


  it 'Test logout', ->
    element(_by_.buttonText('Logout')).click().then ->
      check_logout_state()
