chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

{SkypeChatClient} = require('./../src/skype-chat-client')
{User} = require 'hubot'
SkypeAdapter = require('./../src/skypebots')

describe 'SkypeBotsAdapter', ->

  beforeEach ->
    @bots = SkypeAdapter.use null
    
  describe '_getConversationId', ->
    it 'Should be a private room', ->
      user = new User('8:varys')
      user.room = 'private'
      expect(@bots._getConversationId(user)).to.equal('8:varys')

    it 'Should be a chat room', ->
      user = new User('8:daenerys')
      user.room = '19:meereen@thread.skype'
      expect(@bots._getConversationId(user)).to.equal('19:meereen@thread.skype')
      
  describe '_getFileNameOrDefault', ->
    it 'it should return name from event', ->
      event =
        "name": "westeros.jpg"
        "type": "Image"
      expect(@bots._getFileNameOrDefault(event)).to.equal('westeros.jpg')
      
    it 'it should return default value for Image', ->
      event =
        "type": "Image"
      expect(@bots._getFileNameOrDefault(event)).to.equal('image.jpg')
      
    it 'it should return default value for Video', ->
      event =
        "type": "Video"
      expect(@bots._getFileNameOrDefault(event)).to.equal('video.mp4')
      
    it 'it should return default value for File', ->
      event =
        "type": "File"
      expect(@bots._getFileNameOrDefault(event)).to.equal('file.txt')
        
  

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
    
    
  describe '_handleInputEvent', ->
    it 'should be a message event', ->
      spy = sinon.spy()
      @skype.on 'MessageReceived', spy
      event =
        "activity": 'message'
      @skype._handleInputEvent event
      expect(spy.called).to.equal(true)
      
    it 'should add contact', ->
      spy = sinon.spy()
      @skype.on 'ContactAdded', spy
      event =
        "activity": "contactRelationUpdate"
        "action": "add"
      @skype._handleInputEvent event
      expect(spy.called).to.equal(true)
      
    it 'should remove contact', ->
      spy = sinon.spy()
      @skype.on 'ContactRemoved', spy
      event =
        "activity": "contactRelationUpdate"
        "action": "remove"
      @skype._handleInputEvent event
      expect(spy.called).to.equal(true)
      
    it 'should remove contact', ->
      spy = sinon.spy()
      @skype.on 'ContactRemoved', spy
      event =
        "activity": "contactRelationUpdate"
        "action": "remove"
      @skype._handleInputEvent event
      expect(spy.called).to.equal(true)
      
    it 'should update topic', ->
      spy = sinon.spy()
      @skype.on 'TopicUpdated', spy
      event =
        "activity": "conversationUpdate"
        "topicName": "winter is coming"
      @skype._handleInputEvent event
      expect(spy.called).to.equal(true)
      
    it 'should add members', ->
      spy = sinon.spy()
      @skype.on 'MembersAdded', spy
      event =
        "activity": "conversationUpdate"
        "membersAdded": ["8:jonsnow", "8:samtarly"]
      @skype._handleInputEvent event
      expect(spy.called).to.equal(true)
      
    it 'should remove members', ->
      spy = sinon.spy()
      @skype.on 'MembersRemoved', spy
      event =
        "activity": "conversationUpdate"
        "membersRemoved": ["8:nedstark", "8:robertbaratheon"]
      @skype._handleInputEvent event
      expect(spy.called).to.equal(true)
      