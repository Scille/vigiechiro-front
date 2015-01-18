"use strict"

baseUrl = 'http://www.lvh.me:9000/#/'
observateurToken = "26GLD0MWB2ISABOQN2F5K1JNKVZNLOOT"
adminToken = "SQIWJ0GLDKI2001GA03M9P5QYMY7SV8M"
validateurToken = "HKTG700ROM0TFNHFQZX0IQK53DU6ZY4W"

login = (userRole) ->
  if userRole == 'Administrateur'
    token = adminToken
  else if userRole == 'Validateur'
    token = validateurToken
  else
    token = observateurToken
  pageReady = false
  browser.get(baseUrl).then ->
    browser.executeScript("window.localStorage.setItem('auth-session-token', '#{token}')").then ->
      browser.refresh().then ->
        pageReady = true
  browser.wait -> pageReady


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
    browser.get(baseUrl)

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  it 'Test title', ->
    expect(browser.getTitle()).toEqual('Vigiechiro')

  it 'Test login page', ->
    check_logout_state()
    # Now process to login
    element.all(`by`.css('.btn-login')).get(0).click().then ->
      # Login should be complete, retrieve the element and check their visibility
      buttonsLogin = $('.btn-login')
      element.all(`by`.css('.btn-login')).each (element) ->
        expect(element.isDisplayed()).toBe(false)
      content = $("content-directive")
      expect(content.isDisplayed()).toBe(true)

  it 'Test redirection relog', ->
    # Manual login
    element.all(`by`.css('.btn-login')).get(0).click().then ->
      element(`by`.binding("user.pseudo")).getText().then (name) ->
        # Make sure the user is logged as John Doe
        expect(name).toBe('John Doe')
        # Now manually change token
        browser.get("#{baseUrl}?token=#{observateurToken}").then ->
          # Wait for the login to complete
          browser.wait( ->
            # Refresh can occure during login, thus we must look for
            # content-directive each time we evalute the test
            $('content-directive').isDisplayed()
          ).then ->
            # Check the user has changed
            element(`by`.binding("user.pseudo")).getText().then (name) ->
              expect(name).toBe('Observateur Name')

  it 'Test token invalidation relog', ->
    # Manual login
    element.all(`by`.css('.btn-login')).get(0).click().then ->
      element(`by`.binding("user.pseudo")).getText().then (name) ->
        # Make sure the user is logged as John Doe
        expect(name).toBe('John Doe')
        # Now manually change token
        browser.executeScript("window.localStorage.setItem('auth-session-token', '#{observateurToken}')").then ->
          browser.refresh().then ->
            # Check the user has changed
            element(`by`.binding("user.pseudo")).getText().then (name) ->
              expect(name).toBe('Observateur Name')

  it 'Test logout', ->
   element.all(`by`.css('.btn-login')).get(0).click().then ->
    element(`by`.buttonText('Logout')).click().then ->
      check_logout_state()


describe 'Test once logged', ->

  beforeEach ->
    login()

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  it 'Test token login', ->
    buttonsLogin = $('.btn-login')
    $$('.btn-login').each (element) ->
      expect(element.isDisplayed()).toBe(false)
    content = $("content-directive")
    expect(content.isDisplayed()).toBe(true)
    browser.executeScript('return localStorage.getItem("auth-session-token")').then (token) ->
      expect(token).toBe(observateurToken)
    userStatus = $('user-status')
    userStatus.element(`by`.binding("user.pseudo")).getText().then (name) ->
      expect(name).toBe('Observateur Name')

  it 'Test get user profile', ->
    userStatus = $('user-status')
    userStatus.element(`by`.binding("user.pseudo")).getText().then (name) ->
      expect(name).toBe('Observateur Name')
    userStatus.element(`by`.css('a')).click().then ->
      browser.waitForAngular().then ->
        element(`by`.model('utilisateur.email')).getAttribute('value').then (email) ->
          expect(email).toBe('observateur@facebook.com')
        element(`by`.model('utilisateur.pseudo')).getAttribute('value').then (pseudo) ->
          expect(pseudo).toBe('Observateur Name')
        element(`by`.model('utilisateur.prenom')).clear().sendKeys('John')
        element(`by`.model('utilisateur.nom')).clear().sendKeys('Doe')
        element(`by`.css('input[type="submit"]')).click().then ->
          # Reload page to make sure submit has worked
          element(`by`.css('user-status')).element(`by`.css('a')).click().then ->
            element(`by`.model('utilisateur.prenom')).getAttribute('value').then (email) ->
              expect(email).toBe('John')
            element(`by`.model('utilisateur.nom')).getAttribute('value').then (pseudo) ->
              expect(pseudo).toBe('Doe')
