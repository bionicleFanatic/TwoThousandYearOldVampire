class_name NeuroText
extends NeuroAction

var gameController = null


func _init(gController, actionWindow=null): #add the actionWindow if we're initializing this action as part of a wondow
	if(actionWindow != null):
		super(actionWindow)
	
	gameController = gController

func _get_name() -> String:
	return "text"

func _get_description() -> String:
	return "Text written into the game."

func _get_schema() -> Dictionary:
	return JsonUtils.wrap_schema({
		"text":{
			"type": "string"
		}
	})


func _validate_action(data: IncomingData, state: Dictionary) -> ExecutionResult:
	
	var text := data.get_string("text")
	if !text:
		return ExecutionResult.failure(Strings.action_failed_missing_required_parameter.format(["text"]))
	print(text)
	if(typeof(text) != TYPE_STRING):
		return ExecutionResult.failure("Oopsie, that needs to be a string of text.")
	
	state["text"] = text
	return ExecutionResult.success()


func _execute_action(state: Dictionary) -> void:
	gameController.evilResponse = state["text"]
	gameController.UpdateGraphics()




