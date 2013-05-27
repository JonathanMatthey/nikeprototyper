# Requires
pathUtil = require('path')
{NikeProto,queryEngine,Backbone,createInstance,createMiddlewareInstance} = require(__dirname+'/lib/nikeproto')

# Export
module.exports =
	# Pre-Defined
	NikeProto: NikeProto
	queryEngine: queryEngine
	Backbone: Backbone
	createInstance: createInstance
	createMiddlewareInstance: createMiddlewareInstance

	# Require a local NikeProto file
	require: (relativePath) ->
		# Absolute the path
		absolutePath = pathUtil.normalize(pathUtil.join(__dirname,relativePath))

		# now check we if are actually a local nikeproto file
		if absolutePath.replace(__dirname,'') is absolutePath
			throw new Error("nikeproto.require is limited to local nikeproto files only: #{relativePath}")

		# now check if the path actually exists
		try
			require.resolve(absolutePath)

		# if it doesn't exist, then try add the lib directory
		catch err
			absolutePath = pathUtil.join(__dirname,'lib',relativePath)
			require.resolve(absolutePath)

		# finally, require the path
		return require(absolutePath)
