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
    browser.waitForAngular().then ->
      element.all(_by_.css('.btn-login')).get(0).click().then ->
      # buttonLogin.click().then ->
        # Login should be complete, retrieve the element and check their visibility
        buttonsLogin = $('.btn-login')
        element.all(_by_.css('.btn-login')).each (element) ->
          expect(element.isDisplayed()).toBe(false)
        content = $("content-directive")
        expect(content.isDisplayed()).toBe(true)


login = (callback) ->
  element.all(_by_.css('.btn-login')).get(0).click().then callback

userStatusPage = (callback) ->
  userStatus = element(_by_.css('user-status'))
  userStatus.element(_by_.css('a')).click().then callback

describe 'E2e test once logged', ->

  beforeEach ->
    browser.get('http://localhost:9001')

  it 'Test get user profile', ->
    login ->
      userStatus = element(_by_.css('user-status'))
      userStatus.element(_by_.binding("user.pseudo")).getText().then (name) ->
        expect(name).toBe('John Doe')
      userStatus.element(_by_.css('a')).click().then ->
        browser.waitForAngular().then ->
          element(_by_.model('utilisateur.email')).getAttribute('value').then (email) ->
            expect(email).toBe('mock_user@google.com')
          element(_by_.model('utilisateur.pseudo')).getAttribute('value').then (pseudo) ->
            expect(pseudo).toBe('John Doe')
          element(_by_.model('utilisateur.prenom')).clear().sendKeys('John')
          element(_by_.model('utilisateur.nom')).clear().sendKeys('Doe')
          element(_by_.css('input[type="submit"]')).click().then ->
            # Reload page to make sure submit has worked
            userStatusPage ->
              element(_by_.model('utilisateur.prenom')).getAttribute('value').then (email) ->
                expect(email).toBe('John')
              element(_by_.model('utilisateur.nom')).getAttribute('value').then (pseudo) ->
                expect(pseudo).toBe('Doe')

  it 'Test logout', ->
    login ->
      element(_by_.buttonText('Logout')).click().then ->
        check_logout_state()
