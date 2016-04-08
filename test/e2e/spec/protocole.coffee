"use strict"

helper = require('../helper')


describe 'Test protocole for observateur', ->

  beforeEach ->
    helper.login()

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  it 'Test get protocole list', ->
    browser.setLocation('protocoles').then ->
      protocoles = $$('.list-group-item')
      expect(protocoles.count()).toEqual(4)
      expect(element(By.id('create-protocole')).isDisplayed()).toBe(false)

  it 'Test view macro protocole', ->
    browser.setLocation('protocoles').then ->
      protocoles = $$('.list-group-item')
      protocoles.get(0).element(`by`.css('a')).click().then ->
        element(By.binding('protocole.titre')).getText().then (value) ->
          expect(value).toBe('Vigiechiro')
        expect(element(By.id('edit-protocole')).isDisplayed()).toBe(false)
        expect(element(By.id('register-protocole')).isDisplayed()).toBe(false)

  # it 'Test view protocole', ->
  #   browser.setLocation('protocoles').then ->
  #     protocoles = $$('.list-group-item')
  #     protocoles.get(1).element(`by`.css('a')).click().then ->
  #       element(By.binding('protocole.titre')).getText().then (value) ->
  #         expect(value).toBe('Vigiechiro-A')
  #       expect(element(By.id('edit-protocole')).isDisplayed()).toBe(false)
  #
  # it 'Test inscription protocole', ->
  #   browser.setLocation('protocoles').then ->
  #     protocoles = $$('.list-group-item')
  #     protocoles.get(1).element(`by`.css('a')).click().then ->
  #       register = element(By.id('register-protocole'))
  #       expect(register.isDisplayed()).toBe(true)
  #       register.click().then ->
  #         expect(element(By.id('register-protocole')).isDisplayed()).toBe(false)

#describe 'Test protocole for administrateur', ->#

#  beforeEach ->
#    helper.login('Administrateur')#

#  afterEach ->
#    browser.executeScript("window.localStorage.clear()")#

#  it 'Test get protocole list', ->
#    browser.setLocation('protocoles').then ->
#      expect($('.create-protocole').isDisplayed()).toBe(true)#

#  it 'Test edit protocole', ->
#    browser.setLocation('protocoles').then ->
#      protocoles = element.all(`by`.repeater('resource in resources'))
#      protocoles.get(0).element(`by`.css('a')).click().then ->
#        browser.getCurrentUrl().then (url) ->
#          protocoleUrl = url
#          editElement = $('.edit-protocole')
#          expect(editElement.isDisplayed()).toBe(true)
#          editElement.click().then ->
#            libelle_longElement = element(`by`.model('protocole.libelle_long'))
#            libelle_courtElement = element(`by`.model('protocole.libelle_court'))
#            descriptionElement = element(`by`.model('protocole.description')).element(`by`.css('.ta-scroll-window'))
#            libelle_longElement.clear().sendKeys('edit protocole libelle long')
#            libelle_courtElement.clear().sendKeys('edit protocole libelle court')
#            descriptionElement.click().then ->
#              browser.driver.actions()
#                .sendKeys(protractor.Key.chord(protractor.Key.CONTROL, "a"))
#                .sendKeys(protractor.Key.DELETE)
#                .sendKeys('edit protocole description').perform()
#              saveprotocoleButton = $('.save-protocole')
#              expect(saveprotocoleButton.isDisplayed()).toBe(true)
#              saveprotocoleButton.click().then ->
#                browser.get(protocoleUrl).then ->
#                  element(`by`.binding('protocole.libelle_long')).getText().then (text) ->
#                    expect(text).toBe('edit protocole libelle long')
#                  element(`by`.binding('protocole.libelle_court')).getText().then (text) ->
#                    expect(text).toBe('(edit protocole libelle court)')
#                  element(`by`.binding('protocole.description')).getText().then (text) ->
#                    expect(text).toBe('edit protocole description')#

#  it 'Test add protocole', ->
#    browser.setLocation('protocoles').then ->
#      expect($('.create-protocole').isDisplayed()).toBe(true)
#      $('.create-protocole').click().then ->
#        browser.getCurrentUrl().then (url) ->
#          expect(url).toBe("#{helper.baseUrl}/protocoles/nouveau")
#          libelle_longElement = element(`by`.model('protocole.libelle_long'))
#          libelle_courtElement = element(`by`.model('protocole.libelle_court'))
#          descriptionElement = element(`by`.model('protocole.description')).element(`by`.css('.ta-scroll-window'))
#          libelle_longElement.clear().sendKeys('new protocole libelle long')
#          libelle_courtElement.clear().sendKeys('new protocole libelle court')
#          descriptionElement.click().then ->
#            browser.driver.actions()
#              .sendKeys(protractor.Key.chord(protractor.Key.CONTROL, "a"))
#              .sendKeys(protractor.Key.DELETE)
#              .sendKeys('new protocole description').perform()
#            protocolesParents = $('#protocoles_parents')
#            protocolesParents.click().then ->
#              protocolesParents.element(`by`.css('input'))
#                .sendKeys('Chauve')
#                .sendKeys(protractor.Key.ENTER)
#            saveprotocoleButton = $('.save-protocole')
#            expect(saveprotocoleButton.isDisplayed()).toBe(true)
#            saveprotocoleButton.click().then ->
#              browser.getCurrentUrl().then (url) ->
#                expect(url).toBe("#{helper.baseUrl}/protocoles")
#                protocoles = $$('.list-group-item')
#                expect(protocoles.count()).toEqual(5)
