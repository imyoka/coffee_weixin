webot= require 'webot-meiva'
Webot= webot.Webot
Info= webot.Info
wechat= require 'wechat-smp'

mp= wechat()

# keep the original watch method private,
# but accessible.
Webot::_watch = Webot::watch
Webot::watch= (app, options)->
	options= options or {}
	if typeof options is 'string' then options= {token: options}

	self= @
	path= options.path or '/'

	# start must go before cookie middleware
	app.use path, mp.start options

	# handlers can be set at last
	process.nextTick ->
		app.use path, self.middleware()
		app.use path, mp.end()

Webot::formatReply= (info)->
	# the response body should be data we want to send to wechat
	# empty news will shut up wechat
	reply= info.reply or ''
	msgType= if 'object' isnt typeof reply then 'text' else reply.type
	kfAccount= reply.kfAccount or ''
	content= reply.content or reply

	if msgType isnt 'text'
		msgType= msgType or 'news'
		if msgType is 'news' and not Array.isArray content
			content= [content]
	if info.noReplay
		content= ''
		msgType= 'text'
	return {
		sp: info.sp
		uid: info.uid
		msgType: msgType
		content: content
		createTime: new Date()
		kfAccount: kfAccount
	}

Webot::middleware= ->
	self= @
	return (req, res, next)->
		info= Info req.body
		info.req= req
		info.res= res
		info.session= req.session

		self.reply info, (err, info)->
			res.body= self.formatReply info
			next()
			
# Export `wechat-mp` module.
webot.wechat = wechat

module.exports = webot