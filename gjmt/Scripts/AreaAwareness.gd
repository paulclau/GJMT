extends Node
class_name AreaAwareness

var last_pushback_vector : Vector3
var last_input_package : InputPackage
var on_floor_height : float = 1.3
const FLOOR_DISTANCE_DEFAULT = 999999

@onready var downcast = $Downcast as RayCast3D

func add_context(input : InputPackage) -> InputPackage:
	if not is_on_floor():
		input.actions.append("midair")
	last_input_package = input
	return input

func is_on_floor() -> bool:
	return get_floor_distance() <= on_floor_height

func get_floor_distance() -> float:
	downcast.force_raycast_update()
	if downcast.is_colliding():
		return downcast.global_position.distance_to(downcast.get_collision_point())
	return FLOOR_DISTANCE_DEFAULT
