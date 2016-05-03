{Robot, Adapter, TextMessage, User, TopicMessage, EnterMessage, LeaveMessage} = require 'hubot'
{SkypeChatClient} = require './skype-chat-client'

class SkypeBots extends Adapter

  constructor: (robot) ->
    @robot = robot

  send: (envelope, strings...) ->
    message = strings.join()
    message = @skype.escape(message) unless envelope?.escape == false
    conversationId = @_getConversationId(envelope.user)
    @skype.send conversationId, message
    
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
    
    listenPath = process.env.SKYPE_BOTS_LISTEN_PATH
    
    skypeOptions =
      "appId": process.env.SKYPE_BOTS_APP_ID
      "appSecret": process.env.SKYPE_BOTS_APP_SECRET
     
      
    @skype = new SkypeChatClient skypeOptions, robot
    
    # # register events
    @skype.on 'MessageReceived', (event) =>
      user = @getUser(event)
      @receive new TextMessage user, event.content.trim()
      
    @skype.on 'AttachmentReceived', (event) =>
      user = @getUser(event)
      @robot.logger.info(event)
      name = @_getFileNameOrDefault event
      for view in event.views
        if view.viewId == 'thumbnail'
          name = view.viewId + '-' + name
        @skype.downloadAttachment event.id, view.viewId, (err, stream) =>
          @robot.emit 'skype:attachment', user, name, event.type, stream

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
       
    
    # listen for attachments
    @robot.on 'skype:sendAttachment', (user, name, type, originStream, thumbnailStream) =>
      conversationId = @_getConversationId(user)
      @skype.uploadAttchment conversationId, name, type, originStream, thumbnailStream
      
      
    # listen for webhooks from skype
    @robot.logger.info "Skype Chat Client is listening requests on #{listenPath}"
    @robot.router.post listenPath, (req, res) =>
      @robot.logger.debug "Skype Chat Client received data:"
      @robot.logger.debug "\t#{JSON.stringify(req.body)}"
      
      for event in req.body
        @skype._handleInputEvent event
        
      res.send 'OK'
      
    @robot.logger.info "Connected to SkypeNet..."
    @emit "connected"
   
  _getConversationId: (user) ->
    return if user.room == 'private' then user.id else user.room
    
  _getFileNameOrDefault: (event) ->
    if event.name
      name = event.name
    else
      name = 'video.mp4' if event.type == 'Video'
      name = 'image.jpg' if event.type == 'Image'
      name = 'file.txt' if event.type == 'File'
    
    return name
    
exports.use = (robot) ->
  new SkypeBots robot

