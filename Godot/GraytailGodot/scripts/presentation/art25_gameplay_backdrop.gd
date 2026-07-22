extends Control
class_name Art25GameplayBackdrop

const Art24InRunAssetContractScript := preload("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")

var atmosphere: TextureRect


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
	atmosphere.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# This is only an atmospheric continuation behind the intact 560x560 room.
	# Low luminance and alpha prevent duplicate props from competing with play.
	atmosphere.modulate = Color(0.30, 0.26, 0.20, 0.26)
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
	if atmosphere == null:
		return
	var room_token := String(room_type).to_lower()
	if room_token == "chest":
		room_token = "normal"
	if not Art24InRunAssetContractScript.ROOM_PATHS.has(room_token):
		room_token = "normal"
	atmosphere.texture = Art24InRunAssetContractScript.texture(StringName("visual.art24.room.%s" % room_token))
