extends CharacterBody3D
class_name Player

@export_category("Movement")

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0

@export var ground_acceleration: float = 25.0
@export var ground_deceleration: float = 30.0

@export var air_acceleration: float = 8.0
@export var air_deceleration: float = 3.0

@export var jump_velocity: float = 4.8

@export_category("Camera")

@export var mouse_sensitivity: float = 0.002
@export var min_look_angle: float = -40.0
@export var max_look_angle: float = 60.0

@onready var camera_mount: Node3D = $CameraMount
@onready var camera: Camera3D = $CameraMount/PlayerCam

@export_category("Head Bob")

@export var bob_frequency: float = 2.4
@export var bob_amplitude: float = 0.08

var bob_time: float = 0.0

@export_category("FOV")

@export var base_fov: float = 75.0
@export var fov_change: float = 1.5
@export var fov_smoothing: float = 8.0

@export_category("Carve Mode")

@export var carve_time_limit: float = 60.0 # seconds allowed to carve per session
@export var carve_sensitivity_multiplier: float = 0.2 # lower = heavier reticle lag while carving
@export var sensitivity_smoothing: float = 5.0 # higher = reticle catches up faster
@export var carve_reticle: Control
@export var carve_timer_label: Label
@export var label_hide_delay: float = 3.0
@export var player_model: Node3D

var is_carving_mode: bool = false
var active_carve_camera: Camera3D = null
var virtual_mouse_pos: Vector2 = Vector2.ZERO
var can_carve: bool = true
var time_remaining: float = 0.0
var carve_started: bool = false
var label_hide_countdown: float = 0.0

@export_category("Wheelchair Mode")

@export var wheelchair_move_speed: float = 2.0
@export var wheelchair_turn_speed: float = 1.5
@export var wheelchair_acceleration: float = 10.0
@export var wheelchair_shake_amplitude: float = 0.015
@export var wheelchair_shake_frequency: float = 14.0
@export var wheelchair_camera_height: float = -0.4
@export var wheelchair_height_transition_speed: float = 4.0
@export var wheelchair_yaw_limit: float = 60.0

var is_wheelchair_mode: bool = false
var wheelchair_shake_time: float = 0.0
var wheelchair_look_yaw: float = 0.0
var standing_camera_mount_y: float = 0.0

var is_frozen: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var b_is_on_pillow = false;

# FMOD 
@onready var footsteps = get_node_or_null("Footsteps")
@onready var wheelchair = get_node_or_null("wheel")
@onready var ground_ray = get_node_or_null("GroundRayCheck")

# LIFECYCLE
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	standing_camera_mount_y = camera_mount.position.y

func _unhandled_input(event: InputEvent) -> void:
	if is_carving_mode or is_frozen:
		return
	if event is InputEventMouseMotion:
		_handle_camera_look(event)

func _physics_process(delta: float) -> void:
	if is_carving_mode:
		_update_carve_cursor(delta)
		_apply_gravity(delta)
		move_and_slide()  # keeps them grounded while frozen
		return
	
	if is_frozen:
		_apply_gravity(delta)
		move_and_slide()
		return
	
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	_update_head_bob(delta)
	_update_fov(delta)
	_update_camera_height(delta)
	move_and_slide()

func _process(delta: float) -> void:
	_update_carve_timer(delta)

# CARVE MODE
func enter_carve_mode(cam: Camera3D) -> void:
	is_carving_mode = true
	active_carve_camera = cam
	
	velocity = Vector3.ZERO
	camera.current = false
	cam.current = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	virtual_mouse_pos = get_viewport().get_mouse_position()
	
	if not carve_started:
		carve_started = true
		time_remaining = carve_time_limit
	
	if carve_reticle:
		carve_reticle.show()
	if carve_timer_label:
		carve_timer_label.show()
		_update_timer_label()
	
	if player_model:
		player_model.hide()

