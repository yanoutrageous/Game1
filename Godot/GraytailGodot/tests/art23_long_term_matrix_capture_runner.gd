extends SceneTree

const MATRIX := [
	[&"goals", [&"task", &"achievement", &"commission_record"]],
	[&"codex", [&"map", &"monster", &"collectible", &"equipment", &"consumable", &"event", &"rule", &"lore"]],
	[&"research", [&"unlock_interface", &"research_entry"]],
	[&"profile", [&"qualification_level", &"history", &"statistics", &"milestone", &"title", &"badge"]],
	[&"gacha", [&"pool", &"cost", &"result_entry"]],
	[&"collection_appearance", [&"unique_display", &"appearance_config", &"display_content", &"badge_title", &"settlement_display"]],
]


func _initialize() -> void:
	call_deferred("_capture_matrix")


func _capture_matrix() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var output_dir := String(options.get("output-dir", "res://art23_long_term_matrix"))
	var output_path := output_dir if output_dir.is_absolute_path() else ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(output_path)

	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var design_root := Control.new()
	design_root.size = Vector2(1280, 720)
	design_root.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	root.add_child(design_root)

	var shell_script := load("res://scripts/ui/long_term/long_term_shell.gd")
	if shell_script == null:
		push_error("ART23 matrix could not load LongTermShell")
		quit(2)
		return
	var shell := shell_script.new() as Control
	shell.size = Vector2(1280, 720)
	design_root.add_child(shell)
	shell.call("build")
	shell.call("apply_snapshot", {
		"meta_progress_summary": {
			"profile_level": 12, "profile_exp": 3456, "run_count": 23,
			"extract_count": 14, "fail_count": 9, "long_term_gold": 12840,
			"gold": 12840, "warehouse_items": [], "warehouse_items_count": 0,
		},
	})
	await _frames(16)
	var captured := 0
	for raw_entry in MATRIX:
		var entry := raw_entry as Array
		var module_id := StringName(entry[0])
		shell.call("_apply_module_immediately", module_id)
		await _frames(3)
		for raw_group_id in entry[1] as Array:
			var group_id := StringName(raw_group_id)
			shell.call("show_secondary", group_id)
			await _frames(3)
			var image := root.get_texture().get_image()
			if image == null:
				push_error("ART23 matrix renderer returned no image")
				quit(2)
				return
			var file_path := output_path.path_join("%s__%s__%dx%d.png" % [String(module_id), String(group_id), width, height])
			var result := image.save_png(file_path)
			if result != OK:
				push_error("ART23 matrix capture failed: %s" % file_path)
				quit(2)
				return
			captured += 1
	print("ART23_MATRIX_CAPTURE=PASS states=%d size=%dx%d output=%s" % [captured, width, height, output_path])
	quit(0 if captured == 27 else 2)


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
