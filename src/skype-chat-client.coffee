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
   
   
  downloadAttachment: (attachmentId, viewId, callback) ->
    robot = @robot
    @_withAuth (err, auth) =>
      if err
        callback err
      else
        requestOptions =
          "url": "#{@skypeApiUrl}/attachments/#{attachmentId}/views/#{viewId}"
          "auth": "bearer": auth.token
          encoding: null
        
        callback null, request.get requestOptions
           
  uploadAttchment: (conversationId, name, type, originStream, thumbnailStream) ->
    robot = @robot
    @_withAuth (err, auth) =>
      if err
        @emit 'error', err
      else
        @_stream_to_base64 originStream, (originBase64str) =>
          @_stream_to_base64 thumbnailStream, (thumbnailBase64str) =>
            body =
              "name": name
              "type": type
              "originalBase64": originBase64str
              "thumbnailBase64": thumbnailBase64str
              
            requestOptions =
              "url": "#{@skypeApiUrl}/conversations/#{conversationId}/attachments"
              "json": true
              "auth": "bearer": auth.token
              "body": body
              encoding: null
            
            request.post requestOptions, (err, response, body) =>
              if err
                @emit 'error', err
              else
                @logger.debug("Successfully send attachment #{name} " +
                      "of type #{type} to #{conversationId}")

            
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
  
  _stream_to_base64: (stream, callback) ->
    unless stream
      callback null
    else
      chunks = []
      stream.on 'data', (chunk) ->
        chunks.push(chunk)
      stream.on 'end', ->
        result = Buffer.concat(chunks)
        callback result.toString('base64')
       
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
        @emit 'AttachmentReceived', event
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