func exit_carve_mode() -> void:
	is_carving_mode = false
	if is_instance_valid(active_carve_camera):
		active_carve_camera.current = false
	active_carve_camera = null
	
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if carve_reticle:
		carve_reticle.hide()
	# carve_timer_label intentionally NOT hidden here — stays visible so
	# the player can see time still counting down after leaving carve mode.
	
	if player_model:
		player_model.show()

func _update_carve_cursor(delta: float) -> void:
	var real_mouse_pos := get_viewport().get_mouse_position()
	virtual_mouse_pos = virtual_mouse_pos.lerp(real_mouse_pos, delta * sensitivity_smoothing * carve_sensitivity_multiplier * 10.0)
	
	if virtual_mouse_pos.distance_to(real_mouse_pos) < 1.0:
		virtual_mouse_pos = real_mouse_pos
	
	if carve_reticle:
		carve_reticle.position = virtual_mouse_pos - carve_reticle.size / 2.0

func _update_carve_timer(delta: float) -> void:
	if not carve_started:
		return
	
	if not can_carve:
		if carve_timer_label and carve_timer_label.visible:
			label_hide_countdown -= delta
			if label_hide_countdown <= 0.0:
				carve_timer_label.hide()
		return
	
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		can_carve = false
		label_hide_countdown = label_hide_delay
	
	_update_timer_label()

func _update_timer_label() -> void:
	if carve_timer_label:
		carve_timer_label.text = "%d" % ceil(time_remaining)

# WHEELCHAIR MODE
func toggle_wheelchair_mode() -> void:
	is_wheelchair_mode = not is_wheelchair_mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	wheelchair_look_yaw = 0.0
	camera_mount.rotation.y = 0.0

func _handle_wheelchair_movement(delta: float) -> void:
	var turn_input := Input.get_axis("left", "right")
	rotate_y(-turn_input * wheelchair_turn_speed * delta)
	
	var forward_input := Input.get_axis("forward", "backward")
	var move_direction := global_transform.basis * Vector3(0, 0, forward_input)
	move_direction = move_direction.normalized() if forward_input != 0.0 else Vector3.ZERO
	
	var target_velocity := move_direction * wheelchair_move_speed
	if move_direction:
		velocity.x = move_toward(velocity.x, target_velocity.x, wheelchair_acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, wheelchair_acceleration * delta)
		if wheelchair:
			wheelchair.play(false)
		$"../FmodEventEmitter2D".set_parameter("Hospital States", "Moving")
	else:
		velocity.x = move_toward(velocity.x, 0.0, wheelchair_acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, wheelchair_acceleration * delta)
		if wheelchair:
			wheelchair.stop()
		$"../FmodEventEmitter2D".set_parameter("Hospital States", "Still")

func _update_wheelchair_shake(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	
	if horizontal_speed > 0.1:
		wheelchair_shake_time += delta * wheelchair_shake_frequency
		var shake_offset := Vector3(
			sin(wheelchair_shake_time * 1.3) * wheelchair_shake_amplitude,
			sin(wheelchair_shake_time) * wheelchair_shake_amplitude * 0.5,
			0.0)
		camera.position = camera.position.lerp(shake_offset, delta * 10.0)
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)

func _update_camera_height(delta: float) -> void:
	var target_y := standing_camera_mount_y
	if is_wheelchair_mode:
		target_y += wheelchair_camera_height
	camera_mount.position.y = move_toward(camera_mount.position.y, target_y, wheelchair_height_transition_speed * delta)

# CAMERA LOOK
func _handle_camera_look(event: InputEventMouseMotion) -> void:
	if is_wheelchair_mode:
		wheelchair_look_yaw -= event.relative.x * mouse_sensitivity
		wheelchair_look_yaw = clamp(wheelchair_look_yaw, deg_to_rad(-wheelchair_yaw_limit), deg_to_rad(wheelchair_yaw_limit))
		camera_mount.rotation.y = wheelchair_look_yaw
	else:
		rotate_y(-event.relative.x * mouse_sensitivity)
	
	camera.rotation.x -= event.relative.y * mouse_sensitivity
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(min_look_angle), deg_to_rad(max_look_angle))

