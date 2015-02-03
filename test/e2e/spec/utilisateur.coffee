"use strict"

helper = require('../helper')


userFields = [
  'utilisateur.role',
  'utilisateur.pseudo',
  'utilisateur.prenom',
  'utilisateur.nom',
  'utilisateur.email',
  'utilisateur.telephone',
  'utilisateur.adresse',
  'utilisateur.organisation',
  'utilisateur.commentaire',
  'utilisateur.professionnel',
  'utilisateur.donnees_publiques'
]


describe 'Test profile', ->

  it 'Test change role', ->
    # Observateur cannot change role
    helper.login()
    browser.get("#{helper.baseUrl}/profil").then ->
      browser.waitForAngular().then ->
        expect(element(`by`.model('utilisateur.role')).isEnabled()).toBe(false)
    # Same for Validateur
    helper.login('Validateur')
    browser.get("#{helper.baseUrl}/profil").then ->
      expect(element(`by`.model('utilisateur.role')).isEnabled()).toBe(false)
    # Only Administrateur can
    helper.login('Administrateur')
    browser.get("#{helper.baseUrl}/profil").then ->
      expect(element(`by`.model('utilisateur.role')).isEnabled()).toBe(true)

  it 'Test goto user profile', ->
    helper.login()
    userStatus = $('.user-status')
    userStatus.element(`by`.binding("user.pseudo")).getText().then (name) ->
      expect(name).toBe('Observateur Name')
    $('.user-status').click().then ->
      expect($('.button-profile').isDisplayed()).toBe(true)
      $('.button-profile').click().then ->
        for field in userFields
          if field != 'utilisateur.role'
            # Observateur can change everything but role
            expect(element(`by`.model(field)).isEnabled()).toBe(true)

  it 'Test change profile', ->
    helper.login()
    browser.get("#{helper.baseUrl}/profil").then ->
      element(`by`.model('utilisateur.prenom')).clear().sendKeys('John')
      element(`by`.model('utilisateur.nom')).clear().sendKeys('Doe')
      expect($('.save-user').isDisplayed()).toBe(true)
      $('.save-user').click().then ->
        # Reload page to make sure submit has worked
        browser.get("#{helper.baseUrl}/profil").then ->
          element(`by`.model('utilisateur.prenom')).getAttribute('value').then (value) ->
            expect(value).toBe('John')
          element(`by`.model('utilisateur.nom')).getAttribute('value').then (value) ->
            expect(value).toBe('Doe')


describe 'Test utilisateur access', ->

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  it 'Test for Observateur', ->
    helper.login('Observateur')
    browser.setLocation('utilisateurs').then ->
      expect(browser.getCurrentUrl()).toBe("#{helper.baseUrl}/403")
    browser.setLocation("utilisateurs/#{helper.validateurId}").then ->
      expect(browser.getCurrentUrl()).toBe("#{helper.baseUrl}/403")

  it 'Test for Validateur', ->
    helper.login('Validateur')
    browser.setLocation('utilisateurs').then ->
      expect(browser.getCurrentUrl()).toBe("#{helper.baseUrl}/utilisateurs")

  it 'Test Validateur read only', ->
    helper.login('Validateur')
    browser.setLocation("utilisateurs/#{helper.observateurId}").then ->
      for field in userFields
        expect(element(`by`.model(field)).isEnabled()).toBe(false)

  it 'Test for Administrateur', ->
    helper.login('Administrateur')
    browser.setLocation('utilisateurs').then ->
      expect(browser.getCurrentUrl()).toBe("#{helper.baseUrl}/utilisateurs")

  it 'Test Administrateur all powerfull', ->
    input = "I'm the mighty admin."
    helper.login('Administrateur')
    browser.setLocation("utilisateurs/#{helper.observateurId}").then ->
      for field in userFields
        expect(element(`by`.model(field)).isEnabled()).toBe(true)
      element(`by`.model('utilisateur.commentaire')).clear().sendKeys(input)
      $('.save-user').click().then ->
        # Reload page to make sure submit has worked
        browser.get("#{helper.baseUrl}/utilisateurs/#{helper.observateurId}").then ->
          element(`by`.model('utilisateur.commentaire')).getAttribute('value').then (comment) ->
            expect(comment).toBe(input)


describe 'Test list utilisateurs', ->

  beforeEach ->
    helper.login('Administrateur')
    browser.setLocation('utilisateurs')

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  it 'Test list count', ->
    expect($$('.list-group-item').count()).toEqual(4)

  it 'Test filter', ->
    $(".search-field").sendKeys('observateur')
    expect($$('.list-group-item').count()).toEqual(1)

  it 'Test result per page', ->
    $(".max-result-fields")
      .sendKeys(protractor.Key.chord(protractor.Key.CONTROL, "a"))
      .sendKeys('2')
    expect($$('.list-group-item').count()).toEqual(2)
