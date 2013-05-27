# RequirestestServer
balUtil = require('bal-util')
safefs = require('safefs')
chai = require('chai')
expect = chai.expect
joe = require('joe')
pathUtil = require('path')

# -------------------------------------
# Configuration

# Vars
nikeprotoPath = pathUtil.join(__dirname,'..','..')
rootPath = pathUtil.join(nikeprotoPath,'test')
renderPath = pathUtil.join(rootPath,'render')
outPath = pathUtil.join(rootPath,'render-out')
expectPath = pathUtil.join(rootPath,'render-expected')
cliPath = pathUtil.join(nikeprotoPath,'bin','nikeproto')
nodePath = null

# -------------------------------------
# Tests

joe.suite 'nikeproto-render', (suite,test) ->

	suite 'files', (suite,test) ->
		# Check render physical files
		inputs = [
			{
				filename: 'markdown-with-extension.md'
				stdout: '*awesome*'
			}
			{
				filename: 'markdown-with-extensions.html.md'
				stdout: '<p><em>awesome</em></p>'
			}
		]
		inputs.forEach (input) ->
			test input.filename, (done) ->
				# IMPORTANT THAT ANY OPTIONS GO AFTER THE RENDER CALL, SERIOUSLY
				# OTHERWISE the sky falls down on scoping, seriously, it is wierd
				command = [cliPath, 'render', pathUtil.join(renderPath,input.filename)]
				balUtil.spawnCommand 'node', command, {cwd:rootPath}, (err,stdout,stderr,code,signal) ->
					return done(err)  if err
					expect(stdout.trim()).to.equal(input.stdout)
					done()

	suite 'stdin', (suite,test) ->
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
				command = [cliPath, 'render']
				command.push(input.filename)  if input.filename
				balUtil.spawnCommand 'node', command, {stdin:input.stdin,cwd:rootPath}, (err,stdout,stderr,code,signal) ->
					return done(err)  if err
					expect(stdout.trim()).to.equal(input.stdout)
					done()

		# Works with out path
		test 'outPath', (done) ->
			input = {
				in: '*awesome*'
				out: '<p><em>awesome</em></p>'
				outPath: pathUtil.join(outPath,'outpath-render.html')
			}
			balUtil.spawnCommand 'node', [cliPath, 'render', 'markdown', '-o', input.outPath], {stdin:input.in, cwd:rootPath}, (err,stdout,stderr,code,signal) ->
				return done(err)  if err
				expect(stdout).to.equal('')
				safefs.readFile input.outPath, (err,data) ->
					return done(err)  if err
					result = data.toString()
					expect(result.trim()).to.equal(input.out)
					done()