{Robot, Adapter, TextMessage, User, TopicMessage, EnterMessage, LeaveMessage} = require 'hubot'
{SkypeChatClient} = require './skype-chat-client'

class SkypeBots extends Adapter

  constructor: (robot) ->
    @robot = robot

  send: (envelope, strings...) ->
    message = strings.join()
    #message = @skype.escape(message)
    if envelope.room == 'private'
      @skype.send envelope.user.id, message
    else
      @skype.send envelope.room, message

  emote: (envelope, strings...) ->
    @send envelope, strings.map((str) -> "*#{str}*")...

  reply: (envelope, strings...) ->
    @send envelope, strings.map((str) -> "@#{envelope.user.name}: #{str}")...
    
  shutdown: () ->
    @robot.shutdown()
    process.exit 0
  
  getUser: (event) ->
    if @skype.isGroupMessage event
      r = event.to
    else
      r = 'private'
    return @robot.brain.userForId event.from, name: @skype.skypeIdToName(event.from), room: r
  
  run: ->
    self = @
    robot = @robot
    
    skypeOptions =
      "appId": process.env.SKYPE_BOTS_APP_ID
      "appSecret": process.env.SKYPE_BOTS_APP_SECRET
      "listenPath": process.env.SKYPE_BOTS_LISTEN_PATH
    
    @skype = new SkypeChatClient skypeOptions, robot
    
    # # register events
    @skype.on 'MessageReceived', (event) =>
      user = @getUser(event)
      @robot.logger.info(user)
      @receive new TextMessage user, event.content.trim()
      
    
    @skype.on 'TopicUpdated', (event) =>
      user = @getUser(event)
      @receive new TopicMessage user, event.topicName.trim()
    
    @skype.on 'MembersAdded', (event) =>
      for member in event.membersAdded
        user = @robot.brain.userForId member, name: @skype.skypeIdToName(member), room: event.to
        @receive new EnterMessage user
        
    @skype.on 'MembersRemoved', (event) =>
      for member in event.membersRemoved
        user = @robot.brain.userForId member, name: @skype.skypeIdToName(member), room: event.to
        @receive new LeaveMessage user
       
    @robot.logger.info "Connected to SkypeNet..."
    @emit "connected"
   

exports.use = (robot) ->
  new SkypeBots robot

