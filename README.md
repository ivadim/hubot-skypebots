# Depricated repository. This project isn't suppoted anymore. Please use official [Microsoft Bot SDK](https://docs.botframework.com/en-us/skype/getting-started) which has more features!
A Skype Bot Api Adapter for Hubot
--------------------------------
[![Build Status](https://travis-ci.org/ivadim/hubot-skypebots.svg?branch=master)](https://travis-ci.org/ivadim/hubot-skypebots)
[![npm version](https://badge.fury.io/js/hubot-skypebots.svg)](https://badge.fury.io/js/hubot-skypebots)

## Installation

* Signup to the Skype Bot Platform preview program: https://www.skype.com/en/developer/signup/
* Follow https://developer.microsoft.com/en-us/skype/bots/docs to create a new bot and obtain an Application ID and a Microsoft Application Secret
* (optional) Generate a new hubot using official instruction https://hubot.github.com/docs/
* Install a SkypeBots adapter 
`npm install --save hubot-skypebots`

## Configuration

* *SKYPE_BOTS_APP_ID* - the Application ID generated in a Microsoft portal
* *SKYPE_BOTS_APP_SECRET* - the Application Secret generated in the Microsoft portal
* *SKYPE_BOTS_BOT_ID* - a Skype bot ID
* *SKYPE_BOTS_LISTEN_PATH* - a web path on your server to listen chat responses/outgoing webhooks. The url should be accessable from the internet. 

```
export SKYPE_BOTS_APP_ID=111111111-aaaa-bbbb-cccc-222222222222
export SKYPE_BOTS_APP_SECRET=secret_secret
export SKYPE_BOTS_BOT_ID=28:xxxxxxx-aaaa-bbbb-cccc-zzzzzzzzzzzz
export SKYPE_BOTS_LISTEN_PATH=/skype
`bin/hubot -a skypebots`
```

## Encoding html entities 

By default html entities "<",">" and "&" are escaped. To disable this behaviour you can set a property 'envelope.escape' to `false`. 
Bear in mind that Skype doesn't allow some html tags and silently ignores messages with unclosed tags.

```
  robot.respond /small/i, (res) ->
    html = "<font size=\"15\">It's small</font>"
    res.send html
```

```
  robot.respond /big/i, (res) ->
    res.envelope.escape = false
    html = "<font size=\"15\">It's big</font>"
    res.send html
```

## Send files

Attachments can be send using Skype Bot Api. Supported types 'Images', 'Videos' and 'Files'. 
To send attachment you need to emit a 'skype:sendAttachment' event with params:
* user - a User object
* attachmentName - File/Image/Video name
* attachmentType - a type of a data content (File, Image or Video)
* originalStream - a nodejs [stream](https://nodejs.org/api/stream.html) of the data content
* thumbnailStream - (optional) nodejs [stream](https://nodejs.org/api/stream.html) of a video thumbnail content. Used only by Video type. Videos thumbnails should be JPEG

### Send File
```
robot.respond /get settings/i, (res) ->
    user = res.envelope.user
    originalStream = fs.createReadStream("files/settings.json")
    robot.emit 'skype:sendAttachment', user, 'settings.json', 'FILE',  originalStream
```

### Send Image

```
robot.respond /get image with funny cats/i, (res) ->
    user = res.envelope.user
    originalStream = fs.createReadStream("files/funny_cats.jpg")
    robot.emit 'skype:sendAttachment', user, 'funny_cats.jpg', 'Image',  originalStream
```

### Send Video
```
robot.respond /get epic fail video/i, (res) ->
    user = res.envelope.user
    originalStream = fs.createReadStream("files/epic_fail.mp4")
    thumbnailStream = fs.createReadStream("files/thumbnail-epic_fail.jpg")
    robot.emit 'skype:sendAttachment', user, 'epic_fail.mp4', 'Video',  originalStream, thumbnailStream
```

## Receive File

Attachments can be received using Skype Bot Api. When SkypeBots adapter receive a new attachment it emit a 'skype:attachment' with params
* user - a User object
* attachmentName - File/Image/Video name
* attachmentType - a type of a data content (File, Image or Video)
* attachmentStream - a nodejs [stream](https://nodejs.org/api/stream.html) of a data content

```
robot.on 'skype:attachment', (user, attachmentName, attachmentType, attachmentStream) ->
    robot.logger.info "Revceived attachment #{attachmentName} of type #{attachmentType} from #{user.id} in room #{user.room}"
    attachmentStream.pipe(fs.createWriteStream("files/#{attachmentName}"))
```
