extends MeshInstance2D

var native_size := Vector2.ONE
var effect := 0
var wind_offset := 0.0
var strength := 1.0

func configure(image: Texture2D, dimensions: Vector2, effect_id: int = 0, spacing: float = 8.0) -> void:
	texture = image
	native_size = dimensions
	effect = effect_id
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var columns := maxi(1,ceili(dimensions.x/spacing))
	var rows := maxi(1,ceili(dimensions.y/spacing))
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(rows+1):
		for column in range(columns+1):
			var point := Vector2(float(column)/columns,float(row)/rows)
			vertices.append(point*dimensions)
			uv.append(point)
	for row in range(rows):
		for column in range(columns):
			var a := row*(columns+1)+column
			var b := a+1
			var c := a+columns+2
			var d := a+columns+1
			indices.append_array(PackedInt32Array([a,b,c,a,c,d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	mesh = result
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://scripts/ui/main_menu/main_menu_motion.gdshader")
	shader_material.set_shader_parameter("dimensions",dimensions)
	shader_material.set_shader_parameter("effect",effect)
	shader_material.set_shader_parameter("phase",wind_offset)
	shader_material.set_shader_parameter("strength",strength)
	material = shader_material

func set_clock(value: float) -> void:
	material.set_shader_parameter("scene_time",value)

func set_hover(value: float) -> void:
	material.set_shader_parameter("hover_amount",value)
