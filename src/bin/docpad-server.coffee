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
action = getArgument('action',null,'server generate')

# NikeProto Configuration
nikeprotoConfig = {}
nikeprotoConfig.port = (->
	port = getArgument('port')
	port = parseInt(port,10)  if port and isNaN(port) is false
	return port
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