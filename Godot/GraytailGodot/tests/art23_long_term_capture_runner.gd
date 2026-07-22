extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var module_id := StringName(options.get("module", "task_archive"))
	var secondary_id := StringName(options.get("secondary", ""))
	var collapsed := String(options.get("collapsed", "false")) == "true"
	var sample_time := float(options.get("time", "0"))
	var output := String(options.get("output", "res://art23_long_term_capture.png"))
	print("ART23_CAPTURE_STAGE=setup")

	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.transparent_bg = false
	var design_root := Control.new()
	design_root.name = "Art23DesignCanvas"
	design_root.size = Vector2(1280, 720)
	design_root.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	root.add_child(design_root)

	var shell_script := load("res://scripts/ui/long_term/long_term_shell.gd")
	if shell_script == null:
		push_error("ART23 capture could not load LongTermShell")
		quit(2)
		return
	var long_term := shell_script.new() as Control
	long_term.name = "Art23CaptureLongTerm"
	long_term.size = Vector2(1280, 720)
	design_root.add_child(long_term)
	long_term.call("build")
	print("ART23_CAPTURE_STAGE=built")
	long_term.call("apply_snapshot", {
		"meta_progress_summary": {
			"profile_level": 12,
			"profile_exp": 3456,
			"run_count": 23,
			"extract_count": 14,
			"fail_count": 9,
			"long_term_gold": 12840,
			"gold": 12840,
			"warehouse_items": [
				{"item_id": "mushroom_sample", "display_name": "菌菇样本", "category": "collectible"},
				{"item_id": "cave_bat_sample", "display_name": "洞穴蝙蝠样本", "category": "monster_sample"},
			],
			"warehouse_items_count": 2,
		},
	})
	long_term.call("_apply_module_immediately", module_id)
	print("ART23_CAPTURE_STAGE=module")
	if not secondary_id.is_empty():
		long_term.call("show_secondary", secondary_id)
	if collapsed:
		long_term.call("set_archive_collapsed", true, false)
	await _frames(12)
	print("ART23_CAPTURE_STAGE=rendered")
	var remaining := maxf(0.0, sample_time)
	while remaining > 0.0:
		var step := minf(0.12, remaining)
		long_term.call("_process", step)
		remaining -= step
		await process_frame

	print("ART23_CAPTURE_STAGE=readback")
	var image := root.get_texture().get_image()
	print("ART23_CAPTURE_STAGE=image")
	if image == null:
		push_error("ART23 capture renderer returned no image")
		quit(2)
		return
	var output_path := output if output.is_absolute_path() else ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var result := image.save_png(output_path)
	if result != OK:
		push_error("ART23 capture failed: %s -> %s" % [output_path, error_string(result)])
		quit(2)
		return
	print("ART23_CAPTURE=PASS module=%s secondary=%s collapsed=%s size=%dx%d output=%s" % [String(module_id), String(secondary_id), collapsed, image.get_width(), image.get_height(), output_path])
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
