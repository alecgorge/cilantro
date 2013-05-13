
Setting = require '../models/setting'

cache = {}

module.exports.load = (app) ->
	Setting.count().success (c) ->
		if c is 0
			Setting.create
				name: 'Site Name'
				key: 'site_name'
				value: 'Cilantro CI'
				description: "This shows in the upper-left hand corner, among other places."

			Setting.create
				name: 'Theme'
				description: "Pick from any of the lovely themes available from <a href='http://bootswatch.com/'>Bootswatch</a>."
				key: 'theme'
				value: 'spruce'

			Setting.create
				name: 'Artifact Storage Directory'
				description: 'Artifacts from each build will be stored in this directory, in a structure that mirrors the original folder tree. You can use 3 variables: job_name, build_number and branch.'
				key: 'artifact_dir'
				value: './workspace/<%=job_name%>/artifacts/<%=build_number%>/<%=branch%>/'

			Setting.create
				name: 'Build Directory'
				description: 'Your source code will be stored here and the project will be built here. You can use 3 variables: job_name, build_number and branch.'
				key: 'build_dir'
				value: './workspace/<%=job_name%>/build/'

		themes = [
		    { "value": "bootstrap", "text": "Bootstrap — The original. An instant classic." },
		    { "value": "amelia", "text": "Amelia — Sweet and cheery." },
		    { "value": "cerulean", "text": "Cerulean — A calm blue sky."},
		    { "value": "cosmo", "text": "Cosmo — An ode to Metro."},
		    { "value": "cyborg", "text": "Cyborg — Jet black and electric blue." },
		    { "value": "journal", "text": "Journal — Crisp like a new sheet of paper." },
		    { "value": "readable", "text": "Readable — Optimized for legibility." },
		    { "value": "simplex", "text": "Simplex — Mini and minimalist." },
		    { "value": "slate", "text": "Slate — Shades of gunmetal gray." },
		    { "value": "spacelab", "text": "Spacelab — Silvery and sleek." },
		    { "value": "spruce", "text": "Spruce — Camping in the woods." },
		    { "value": "superhero", "text": "Superhero — Batman meets... Aquaman?" },
		    { "value": "united", "text": "United — Ubuntu orange and unique font." }
		]

		Setting.findAll().success (settings) ->
			app.locals.settings = {}
			app.locals.settings['themes'] = themes
			for v in settings
				cache[v.key] = v
				app.locals.settings[v.key] = v.value

module.exports.recache = (req) ->
	for k,v of cache
		req.app.locals.settings[v.key] = v.value

module.exports.get = (key) -> cache[key]
module.exports.set = (key,val) -> cache[key] = val
module.exports.all = () -> cache
