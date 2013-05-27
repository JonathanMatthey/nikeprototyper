module.exports =
	reportStatistics: false
	reportErrors: false
	detectEncoding: true

	environments:
		development:
			a: 'websiteConfig'
			b: 'websiteConfig'
			c: 'websiteConfig'
			templateData:
				a: 'websiteConfig'
				b: 'websiteConfig'
				c: 'websiteConfig'

	templateData:
		require: require

	collections:
		nikeprotoConfigCollection: (database) ->
			database.findAllLive({tag: $has: 'nikeproto-config-collection'})

	events:
		renderDocument: (opts) ->
			src = "testing the nikeproto configuration renderDocument event"
			out = src.toUpperCase()
			opts.content = opts.content.replace(src,out)