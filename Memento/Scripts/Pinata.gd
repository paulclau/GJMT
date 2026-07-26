@tool
extends Node3D

@export var setup_pieces: bool = false:
	set(value):
		if value:
			_convert_pieces_to_rigidbodies()

@export var piece_mass: float = 0.5

func _convert_pieces_to_rigidbodies() -> void:
	print("--- tree under ", name, " ---")
	_print_tree(self, 0)
	var mesh_pieces: Array[MeshInstance3D] = []
	_collect_mesh_instances(self, mesh_pieces)

	if mesh_pieces.is_empty():
		push_warning("PinataSetup: no MeshInstance3D found anywhere under this node.")
		return

	var converted := 0
	for mesh_instance in mesh_pieces:
		if _wrap_in_rigidbody(mesh_instance):
			converted += 1

	print("Pinata setup: converted ", converted, " / ", mesh_pieces.size(), " pieces.")

func _print_tree(node: Node, depth: int) -> void:
	print("  ".repeat(depth), node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		_print_tree(child, depth + 1)

# Recursively finds every MeshInstance3D anywhere in the subtree, not just
# direct children — needed since imported models often nest pieces inside
# an extra wrapper node.
func _collect_mesh_instances(node: Node, result: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)
		_collect_mesh_instances(child, result)  # keep descending regardless

func _wrap_in_rigidbody(mesh_instance: MeshInstance3D) -> bool:
	print("checking piece: ", mesh_instance.name, " | mesh: ", mesh_instance.mesh, " | class: ", (mesh_instance.mesh.get_class() if mesh_instance.mesh else "null"))

	if not mesh_instance.mesh:
		push_warning("PinataSetup: skipping '" + mesh_instance.name + "' — no mesh assigned.")
		return false

	@warning_ignore("unused_variable")
	var original_transform := mesh_instance.transform
	var original_global_transform := mesh_instance.global_transform
	var original_name := mesh_instance.name
	var original_parent := mesh_instance.get_parent()

	var body := RigidBody3D.new()
	body.name = original_name + "_Body"
	body.mass = piece_mass

	original_parent.remove_child(mesh_instance)
	add_child(body)  # new body goes directly under the Pinata root, flattening the hierarchy
	body.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
	body.global_transform = original_global_transform

	mesh_instance.transform = Transform3D.IDENTITY
	body.add_child(mesh_instance)
	mesh_instance.owner = body.owner

	var shape := mesh_instance.mesh.create_convex_shape()
	if not shape:
		push_warning("PinataSetup: convex shape generation failed for '" + original_name + "'.")
		return false

	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = shape
	body.add_child(collision_shape)
	collision_shape.owner = body.owner

	return true
