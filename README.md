A Skype Bot Api Adapter for Hubot
--------------------------------

## Installation

* Signup to the Skype Bot Platform preview https://www.skype.com/en/developer/signup/
* Follow https://developer.microsoft.com/en-us/skype/bots/docs to create new bot and obtain Application ID and Microsoft Application Secret

* `npm install --save hubot-skypebots`
* Run hubot `bin/hubot -a skypebots`

## Configuration

* *SKYPE_BOTS_APP_ID* - Application ID generated in Microsoft portal
* *SKYPE_BOTS_APP_SECRET* - Application Secret generated in Microsoft portal
* *SKYPE_BOTS_BOT_ID* - Skype bot ID
* *SKYPE_BOTS_LISTEN_PATH* - web path in your server to listen chat responses.

```
export SKYPE_BOTS_APP_ID=111111111-aaaa-bbbb-cccc-222222222222
export SKYPE_BOTS_APP_SECRET=secret_secret
export SKYPE_BOTS_BOT_ID=28:xxxxxxx-aaaa-bbbb-cccc-zzzzzzzzzzzz
export SKYPE_BOTS_LISTEN_PATH=/skype
`bin/hubot -a skypebots`
```

