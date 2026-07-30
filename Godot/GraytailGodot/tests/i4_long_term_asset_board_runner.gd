extends SceneTree

const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

const PASS_MARKER := "I4_LONG_TERM_ASSET_BOARD=PASS"
const FAIL_MARKER := "I4_LONG_TERM_ASSET_BOARD=FAIL"
const ASSET_MANIFEST := "res://data/assets/asset_manifest.csv"
const EXPECTED_ASSET_COUNT := 58
const LOGICAL_SIZE := Vector2i(1280, 720)
const COLUMNS := 4
const ROWS := 2
const ASSETS_PER_PAGE := COLUMNS * ROWS
const WAIT_TIMEOUT_MS := 5000

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var ui_scale := Art10UISkinKitScript.set_runtime_ui_scale_factor(
		float(options.get("ui-scale", 1.0))
	)
	var output_dir := String(options.get("output-dir", "res://i4_long_term_asset_board"))
	var output_path := (
		output_dir
		if output_dir.is_absolute_path()
		else ProjectSettings.globalize_path(output_dir)
	)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_path)
	_require(
		mkdir_error == OK or DirAccess.dir_exists_absolute(output_path),
		"could not create output directory: %s" % output_path
	)
	var assets := _load_assets()
	_require(
		assets.size() == EXPECTED_ASSET_COUNT,
		"expected %d admitted LongTerm assets, got %d"
		% [EXPECTED_ASSET_COUNT, assets.size()]
	)
	if not failures.is_empty():
		_finish(0, 0, width, height, ui_scale, output_path)
		return

	root.size = LOGICAL_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var capture_viewport := SubViewport.new()
	capture_viewport.name = "I4LongTermAssetBoardViewport"
	capture_viewport.size = Vector2i(width, height)
	capture_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.disable_3d = true
	root.add_child(capture_viewport)
	var design_root := Control.new()
	design_root.name = "I4LongTermAssetBoard"
	design_root.size = LOGICAL_SIZE
	design_root.scale = Vector2(
		float(width) / float(LOGICAL_SIZE.x),
		float(height) / float(LOGICAL_SIZE.y)
	)
	capture_viewport.add_child(design_root)
	_build_board_frame(design_root, ui_scale)
	var grid := Control.new()
	grid.name = "AssetGrid"
	grid.position = Vector2(20, 66)
	grid.size = Vector2(1240, 634)
	design_root.add_child(grid)

	var page_count := ceili(float(assets.size()) / float(ASSETS_PER_PAGE))
	var index_rows: Array[Dictionary] = []
	var captured := 0
	for page_index in range(page_count):
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
		var page_start := page_index * ASSETS_PER_PAGE
		var page_end := mini(page_start + ASSETS_PER_PAGE, assets.size())
		for asset_index in range(page_start, page_end):
			var asset := assets[asset_index] as Dictionary
			var local_index := asset_index - page_start
			_build_asset_tile(
				grid,
				asset,
				local_index % COLUMNS,
				local_index / COLUMNS,
				ui_scale
			)
		if not await _wait_for_stable_layout(
			grid,
			"asset page %d" % (page_index + 1)
		):
			continue
		RenderingServer.force_draw(false)
		var image := capture_viewport.get_texture().get_image()
		_require(image != null and not image.is_empty(), "asset page %d is empty" % (page_index + 1))
		if image == null or image.is_empty():
			continue
		_require(
			image.get_size() == Vector2i(width, height),
			"asset page %d size=%s expected=%s"
			% [page_index + 1, image.get_size(), Vector2i(width, height)]
		)
		var file_name := (
			"long_term_assets__p%02d__%dx%d__ui%d.png"
			% [page_index + 1, width, height, int(round(ui_scale * 100.0))]
		)
		var file_path := output_path.path_join(file_name)
		var save_error := image.save_png(file_path)
		_require(
			save_error == OK,
			"asset page %d save failed: %s"
			% [page_index + 1, error_string(save_error)]
		)
		if save_error != OK:
			continue
		captured += 1
		for asset_index in range(page_start, page_end):
			var asset := assets[asset_index] as Dictionary
			index_rows.append({
				"asset_id": String(asset.get("asset_id", "")),
				"godot_path": String(asset.get("godot_path", "")),
				"theme_key": String(asset.get("theme_key", "")),
				"state": String(asset.get("state", "")),
				"variant": String(asset.get("variant", "")),
				"page": page_index + 1,
				"image": file_name,
			})
	var index_path := output_path.path_join(
		"long_term_assets__%dx%d__ui%d.json"
		% [width, height, int(round(ui_scale * 100.0))]
	)
	var index_file := FileAccess.open(index_path, FileAccess.WRITE)
	_require(index_file != null, "could not open asset-board index: %s" % index_path)
	if index_file != null:
		index_file.store_string(JSON.stringify({
			"schema_version": 1,
			"standard_id": "I4-QA-FROZEN-1",
			"status": "PASS" if failures.is_empty() else "FAIL",
			"width": width,
			"height": height,
			"ui_scale": ui_scale,
			"asset_count": assets.size(),
			"page_count": page_count,
			"rows": index_rows,
		}, "\t") + "\n")
	_finish(captured, page_count, width, height, ui_scale, output_path)


