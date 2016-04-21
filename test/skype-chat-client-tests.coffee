chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

{SkypeChatClient} = require('./../src/skype-chat-client')

describe 'SkypeChatClient', ->
  beforeEach ->
    opts =
      "appId": "testId"
      "appSecret": "appSecret"
     @robot =
       logger:
         info: sinon.spy()
       router:
         post: sinon.spy()
    @skype = new SkypeChatClient opts, @robot

  afterEach ->
    #pass
    
  describe 'skypeIdToName', ->
    it 'Correctly transform real user skypeId to name', ->
      expect(@skype.skypeIdToName('8:jonsnow')).to.equal('jonsnow')
        
    it 'Correctly transform bot skypeId to name', ->
      expect(@skype.skypeIdToName('28:1e33f25e-cca4-4c08-b40f-5c6e006cd410'))
        .to.equal('1e33f25e-cca4-4c08-b40f-5c6e006cd410')
  
  describe 'escape', ->
    it 'Escape html entities', ->
      expect(@skype.escape('<test&/>')).to.equal('&lt;test&amp;/&gt;')
    
  describe '_isOauthTokenValid', ->
    it 'Expired token', ->
      auth =
      "token" : "winter_is_comming"
      "expire_time": new Date(new Date().getTime() - 60*1000)
      expect(@skype._isOauthTokenValid(auth)).to.equal(false)
    
    it 'Valid token', ->
      auth =
      "token" : "here_me_roar"
      "expire_time": new Date(new Date().getTime() + 60*1000)
      expect(@skype._isOauthTokenValid(auth)).to.equal(true)
        
    it 'With empty auth', ->
      auth = null
      expect(@skype._isOauthTokenValid(auth)).to.equal(false)
    