# RequirestestServer
{expect} = require('chai')
joe = require('joe')

# -------------------------------------
# Configuration

# Vars
nikeprotoPath = __dirname+'/../..'
rootPath = nikeprotoPath+'/test'
renderPath = rootPath+'/render'
expectPath = rootPath+'/render-expected'
cliPath = nikeprotoPath+'/bin/nikeproto'

# Configure NikeProto
nikeprotoConfig =
	growl: false
	port: 9780
	rootPath: rootPath
	logLevel: if process.env.TRAVIS_NODE_VERSION? then 7 else 5
	skipUnsupportedPlugins: false
	catchExceptions: false
	environments:
		development:
			a: 'instanceConfig'
			b: 'instanceConfig'
			templateData:
				a: 'instanceConfig'
				b: 'instanceConfig'

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Local globals
nikeproto = null


# -------------------------------------
# Tests

joe.suite 'nikeproto-api', (suite,test) ->

	# Create a NikeProto Instance
	test 'createInstance', (done) ->
		nikeproto = require(__dirname+'/../main').createInstance(nikeprotoConfig,done)

	# Render some input
	suite 'render', (suite,test) ->
		# Check rendering stdin inputs
		inputs = [
			{
				testname: 'markdown without extension'
				filename: ''
				stdin: '*awesome*'
				stdout: '*awesome*'
			}
			{
				testname: 'markdown with extension as filename'
				filename: 'markdown'
				stdin: '*awesome*'
				stdout: '<p><em>awesome</em></p>'
			}
			{
				testname: 'markdown with extension'
				filename: 'example.md'
				stdin: '*awesome*'
				stdout: '*awesome*'
			}
			{
				testname: 'markdown with extensions'
				filename: '.html.md'
				stdin: '*awesome*'
				stdout: '<p><em>awesome</em></p>'
			}
			{
				testname: 'markdown with filename'
				filename: 'example.html.md'
				stdin: '*awesome*'
				stdout: '<p><em>awesome</em></p>'
			}
		]
		inputs.forEach (input) ->
			test input.testname, (done) ->
				opts =
					data: input.stdin
					filename: input.filename
					renderSingleExtensions: 'auto'
				nikeproto.action 'render', opts, (err,result) ->
					return done(err)  if err
					expect(result.trim()).to.equal(input.stdout)
					done()
