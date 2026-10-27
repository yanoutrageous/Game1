extends Control
class_name Art25GameplayBackdrop

var atmosphere: TextureRect
var current_room_type: StringName = &""


func _ready() -> void:
	name = "Art25GameplayBackdrop"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = -1000
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	atmosphere = TextureRect.new()
	atmosphere.name = "RoomAtmosphereExtension"
	atmosphere.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	atmosphere.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	atmosphere.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The room plate is the only depiction of doors and obstacles. A small
	# matte wash grounds its perimeter without repeating those objects outside it.
	var wash := GradientTexture2D.new()
	wash.width = 64
	wash.height = 64
	wash.fill = GradientTexture2D.FILL_RADIAL
	wash.fill_from = Vector2(0.5, 0.44)
	wash.fill_to = Vector2(1.0, 0.94)
	wash.gradient = Gradient.new()
	atmosphere.texture = wash
	add_child(atmosphere)
	apply_room_type(&"Normal")


func apply_layout(viewport_size: Vector2, gameplay_left: float) -> void:
	position = Vector2.ZERO
	size = viewport_size
	if atmosphere == null:
		return
	atmosphere.position = Vector2(gameplay_left, 0.0)
	atmosphere.size = Vector2(maxf(1.0, viewport_size.x - gameplay_left), viewport_size.y)


func apply_room_type(room_type: StringName) -> void:
	if atmosphere == null or current_room_type == room_type:
		return
	current_room_type = room_type
	var center := Color(0.15, 0.14, 0.105)
	if room_type == &"Monster":
		center = Color(0.16, 0.12, 0.10)
	elif room_type == &"Exit":
		center = Color(0.10, 0.145, 0.13)
	var wash := atmosphere.texture as GradientTexture2D
	wash.gradient.colors = PackedColorArray([center, Color(0.018, 0.022, 0.020)])
