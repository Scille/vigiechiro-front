"use strict"

describe 'E2e login', ->
  content = $("content-directive")
  loginGoogle = element(by.buttonText("Login with Google"))

#   console.log(browser.getCurrentUrl)

  # beforeEach module 'appSettings'

  # beforeEach inject (SETTINGS) ->
  #   console.log(SETTINGS.FRONT_DOMAIN)

#   var firstNumber = element(by.model('first'));
#   var secondNumber = element(by.model('second'));
#   var goButton = element(by.id('gobutton'));
#   var latestResult = element(by.binding('latest'));

  beforeEach ->
    console.log(protractor)
    browser.get('http://localhost:9001')
    # browser.get('http://juliemr.github.io/protractor-demo/');

  it 'Test title', ->
    expect(browser.getTitle()).toEqual('Vigiechiro')


  it 'Test login page', ->
    # expect(browser.getTitle()).toEqual('Vigiechiro')
    expect(content.isDisplayed()).toBe(false)
    expect(loginGoogle.isDisplayed()).toBe(true)

#   it('should add one and two', function() {
#     firstNumber.sendKeys(1);
#     secondNumber.sendKeys(2);

#     goButton.click();

#     expect(latestResult.getText()).toEqual('3');
#   });

#   it('should add four and six', function() {
#     firstNumber.sendKeys(4);
#     secondNumber.sendKeys(6);

#     goButton.click();

#     expect(latestResult.getText()).toEqual('10');
#   });
# });
