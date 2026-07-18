extends SceneTree

const PreviewScript := preload("res://scripts/presentation/art24/art24_in_run_preview.gd")
const Catalog := preload("res://scripts/presentation/art24/art24_state_catalog.gd")

var preview: Control
var state_index := 0
var primary_order: Array[StringName] = []
var capture_output := ""


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	capture_output = String(options.get("output", ""))
	var requested_state := StringName(options.get("state", "room.normal.idle"))

	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.transparent_bg = false
	root.title = "Graytail ART24 局内美术预览"

	var canvas := Control.new()
	canvas.name = "Art24DesignCanvas"
	canvas.size = Vector2(1280, 720)
	canvas.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	root.add_child(canvas)

	preview = PreviewScript.new() as Control
	preview.name = "Art24InRunPreview"
	preview.size = Vector2(1280, 720)
	canvas.add_child(preview)
	preview.call("set_interactive", capture_output.is_empty())
	preview.connect("navigation_requested", _on_navigation_requested)
	preview.connect("primary_navigation_requested", _on_primary_navigation_requested)

	_build_primary_order()
	state_index = _index_for_state(requested_state)
	_apply_current_state()
	await _frames(18)

	if not capture_output.is_empty():
		_capture_and_quit(capture_output)
	else:
		print("ART24_PREVIEW=READY states=%d current=%s keys=Left/Right state PageUp/PageDown module" % [Catalog.STATES.size(), String((Catalog.STATES[state_index] as Dictionary).secondary_id)])


func _on_navigation_requested(direction: int) -> void:
	state_index = posmod(state_index + direction, Catalog.STATES.size())
	_apply_current_state()


func _on_primary_navigation_requested(direction: int) -> void:
	var current_primary := StringName((Catalog.STATES[state_index] as Dictionary).primary_id)
	var primary_index := primary_order.find(current_primary)
	primary_index = posmod(primary_index + direction, primary_order.size())
	state_index = Catalog.first_index_for_primary(primary_order[primary_index])
	_apply_current_state()


func _apply_current_state() -> void:
	var state := (Catalog.STATES[state_index] as Dictionary).duplicate(true)
	preview.call("apply_state", StringName(state.secondary_id), state)
	root.title = "Graytail ART24 · %02d/%02d · %s" % [state_index + 1, Catalog.STATES.size(), String(state.secondary_id)]


func _build_primary_order() -> void:
	for raw_state: Dictionary in Catalog.STATES:
		var primary := StringName(raw_state.primary_id)
		if not primary_order.has(primary):
			primary_order.append(primary)


func _index_for_state(requested: StringName) -> int:
	for index in range(Catalog.STATES.size()):
		if StringName((Catalog.STATES[index] as Dictionary).secondary_id) == requested:
			return index
	return 0


func _capture_and_quit(output: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		push_error("ART24 preview capture returned no image")
		quit(2)
		return
	var output_path := output if output.is_absolute_path() else ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var result := image.save_png(output_path)
	if result != OK:
		push_error("ART24 preview capture failed: %s" % output_path)
		quit(2)
		return
	print("ART24_PREVIEW_CAPTURE=PASS state=%s size=%dx%d output=%s" % [String((Catalog.STATES[state_index] as Dictionary).secondary_id), image.get_width(), image.get_height(), output_path])
	quit(0)


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
