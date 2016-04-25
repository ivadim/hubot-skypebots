request = require 'request'
{EventEmitter} = require 'events'

class SkypeChatClient extends EventEmitter
  
  RENEW_BEFORE: 600  # 10 minutes before oauth token expiration
  MILLISECONDS_IN_SECOND: 1000
  
  constructor: (options, robot) ->
    unless options.appId? and options.appSecret?
      @robot.logger.error "Skype AppId and Skype AppSecret are mandatory"
      process.exit(1)
    @robot = robot
    @logger = robot.logger
    @oauthUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
    @skypeApiUrl = 'https://apis.skype.com/v2/'
                    
    @oauthContent =
       "client_id"     : options.appId
       "client_secret" : options.appSecret
       "grant_type"    : 'client_credentials'
       "scope"         : 'https://graph.microsoft.com/.default'
       
    @_listen options.listenPath
    
    @auth = {}
  
  send: (conversationId, message) ->
    @_withAuth (err, auth) =>
      if err
        @emit 'error', err
      else
        requestOptions =
          "url": "#{@skypeApiUrl}/conversations/#{conversationId}/activities/"
          "json": true
          "body": @_wrapMessage(message)
          "auth": "bearer": auth.token
          
        request.post requestOptions, (err, response, body) =>
          if err
            @emit 'error', err
          else
            @logger.debug("Successfully send message: '#{message}' to #{conversationId}")
          
  skypeIdToName: (id) ->
    id.substring(id.indexOf(":") + 1, id.length)
    
  escape: (message) ->
    return message.replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
    
  isGroupMessage: (event) ->
    to = event.to
    suffix = '@thread.skype'
    return to.indexOf(suffix, to.length - suffix.length) != -1
        
  _listen: (path) ->
    @logger.info "Skype Chat Client is listening requests on #{path}"
    @robot.router.post path, (req, res) =>
      @logger.debug "Skype Chat Client received data:"
      @logger.debug "\t#{JSON.stringify(req.body)}"
      
      for event in req.body
        _handleInputEvent event
        
      res.send 'OK'
      
  _handleInputEvent: (event) ->
    activity = event.activity
    switch activity
      when 'message'
        @emit 'MessageReceived', event
      when 'contactRelationUpdate'
        if event.action == 'add'
          @emit 'ContactAdded', event
        else
          @emit 'ContactRemoved', event
      when 'conversationUpdate'
        @emit('TopicUpdated', event) if event.topicName
        @emit('MembersAdded', event) if event.membersAdded
        @emit('MembersRemoved', event) if event.membersRemoved
        @emit('HistoryDisclosed', event) if event.historyDisclosed
      when 'attachment'
        @logger.info 'attachment event is unsupported'
      else
        @logger.warn "Received unsuppored event type #{activity}"
    @emit event.activity, event
        
           
  _wrapMessage: (message) ->
    return {"message": {"content": message}}
       
  _isOauthTokenValid: (auth) ->
    return auth?.token? && (auth?.expire_time?.getTime() >= new Date().getTime())
  
  _getExpireDate: (expires_in) ->
    nowInMilliseconds = new Date().getTime()
    expireAfter = (expires_in - @RENEW_BEFORE) * @MILLISECONDS_IN_SECOND
    return new Date(nowInMilliseconds + expireAfter)
    
  _withAuth: (callback) ->
    if @_isOauthTokenValid(@auth)
      @logger.debug("Using old oauth token")
      callback null, @auth
    else
      @logger.debug("Generate new oauth token")
      request.post url: @oauthUrl, form: @oauthContent, (err, response, body) =>
        try
          data = JSON.parse(body)
          if err || data.error
            callback "#{err} #{body}"
          else
            @auth =
              "token": data.access_token
              "expire_time": @_getExpireDate(data.expires_in)
            callback null, @auth
         catch exception
           callback exception
          
module.exports = { SkypeChatClient }