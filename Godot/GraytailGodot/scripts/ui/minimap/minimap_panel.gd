extends Control
class_name MiniMapPanel

# UI reads MiniMapViewModel only. UI must not read TruthMap directly.

var view_model: MiniMapViewModel


func apply_view_model(next_view_model: MiniMapViewModel) -> void:
	view_model = next_view_model
	_rebuild_grid()
	queue_redraw()


func clear() -> void:
	view_model = null
	_rebuild_grid()
	queue_redraw()


func _ready() -> void:
	_rebuild_grid()


func _rebuild_grid() -> void:
	var grid := get_node_or_null("Grid") as GridContainer
	var placeholder := get_node_or_null("PlaceholderLabel") as Label
	if grid == null:
		return

	for child in grid.get_children():
		child.queue_free()

	if view_model == null:
		if placeholder != null:
			placeholder.text = "MiniMap: no intel"
		return

	grid.columns = max(1, view_model.width)
	for marker in view_model.room_markers:
		var asset_id := StringName(marker.get("asset_id", &""))
		var asset_ref: Resource = null
		if asset_id != &"":
			asset_ref = ContentDB.get_asset_ref(asset_id)

		if asset_ref is Texture2D:
			var icon := TextureRect.new()
			icon.texture = asset_ref
			icon.custom_minimum_size = Vector2(28, 28)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			grid.add_child(icon)
		else:
			var label := Label.new()
			label.custom_minimum_size = Vector2(28, 28)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.text = String(marker.get("label", "?"))
			label.tooltip_text = ContentDB.get_placeholder_label(asset_id) if asset_id != &"" else "unknown cell"
			grid.add_child(label)

	if placeholder != null:
		placeholder.text = "MiniMap: icons fallback to text"
