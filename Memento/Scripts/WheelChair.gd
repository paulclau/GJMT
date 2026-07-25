extends Node3D

@export var player: Player
@export var seat_forward_offset: float = 0.3
@export var stand_forward_offset: float = 0.6

@onready var interaction_area: InterationArea = $InteractionArea
@onready var seat_point: Marker3D = $SeatPoint
@onready var collision_shape: CollisionShape3D = $WheelChairMesh/StaticBody3D/CollisionShape3D

var world_parent: Node = null

func _ready() -> void:
	world_parent = get_parent()
	interaction_area.interact = Callable(self, "_on_interact")
	_update_prompt()

func _on_interact() -> void:
	if not is_instance_valid(player):
		push_warning("WheelchairPickup: missing player reference.")
		return
	if not player.is_wheelchair_mode:
		_seat_player()
	else:
		_stand_player()
	_update_prompt()

func _seat_player() -> void:
	if collision_shape:
		collision_shape.disabled = true
	player.global_position = seat_point.global_position + seat_offset_transformed()
	
	# force the player to face the same direction as the chair
	player.global_rotation.y = seat_point.global_rotation.y
	
	var _current_transform := global_transform
	world_parent.remove_child(self)
	player.add_child(self)
	transform = seat_point.transform.affine_inverse()
	
	InteractionManager.register_area(interaction_area)
	player.toggle_wheelchair_mode()

func _stand_player() -> void:
	var world_transform := global_transform
	
	player.remove_child(self)
	world_parent.add_child(self)
	global_transform = world_transform
	
	# Move the player out to stand just in front of the wheelchair, using
	# the chair's current facing, not the seat_point child anymore since
	# that's now only meaningful while attached, so we use our own -Z instead
	player.global_position = global_position - global_transform.basis.z * stand_forward_offset
	
	InteractionManager.unregister_area(interaction_area)
	player.toggle_wheelchair_mode()
	
	if collision_shape:
		collision_shape.disabled = false

func _update_prompt() -> void:
	if is_instance_valid(player) and player.is_wheelchair_mode:
		interaction_area.action_name = "stand up"
	else:
		interaction_area.action_name = "sit in wheelchair"

func seat_offset_transformed() -> Vector3:
	# seat_point's local -Z is "forward" by Godot convention, push the
	# player that direction, scaled by the exported offset distance
	return -seat_point.global_transform.basis.z * seat_forward_offset
