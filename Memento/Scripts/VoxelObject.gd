class_name VoxelObject
extends Node3D


@export var grid_size := Vector3i(32, 32, 32)
@export var voxel_size := 0.1


var voxels: Array = []


func _ready() -> void:

	create_voxel_grid()

	rebuild_mesh()


# ============================================================
# CREATE VOXEL GRID
# ============================================================

func create_voxel_grid() -> void:

	voxels.resize(grid_size.x)


	for x in range(grid_size.x):

		voxels[x] = []
		voxels[x].resize(grid_size.y)


		for y in range(grid_size.y):

			voxels[x][y] = []
			voxels[x][y].resize(grid_size.z)


			for z in range(grid_size.z):

				voxels[x][y][z] = true


# ============================================================
# CARVE WITH A SPHERE
# ============================================================

func carve_sphere(
	world_position: Vector3,
	radius: float
) -> void:

	# Convert world position to local position.
	var local_position := to_local(
		world_position
	)


	# Convert local position to voxel coordinates.
	var center := Vector3i(
		local_position / voxel_size
	)


	# Convert radius to voxel units.
	var voxel_radius := int(
		ceil(radius / voxel_size)
	)


	# Only check voxels near the carving sphere.
	for x in range(
		center.x - voxel_radius,
		center.x + voxel_radius + 1
	):

		for y in range(
			center.y - voxel_radius,
			center.y + voxel_radius + 1
		):

			for z in range(
				center.z - voxel_radius,
				center.z + voxel_radius + 1
			):

				# Ignore voxels outside the grid.
				if not is_inside_grid(
					x,
					y,
					z
				):

					continue


				# Get the voxel's local position.
				var voxel_position := Vector3(
					x,
					y,
					z
				) * voxel_size


				# Check if the voxel is inside
				# the carving sphere.
				if voxel_position.distance_to(
					local_position
				) <= radius:

					# Remove the voxel.
					voxels[x][y][z] = false


	# Rebuild the visible mesh.
	rebuild_mesh()


# ============================================================
# REBUILD MESH
# ============================================================

func rebuild_mesh() -> void:

	var surface_tool := SurfaceTool.new()


	surface_tool.begin(
		Mesh.PRIMITIVE_TRIANGLES
	)


	# Loop through every voxel.
	for x in range(grid_size.x):

		for y in range(grid_size.y):

			for z in range(grid_size.z):

				# Skip empty voxels.
				if not voxels[x][y][z]:

					continue


				# Add only the visible faces.
				add_voxel_faces(
					surface_tool,
					Vector3i(x, y, z)
				)


	# Create the mesh.
	var mesh := surface_tool.commit()


	# Assign the mesh.
	$MeshInstance3D.mesh = mesh


# ============================================================
# ADD VISIBLE VOXEL FACES
# ============================================================

func add_voxel_faces(
	surface_tool: SurfaceTool,
	voxel_position: Vector3i
) -> void:

	var world_position := (
		Vector3(voxel_position)
		* voxel_size
	)


	# +X
	if not is_solid(
		voxel_position.x + 1,
		voxel_position.y,
		voxel_position.z
	):

		add_face(
			surface_tool,
			world_position,
			Vector3.RIGHT
		)


	# -X
	if not is_solid(
		voxel_position.x - 1,
		voxel_position.y,
		voxel_position.z
	):

		add_face(
			surface_tool,
			world_position,
			Vector3.LEFT
		)


	# +Y
	if not is_solid(
		voxel_position.x,
		voxel_position.y + 1,
		voxel_position.z
	):

		add_face(
			surface_tool,
			world_position,
			Vector3.UP
		)


	# -Y
	if not is_solid(
		voxel_position.x,
		voxel_position.y - 1,
		voxel_position.z
	):

		add_face(
			surface_tool,
			world_position,
			Vector3.DOWN
		)


	# +Z
	if not is_solid(
		voxel_position.x,
		voxel_position.y,
		voxel_position.z + 1
	):

		add_face(
			surface_tool,
			world_position,
			Vector3.BACK
		)


	# -Z
	if not is_solid(
		voxel_position.x,
		voxel_position.y,
		voxel_position.z - 1
	):

		add_face(
			surface_tool,
			world_position,
			Vector3.FORWARD
		)


# ============================================================
# CHECK IF VOXEL IS SOLID
# ============================================================

func is_solid(
	x: int,
	y: int,
	z: int
) -> bool:

	if not is_inside_grid(
		x,
		y,
		z
	):

		# Outside the grid is empty.
		return false


	return voxels[x][y][z]


# ============================================================
# CHECK GRID BOUNDS
# ============================================================

func is_inside_grid(
	x: int,
	y: int,
	z: int
) -> bool:

	return (
		x >= 0
		and x < grid_size.x
		and y >= 0
		and y < grid_size.y
		and z >= 0
		and z < grid_size.z
	)


# ============================================================
# CREATE ONE QUAD FACE
# ============================================================

func add_face(
	surface_tool: SurfaceTool,
	position: Vector3,
	normal: Vector3
) -> void:

	var vertices := PackedVector3Array()


	# RIGHT
	if normal == Vector3.RIGHT:

		vertices = PackedVector3Array([
			position + Vector3(voxel_size, 0, 0),
			position + Vector3(voxel_size, voxel_size, 0),
			position + Vector3(voxel_size, voxel_size, voxel_size),
			position + Vector3(voxel_size, 0, voxel_size)
		])


	# LEFT
	elif normal == Vector3.LEFT:

		vertices = PackedVector3Array([
			position,
			position + Vector3(0, 0, voxel_size),
			position + Vector3(0, voxel_size, voxel_size),
			position + Vector3(0, voxel_size, 0)
		])


	# UP
	elif normal == Vector3.UP:

		vertices = PackedVector3Array([
			position + Vector3(0, voxel_size, 0),
			position + Vector3(0, voxel_size, voxel_size),
			position + Vector3(voxel_size, voxel_size, voxel_size),
			position + Vector3(voxel_size, voxel_size, 0)
		])


	# DOWN
	elif normal == Vector3.DOWN:

		vertices = PackedVector3Array([
			position,
			position + Vector3(voxel_size, 0, 0),
			position + Vector3(voxel_size, 0, voxel_size),
			position + Vector3(0, 0, voxel_size)
		])


	# BACK
	elif normal == Vector3.BACK:

		vertices = PackedVector3Array([
			position + Vector3(0, 0, voxel_size),
			position + Vector3(voxel_size, 0, voxel_size),
			position + Vector3(voxel_size, voxel_size, voxel_size),
			position + Vector3(0, voxel_size, voxel_size)
		])


	# FORWARD
	elif normal == Vector3.FORWARD:

		vertices = PackedVector3Array([
			position,
			position + Vector3(0, voxel_size, 0),
			position + Vector3(voxel_size, voxel_size, 0),
			position + Vector3(voxel_size, 0, 0)
		])


	else:

		return


	# First triangle.
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(vertices[0])

	surface_tool.set_normal(normal)
	surface_tool.add_vertex(vertices[1])

	surface_tool.set_normal(normal)
	surface_tool.add_vertex(vertices[2])


	# Second triangle.
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(vertices[0])

	surface_tool.set_normal(normal)
	surface_tool.add_vertex(vertices[2])

	surface_tool.set_normal(normal)
	surface_tool.add_vertex(vertices[3])
