
passport = require('../src/auth').passport

User = require '../models/user'

module.exports.index = (req, res) ->
	User.findAll().success (users) ->
		res.render "users", title: "Users", users: users

module.exports.add = (req, res, next) ->
	res.render "user_edit", title: "Add User", body: req.body

module.exports.add_post = (req, res, next) ->
	for t in ['username', 'name']
		if not req.body[t]
			return res.render "user_edit", {
				title: "Add User"
				body: req.body
				error: "Don't leave  blank!"
			}

	User.find(where: username: req.body.username).success (user) ->
		if user
			return res.render "user_edit", {
				title: "Add User"
				body: req.body
				error: "A user with that username already exists."
			}

		User.createNew req.body.name, req.body.username, req.body.password, (user) ->
			res.redirect '/users'

module.exports.edit = (req, res, next) ->
	username = req.param('username')

	User.find(where: username: username).success (user) ->
		if not user
			return next()

		res.render "user_edit", title: "Edit #{username}", body: user

module.exports.edit_post = (req, res, next) ->
	username = req.param('username')

	for t in ['username', 'name']
		if not req.body[t]
			return res.render "user_edit", {
				title: username
				body: req.body
				error: "Don't leave  blank!"
			}

	User.find(where: username: username).success (user) ->
		user.updateAttributes(username: req.body.username, name: req.body.name).success () ->
			if req.body.password
				user.updatePassword(req.body.password)
			res.redirect '/users'
		.error (err) ->
			res.render "user_edit", {
				title: "Edit #{username}"
				body: req.body
				error: err.toString()
			}

module.exports.delete = (req, res, next) ->
	username = req.param('username')

	User.find(where: username: username).success (user) ->
		if not user
			return next()

		user.destroy().success () -> res.json result: true

module.exports.logout = (req, res) ->
	req.logout()
	res.redirect('/')

module.exports.login = (req, res) ->
	res.render "login", title: "Log In", post_url: req.url

module.exports.login_post = (req, res, next) ->
	passport.authenticate("local", (err, user, info) ->
		if err
			return next(err)

		if not user
			res.render "login", title: "Log In", error: "Invalid username/password!"
			return

		req.logIn user, (err) ->
			return next(err) if err
			return res.redirect req.query.backto if req.query.backto
			res.redirect "/"
	) req, res, next