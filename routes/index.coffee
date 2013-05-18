
settings = require '../src/settings'
auth = require '../src/auth'

Sequelize = require 'sequelize'
_ = Sequelize.Utils._

Setting = require '../models/setting'
Job = require '../models/job'
Build = require '../models/build'

async = require 'async'
logger = require 'winston'

deCamelCase = (str) ->
	str.replace(/([A-Z])/g, " $1").replace /^./, (str) ->
  		str.toUpperCase()

module.exports.index = (req, res) ->
	isJSON = req.param('type') is "json"

	handleJobs = (jobs) ->
		async.each jobs, (job, done) ->
			async.parallel [
				(cb) ->
					Build.find(
						order: "startDate DESC"
						where:
							JobId: job.id
							success: 1
							inProgress: 0
					).success (b) -> cb(null, b)
				, (cb) ->
					Build.find(
						order: "startDate DESC"
						where:
							JobId: job.id
							success: 0
					).success (b) -> cb(null, b)
				, (cb) ->
					Build.find(
						order: "startDate DESC"
						where:
							JobId: job.id
					).success (b) -> cb(null, b)
			], (err, results) ->
				[job.lastSuccess, job.lastFailure, job.mostRecent] = results

				done()
		, (err) ->
			res.render "index",
				title: "Jobs"
				jobs:  jobs

	if req.isAuthenticated()
		Job.findAll().success handleJobs
	else
		Job.findAll(isPublic: 1).success handleJobs

module.exports.settings = (req, res) ->
	res.render "settings", title: "Settings", fields: settings.all()

module.exports.settings_post = (req, res) ->
	chainer = new Sequelize.Utils.QueryChainer
	for k, v of req.body
		setting = settings.get k
		setting.value = v
		chainer.add(setting.save())

	chainer.run().success ->
		settings.recache(req)
		res.render 'settings', title: 'Settings', fields: settings.all(), success: 'Settings updated' 
	.error (errs) ->
		throw errs if errs

	
module.exports.add = (req, res) ->
	res.render "jobs_add", {title: "Add Job", body: req.body}
	
module.exports.add_post = (req, res) ->
	for t in ['title', 'repo', 'repoType']
		if not req.body[t]
			return res.render "jobs_add", {
				title: "Add Job"
				body: req.body
				error: "Don't leave #{deCamelCase(t)} blank!"
			}

	if not req.body.isPublic
		req.body.isPublic = 0

	slug = req.body.title.replace(/[^a-zA-Z0-9.-]/g, '-')

	# make sure no job already has the same slug
	Job.find(where: slug: slug).success (job) ->
		if job
			return res.render "jobs_add", {
				title: "Add Job"
				body: req.body
				error: "A job already exists with that name!"
			}

		props = {}
		_.extend(props, req.body, slug: slug)

		Job.create(props).success (newjob) ->
			res.redirect '/jobs/' + slug + '/'
		.error (err) ->
			res.render "jobs_add", {
				title: "Add Job"
				body: req.body
				error: err.toString()
			}
	
module.exports.delete = (req, res) ->
	res.render "index",
		title: "Express"
	

module.exports.job = require './job'
module.exports.build = require('./build')
