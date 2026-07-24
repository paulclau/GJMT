extends Node3D

@onready var camera: Camera3D = $Player/CameraMount/PlayerCam
@onready var carving_object: CSGCombiner3D = $Map/CarvingObject
@onready var base_mesh: CSGMesh3D = $Map/CarvingObject/Base
@onready var collision_body: StaticBody3D = $Map/CarvingObject/StaticBody3D

@export var carve_radius = 0.2
@export var carve_spacing = 0.1
@export var bake_after_carves = 20
@export var max_carves = 100

var is_carving = false
var mouse_position = Vector2.ZERO
var last_carve_position = Vector3.ZERO
var has_last_carve_position = false
var carve_count = 0
var temporary_carves = 0
var is_baking = false

func _ready() -> void:
	mouse_position = get_viewport().get_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_carving = event.pressed

			if is_carving:
				mouse_position = event.position
				has_last_carve_position = false

	if event is InputEventMouseMotion:
		mouse_position = event.position

func _physics_process(_delta: float) -> void:
	if not is_carving or is_baking or carve_count >= max_carves:
		return
	
	carve_at_mouse(mouse_position)

func carve_at_mouse(mouse_pos: Vector2) -> void:
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000.0)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty() or result.collider != collision_body:
		return
	var hit_position: Vector3 = result.position
	var hit_normal: Vector3 = result.normal

	if not has_last_carve_position:
		add_carving_sphere(hit_position, hit_normal)
		last_carve_position = hit_position
		has_last_carve_position = true
		return

	var distance = hit_position.distance_to(last_carve_position)

	if distance < carve_spacing:
		return

	var steps = int(ceil(distance / carve_spacing))

	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var point = last_carve_position.lerp(hit_position, t)

		add_carving_sphere(point, hit_normal)

		if carve_count >= max_carves:
			break

	last_carve_position = hit_position

func add_carving_sphere(
	carve_position: Vector3, surface_normal: Vector3) -> void:
	if carve_count >= max_carves or is_baking:
		return

	var carving_sphere = CSGSphere3D.new()
	carving_sphere.radius = carve_radius
	carving_sphere.radial_segments = 8
	carving_sphere.rings = 4
	carving_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION

	var sphere_position = carve_position + surface_normal * 0.05

	carving_sphere.position = carving_object.to_local(sphere_position)
	carving_object.add_child(carving_sphere)

	carve_count += 1
	temporary_carves += 1

	if temporary_carves >= bake_after_carves:
		bake_carves()

func bake_carves() -> void:
	if is_baking:
		return
	is_baking = true
	carving_object._update_shape()
	await get_tree().process_frame
	var meshes = carving_object.get_meshes()

	if meshes.size() <= 1:
		is_baking = false
		return

	var baked_mesh: Mesh = meshes[1]
	if baked_mesh == null:
		is_baking = false
		return
	var old_material = base_mesh.material

	for child in carving_object.get_children():
		if child is CSGSphere3D:
			child.queue_free()
	await get_tree().process_frame
	base_mesh.mesh = baked_mesh

	if old_material != null:
		base_mesh.material = old_material
	temporary_carves = 0
	is_baking = false
