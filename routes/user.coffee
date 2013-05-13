
passport = require('../src/auth').passport

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