extends MeshInstance3D

const MASK_SIZE := 1024

var carve_image: Image
var carve_texture: ImageTexture
var shell_material: ShaderMaterial

func _ready() -> void:
	carve_image = Image.create(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_R8)
	carve_image.fill(Color(0, 0, 0))
	carve_texture = ImageTexture.create_from_image(carve_image)
	
	shell_material = ShaderMaterial.new()
	shell_material.shader = preload("res://Assets/Shaders/Carving.gdshader")
	set_surface_override_material(0, shell_material)
	
	shell_material.set_shader_parameter("carve_mask", carve_texture)

func stamp_carve(uv: Vector2, brush_radius_px: int = 15) -> void:
	var center := Vector2i(uv.x * MASK_SIZE, uv.y * MASK_SIZE)
	
	for y in range(-brush_radius_px, brush_radius_px):
		for x in range(-brush_radius_px, brush_radius_px):
			if Vector2(x, y).length() > brush_radius_px:
				continue
			var px := center.x + x
			var py := center.y + y
			# wrap horizontally in case the UV seam is mid-brush
			px = wrapi(px, 0, MASK_SIZE)
			if py < 0 or py >= MASK_SIZE:
				continue
			carve_image.set_pixel(px, py, Color(1, 0, 0))
		
	carve_texture.update(carve_image)
