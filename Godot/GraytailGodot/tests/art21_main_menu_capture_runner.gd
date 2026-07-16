extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var state := StringName(options.get("state", "default"))
	var output := String(options.get("output", "res://docs_art21_main_menu_capture.png"))

	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.transparent_bg = false
	var design_root := Control.new()
	design_root.name = "Art21DesignCanvas"
	design_root.position = Vector2.ZERO
	design_root.size = Vector2(1280, 720)
	design_root.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	root.add_child(design_root)

	# Load after autoload singletons are registered. Direct preloading from a
	# --script main loop compiles presentation scripts before ContentDB exists.
	var app_shell_script := load("res://scripts/ui/app_shell/app_shell.gd")
	if app_shell_script == null:
		push_error("ART21 capture could not load AppShell")
		quit(2)
		return
	var shell: Control = app_shell_script.new() as Control
	shell.name = "Art21CaptureAppShell"
	design_root.add_child(shell)
	shell.position = Vector2.ZERO
	shell.size = Vector2(1280, 720)
	shell.build()
	for _index in range(12):
		await process_frame
	var built_main: Control = shell.call("get_main_page") as Control
	print("ART21_CAPTURE_METRICS root=%s visible=%s window=%s design=%s scale=%s shell_pos=%s shell_size=%s shell_scale=%s main_pos=%s main_size=%s main_scale=%s" % [root.size, root.get_visible_rect(), DisplayServer.window_get_size(), design_root.size, design_root.scale, shell.position, shell.size, shell.scale, built_main.position, built_main.size, built_main.scale])

	var main_menu: Control = shell.call("get_main_page") as Control
	match state:
		&"long_term":
			main_menu.call("_set_focus_state", &"long_term")
		&"settings":
			shell.show_settings()
		&"exit":
			shell.call("_show_exit_confirm")
		_:
			main_menu.call("_set_focus_state", &"deploy")

	for _index in range(12):
		await process_frame
	var image := root.get_texture().get_image()
	var output_path := output if output.is_absolute_path() else ProjectSettings.globalize_path(output)
	var output_dir := output_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(output_dir)
	var result := image.save_png(output_path)
	if result != OK:
		push_error("ART21 capture failed: %s -> %s" % [output_path, error_string(result)])
		quit(2)
		return
	print("ART21_CAPTURE=PASS state=%s size=%dx%d output=%s" % [String(state), image.get_width(), image.get_height(), output_path])
	quit(0)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for argument in arguments:
		var token := String(argument)
		if not token.begins_with("--") or not token.contains("="):
			continue
		var separator := token.find("=")
		result[token.substr(2, separator - 2)] = token.substr(separator + 1)
	return result
