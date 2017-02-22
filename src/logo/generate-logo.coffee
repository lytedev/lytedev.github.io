fs = require 'fs'
path = require 'path'
pug = require 'pug'

logoPartialPath = path.resolve __dirname, "./../../layouts/partials/logo.html"

logoInfo = require __dirname + "/logo-path-gen.coffee"
logoHtml = pug.renderFile __dirname + '/logo.svg.pug', logoInfo
fs.writeFile logoPartialPath, logoHtml, (err) ->
	if err then return console.log err
	console.log "Wrote #{logoHtml.length} characters to #{path.relative __dirname + "/../..", logoPartialPath}"

