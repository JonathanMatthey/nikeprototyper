# Requires
extendr = require('extendr')
typeChecker = require('typechecker')
ambi = require('ambi')
eachr = require('eachr')

# Define Plugin
class BasePlugin

	# ---------------------------------
	# Inherited

	# NikeProto Instance
	nikeproto: null


	# ---------------------------------
	# Variables

	# Plugin name
	name: null

	# Plugin config
	config: {}
	instanceConfig: {}

	# Plugin priority
	priority: 500

	# Constructor
	constructor: (opts) ->
		# Prepare
		me = @
		{nikeproto,config} = opts
		@nikeproto = nikeproto

		# Bind listeners
		@bindListeners()

		# Swap out our configuration
		@config = extendr.deepClone(@config)
		@instanceConfig = extendr.deepClone(@instanceConfig)
		@initialConfig = @config
		@setConfig(config)

		# Return early if we are disabled
		return @  if @isEnabled() is false

		# Listen to events
		@addListeners()

		# Chain
		@

	# Set Instance Configuration
	setInstanceConfig: (instanceConfig) ->
		# Merge in the instance configurations
		if instanceConfig
			extendr.safeDeepExtendPlainObjects(@instanceConfig, instanceConfig)
			extendr.safeDeepExtendPlainObjects(@config, instanceConfig)  if @config
		@

	# Set Configuration
	setConfig: (instanceConfig=null) =>
		# Prepare
		nikeproto = @nikeproto
		userConfig = @nikeproto.config.plugins[@name]
		@config = @nikeproto.config.plugins[@name] = {}

		# Instance config
		@setInstanceConfig(instanceConfig)  if instanceConfig

		# Merge configurations
		configPackages = [@initialConfig, userConfig, @instanceConfig]
		configsToMerge = [@config]
		nikeproto.mergeConfigurations(configPackages, configsToMerge)

		# Unbind if we are disabled
		@unbindEvents()  unless @isEnabled()

		# Chain
		@

	# Get Configuration
	getConfig: =>
		return @config

	# Alias for b/c
	bindEvents: -> @addListeners()

	# Bind Listeners
	bindListeners: ->
		# Prepare
		pluginInstance = @
		nikeproto = @nikeproto
		events = nikeproto.getEvents()

		# Bind events
		eachr events, (eventName) ->
			# Fetch the event handler
			eventHandler = pluginInstance[eventName]

			# Check it exists and is a function
			if typeChecker.isFunction(eventHandler)
				# Bind the listener to the plugin
				pluginInstance[eventName] = eventHandler.bind(pluginInstance)

		# Chain
		@

	# Add Listeners
	addListeners: ->
		# Prepare
		pluginInstance = @
		nikeproto = @nikeproto
		events = nikeproto.getEvents()

		# Bind events
		eachr events, (eventName) ->
			# Fetch the event handler
			eventHandler = pluginInstance[eventName]

			# Check it exists and is a function
			if typeChecker.isFunction(eventHandler)
				# Apply the priority
				eventHandlerPriority = pluginInstance[eventName+'Priority'] or pluginInstance.priority or null
				eventHandler.priority = eventHandlerPriority

				# Wrap the event handler, and bind it to nikeproto
				nikeproto
					.off(eventName, eventHandler)
					.on(eventName, eventHandler)

		# Chain
		@

	# Remove Listeners
	removeListeners: ->
		# Prepare
		pluginInstance = @
		nikeproto = @nikeproto
		events = nikeproto.getEvents()

		# Bind events
		eachr events, (eventName) ->
			# Fetch the event handler
			eventHandler = pluginInstance[eventName]

			# Check it exists and is a function
			if typeChecker.isFunction(eventHandler)
				# Wrap the event handler, and unbind it from nikeproto
				nikeproto.off(eventName, eventHandler)

		# Chain
		@

	# Is Enabled?
	isEnabled: ->
		return @config.enabled isnt false


# Export Plugin
module.exports = BasePlugin
