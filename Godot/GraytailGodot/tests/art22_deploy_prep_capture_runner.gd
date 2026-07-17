extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var state := StringName(options.get("state", "expanded"))
	var filter_id := StringName(options.get("filter", ""))
	var sample_time := float(options.get("time", "0"))
	var output := String(options.get("output", "res://art22_deploy_prep_capture.png"))

	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.transparent_bg = false
	var design_root := Control.new()
	design_root.name = "Art22DesignCanvas"
	design_root.size = Vector2(1280, 720)
	design_root.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	root.add_child(design_root)

	var app_shell_script := load("res://scripts/ui/app_shell/app_shell.gd")
	if app_shell_script == null:
		push_error("ART22 capture could not load AppShell")
		quit(2)
		return
	var app_shell := app_shell_script.new() as Control
	app_shell.name = "Art22CaptureAppShell"
	app_shell.size = Vector2(1280, 720)
	design_root.add_child(app_shell)
	app_shell.call("build")
	app_shell.call("show_deploy", &"map")
	await _frames(14)
	var deploy := app_shell.call("get_deploy_page") as Control

	match state:
		&"collapsed":
			deploy.call("set_parchment_collapsed", true, false)
		&"active_run":
			app_shell.call("apply_snapshot", {"run_active": true})
		&"cancel_modal":
			app_shell.call("apply_snapshot", {"run_active": true})
			await _frames(4)
			deploy.call("_show_cancel_modal")
		&"warehouse", &"claim", &"objective", &"loadout":
			deploy.call("show_tab", state)
		_:
			deploy.call("show_tab", &"map")
	if not filter_id.is_empty():
		var filter_buttons := deploy.get("filter_buttons") as Dictionary
		if not filter_buttons.has(filter_id):
			push_error("ART22 capture filter is not available for %s: %s" % [String(state), String(filter_id)])
			quit(2)
			return
		deploy.call("_on_filter_pressed", filter_id)
	await _frames(16)
	var remaining := maxf(0.0, sample_time)
	while remaining > 0.0:
		var step := minf(0.12, remaining)
		deploy.call("_process", step)
		remaining -= step
		await process_frame

	var image := root.get_texture().get_image()
	var output_path := output if output.is_absolute_path() else ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var result := image.save_png(output_path)
	if result != OK:
		push_error("ART22 capture failed: %s -> %s" % [output_path, error_string(result)])
		quit(2)
		return
	print("ART22_CAPTURE=PASS state=%s filter=%s time=%.2f size=%dx%d output=%s" % [String(state), String(filter_id), sample_time, image.get_width(), image.get_height(), output_path])
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
