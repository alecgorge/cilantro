cilantro
=========

A simple CI machine built in Node. Super lightweight.

Supports remote push hooks, from GitHub, BitBucket and the like.

Think of it like Jenkins on diet.

The main functionality I wanted was multiple public and private jobs, artifacting, SQLite based, custom scripts for building and git support. Anything else probably won't happen.

# Launching

    npm install
    npm install -g coffee-script
    npm start

I like using `supervisor` to make sure cilantro stays up:

    npm install -g supervisor coffee-script
    supervisor app.coffee

# Configuration

Set the `PORT` env variable for the listen port (default: 3000). The default username and password is `admin` and `demo`. You can log in and then change these.

All other setup is done in the app itself.
