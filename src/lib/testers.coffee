# Requires
pathUtil = require('path')
balUtil = require('bal-util')
extendr = require('extendr')
joe = require('joe')
{expect} = require('chai')
CSON = require('cson')
NikeProto = require(__dirname+'/nikeproto')

# Prepare
pluginPort = 2000+String((new Date()).getTime()).substr(-6,4)
testers = {
	CSON,
	NikeProto
}

# Plugin Tester
testers.PluginTester =
class PluginTester
	# Plugin Config
	config:
		pluginName: null
		pluginPath: null
		autoExit: true
		testPath: null
		outExpectedPath: null
		removeEmptyLines: false

	# NikeProto Config
	nikeprotoConfig:
		port: null
		growl: false
		logLevel: (if ('-d' in process.argv) then 7 else 5)
		rootPath: null
		outPath: null
		srcPath: null
		pluginPaths: null
		enableUnlistedPlugins: false
		enabledPlugins: null
		skipUnsupportedPlugins: false
		catchExceptions: false
		environment: null

	# NikeProto Instance
	nikeproto: null

	# Constructor
	constructor: (config={},nikeprotoConfig={},next) ->
		# Apply Configuration
		tester = @
		@config = extendr.deepExtendPlainObjects({}, PluginTester::config, @config, config)
		@nikeprotoConfig = extendr.deepExtendPlainObjects({}, PluginTester::nikeprotoConfig, @nikeprotoConfig, nikeprotoConfig)
		@nikeprotoConfig.port ?= ++pluginPort
		@config.testerName ?= @config.pluginName

		# Extend Configuration
		@config.testPath or= pathUtil.join(@config.pluginPath,'test')
		@config.outExpectedPath or= pathUtil.join(@config.testPath,'out-expected')

		# Extend NikeProto Configuration
		@nikeprotoConfig.rootPath or= @config.testPath
		@nikeprotoConfig.outPath or= pathUtil.join(@nikeprotoConfig.rootPath,'out')
		@nikeprotoConfig.srcPath or= pathUtil.join(@nikeprotoConfig.rootPath,'src')
		@nikeprotoConfig.pluginPaths ?= [@config.pluginPath]
		defaultEnabledPlugins = {}
		defaultEnabledPlugins[@config.pluginName] = true
		@nikeprotoConfig.enabledPlugins or= defaultEnabledPlugins

		# Test API
		joe.describe @config.testerName, (suite,task) ->
			tester.describe = tester.suite = suite
			tester.it = tester.test = task
			tester.done = tester.exit = -> # b/c
			next?(null,tester)

		# Chain
		@

	# Create NikeProto Instance
	testCreate: ->
		# Prepare
		tester = @
		nikeprotoConfig = @nikeprotoConfig

		# Create Instance
		@test "create", (done) ->
			NikeProto.createInstance nikeprotoConfig, (err,nikeproto) ->
				return done(err)  if err
				tester.nikeproto = nikeproto
				tester.nikeproto.action 'clean', (err) ->
					return done(err)  if err
					tester.nikeproto.action 'install', (err) ->
						return done(err)

		# Chain
		@

	# Test Loaded
	testLoad: ->
		# Prepare
		tester = @

		# Test
		@test "load plugin #{tester.config.pluginName}", (done) ->
			tester.nikeproto.loadedPlugin tester.config.pluginName, (err,loaded) ->
				return done(err)  if err
				expect(loaded).to.be.ok
				return done()

		# Chain
		@

	# Perform Server
	testServer: (next) ->
		# Prepare
		tester = @

		# Handle
		@test "server", (done) ->
			tester.nikeproto.action 'server', (err) ->
				return done(err)

		# Chain
		@

	# Test Generate
	testGenerate: ->
		# Prepare
		tester = @

		# Test
		@test "generate", (done) ->
			tester.nikeproto.action 'generate', (err) ->
				return done(err)

		# Chain
		@

	# Test everything
	testEverything: ->
		# Prepare
		tester = @

		# Tests
		@testCreate()
		@testLoad()
		@testGenerate()
		@testServer()
		@testCustom?()

		# Finish
		@finish()

		# Chain
		@

	# Finish
	finish: ->
		# Prepare
		tester = @

		# Finish
		if tester.config.autoExit
			@test 'finish up', (done) ->
				done()
				tester.exit()
				if tester.config.autoExit isnt 'safe'
					process.exit()

		# Chain
		@


# Server Tester
testers.ServerTester =
class ServerTester extends PluginTester


# Renderer Tester
testers.RendererTester =
class RendererTester extends PluginTester
	# Test Generation
	testGenerate: ->
		# Prepare
		tester = @

		# Test
		@suite "generate", (suite,test) ->
			test 'action', (done) ->
				tester.nikeproto.action 'generate', (err) ->
					return done(err)

			test 'results', (done) ->
				# Get actual results
				balUtil.scantree tester.nikeprotoConfig.outPath, (err,outResults) ->
					return done(err)  if err
					# Get expected results
					balUtil.scantree tester.config.outExpectedPath, (err,outExpectedResults) ->
						return done(err)  if err

						# Remove empty lines
						if tester.config.removeWhitespace
							replaceLinesRegex = /(\\r|\\n|\\t|\s)+/g
							outResults = JSON.parse JSON.stringify(outResults).replace(replaceLinesRegex,'')
							outExpectedResults = JSON.parse JSON.stringify(outExpectedResults).replace(replaceLinesRegex,'')

						# Test results
						expect(outResults).to.eql(outExpectedResults)

						# Forward
						done()

		# Chain
		@

# Test a plugin
# test({pluginPath: String})
testers.test =
test = (testerConfig, nikeprotoConfig) ->
	# Configure
	testerConfig.pluginPath = pathUtil.resolve(testerConfig.pluginPath)
	testerConfig.pluginName ?= pathUtil.basename(testerConfig.pluginPath).replace('nikeproto-plugin-','')
	testerConfig.testerPath ?= pathUtil.join('out', "#{testerConfig.pluginName}.tester.js")
	testerConfig.testerPath = pathUtil.resolve(testerConfig.pluginPath, testerConfig.testerPath)

	# Test the plugin's tester
	testerClass = require(testerConfig.testerPath)(testers)
	new testerClass testerConfig, nikeprotoConfig, (err,testerInstance) ->
		throw err  if err
		testerInstance.testEverything()

	# Chain
	return testers

# Export Testers
module.exports = testers