func _build_board_frame(parent: Control, ui_scale: float) -> void:
	var background := ColorRect.new()
	background.name = "BoardBackground"
	background.position = Vector2.ZERO
	background.size = LOGICAL_SIZE
	background.color = Color(0.012, 0.026, 0.030, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(background)
	var title := Label.new()
	title.name = "BoardTitle"
	title.position = Vector2(20, 12)
	title.size = Vector2(1240, 42)
	title.text = "I4 长期系统运行资产原图板 · 同源纹理 / 非衍生联系表"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override(
		"font",
		Art10UISkinKitScript.font_for_role(&"readable")
	)
	title.add_theme_font_size_override(
		"font_size",
		Art10UISkinKitScript.scaled_font_size(18, ui_scale)
	)
	title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.42, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(title)


func _build_asset_tile(
	parent: Control,
	asset: Dictionary,
	column: int,
	row: int,
	ui_scale: float
) -> void:
	var tile := PanelContainer.new()
	tile.name = "AssetTile_%02d_%02d" % [row, column]
	tile.position = Vector2(column * 310.0, row * 317.0)
	tile.size = Vector2(300, 307)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.060, 0.065, 1.0)
	panel_style.border_color = Color(0.26, 0.72, 0.68, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(3)
	panel_style.set_content_margin_all(6.0)
	tile.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(tile)
	var body := Control.new()
	body.name = "TileBody"
	body.custom_minimum_size = Vector2(288, 295)
	tile.add_child(body)
	for y in range(8):
		for x in range(8):
			var cell := ColorRect.new()
			cell.position = Vector2(6 + x * 35, 6 + y * 27)
			cell.size = Vector2(35, 27)
			cell.color = (
				Color(0.18, 0.20, 0.20, 1.0)
				if (x + y) % 2 == 0
				else Color(0.08, 0.10, 0.10, 1.0)
			)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(cell)
	var texture_rect := TextureRect.new()
	texture_rect.name = "AssetVisual"
	texture_rect.position = Vector2(6, 6)
	texture_rect.size = Vector2(280, 216)
	texture_rect.texture = asset.get("texture") as Texture2D
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(texture_rect)
	var label := Label.new()
	label.name = "AssetIdentity"
	label.position = Vector2(6, 226)
	label.size = Vector2(280, 62)
	var asset_id := String(asset.get("asset_id", ""))
	var common_prefix := "ui.art23.long_term."
	var asset_suffix := (
		asset_id.trim_prefix(common_prefix)
		if asset_id.begins_with(common_prefix)
		else asset_id
	)
	label.text = "%s\n%s\n%s / %s" % [
		common_prefix.trim_suffix("."),
		asset_suffix,
		String(asset.get("state", "")),
		String(asset.get("variant", "")),
	]
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.max_lines_visible = 3
	label.add_theme_font_override(
		"font",
		Art10UISkinKitScript.font_for_role(&"readable")
	)
	label.add_theme_font_size_override(
		"font_size",
		# Evidence identity must remain fully visible even when the production
		# UI scale under test is 150%; the asset itself, not this audit caption,
		# is the scaled subject.
		Art10UISkinKitScript.scaled_font_size(9, minf(ui_scale, 1.0))
	)
	label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.86, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(label)


func _load_assets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var file := FileAccess.open(ASSET_MANIFEST, FileAccess.READ)
	_require(file != null, "asset manifest could not be opened")
	if file == null:
		return result
	var headers := file.get_csv_line(",")
	var header_index := {}
	for index in range(headers.size()):
		header_index[String(headers[index])] = index
	for required in [
		"asset_id",
		"godot_path",
		"linked_scene",
		"theme_key",
		"state",
		"variant",
		"source_status",
	]:
		_require(header_index.has(required), "asset manifest lacks %s" % required)
	while not file.eof_reached():
		var values := file.get_csv_line(",")
		if values.is_empty() or String(values[0]).is_empty():
			continue
		var asset_id := _csv_value(values, header_index, "asset_id")
		if not asset_id.begins_with("ui.art23.long_term."):
			continue
		if (
			_csv_value(values, header_index, "linked_scene")
			!= "scripts/ui/long_term/long_term_shell.gd"
			or _csv_value(values, header_index, "source_status")
			!= "i3r_current_generated_from_audited_source"
		):
			continue
		var godot_path := _csv_value(values, header_index, "godot_path")
		var texture := load(godot_path) as Texture2D
		_require(texture != null, "asset did not resolve: %s" % godot_path)
		_require(
			texture != null and texture.get_width() > 0 and texture.get_height() > 0,
			"asset has no positive texture size: %s" % godot_path
		)
		result.append({
			"asset_id": asset_id,
			"godot_path": godot_path,
			"theme_key": _csv_value(values, header_index, "theme_key"),
			"state": _csv_value(values, header_index, "state"),
			"variant": _csv_value(values, header_index, "variant"),
			"texture": texture,
		})
	return result


func _csv_value(values: PackedStringArray, header_index: Dictionary, key: String) -> String:
	var index := int(header_index.get(key, -1))
	return String(values[index]) if index >= 0 and index < values.size() else ""


func _wait_for_stable_layout(subject: Node, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + WAIT_TIMEOUT_MS
	var previous := ""
	var stable_submissions := 0
	while Time.get_ticks_msec() <= deadline:
		await process_frame
		var current := _visible_layout_fingerprint(subject)
		if not current.is_empty() and current == previous:
			stable_submissions += 1
		else:
			previous = current
			stable_submissions = 1 if not current.is_empty() else 0
		if stable_submissions >= 3:
			return true
	failures.append("layout did not stabilize: %s" % label)
	return false


func _visible_layout_fingerprint(subject: Node) -> String:
	var records: Array[String] = []
	for candidate in subject.find_children("*", "Control", true, false):
		var control := candidate as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		var text := (control as Label).text if control is Label else ""
		records.append(
			"%s|%.2f,%.2f,%.2f,%.2f|%.3f|%s"
			% [
				String(control.get_path()),
				rect.position.x,
				rect.position.y,
				rect.size.x,
				rect.size.y,
				control.modulate.a,
				text,
			]
		)
	records.sort()
	return "\n".join(records)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for raw_argument in arguments:
		var argument := String(raw_argument)
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var separator := argument.find("=")
		result[argument.substr(2, separator - 2)] = argument.substr(separator + 1)
	return result


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(
	captured: int,
	page_count: int,
	width: int,
	height: int,
	ui_scale: float,
	output_path: String
) -> void:
	if failures.is_empty() and captured == page_count and page_count > 0:
		print(
			"%s assets=%d pages=%d size=%dx%d ui_scale=%d output=%s"
			% [
				PASS_MARKER,
				EXPECTED_ASSET_COUNT,
				page_count,
				width,
				height,
				int(round(ui_scale * 100.0)),
				output_path,
			]
		)
		quit(0)
		return
	for failure in failures:
		printerr("%s:%s" % [FAIL_MARKER, failure])
	quit(1)
