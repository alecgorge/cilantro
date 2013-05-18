
_ = require('sequelize').Utils._

fs = require 'fs'
path = require 'path'

auth = require '../src/auth'
settings = require '../src/settings'

Job = require '../models/job'
Build = require '../models/build'

module.exports.index = (req, res, next) ->
	job_slug = req.param 'name'
	build_number = req.param 'build_number'

	Job.find(where: slug: job_slug).success (job) ->
		return next() if not job

		doBuild = () ->
			Build.find(where: buildNumber: build_number).success (build) ->
				return next() if not build

				res.render "build_page", title: "Build ##{build_number}", job: job, build: build

		if not req.isAuthenticated() and not job.isPublic
			auth.middleware req, res, doBuild
		else
			doBuild()

module.exports.artifact_download = (req, res, next) ->
	job_slug = req.param 'name'
	build_number = req.param 'build_number'

	Job.find(where: slug: job_slug).success (job) ->
		return next() if not job

		doBuild = () ->
			Build.find(where: buildNumber: build_number).success (build) ->
				return next() if not build

				parts = req.path.split('/artifacts/')
				parts.shift()
				artifact_path = parts.join('/artifacts/')

				artifact_path = path.join(_.template(settings.get('artifact_dir').value, {
					job_name: job.slug
					build_number: build.buildNumber
					branch: build.branch
				}), artifact_path)

				fs.exists artifact_path, (exists) ->
					return next() if not exists

					res.sendfile artifact_path, maxAge: 1000 * 60 * 60 * 24 * 365 # one year

		if not req.isAuthenticated() and not job.isPublic
			auth.middleware req, res, doBuild
		else
			doBuild()
