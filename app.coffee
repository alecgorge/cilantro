
require('console-trace')(always: true)

###
Module dependencies.
###
express = require("express")
http = require("http")
passport = require("passport")
path = require("path")

ui = require("./routes")
user = require("./routes/user")

db	 = require('./src/db')
auth = require("./src/auth")
settings = require('./src/settings')

Action = require './models/action'
Job = require './models/job'
Setting = require './models/setting'
User = require './models/user'
Build = require './models/build'

Job.hasMany(Action, {joinTableName: 'JobActions'})
Job.hasMany(Build, {joinTableName: 'JobBuilds'})

Action.belongsTo(Job)
Build.belongsTo(Job)

Build.sync()
Action.sync()
Job.sync()
Setting.sync()
User.sync()

db.sync()

User.findAll().success (users) ->
	if users.count is 0
		User.createUser("admin", "admin", "demo")

app = express()

# all environments
app.set "port", process.env.PORT or 3000
app.set "views", __dirname + "/views"
app.set "view engine", "jade"
app.set "trust proxy", true

app.use (req, res, next) ->
	origRender = res.render
	
	res.render = (view, locals, callback) ->
		if "function" is typeof locals
			callback = locals
			locals = `undefined`

		if not locals
			locals = {}
		locals.req = req

		origRender.call res, view, locals, callback

	next()

app.use require('connect-assets')()
app.use express.favicon()
app.use express.logger("dev")
app.use express.cookieParser("your secret here")
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.session()

# initialize passport
app.use passport.initialize()
app.use passport.session()

app.use app.router
app.use require("stylus").middleware(__dirname + "/public")

app.use express.static(path.join(__dirname, "public"))

# development only
app.configure 'development', ->
	console.log "Running in development mode."
	app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

app.configure 'production', ->
	console.log "Running in production mode."
	app.use express.errorHandler()

app.get "/", ui.index

app.get "/users", auth.middleware, user.index

app.get "/users/add", auth.middleware, user.add
app.post "/users/add", auth.middleware, user.add_post

app.get "/users/:username/edit", auth.middleware, user.edit
app.post "/users/:username/edit", auth.middleware, user.edit_post

app.post "/users/:username/delete", auth.middleware, user.delete

app.get "/settings", auth.middleware, ui.settings
app.post "/settings", auth.middleware, ui.settings_post

app.get "/login", user.login
app.post "/login", user.login_post

app.get "/logout", user.logout

app.get "/jobs/", ui.index

app.get "/jobs/:name", ui.job.job
app.post "/jobs/:name/build", ui.job.build_job

app.get "/jobs/:name/edit", auth.middleware, ui.job.settings
app.post "/jobs/:name/edit", auth.middleware, ui.job.settings_post

app.get "/jobs/:name/builds/:build_number", ui.build.index
app.get "/jobs/:name/builds/:build_number/artifacts/*", ui.build.artifact_download

app.get "/jobs/add", auth.middleware, ui.add
app.post "/jobs/add", auth.middleware, ui.add_post

app.post "/jobs/delete", auth.middleware, ui.delete

app.use (req, res) ->
	res.status 404	
	res.render '404', status: 404, title: '404', url: req.url 

http.createServer(app).listen app.get("port"), ->
	console.log "Express server listening on port " + app.get("port")
	settings.load app
