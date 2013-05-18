
Sequelize = require "sequelize"

Action = require './action'
Build = require './build'

db = require '../src/db'

Job = db.define('Job',
	slug: Sequelize.STRING
	title: Sequelize.STRING
	description: Sequelize.STRING
	buildCommand: Sequelize.STRING
	repoType: Sequelize.STRING
	repo: Sequelize.STRING
	branches: Sequelize.STRING
	webRepoUrl: Sequelize.STRING
	webUrl: Sequelize.STRING
	triggerKey: Sequelize.STRING
	artifacts: Sequelize.STRING
	isPublic: 
		type: Sequelize.INTEGER
		default: 0
,
	instanceMethods:
		getBuilds: (limit=-1) ->
			parms = order: "startDate DESC", where: JobId: @id
			if limit > -1
				parms['limit'] = limit
				
			Build.findAll(parms)
		artifactsArray: () -> @artifacts.split(',').map (v) -> v.trim()
		artifactLink: (build, artifact) -> @buildLink(build) + "/artifacts/" + artifact
		getActions: () -> Action.findAll(where: JobId: @id)
		link: () -> '/jobs/' + @slug
		buildLink: (build) ->
			if typeof build is "number"
				return @link() + '/' + build
			return @link() + '/builds/' + build.buildNumber
		consoleLink: (build) -> @buildLink(build) + '#console'
		settingsLink: () -> '/jobs/' + @slug + '/edit'
)

module.exports = Job
