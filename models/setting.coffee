
Sequelize = require "sequelize"
db = require '../src/db'

module.exports = db.define('Setting', {
	key: Sequelize.STRING
	name: Sequelize.STRING
	description:
		type: Sequelize.STRING
		defaultValue: ""
	value: Sequelize.STRING
})
