extends Node3D

@export_group("Carving")
@export var carve_range: float = 3.0
@export var carve_action: String = "carve"

@export var player_camera: Camera3D
@export var carve_camera: Camera3D
@export var player: Player  # your CharacterBody3D script, type-hinted so autocomplete works

@onready var outer_shell: MeshInstance3D = $Outer
@onready var interaction_area = $InteractionArea

var mesh_faces: Array = []
var using_carve_mode: bool = false

func _ready() -> void:
	interaction_area.interact = Callable(self, "toggle_carve_mode")
	interaction_area.action_name = "carve"
	_bake_face_uv_lookup(outer_shell.mesh)

# ENTER / EXIT CARVE MODE
func toggle_carve_mode() -> void:
	if not using_carve_mode:
		using_carve_mode = true
		interaction_area.action_name = "exit"
		player.enter_carve_mode(carve_camera)
		var resource = load("res://Dialouge/Halloween.dialogue")
		DialogueManager.show_dialogue_balloon(resource, "start")
	else:
		using_carve_mode = false
		interaction_area.action_name = "carve"
		player.exit_carve_mode()

func _physics_process(_delta: float) -> void:
	if using_carve_mode and player.can_carve and Input.is_action_pressed(carve_action):
		_try_carve()

func _try_carve() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	
	var mouse_pos := player.virtual_mouse_pos
	var from := cam.global_position
	var to := from + cam.project_ray_normal(mouse_pos) * carve_range
	
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player.get_rid()] # exclude player's collider
	var result: Dictionary = space.intersect_ray(query)
	
	if result.is_empty():
		return
	
	var local_point: Vector3 = outer_shell.to_local(result.position)
	var uv: Variant = _closest_face_uv(local_point)
	if uv != null:
		outer_shell.stamp_carve(uv)

func _bake_face_uv_lookup(mesh: Mesh) -> void:
	var array_mesh: ArrayMesh
	if mesh is ArrayMesh:
		array_mesh = mesh
	else:
		array_mesh = ArrayMesh.new()
		var arrays: Array = mesh.surface_get_arrays(0)
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(array_mesh, 0)
	for i in mdt.get_face_count():
		var face_data := {"verts": [], "uvs": []}
		for j in range(3):
			var vi := mdt.get_face_vertex(i, j)
			face_data.verts.append(mdt.get_vertex(vi))
			face_data.uvs.append(mdt.get_vertex_uv(vi))
		mesh_faces.append(face_data)

func _closest_face_uv(point: Vector3) -> Variant:
	var best_dist := INF
	var best_uv := Vector2.ZERO
	var found := false
	
	for face in mesh_faces:
		var bary: Variant = _barycentric(point, face.verts[0], face.verts[1], face.verts[2])
		if bary == null:
			continue
		
		var b: Vector3 = bary
		var hit_on_face: Vector3 = face.verts[0]*b.x + face.verts[1]*b.y + face.verts[2]*b.z
		var dist: float = point.distance_to(hit_on_face)
		
		if dist < best_dist:
			best_dist = dist
			best_uv = face.uvs[0]*b.x + face.uvs[1]*b.y + face.uvs[2]*b.z
			found = true
		
	if found:
		return best_uv
	return null

func _barycentric(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Variant:
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	
	var denom := d00 * d11 - d01 * d01
	if abs(denom) < 0.0001:
		return null
	
	var v := (d11 * d20 - d01 * d21) / denom
	var w := (d00 * d21 - d01 * d20) / denom
	var u := 1.0 - v - w
	
	return Vector3(u, v, w)
