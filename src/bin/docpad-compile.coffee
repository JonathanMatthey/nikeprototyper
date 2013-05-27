# Require
NikeProto = require(__dirname+'/../lib/nikeproto')

# Prepare
getArgument = (name,value=null,defaultValue=null) ->
	result = defaultValue
	argumentIndex = process.argv.indexOf("--#{name}")
	if argumentIndex isnt -1
		result = value ? process.argv[argumentIndex+1]
	return result

# NikeProto Action
action = (getArgument('action',null,'generate')+' '+getArgument('watch','watch','')).trim()

# NikeProto Configuration
nikeprotoConfig = {}
nikeprotoConfig.rootPath = getArgument('rootPath',null,process.cwd())
nikeprotoConfig.outPath = getArgument('outPath',null,nikeprotoConfig.rootPath+'/out')
nikeprotoConfig.srcPath = getArgument('srcPath',null,nikeprotoConfig.rootPath+'/src')
nikeprotoConfig.documentsPaths = (->
	documentsPath = getArgument('documentsPath')
	if documentsPath?
		documentsPath = nikeprotoConfig.srcPath  if documentsPath is 'auto'
	else
		documentsPath = nikeprotoConfig.srcPath+'/documents'
	return [documentsPath]
)()
nikeprotoConfig.port = (->
	port = getArgument('port')
	port = parseInt(port,10)  if port and isNaN(port) is false
	return port
)()
nikeprotoConfig.renderSingleExtensions = (->
	renderSingleExtensions = getArgument('renderSingleExtensions',null,'auto')
	if renderSingleExtensions in ['true','yes']
		renderSingleExtensions = true
	else if renderSingleExtensions in ['false','no']
		renderSingleExtensions = false
	return renderSingleExtensions
)()

# Create NikeProto Instance
NikeProto.createInstance nikeprotoConfig, (err,nikeproto) ->
	# Check
	return console.log(err.stack)  if err

	# Generate and Serve
	nikeproto.action action, (err) ->
		# Check
		return console.log(err.stack)  if err

		# Done
		console.log('OK')
