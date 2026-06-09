extends Node2D
class_name RoomSceneController

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
	var prop_asset := StringName(room_data.get("prop_asset_id", &""))
	var background_ref := ContentDB.get_asset_ref(background_asset) if background_asset != &"" else null
	var prop_ref := ContentDB.get_asset_ref(prop_asset) if prop_asset != &"" else null

	if background != null and background_ref is Texture2D:
		background.texture = background_ref
	if title != null:
		title.text = "%s\n%s" % [String(room_data.get("title", "Room")), String(room_data.get("hint", ""))]
		title.add_theme_color_override("font_color", PresentationTheme.color_for_key(StringName(room_data.get("risk_key", &"ui.text"))))
	if prop != null:
		prop.visible = prop_ref is Texture2D
		if prop_ref is Texture2D:
			prop.texture = prop_ref


func _ensure_background() -> void:
	var background_layer := get_node_or_null("Background") as Node2D
	if background_layer == null or background_layer.get_node_or_null("BackgroundSprite") != null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "BackgroundSprite"
	sprite.position = Vector2(640, 360)
	sprite.scale = Vector2(0.45, 0.45)
	background_layer.add_child(sprite)


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
