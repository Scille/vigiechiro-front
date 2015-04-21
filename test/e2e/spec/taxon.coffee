"use strict"

helper = require('../helper')


describe 'Test taxon for observateur', ->

  beforeEach ->
    helper.login()

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  it 'Test get taxon list', ->
    browser.setLocation('taxons').then ->
      taxons = $$('.list-group-item')
      expect(taxons.count()).toEqual(20)

  it 'Test view taxon', ->
    browser.setLocation('taxons').then ->
      taxons = $$('.list-group-item')
      taxons.get(0).element(`by`.css('a')).click().then ->
        element(`by`.binding('taxon.libelle_long')).getText().then (value) ->
          expect(value).toBe('Chauves-souris')


describe 'Test taxon for administrateur', ->

  beforeEach ->
    helper.login('Administrateur')

  afterEach ->
    browser.executeScript("window.localStorage.clear()")

  it 'Test get taxon list', ->
    browser.setLocation('taxons').then ->
      expect(element(By.id('create-taxon')).isDisplayed()).toBe(true)

  it 'Test edit taxon', ->
    browser.setLocation('taxons').then ->
      taxons = element.all(`by`.repeater('resource in resources'))
      taxons.get(0).element(`by`.css('a')).click().then ->
        browser.getCurrentUrl().then (url) ->
          taxonUrl = url
          editElement = $('.edit-taxon')
          expect(editElement.isDisplayed()).toBe(true)
          editElement.click().then ->
            libelle_longElement = element(`by`.model('taxon.libelle_long'))
            libelle_courtElement = element(`by`.model('taxon.libelle_court'))
            descriptionElement = element(`by`.model('taxon.description')).element(`by`.css('.ta-scroll-window'))
            libelle_longElement.clear().sendKeys('edit taxon libelle long')
            libelle_courtElement.clear().sendKeys('edit taxon libelle court')
            descriptionElement.click().then ->
              browser.driver.actions()
                .sendKeys(protractor.Key.chord(protractor.Key.CONTROL, "a"))
                .sendKeys(protractor.Key.DELETE)
                .sendKeys('edit taxon description').perform()
              saveTaxonButton = $('.save-taxon')
              expect(saveTaxonButton.isDisplayed()).toBe(true)
              saveTaxonButton.click().then ->
#                browser.get(taxonUrl).then ->
#                  element(`by`.binding('taxon.libelle_long')).getText().then (text) ->
#                    expect(text).toBe('edit taxon libelle long')
#                  element(`by`.binding('taxon.libelle_court')).getText().then (text) ->
#                    expect(text).toBe('(edit taxon libelle court)')
#                  element(`by`.binding('taxon.description')).getText().then (text) ->
#                    expect(text).toBe('edit taxon description')

  it 'Test add taxon', ->
    browser.setLocation('taxons').then ->
      expect($('.create-taxon').isDisplayed()).toBe(true)
      $('.create-taxon').click().then ->
        browser.getCurrentUrl().then (url) ->
          expect(url).toBe("#{helper.baseUrl}/taxons/nouveau")
          libelle_longElement = element(`by`.model('taxon.libelle_long'))
          libelle_courtElement = element(`by`.model('taxon.libelle_court'))
          descriptionElement = element(`by`.model('taxon.description')).element(`by`.css('.ta-scroll-window'))
          libelle_longElement.clear().sendKeys('new taxon libelle long')
          libelle_courtElement.clear().sendKeys('new taxon libelle court')
          descriptionElement.click().then ->
            browser.driver.actions()
              .sendKeys(protractor.Key.chord(protractor.Key.CONTROL, "a"))
              .sendKeys(protractor.Key.DELETE)
              .sendKeys('new taxon description').perform()
            taxonsParents = $('#taxons_parents')
            taxonsParents.click().then ->
              taxonsParents.element(`by`.css('input'))
                .sendKeys('Chauve')
                .sendKeys(protractor.Key.ENTER)
            saveTaxonButton = $('.save-taxon')
            expect(saveTaxonButton.isDisplayed()).toBe(true)
            saveTaxonButton.click().then ->
              browser.getCurrentUrl().then (url) ->
                expect(url).toBe("#{helper.baseUrl}/taxons")
                taxons = $$('.list-group-item')
                expect(taxons.count()).toEqual(5)
