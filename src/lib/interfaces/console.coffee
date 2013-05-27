# Requires
pathUtil = require('path')
balUtil = require('bal-util')
safefs = require('safefs')
{TaskGroup} = require('taskgroup')
extendr = require('extendr')

# Console Interface
class ConsoleInterface

	# Setup the CLI
	constructor: (opts,next) ->
		# Prepare
		consoleInterface = @
		@nikeproto = nikeproto = opts.nikeproto
		@commander = commander = require('commander')
		locale = nikeproto.getLocale()

		# Version information
		version = require(__dirname+'/../../../package.json').version

		# -----------------------------
		# Global config

		commander
			.version(version)
			.option(
				'-o, --out <outPath>'
				locale.consoleOptionOut
			)
			.option(
				'-c, --config <configPath>'
				locale.consoleOptionConfig
			)
			.option(
				'-e, --env <environment>'
				locale.consoleOptionEnv
			)
			.option(
				'-d, --debug [logLevel]'
				locale.consoleOptionDebug
				parseInt
			)
			.option(
				'-f, --force'
				locale.consoleOptionForce
			)
			.option(
				'-p, --port <port>'
				locale.consoleOptionPort
				parseInt
			)
			.option(
				'-s, --skeleton <skeleton>'
				locale.consoleOptionSkeleton
			)


		# -----------------------------
		# Commands

		# actions
		commander
			.command('action <actions>')
			.description(locale.consoleDescriptionRun)
			.action(consoleInterface.wrapAction(consoleInterface.action))

		# run
		commander
			.command('run')
			.description(locale.consoleDescriptionRun)
			.action(consoleInterface.wrapAction(consoleInterface.run))

		# server
		commander
			.command('server')
			.description(locale.consoleDescriptionServer)
			.action(consoleInterface.wrapAction(consoleInterface.server))

		# skeleton
		commander
			.command('skeleton')
			.description(locale.consoleDescriptionSkeleton)
			.option(
				'-s, --skeleton <skeleton>'
				locale.consoleOptionSkeleton
			)
			.action(consoleInterface.wrapAction(consoleInterface.skeleton))

		# render
		commander
			.command('render [path]')
			.description(locale.consoleDescriptionRender)
			.action(consoleInterface.wrapAction(consoleInterface.render,{
				# Disable anything uncessary or that could cause extra output we don't want
				logLevel: 5
				checkVersion: false
				welcome: false
				prompts: false
			}))

		# generate
		commander
			.command('generate')
			.description(locale.consoleDescriptionGenerate)
			.action(consoleInterface.wrapAction(consoleInterface.generate))

		# watch
		commander
			.command('watch')
			.description(locale.consoleDescriptionWatch)
			.action(consoleInterface.wrapAction(consoleInterface.watch))

		# install
		commander
			.command('install')
			.description(locale.consoleDescriptionInstall)
			.action(consoleInterface.wrapAction(consoleInterface.install))

		# clean
		commander
			.command('clean')
			.description(locale.consoleDescriptionClean)
			.action(consoleInterface.wrapAction(consoleInterface.clean))

		# info
		commander
			.command('info')
			.description(locale.consoleDescriptionInfo)
			.action(consoleInterface.wrapAction(consoleInterface.info))

		# help
		commander
			.command('help')
			.description(locale.consoleDescriptionHelp)
			.action(consoleInterface.wrapAction(consoleInterface.help))

		# unknown
		commander
			.command('*')
			.description(locale.consoleDescriptionUnknown)
			.action(consoleInterface.wrapAction(consoleInterface.help))


		# -----------------------------
		# NikeProto Listeners

		# Welcome
		nikeproto.on 'welcome', (data,next) ->
			return consoleInterface.welcomeCallback(data,next)


		# -----------------------------
		# Finish Up

		# Plugins
		nikeproto.emitSync 'consoleSetup', {consoleInterface,commander}, (err) ->
			return consoleInterface.handleError(err)  if err
			next(null,consoleInterface)

		# Chain
		@


	# =================================
	# Helpers

	# Start the CLI
	start: (argv) =>
		@commander.parse(argv or process.argv)
		@

	# Get the commander
	getCommander: =>
		@commander

	# Handle Error
	handleError: (err) =>
		# Prepare
		nikeproto = @nikeproto
		locale = nikeproto.getLocale()

		# Handle
		nikeproto.log('error', locale.consoleError)
		nikeproto.error(err)
		process.exit(1)

		# Chain
		@

	# Wrap Action
	wrapAction: (action,config) ->
		consoleInterface = @
		return (args...) ->
			consoleInterface.performAction(action,args,config)

	# Perform Action
	performAction: (action,args,config) =>
		# Create
		opts = {}
		opts.commander = args[-1...][0]
		opts.args = args[...-1]
		opts.instanceConfig = extendr.safeDeepExtendPlainObjects({}, @extractConfig(opts.commander), config)

		# Load
		@nikeproto.action 'load ready', opts.instanceConfig, (err) =>
			# Error
			if err
				return @completeAction(err)

			# Action
			return action(@completeAction,opts)  # this order for b/c

		# Chain
		@

	# Complete Action
	completeAction: (err) =>
		# Prepare
		nikeproto = @nikeproto
		locale = nikeproto.getLocale()

		# Handle the error
		if err
			@handleError(err)
		else
			nikeproto.log('info', locale.consoleSuccess)

		# Chain
		@

	# Extract Configuration
	extractConfig: (customConfig={}) =>
		# Prepare
		config = {}
		commanderConfig = @commander
		sourceConfig = @nikeproto.initialConfig

		# debug -> logLevel
		if commanderConfig.debug
			commanderConfig.debug = 7  if commanderConfig.debug is true
			commanderConfig.logLevel = commanderConfig.debug

		# config -> configPaths
		if commanderConfig.config
			configPath = pathUtil.resolve(process.cwd(),commanderConfig.config)
			commanderConfig.configPaths = [configPath]

		# out -> outPath
		if commanderConfig.out
			outPath = pathUtil.resolve(process.cwd(),commanderConfig.out)
			commanderConfig.outPath = outPath

		# Apply global configuration
		for own key, value of commanderConfig
			if typeof sourceConfig[key] isnt 'undefined'
				config[key] = value

		# Apply custom configuration
		for own key, value of customConfig
			if typeof sourceConfig[key] isnt 'undefined'
				config[key] = value

		# Return config object
		config

	# Select a skeleton
	selectSkeletonCallback: (skeletonsCollection,next) =>
		# Prepare
		commander = @commander
		nikeproto = @nikeproto
		locale = nikeproto.getLocale()
		skeletonNames = []

		# Show
		nikeproto.log 'info', locale.skeletonSelectionIntroduction+'\n'
		skeletonsCollection.forEach (skeletonModel) ->
			skeletonName = skeletonModel.get('name')
			skeletonDescription = skeletonModel.get('description').replace(/\n/g,'\n\t')
			skeletonNames.push(skeletonName)
			console.log """
				#{skeletonModel.get('position')+1}. #{skeletonName}
				   #{skeletonDescription}

				"""

		# Select
		nikeproto.log 'info', locale.skeletonSelectionPrompt
		commander.choose skeletonNames, (i) ->
			process.stdin.destroy()
			return next(null, skeletonsCollection.at(i))

		# Chain
		@

	# Welcome Callback
	welcomeCallback: (opts,next) =>
		# Prepare
		consoleInterface = @
		commander = @commander
		nikeproto = @nikeproto
		locale = nikeproto.getLocale()
		userConfig = nikeproto.userConfig
		welcomeTasks = new TaskGroup().once('complete',next)

		# TOS
		welcomeTasks.addTask (complete) ->
			return complete()  if nikeproto.config.prompts is false or userConfig.tos is true

			# Ask the user if they agree to the TOS
			consoleInterface.confirm locale.tosPrompt, true, (ok) ->  nikeproto.track 'tos', {ok}, (err) ->
				# Check
				if ok
					userConfig.tos = true
					console.log locale.tosAgree
					nikeproto.updateUserConfig(complete)
					return
				else
					console.log locale.tosDisagree
					process.exit()
					return

		# Newsletter
		welcomeTasks.addTask (complete) ->
			return complete()  if nikeproto.config.prompts is false or userConfig.subscribed? or (userConfig.subscribeTryAgain? and (new Date()) > (new Date(userConfig.subscribeTryAgain)))

			# Ask the user if they want to subscribe to the newsletter
			consoleInterface.confirm locale.subscribePrompt, true, (ok) ->  nikeproto.track 'subscribe', {ok}, (err) ->
				# If they don't want to, that's okay
				unless ok
					# Inform the user that we received their preference
					console.log locale.subscribeIgnore

					# Save their preference in the user configuration
					userConfig.subscribed = false
					nikeproto.updateUserConfig (err) ->
						return complete(err)  if err
						balUtil.wait(2000,complete)
					return

				# Scan configuration to speed up the process
				commands = [
					['config','--get','user.name']
					['config','--get','user.email']
					['config','--get','github.user']
				]
				balUtil.spawnCommands 'git', commands, (err,results) ->
					# Ignore error as it just means a config value wasn't defined
					# return next(err)  if err

					# Fetch
					# The or to '' is there because otherwise we will get "undefined" as a string if the value doesn't exist
					userConfig.name or= String(results?[0]?[1] or '').trim() or null
					userConfig.email or= String(results?[1]?[1] or '').trim() or null
					userConfig.username or= String(results?[2]?[1] or '').trim() or null

					# Let the user know we scanned their configuration if we got anything useful
					if userConfig.name or userConfig.email or userConfig.username
						console.log locale.subscribeConfigNotify

					# Tasks
					subscribeTasks = new TaskGroup().once 'complete', (err) ->
						# Error?
						if err
							# Inform the user
							console.log locale.subscribeError
							# Save a time when we should try to subscribe again
							userConfig.subscribeTryAgain = new Date().getTime() + 1000*60*60*24  # tomorrow

						# Success
						else
							# Inform the user
							console.log locale.subscribeSuccess
							# Save the updated subscription status, and continue to what is next
							userConfig.subscribed = true
							userConfig.subscribeTryAgain = null

						# Save the new user configuration changes, and forward to the next task
						nikeproto.updateUserConfig(userConfig,complete)

					# Name Fallback
					subscribeTasks.addTask (complete) ->
						consoleInterface.prompt locale.subscribeNamePrompt, userConfig.name, (result) ->
							userConfig.name = result
							complete()

					# Email Fallback
					subscribeTasks.addTask (complete) ->
						consoleInterface.prompt locale.subscribeEmailPrompt, userConfig.email, (result) ->
							userConfig.email = result
							complete()

					# Username Fallback
					subscribeTasks.addTask (complete) ->
						consoleInterface.prompt locale.subscribeUsernamePrompt, userConfig.username, (result) ->
							userConfig.username = result
							complete()

					# Save the details
					subscribeTasks.addTask (complete) ->
						nikeproto.updateUserConfig(complete)

					# Perform the subscribe
					subscribeTasks.addTask (complete) ->
						# Inform the user
						console.log locale.subscribeProgress

						# Prepare our connection
						requestUrl = nikeproto.config.helperUrl+'?'+require('querystring').stringify(
							method: 'add-subscriber'
							name: userConfig.name
							email: userConfig.email
							username: userConfig.username
						)

						# Innitialize our request
						balUtil.readPath requestUrl, (err,body) ->
							# Check
							if err
								nikeproto.log 'debug', locale.subscribeRequestError, err.message
								return complete(err)

							# Log it to debug console
							nikeproto.log 'debug', locale.subscribeRequestData, body

							# Inform the user know of the success or not
							try
								data = JSON.parse(body)
								if data.success is false
									complete(new Error(data.error or 'unknown error'))
								else
									complete()
							catch err
								complete(err)

					# Run
					subscribeTasks.run()

		# Run
		welcomeTasks.run()

		# Chain
		@

	# Prompt for input
	prompt: (message,fallback,next) ->
		# Prepare
		consoleInterface = @
		commander = @commander

		# Fallback
		message += " [#{fallback}]"  if fallback

		# Log
		commander.prompt message+' ', (result) ->
			# Parse
			unless result.trim() # no value
				if fallback? # has default value
					result = fallback # set to default value
				else # otherwise try again
					return consoleInterface.prompt(message,fallback,next)

			# Forward
			return next(result)

		# Chain
		@

	# Confirm an option
	confirm: (message,fallback,next) ->
		# Prepare
		consoleInterface = @
		commander = @commander

		# Fallback
		if fallback is true
			message += " [Y/n]"
		else if fallback is false
			message += " [y/N]"

		# Log
		commander.prompt message+' ', (ok) ->
			# Parse
			unless ok.trim() # no value
				if fallback? # has default value
					ok = fallback # set to default value
				else # otherwise try again
					return consoleInterface.confirm(message,fallback,next)
			else # parse the value
				ok = /^y|yes|ok|true$/i.test(ok)

			# Forward
			return next(ok)

		# Chain
		@


	# =================================
	# Actions

	action: (next,opts) =>
		actions = opts.args[0]
		@nikeproto.log 'info', 'Performing the actions:', actions
		@nikeproto.action(actions,next)
		@

	generate: (next) =>
		@nikeproto.action('generate',next)
		@

	help: (next) =>
		help = @commander.helpInformation()
		console.log(help)
		next()
		@

	info: (next) =>
		info = require('util').inspect(@nikeproto.config)
		console.log(info)
		next()
		@

	install: (next) =>
		@nikeproto.action('install',next)
		@

	render: (next,opts) =>
		# Prepare
		nikeproto = @nikeproto
		commander = @commander
		renderOpts = {}

		# Prepare filename
		filename = opts.args[0] or null
		basename = pathUtil.basename(filename)
		renderOpts.filename = filename
		renderOpts.renderSingleExtensions = 'auto'

		# Prepare text
		data = ''

		# Render
		useStdin = true
		renderDocument = ->
			# Perform the render
			nikeproto.action 'render', renderOpts, (err,result) ->
				return nikeproto.fatal(err)  if err
				# Path
				if commander.out?
					safefs.writeFile(commander.out, result, next)
				# Stdout
				else
					process.stdout.write(result)
					next()

		# Timeout if we don't have stdin
		timeout = setTimeout(
			->
				# Clear timeout
				timeout = null
				# Skip if we are using stdin
				return  if data.replace(/\s+/,'')
				# Close stdin as we are not using it
				useStdin = false
				stdin.pause()
				# Render the document
				renderDocument()
			,1000
		)

		# Read stdin
		stdin = process.stdin
		stdin.resume()
		stdin.setEncoding('utf8')
		stdin.on 'data', (_data) ->
			data += _data.toString()
		process.stdin.on 'end', ->
			return  unless useStdin
			if timeout
				clearTimeout(timeout)
				timeout = null
			renderOpts.data = data
			renderDocument()

		@

	run: (next) =>
		@nikeproto.action(
			'run'
			{selectSkeletonCallback: @selectSkeletonCallback}
			next
		)
		@

	server: (next) =>
		@nikeproto.action('server generate',next)
		@

	clean: (next) =>
		@nikeproto.action('clean',next)
		@

	skeleton: (next) =>
		@nikeproto.action(
			'skeleton'
			{selectSkeletonCallback: @selectSkeletonCallback}
			next
		)
		@

	watch: (next) =>
		@nikeproto.action('generate watch',next)
		@


# =================================
# Export

module.exports = ConsoleInterface
