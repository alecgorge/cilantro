
Sequelize = require 'sequelize'

sequelize = new Sequelize 'database', 'username', 'password',{
	dialect: 'sqlite',
	storage: 'db.sqlite'
}

module.exports = sequelize
