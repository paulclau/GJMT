extends Move

func check_relevance(input: InputPackage) -> String:
	input.actions.sort_custom(moves_priority_sort)
	return input.actions[0]

func update(_input : InputPackage, delta : float):
	var y_speed = player.velocity.y
	if area_awareness.get_floor_distance() > 0.8:
		y_speed -= gravity * delta
	player.velocity.y = y_speed


func on_enter_state():
	player.velocity = Vector3.ZERO
