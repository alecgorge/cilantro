
Sequelize = require "sequelize"
db = require '../src/db'

Build = db.define('Build', {
	buildNumber: Sequelize.INTEGER
	consoleOutput: Sequelize.TEXT
	commit: Sequelize.STRING
	source: Sequelize.STRING
	branch: Sequelize.STRING
	cause: Sequelize.STRING
	duration: Sequelize.INTEGER
	success: Sequelize.INTEGER
	startDate: Sequelize.DATE
	compareUrl: Sequelize.TEXT
	commitsInformation: Sequelize.TEXT
	inProgress:
		type: Sequelize.INTEGER
		default: 0
},
	instanceMethods:
		link: () -> return '/jobs/' + @JobId + '/builds/' + @buildNumber
		consoleLink: () -> @link() + "#console"
)

module.exports = Build
