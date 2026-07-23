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

@export_category("Head Bob")

@export var bob_frequency: float = 2.4
@export var bob_amplitude: float = 0.08

var bob_time: float = 0.0

@export_category("FOV")

@export var base_fov: float = 75.0
@export var fov_change: float = 1.5
@export var fov_smoothing: float = 8.0

@onready var camera_mount: Node3D = $CameraMount
@onready var camera: Camera3D = $CameraMount/PlayerCam

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# LIFECYCLE
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_camera_look(event)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	_update_head_bob(delta)
	_update_fov(delta)
	move_and_slide()

# CAMERA LOOK
func _handle_camera_look(event: InputEventMouseMotion) -> void:
	# Rotate the player horizontally.
	rotate_y(-event.relative.x * mouse_sensitivity)

	# Rotate the camera vertically.
	camera.rotation.x -= event.relative.y * mouse_sensitivity
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(min_look_angle), deg_to_rad(max_look_angle))

# GRAVITY AND JUMPING
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# MOVEMENT
func _handle_movement(delta: float) -> void:
	var input_direction := Input.get_vector("left", "right", "forward", "backward")

	var movement_direction := _get_movement_direction(input_direction)
	var current_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if is_on_floor():
		_move_on_ground(movement_direction, current_speed, delta)
	else:
		_move_in_air(movement_direction, current_speed, delta)


func _get_movement_direction(input_direction: Vector2) -> Vector3:
	var direction := Vector3(input_direction.x, 0.0, input_direction.y)
	# Movement follows the player's horizontal rotation.
	direction = global_transform.basis * direction
	return direction.normalized()

func _move_on_ground(direction: Vector3, speed: float, delta: float) -> void:
	var target_velocity = direction * speed
	if direction:
		velocity.x = move_toward(velocity.x, target_velocity.x, ground_acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, ground_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, ground_deceleration * delta)

func _move_in_air(direction: Vector3, speed: float, delta: float) -> void:
	var target_velocity := direction * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, air_acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, air_acceleration * delta)

# HEAD BOB
func _update_head_bob(delta: float) -> void:
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
