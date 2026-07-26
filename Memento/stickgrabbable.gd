extends MeshInstance3D

@export var raycast: RayCast3D
@export var grab_pos: Marker3D
var picked_object: RigidBody3D = null

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if picked_object:
			drop_object()
		else:
			try_grab()
			
	if picked_object:
		picked_object.global_position = grab_pos.global_position
		picked_object.global_rotation = grab_pos.global_rotation

func try_grab() -> void:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("canGrab"):
			picked_object = collider
			picked_object.freeze = true # Disable physics while holding

func drop_object() -> void:
	if picked_object:
		picked_object.freeze = false # Re-enable physics
		picked_object = null
