
Sequelize = require "sequelize"
db = require '../src/db'

Action = db.define('Action', 
	on: Sequelize.STRING
	callerName: Sequelize.STRING
	title: Sequelize.STRING
	options: Sequelize.STRING
)

module.exports = Action
