## A class that contains functions to slice meshes in half.
class_name MeshSlicer
extends Node


static var _root: Window = Engine.get_main_loop().root


## Slice a mesh in half.
## Returns an array containing the 2 halves of the sliced mesh.
static func slice_mesh(
	slice_transform: Transform3D,
	mesh: Mesh,
	cross_section_material: Material = null
) -> Array[ArrayMesh]:

	var combiner := CSGCombiner3D.new()

	var obj_csg := CSGMesh3D.new()
	obj_csg.mesh = mesh

	var slicer_csg := CSGMesh3D.new()

	var box_mesh := BoxMesh.new()
	box_mesh.material = cross_section_material
	slicer_csg.mesh = box_mesh


	# Add the temporary CSG nodes after the current scene setup is finished.
	_root.call_deferred("add_child", combiner)

	# Wait until the deferred add_child has happened.
	await _root.get_tree().process_frame


	# Add the mesh CSG nodes.
	combiner.add_child(obj_csg)
	combiner.add_child(slicer_csg)

	# Wait for the children to enter the scene tree.
	await _root.get_tree().process_frame


	# Find the bounds of the mesh in slicing-plane local space.
	var max_at := Vector3(-INF, -INF, -INF)
	var min_at := Vector3(INF, INF, INF)

	var inverse_transform := slice_transform.affine_inverse()

	for v in mesh.get_faces():

		# Convert the vertex into slicing-plane local space.
		var local_vertex := inverse_transform * v

		max_at = max_at.max(local_vertex)
		min_at = min_at.min(local_vertex)


	# Make the slicer slightly larger than the mesh.
	max_at += Vector3(0.1, 0.1, 0.1)
	min_at -= Vector3(0.1, 0.1, 0.1)


	# Keep one side of the mesh.
	min_at.z = 0.0


	# Calculate the slicer's position and size.
	var center := (max_at + min_at) / 2.0
	var size := max_at - min_at


	# Apply the slicing plane transform.
	slicer_csg.transform = slice_transform
	slicer_csg.position = slice_transform * center
	slicer_csg.mesh.size = size


	# Wait for the CSG nodes to update.
	await _root.get_tree().process_frame


	# ==================================================
	# FIRST HALF
	# ==================================================

	slicer_csg.operation = CSGShape3D.OPERATION_SUBTRACTION

	combiner._update_shape()

	await _root.get_tree().process_frame

	var meshes := combiner.get_meshes()

	var out_mesh: ArrayMesh = null

	if meshes.size() > 1:
		out_mesh = meshes[1]


	# ==================================================
	# SECOND HALF
	# ==================================================

	slicer_csg.operation = CSGShape3D.OPERATION_INTERSECTION

	combiner._update_shape()

	await _root.get_tree().process_frame

	meshes = combiner.get_meshes()

	var out_mesh2: ArrayMesh = null

	if meshes.size() > 1:
		out_mesh2 = meshes[1]


	# ==================================================
	# CLEAN UP
	# ==================================================

	combiner.queue_free()


	return [out_mesh, out_mesh2]
