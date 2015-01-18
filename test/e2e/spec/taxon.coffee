# "use strict"


# baseUrl = 'http://www.lvh.me:9000/#/'
# observateurToken = "26GLD0MWB2ISABOQN2F5K1JNKVZNLOOT"
# adminToken = "SQIWJ0GLDKI2001GA03M9P5QYMY7SV8M"
# validateurToken = "HKTG700ROM0TFNHFQZX0IQK53DU6ZY4W"

# login = (userRole) ->
#   if userRole == 'Administrateur'
#     token = adminToken
#   else if userRole == 'Validateur'
#     token = validateurToken
#   else
#     token = observateurToken
#   pageReady = false
#   browser.get(baseUrl).then ->
#     browser.executeScript("window.localStorage.setItem('auth-session-token', '#{token}')").then ->
#       browser.refresh().then ->
#         pageReady = true
#   browser.wait -> pageReady


# describe 'Test taxon for observateur', ->

#   beforeEach ->
#     login()

#   afterEach ->
#     browser.executeScript("window.localStorage.clear()")

#   it 'Test get taxon list', ->
#     browser.setLocation('taxons').then ->
#       taxons = element.all(`by`.repeater('taxon in taxons'))
#       expect(taxons.count()).toEqual(3)

#   it 'Test view taxon', ->
#     browser.setLocation('taxons').then ->
#       taxons = element.all(`by`.repeater('taxon in taxons'))
#       taxons.get(0).element(`by`.css('a')).click().then ->
#         element(`by`.binding('taxon.libelle_long')).getText().then (value) ->
#           expect(value).toBe('Chauves-souris')

# describe 'Test taxon for adminstrateur', ->

#   beforeEach ->
#     login('Administrateur')

#   afterEach ->
#     browser.executeScript("window.localStorage.clear()")

#   it 'Test get taxon list', ->
#     browser.setLocation('taxons').then ->
#       expect($('a[name="create-taxon"]').isDisplayed()).toBe(true)

#   it 'Test edit taxon', ->
#     browser.setLocation('taxons').then ->
#       taxons = element.all(`by`.repeater('taxon in taxons'))
#       taxons.get(0).element(`by`.css('a')).click().then ->
#         browser.getCurrentUrl().then (url) ->
#           taxonUrl = url
#           editElement = $('a[name="edit-taxon"]')
#           expect(editElement.isDisplayed()).toBe(true)
#           editElement.click().then ->
#             libelle_longElement = element(`by`.model('taxon.libelle_long'))
#             libelle_courtElement = element(`by`.model('taxon.libelle_court'))
#             descriptionElement = element(`by`.model('taxon.description')).element(`by`.css('.ta-scroll-window'))
#             libelle_longElement.clear().sendKeys('new libelle long')
#             libelle_courtElement.clear().sendKeys('new libelle court')
#             descriptionElement.click().then ->
#               browser.driver.actions()
#                 .sendKeys(protractor.Key.chord(protractor.Key.CONTROL, "a"))
#                 .sendKeys(protractor.Key.DELETE)
#                 .sendKeys('new description').perform()
#               saveTaxonButton = $('input[name="save-taxon"]')
#               expect(saveTaxonButton.isDisplayed()).toBe(true)
#               saveTaxonButton.click().then ->
#                 browser.sleep(1000).then ->
#                   browser.get(taxonUrl).then ->
#                     element(`by`.binding('taxon.libelle_long')).getText().then (text) ->
#                       expect(text).toBe('new libelle long')
#                     element(`by`.binding('taxon.libelle_court')).getText().then (text) ->
#                       expect(text).toBe('new libelle court')
#                     element(`by`.binding('taxon.description')).getText().then (text) ->
#                       expect(text).toBe('new description')
