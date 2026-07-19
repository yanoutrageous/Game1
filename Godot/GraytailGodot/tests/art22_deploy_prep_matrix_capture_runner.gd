extends SceneTree

const MATRIX := [
	[&"map", [&"all", &"map_classic_minesweeper", &"map_honeycomb_minesweeper", &"map_special_rule", &"map_unlocked", &"map_recommended"]],
	[&"warehouse", [&"all", &"warehouse_equipment", &"warehouse_consumable", &"warehouse_collectible", &"warehouse_special", &"warehouse_status"]],
	[&"claim", [&"all", &"claim_purchase", &"claim_receive", &"claim_recycle", &"claim_locked", &"claim_recommended"]],
	[&"objective", [&"all", &"objective_available", &"objective_commission", &"objective_map_match", &"objective_locked", &"objective_reward"]],
	[&"loadout", [&"all", &"loadout_map", &"loadout_objective", &"loadout_equipment", &"loadout_consumable", &"loadout_special", &"loadout_bag", &"loadout_validity", &"loadout_intent", &"loadout_permission_interface"]],
]


func _initialize() -> void:
	call_deferred("_capture_matrix")


func _capture_matrix() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var output_dir := String(options.get("output-dir", "res://art22_filter_matrix_full"))
	var output_path := output_dir if output_dir.is_absolute_path() else ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(output_path)

	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var canvas := Control.new()
	canvas.name = "Art22MatrixCanvas"
	canvas.size = Vector2(1280, 720)
	canvas.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	root.add_child(canvas)

	var app_shell_script := load("res://scripts/ui/app_shell/app_shell.gd")
	if app_shell_script == null:
		push_error("ART22 matrix capture could not load AppShell")
		quit(2)
		return
	var app_shell := app_shell_script.new() as Control
	app_shell.size = Vector2(1280, 720)
	canvas.add_child(app_shell)
	app_shell.call("build")
	app_shell.call("show_deploy", &"map")
	await _frames(14)
	var deploy := app_shell.call("get_deploy_page") as Control
	var captured := 0
	for raw_entry in MATRIX:
		var entry := raw_entry as Array
		var tab_id := StringName(entry[0])
		deploy.call("show_tab", tab_id)
		await _frames(3)
		for raw_filter_id in entry[1] as Array:
			var filter_id := StringName(raw_filter_id)
			deploy.call("_on_filter_pressed", filter_id)
			await _frames(5)
			var image := root.get_texture().get_image()
			var file_path := output_path.path_join("%s__%s__%dx%d.png" % [String(tab_id), String(filter_id), width, height])
			var result := image.save_png(file_path)
			if result != OK:
				push_error("ART22 matrix capture failed: %s -> %s" % [file_path, error_string(result)])
				quit(2)
				return
			captured += 1
	print("ART22_MATRIX_CAPTURE=PASS states=%d size=%dx%d output=%s" % [captured, width, height, output_path])
	quit(0 if captured == 34 else 2)


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
