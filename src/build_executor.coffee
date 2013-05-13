
Sequelize = require "sequelize"
_ = Sequelize.Utils._
logger = require 'winston'
async = require 'async'

sys = require 'sys'
fs = require 'fs'
mkdirp = require 'mkdirp'
async = require 'async'
path = require 'path'
child_process = require 'child_process'

Build = require '../models/build'

copy = require './copy'
settings = require '../src/settings'
db = require '../src/db'

rtrim = (s) -> s.replace(/\s+$/,'')

class BuildExecutor
	constructor: (@job, @req, @payload) ->
		@branches = @job.branches.split(',').map (v) -> return v.trim()

		# handle default case
		@branches = [''] if @branches.length is 0

	build: () ->
		logger.info "Building #{@branches.length} branches: '#{@branches.join(',')}'"

		async.eachSeries @branches, @buildBranch

	buildBranch: (branch, done) =>
		logger.info "Building #{branch}. Finding last build..."

		Build.find(order: "buildNumber DESC", where: JobId: @job.id).success (lastBuild) =>
			logger.info "Found last build: #{lastBuild}"

			build_number = if lastBuild then lastBuild.buildNumber + 1 else 1

			logger.info "Starting build #{build_number} for #{@job.title}"

			@commit = if @payload then @payload.after else ''

			logger.info "Starting build process for branch: '#{branch}'"
			startDate = new Date

			build_dir = _.template(settings.get('build_dir').value, {
				job_name: @job.slug
				build_number: build_number
				branch: branch
			})

			logger.info "Checking sanity of build directory: #{build_dir}"
			fs.exists build_dir, (exists) =>
				if not exists
					logger.info "The build directory does not exist, cloning..."
					mkdirp build_dir, (err) =>
						throw err if err

						logger.info "Spawing git..."

						git = child_process.spawn('git', ['clone', @job.repo, '.'], cwd: build_dir)
						git.stdout.on 'data', (data) -> logger.info "[GIT] " + rtrim(data.trim())
						git.stderr.on 'data', (data) -> logger.info "[GIT] " + rtrim(data.trim())
						git.on 'close', (code) ->
							logger.info "...done cloning!"
							@buildSane branch, startDate, build_number, build_dir, done
				else
					@buildSane branch, startDate, build_number, build_dir, done

	buildSane: (branch, startDate, build_number, build_dir, cb) =>
		Build.create({
			buildNumber: build_number
			commit: @commit
			source: @req.ip
			cause: if @req.query.cause then @req.query.cause else ""
			compareUrl: if @payload then @payload.compare else ""
			commitsInformation: if @payload then JSON.stringify(@payload.commits) else "[]"
			startDate: startDate
			consoleOutput: ""
			success: 0
			duration: 0
			branch: branch
			inProgress: 1,
			JobId: @job.id
		}).success (build) =>
			args = ['checkout', @commit, '-b', branch]

			if branch.length is 0 and @commit.length > 0
				# this is how you checkout on the default branch
				args = ['checkout', @commit, '.']
			else if branch.length is 0 and @commit.length is 0
				args = ['pull']
			else if branch.length > 0 and @commit.length is 0
				args = ['checkout', '-b', branch]

			logger.info "Checking out '#{@commit}' on '#{branch}'..."
			git = child_process.spawn 'git', args, cwd: build_dir
			git.stdout.on 'data', (data) -> build.consoleOutput += data
			git.stderr.on 'data', (data) -> build.consoleOutput += data
			git.on 'close', (code) =>
				logger.info "...done!"

				if @job.buildCommand.length is 0
					return @compilingComplete(build_dir, startDate, branch, build, cb)(0)

				logger.info "Building using command: #{@job.buildCommand}"

				builder = child_process.exec @job.buildCommand, cwd: build_dir
				handleData = (data) ->
					build.consoleOutput += data
				builder.stdout.on 'data', handleData
				builder.stderr.on 'data', handleData
				builder.on 'close', @compilingComplete(build_dir, startDate, branch, build, cb)

	compilingComplete: (build_dir, startDate, branch, build, cb) =>
		return (code) =>
			endDate = new Date
			build.success = code is 0
			build.duration = Math.round((endDate.getTime() - startDate.getTime()) / 1000) 
			build.inProgress = 0

			logger.info "[BUILD] exited with #{code} in #{build.duration} seconds"

			build.save().success () ->
				logger.info "[BUILD] Build information saved!"

			if build.success
				raw_artifacts = @job.artifacts.split(',')
				artifacts = raw_artifacts.map (v) -> path.join(build_dir, v.trim())

				logger.info "Looking for #{artifacts.length} artifacts: #{artifacts.join(', ')}"

				async.map artifacts, (art, cb) ->
					fs.exists art, (res) -> cb(null, res)
				, @saveArtifacts(raw_artifacts, artifacts, branch, build, cb)
			else
				cb()

	saveArtifacts: (raw_artifacts, artifacts, branch, build, cb) =>
		return (err, results) =>
			throw err if err

			artifact_dir = _.template(settings.get('artifact_dir').value, {
				job_name: @job.slug
				build_number: build.buildNumber
				branch: branch
			})

			for v, i in results
				if not v
					logger.warning "#{artifacts[i]} does not exist!"
				else
					# save the artifact, but first make necesssary dirs
					artifact_store = path.join(artifact_dir, raw_artifacts[i])
					art = artifacts[i]
					logger.info "Saving #{art} to #{artifact_store}"
					fs.exists path.dirname(artifact_store), (exists) ->
						if not exists
							mkdirp path.dirname(artifact_store), (err) ->
								throw err if err
								copy.copy art, artifact_store, (err) -> throw err if err
						else
							copy.copy art, artifact_store, (err) -> throw err if err

			cb()

module.exports = BuildExecutor
