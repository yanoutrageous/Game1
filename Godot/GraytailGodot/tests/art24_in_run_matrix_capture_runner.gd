extends SceneTree

const PreviewScript := preload("res://scripts/presentation/art24/art24_in_run_preview.gd")
const Catalog := preload("res://scripts/presentation/art24/art24_state_catalog.gd")


func _initialize() -> void:
	call_deferred("_capture_matrix")


func _capture_matrix() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var output_dir := String(options.get("output-dir", "res://art24_matrix"))
	var output_path := output_dir if output_dir.is_absolute_path() else ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(output_path)

	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.transparent_bg = false
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	canvas.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	root.add_child(canvas)
	var preview := PreviewScript.new() as Control
	preview.size = Vector2(1280, 720)
	canvas.add_child(preview)
	await _frames(18)

	var captured := 0
	for raw_state: Dictionary in Catalog.STATES:
		var state := raw_state.duplicate(true)
		preview.call("apply_state", StringName(state.secondary_id), state)
		await _frames(4)
		var image := root.get_texture().get_image()
		if image == null:
			push_error("ART24 matrix renderer returned no image")
			quit(2)
			return
		var file_name := "%s__%dx%d.png" % [String(state.secondary_id).replace(".", "_"), width, height]
		var file_path := output_path.path_join(file_name)
		var result := image.save_png(file_path)
		if result != OK:
			push_error("ART24 matrix capture failed: %s" % file_path)
			quit(2)
			return
		captured += 1
	print("ART24_MATRIX_CAPTURE=PASS states=%d size=%dx%d output=%s" % [captured, width, height, output_path])
	quit(0 if captured == Catalog.STATES.size() else 2)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for argument in arguments:
		var token := String(argument)
		if not token.begins_with("--") or not token.contains("="):
			continue
		var separator := token.find("=")
		result[token.substr(2, separator - 2)] = token.substr(separator + 1)
	return result