# GRAVITY AND JUMPING
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _handle_jump() -> void:
	if is_wheelchair_mode:
		return
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# MOVEMENT
func _handle_movement(delta: float) -> void:
	if is_wheelchair_mode:
		if is_instance_valid(footsteps):
			footsteps.stop()
		_handle_wheelchair_movement(delta)
		return
	if wheelchair:
		wheelchair.stop()
	var input_direction := Input.get_vector("left", "right", "forward", "backward")
	var movement_direction := _get_movement_direction(input_direction)
	var current_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	# FMOD PARAMETERS
	if is_instance_valid(ground_ray) and ground_ray.is_colliding():
		var ground = ground_ray.get_collider()
		if ground:
			if "Type" in ground:
				match ground.Type:
					"Mind":
						if is_instance_valid(footsteps):
							footsteps.set_parameter("Ground Type", "Mind")

					"Level":
						if is_instance_valid(footsteps):
							footsteps.set_parameter("Ground Type", "Level")
	if Input.is_action_pressed("sprint"):
		if footsteps:
			footsteps.set_parameter("Speed", "Sprint")
	else:
		if footsteps:
			footsteps.set_parameter("Speed", "Walk")
		
	if is_on_floor():
		_move_on_ground(movement_direction, current_speed, delta)
	else:
		_move_in_air(movement_direction, current_speed, delta)
		if is_instance_valid(footsteps):
			footsteps.stop()

func _get_movement_direction(input_direction: Vector2) -> Vector3:
	var direction := Vector3(input_direction.x, 0.0, input_direction.y)
	direction = global_transform.basis * direction
	return direction.normalized()

func _move_on_ground(direction: Vector3, speed: float, delta: float) -> void:
	var target_velocity = direction * speed
	if direction:
		velocity.x = move_toward(velocity.x, target_velocity.x, ground_acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, ground_acceleration * delta)
		#footsteps.play(false)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, ground_deceleration * delta)
		if is_instance_valid(footsteps):
			footsteps.stop()

func _move_in_air(direction: Vector3, speed: float, delta: float) -> void:
	var target_velocity := direction * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, air_acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, air_acceleration * delta)

# HEAD BOB
func _update_head_bob(delta: float) -> void:
	if is_wheelchair_mode:
		_update_wheelchair_shake(delta)
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.1:
		bob_time += delta * horizontal_speed
		camera.position = _get_head_bob_position(bob_time)
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)

func _get_head_bob_position(time: float) -> Vector3:
	var bob_position := Vector3.ZERO
	bob_position.y = sin(time * bob_frequency) * bob_amplitude
	bob_position.x = cos(time * bob_frequency * 0.5) * bob_amplitude
	return bob_position

func _update_fov(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var target_fov := base_fov + (fov_change * horizontal_speed)
	camera.fov = lerp(camera.fov, target_fov, fov_smoothing * delta)

func freeze_movement(should_freeze: bool) -> void:
	is_frozen = should_freeze
	if should_freeze:
		velocity = Vector3.ZERO
		
func get_player_bounds()-> AABB:
	return $Mesh.get_aabb();


func _on_area_3d_body_entered(body: Node3D) -> void:
	toggle_wheelchair_mode()
	$"../Door_swing/Camera3D".make_current()
	var resource = load("res://Dialouge/Diagnosis.dialogue")
	DialogueManager.show_dialogue_balloon(resource, "start")
	$"../FmodEventEmitter2D".set_parameter("Hospital States", "Door")


func birthday(body: Node3D) -> void:
	var resource = load("res://Dialouge/Birthday.dialogue")
	DialogueManager.show_dialogue_balloon(resource, "start")
