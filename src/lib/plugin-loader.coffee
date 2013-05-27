# Requires
pathUtil = require('path')
semver = require('semver')
safefs = require('safefs')
util = require('util')

# Define Plugin Loader
class PluginLoader

	# ---------------------------------
	# Constructed

	# NikeProto Instance
	nikeproto: null

	# BasePlugin Class
	BasePlugin: null

	# The full path of the plugin's directory
	dirPath: null


	# ---------------------------------
	# Loaded

	# The full path of the plugin's package.json file
	packagePath: null

	# The parsed contents of the plugin's package.json file
	packageData: {}

	# The full path of the plugin's main file
	pluginPath: null

	# The parsed content of the plugin's main file
	pluginClass: {}

	# Plugin name
	pluginName: null

	# Plugin version
	pluginVersion: null

	# Node modules path
	nodeModulesPath: null


	# ---------------------------------
	# Functions

	# Constructor
	constructor: ({@nikeproto,@dirPath,@BasePlugin}) ->
		# Prepare
		nikeproto = @nikeproto

		# Apply
		@pluginName = pathUtil.basename(@dirPath).replace(/^nikeproto-plugin-/,'')
		@pluginClass = {}
		@packageData = {}
		@nodeModulesPath = pathUtil.resolve(@dirPath, 'node_modules')

	# Exists
	# Loads the package.json file and extracts the main path
	# next(err,exists)
	exists: (next) ->
		# Prepare
		packagePath = @packagePath or pathUtil.resolve(@dirPath, "package.json")
		failure = (err=null) =>
			return next(err,false)
		success = =>
			return next(null,true)

		# Check the package
		safefs.exists packagePath, (exists) =>
			return failure()  unless exists

			# Apply
			@packagePath = packagePath

			# Read the package
			safefs.readFile packagePath, (err,data) =>
				return failure(err)  if err

				# Parse the package
				try
					@packageData = JSON.parse data.toString()
				catch err
					return failure(err)
				finally
					return failure()  unless @packageData

				# Extract the version and main
				pluginVersion = @packageData.version
				pluginPath = @packageData.main and pathUtil.join(@dirPath, @packageData.main)

				# Check defined
				return failure()  unless pluginVersion
				return failure()  unless pluginPath

				# Success
				@pluginPath = pluginVersion
				@pluginPath = pluginPath
				return success()

		# Chain
		@

	# Unsupported
	# Check if this plugin is unsupported
	# next(err,supported)
	unsupported: (next) ->
		# Prepare
		nikeproto = @nikeproto
		unsupported = false

		# Check type
		keywords = @packageData.keywords or []
		unless 'nikeproto-plugin' in keywords
			unsupported = 'type'

		# Check platform
		if @packageData.platforms
			platforms = @packageData.platforms or []
			unless process.platform in platforms
				unsupported = 'platform'

		# Check engines
		if @packageData.engines
			engines = @packageData.engines or {}

			# Node engine
			if engines.node?
				unless semver.satisfies(process.version, engines.node)
					unsupported = 'engine'

			# NikeProto engine
			if engines.nikeproto?
				unless semver.satisfies(nikeproto.version, engines.nikeproto)
					unsupported = 'version'

		# Supported
		next(null,unsupported)

		# Chain
		@

	# Install
	# Installs the plugins node modules
	# next(err)
	install: (next) ->
		# Prepare
		nikeproto = @nikeproto

		# Only install if we have a package path
		if @packagePath
			# Install npm modules
			nikeproto.initNodeModules(
				path: @dirPath
				next: (err,results) ->
					# Forward
					return next(err)
			)
		else
			# Continue
			next()

		# Chain
		@

	# Load
	# Load in the pluginClass from the pugin file
	# next(err,pluginClass)
	load: (next) ->
		# Prepare
		nikeproto = @nikeproto
		locale = nikeproto.getLocale()

		# Load
		try
			# Load in our plugin
			@pluginClass = require(@pluginPath)(@BasePlugin)
			@pluginClass::version ?= @pluginVersion
			pluginPrototypeName = @pluginClass::name

			# Checks
			# Alphanumeric
			if /^[a-z0-9]+$/.test(@pluginName) is false
				validPluginName = @pluginName.replace(/[^a-z0-9]/,'')
				nikeproto.log('warn', util.format(locale.pluginNamingConventionInvalid, @pluginName, validPluginName))
			# Same name
			if pluginPrototypeName is null
				@pluginClass::name = @pluginName
				nikeproto.log('warn',  util.format(locale.pluginPrototypeNameUndefined, @pluginName))
			else if pluginPrototypeName isnt @pluginName
				nikeproto.log('warn', util.format(locale.pluginPrototypeNameDifferent, @pluginName, pluginPrototypeName))
		catch err
			# An error occured, return it
			return next(err,null)

		# Return our plugin
		next(null,@pluginClass)

		# Chain
		@

	# Create Instance
	# next(err,pluginInstance)
	create: (config,next) ->
		# Load
		try
			# Create instance with merged configuration
			nikeproto = @nikeproto
			pluginInstance = new @pluginClass({nikeproto,config})
		catch err
			# An error occured, return it
			return next(err,null)

		# Return our instance
		return next(null,pluginInstance)

		# Chain
		@


# Export
module.exports = PluginLoader