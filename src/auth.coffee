
passport = require 'passport'
db = require './db'
LocalStrategy = require('passport-local').Strategy
BasicStrategy = require('passport-http').BasicStrategy

User = require '../models/user'

endsWith = (str, suffix) ->
    return str.indexOf(suffix, str.length - suffix.length) != -1

testAuth = (username, password, done) ->
	User.find(where: username: username).success (user) ->
		if user is null
			return done null, false, message: "Incorrect username."
		if not user.validPassword password
			return done null, false, message: "Incorrect password."

		return done null, user

passport.use new LocalStrategy testAuth
passport.use new BasicStrategy testAuth

passport.serializeUser = (user, done) ->
	done null, user.id

passport.deserializeUser = (id, done) ->
	User.find(id).success (user) ->
		return done(null, false) if not user
		done null, user

module.exports.middleware = (req, res, next) ->
	return next() if req.isAuthenticated()

	passport.authenticate("basic", (err, user, info) ->
		if err
			return next(err)

		if not user
			res.redirect '/login?backto=' + encodeURIComponent(req.path)
			return

		req.logIn user, (err) ->
			return next(err) if err
			next()
	) req, res, next

module.exports.passport = passport
