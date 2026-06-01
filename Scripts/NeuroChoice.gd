class_name NeuroChoice
extends NeuroAction

var gameController = null
var options = null

func _init(gController, _options, actionWindow=null): #add the actionWindow if we're initializing this action as part of a wondow
	if(actionWindow != null):
		super(actionWindow)
	options = _options
	gameController = gController

func _get_name() -> String:
	return "choice"

func _get_description() -> String:
	return "A choice of options."

func _get_schema() -> Dictionary:
	return JsonUtils.wrap_schema({
		"choice":{
			"enum": options
		}
	})


func _validate_action(data: IncomingData, state: Dictionary) -> ExecutionResult:
	
	var choice := data.get_string("choice")
	if !choice:
		return ExecutionResult.failure(Strings.action_failed_missing_required_parameter.format(["choice"]))
	print(choice)
	
	if(!options.has(choice)):
		return ExecutionResult.failure(Strings.action_failed_invalid_parameter.format(["choice"]))
	
	state["choice"] = choice
	return ExecutionResult.success()


func _execute_action(state: Dictionary) -> void:
	gameController.evilChoice = state["choice"]
	gameController.UpdateGraphics()




