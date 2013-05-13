
Sequelize = require "sequelize"
db = require '../src/db'
bcrypt = require 'bcrypt'

module.exports = db.define('User', {
	username: Sequelize.STRING,
	name: Sequelize.STRING,
	hash: Sequelize.STRING
}, {
	instanceMethods:
		validPassword: (testPassword) ->
			bcrypt.compareSync testPassword, @hash

	classMethods:
		createNew: (name, username, password, cb) ->
			@create({'name': name, 'username': username, 'hash': bcrypt.hashSync(password, 8)})
})
