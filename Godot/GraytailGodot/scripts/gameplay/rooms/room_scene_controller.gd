extends Node2D
class_name RoomSceneController

const ContentDBAccessScript := preload("res://scripts/core/content/content_db_access.gd")
const RuntimeLayout := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")

var room_data: Dictionary = {}


func configure(next_room_data: Dictionary) -> void:
	room_data = next_room_data.duplicate(true)
	_apply_visuals()


func _ready() -> void:
	_apply_visuals()


func _apply_visuals() -> void:
	_ensure_background()
	_ensure_label()
	_ensure_prop()

	var background := get_node_or_null("Background/BackgroundSprite") as Sprite2D
	var title := get_node_or_null("RoomTitle") as Label
	var prop := get_node_or_null("Interactables/PropSprite") as Sprite2D
	var background_asset := StringName(room_data.get("background_asset_id", &""))
	var background_ref := ContentDBAccessScript.get_asset_ref(background_asset) if background_asset != &"" else null
	var fallback := get_node_or_null("Background/MissingBackgroundFallback") as Node2D

	if background != null:
		background.set_meta("requested_asset_id", background_asset)
		background.texture = background_ref as Texture2D if background_ref is Texture2D else null
		background.visible = background.texture != null
		background.set_meta("texture_resolved", background.texture != null)
		background.set_meta("resolved_texture_path", background.texture.resource_path if background.texture != null else "")
		if background.texture != null:
			background.position = RuntimeLayout.ROOM_RECT.get_center()
			background.scale = RuntimeLayout.ROOM_RECT.size / background.texture.get_size()
	if fallback != null:
		fallback.visible = background == null or background.texture == null
		fallback.set_meta("requested_asset_id", background_asset)
		fallback.set_meta("fallback_reason", &"background_texture_unresolved" if fallback.visible else &"none")
	if title != null:
		title.text = "%s\n%s" % [String(room_data.get("title", "Room")), String(room_data.get("hint", ""))]
		title.add_theme_color_override("font_color", PresentationTheme.color_for_key(StringName(room_data.get("risk_key", &"ui.text"))))
	if prop != null:
		# World props are owned by G41RoomRuntimeView's presentation descriptor.
		# Keep the legacy node as a scene-compatibility shell, but never give it
		# texture or visibility authority that could duplicate the live object.
		prop.texture = null
		prop.visible = false


func _ensure_background() -> void:
	var background_layer := get_node_or_null("Background") as Node2D
	if background_layer == null:
		return
	if background_layer.get_node_or_null("BackgroundSprite") == null:
		var sprite := Sprite2D.new()
		sprite.name = "BackgroundSprite"
		sprite.position = RuntimeLayout.ROOM_RECT.get_center()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		background_layer.add_child(sprite)
	if background_layer.get_node_or_null("MissingBackgroundFallback") == null:
		var fallback := Node2D.new()
		fallback.name = "MissingBackgroundFallback"
		fallback.z_index = -1
		var plate := Polygon2D.new()
		plate.name = "FallbackPlate"
		var rect := RuntimeLayout.ROOM_RECT
		plate.polygon = PackedVector2Array([
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		])
		plate.color = Color(0.035, 0.055, 0.058, 1.0)
		fallback.add_child(plate)
		var label := Label.new()
		label.name = "FallbackLabel"
		label.position = rect.get_center() - Vector2(150, 20)
		label.size = Vector2(300, 40)
		label.text = "房间图像未载入"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.74, 0.92))
		fallback.add_child(label)
		background_layer.add_child(fallback)
		background_layer.move_child(fallback, 0)


func _ensure_label() -> void:
	if get_node_or_null("RoomTitle") != null:
		return
	var label := Label.new()
	label.name = "RoomTitle"
	label.position = Vector2(420, 128)
	label.size = Vector2(440, 72)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)


func _ensure_prop() -> void:
	var interactables := get_node_or_null("Interactables") as Node2D
	if interactables == null or interactables.get_node_or_null("PropSprite") != null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "PropSprite"
	sprite.position = Vector2(720, 390)
	sprite.scale = Vector2(0.35, 0.35)
	interactables.add_child(sprite)
