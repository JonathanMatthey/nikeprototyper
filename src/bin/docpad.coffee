# Require
NikeProto = require(__dirname+'/../lib/nikeproto')
ConsoleInterface = require(__dirname+'/../lib/interfaces/console')

# Fetch action
action =
	# we should eventually do a load always
	# but as it is a big change of functionality, lets only do it inclusively for now
	if process.argv[1...].join(' ').indexOf('deploy') isnt -1
		'load'
	else
		false

# Create NikeProto Instance
NikeProto.createInstance {action}, (err,nikeproto) ->
	# Check
	return console.log(err.stack)  if err

	# Create Console Interface
	new ConsoleInterface {nikeproto}, (err,consoleInterface) ->
		# Check
		return console.log(err.stack)  if err

		# Start
		consoleInterface.start()