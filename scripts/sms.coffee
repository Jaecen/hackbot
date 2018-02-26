# Description:
#   Interface for SMSs through Twilio
#
# Notes:
#   
#

accountSid = process.env.TWILIO_ACCOUNT_SID
authToken = process.env.TWILIO_AUTH_TOKEN
fromNumber = process.env.TWILIO_FROM_NUMBER
phoneRoom = process.env.TWILIO_ROOM

twilio = require('twilio');
client = new twilio(accountSid, authToken);

_ = require('lodash');

sms = null

module.exports = (robot) ->

	robot.brain.on 'loaded', (data) ->
		sms = robot.brain.get('sms') or {}

	robot.router.post '/hubot/sms', (req, res) ->
		res.send 'OK'
		addToThread robot,req.body

	robot.respond /sms: ([\s|\S]+)/i, (msg) ->
		if isThread msg
			client.messages.create
				body: msg.match[1]
				to: '+1' + phoneFromThread msg
				from: fromNumber
			.then (message) ->
				robot.logger.debug 'Twilio message ' + message.sid + ' sent.'
				robot.adapter.client.web.reactions.add('tada', {channel: msg.envelope.message.room, timestamp: msg.envelope.message.id})
		else
			msg.reply "Oops... you are not in an active SMS thread!"

addToThread = (robot, body) ->	
	if body.From of sms
		robot.adapter.client.web.chat.postMessage(phoneRoom, body.Body, {thread_ts: sms[body.From].thread_ts, as_user: false, username: body.From, icon_emoji: ':phone:', link_names: 1})	
	else
		robot.adapter.client.web.chat.postMessage(phoneRoom, ':point_down:', {as_user: false, username: 'SMS with '+body.From, icon_emoji: ':phone:', link_names: 1})
		.then (msg) ->
			sms[body.From] = { thread_ts: msg.ts }
			robot.brain.set 'sms', sms
	
			addToThread robot,body

isThread = (msg) ->
	phone = phoneFromThread msg 
	phone?

phoneFromThread = (msg) ->
	_.findKey sms, 'thread_ts': msg.envelope.message.thread_ts