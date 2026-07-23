extends Node
class_name InputGatherer

var input_enabled: bool = true

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()
	
	if !input_enabled:
		new_input.actions.append("idle")
		return new_input
	
	new_input.actions.append("idle")
	
	new_input.input_direction = Input.get_vector("left", "right", "forward", "backward")
	if new_input.input_direction != Vector2.ZERO:
		new_input.actions.append("run")
		if Input.is_action_pressed("sprint"):
			new_input.actions.append("sprint")
	
	if Input.is_action_just_pressed("jump"):
		if new_input.actions.has("sprint"):
			new_input.actions.append("jump_sprint")
		else:
			new_input.actions.append("jump_run")
	
	
	
	return new_input
