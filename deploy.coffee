ghpages = require 'gh-pages'
path = require 'path'

publicPath = path.join __dirname, 'public'
options =
	branch: 'gh-pages'
	message: 'Auto-generated commit via deploy script'
ghpages.publish publicPath, options, (err) ->
	if err
		console.log err
	else
		console.log "Deployed!"

