extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const TruthMapScript := preload("res://scripts/core/map/truth_map.gd")
const IntelMapScript := preload("res://scripts/core/intel/intel_map.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	print("M7_13X13_VISIBILITY:stage=setup")
	var output := "res://artifacts/m7/m7_13x13_map_overlay.png"
	var width := 1280
	var height := 720
	for argument in OS.get_cmdline_user_args():
		var token := str(argument)
		if token.begins_with("--output="):
			output = token.trim_prefix("--output=")
		elif token.begins_with("--width="):
			width = int(token.trim_prefix("--width="))
		elif token.begins_with("--height="):
			height = int(token.trim_prefix("--height="))
	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.transparent_bg = false

	var truth := TruthMapScript.new()
	truth.setup_from_config(M7ContentCatalogScript.map_runtime_config("classic_13x13_normal", 130071, {"map_config_id": "classic_13x13_normal"}))
	var intel := IntelMapScript.new()
	intel.setup(13, 13)
	for y in range(3):
		for x in range(5):
			intel.reveal_cell(Vector2i(x, y), truth)
	intel.toggle_flag(Vector2i(7, 7))
	intel.toggle_flag(Vector2i(11, 3))
	print("M7_13X13_VISIBILITY:stage=model")

	var model_script := load("res://scripts/ui/minimap/minimap_view_model.gd")
	var overlay_scene := load("res://scenes/ui/map_overlay/map_overlay_panel.tscn") as PackedScene
	if model_script == null or overlay_scene == null:
		push_error("M7_13X13_VISIBILITY:required_ui_resource_missing")
		quit(2)
		return
	var view_model = model_script.build_from_intel(intel, Vector2i.ZERO)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.035, 0.04, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var overlay := overlay_scene.instantiate()
	root.add_child(overlay)
	overlay.set("view_model", view_model)
	overlay.call("apply_layout_profile", {
		"supported_size": Vector2(width, height),
		"actual_viewport_size": Vector2i(width, height),
		"is_high_resolution": width >= 1600,
		"is_low_resolution": false,
	})
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	print("M7_13X13_VISIBILITY:stage=render")
	await _frames(2)
	print("M7_13X13_VISIBILITY:stage=verify")
	var grid := overlay.get_node_or_null("Panel/Content/Grid") as GridContainer
	if grid == null or grid.columns != 13 or grid.get_child_count() != 169:
		push_error("M7_13X13_VISIBILITY:grid_contract_failed")
		quit(1)
		return
	for child in grid.get_children():
		if child is Control and ((child as Control).size.x < 26.0 or (child as Control).size.y < 26.0):
			push_error("M7_13X13_VISIBILITY:marker_too_small")
			quit(1)
			return
	var image := root.get_texture().get_image()
	var output_path := output if output.is_absolute_path() else ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var save_result := image.save_png(output_path)
	if save_result != OK:
		push_error("M7_13X13_VISIBILITY:capture_failed:%s" % error_string(save_result))
		quit(2)
		return
	print("M7_13X13_VISIBILITY:PASS columns=13 markers=169 size=%dx%d output=%s" % [width, height, output_path])
	quit(0)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame
