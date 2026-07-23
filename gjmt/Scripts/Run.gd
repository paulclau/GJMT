extends Move

@export var SPEED: float = 4.0
@export var TURN_SPEED: float = 8.0

@export var footsteps: AudioStreamPlayer3D

func check_relevance(input: InputPackage) -> String:
	input.actions.sort_custom(moves_priority_sort)
	if input.actions[0] == "run":
		return "okay"
	return input.actions[0]

func update(input: InputPackage, delta: float) -> void:
	if input.input_direction == Vector2.ZERO:
		if footsteps.playing:
			footsteps.stop()
	else:
		if !footsteps.playing:
			footsteps.play()
	
	var horizontal_velocity: Vector3 = velocity_by_input(input, delta)
	player.velocity.x = horizontal_velocity.x
	player.velocity.z = horizontal_velocity.z
	
	player.move_and_slide()
	
	## Push rigidbodies
	#var push_force = 1.0
	#for i in range(player.get_slide_collision_count()):
		#var collision = player.get_slide_collision(i)
		#
		#if collision.get_collider() is RigidBody3D:
			#print("rigid body detected")
			#var body := collision.get_collider() as RigidBody3D
			#body.apply_central_impulse(-collision.get_normal() * push_force)


func velocity_by_input(input: InputPackage, delta: float) -> Vector3:
	var y_speed = player.velocity.y
	if input.input_direction == Vector2.ZERO:
		return Vector3.ZERO
	
	var move_dir: Vector3 = Vector3(input.input_direction.x, 0, input.input_direction.y).normalized()
	var forward: Vector3 = -player.global_transform.basis.z
	var angle: float = forward.signed_angle_to(move_dir, Vector3.UP)
	
	var turn: float = clamp(angle, -TURN_SPEED * delta, TURN_SPEED * delta)
	player.rotate_y(turn)
	
	if area_awareness.get_floor_distance() > 0.8:
		y_speed -= gravity * delta
	player.velocity.y = y_speed
	
	return move_dir * SPEED

func on_enter_state():
	footsteps.play()

func on_exit_state():
	footsteps.stop()
