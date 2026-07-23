class_name PumpkinCarver
extends Node


static var _root: Window = Engine.get_main_loop().root


static func carve(
	pumpkin_mesh: Mesh,
	carve_transform: Transform3D,
	carve_size: Vector3
) -> ArrayMesh:

	var combiner := CSGCombiner3D.new()

	var pumpkin := CSGMesh3D.new()
	pumpkin.mesh = pumpkin_mesh

	var carving_tool := CSGMesh3D.new()

	var carving_mesh := BoxMesh.new()
	carving_mesh.size = carve_size

	carving_tool.mesh = carving_mesh
	carving_tool.transform = carve_transform


	# Add to the scene tree.
	_root.call_deferred("add_child", combiner)

	await _root.get_tree().process_frame

	combiner.add_child(pumpkin)
	combiner.add_child(carving_tool)

	await _root.get_tree().process_frame


	# Subtract the carving shape.
	carving_tool.operation = CSGShape3D.OPERATION_SUBTRACTION

	combiner._update_shape()

	await _root.get_tree().process_frame

	var meshes := combiner.get_meshes()

	var result: ArrayMesh = null

	if meshes.size() > 1:
		result = meshes[1]


	# Clean up.
	combiner.queue_free()


	return result
