
async = require 'async'
logger = require 'winston'
_ = require('sequelize').Utils._

Job = require '../models/Job'
Build = require '../models/Build'

auth = require '../src/auth'
BuildExecutor = require '../src/build_executor'

deCamelCase = (str) ->
	str.replace(/([A-Z])/g, " $1").replace /^./, (str) ->
  		str.toUpperCase()

module.exports.job = (req, res, next) ->
	job_slug = req.param('name')

	if not isNaN(parseInt(job_slug, 10))
		Job.find(where: id: parseInt(job_slug, 10)).success (job) ->
			res.redirect job.link(), 301
	else
		Job.find(where: slug: job_slug).success (job) ->
			if not job
				return next()

			doJob = () ->
				job.getBuilds(50).success (builds) ->
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

						res.render 'job', {title: job.title, job: job, builds: builds}

			if not req.isAuthenticated() and not job.isPublic
				auth.middleware req, res, doJob
			else
				doJob()

module.exports.build_job = (req, res, next) ->
	job_slug = req.param('name')
	token = req.query.token
	payload = req.body.payload

	Job.find(where: slug: job_slug, triggerKey: token).success (job) ->
		logger.info "Build triggered for #{job_slug}, #{token}"
		if not job
			logger.info "No matching jobs found!"
			return next()

		b = new BuildExecutor job, req, payload
		b.build()
		res.json result: "success", success: true

module.exports.settings = (req, res, next) ->
	job_slug = req.param('name')

	Job.find(where: slug: job_slug).success (job) ->
		job.JobId = job.id
		res.render "jobs_add", {title: "Edit #{job.title}", body: job}

module.exports.settings_post = (req, res, next) ->
	for t in ['title', 'repo', 'repoType', 'JobId']
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
	Job.find(where: id: req.body.JobId).success (job) ->
		props = {}
		_.extend(props, req.body, slug: slug)

		job.updateAttributes(props).success () ->
			res.redirect '/jobs/' + slug + '/'
		.error (err) ->
			res.render "jobs_add", {
				title: "Edit #{job.title}"
				body: req.body
				error: err.toString()
			}
