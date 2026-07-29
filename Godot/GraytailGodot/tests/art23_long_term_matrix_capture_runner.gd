extends SceneTree

const MATRIX := [
	[&"task_archive", [&"task", &"achievement", &"commission_record"]],
	[&"codex", [&"map", &"monster", &"collectible", &"equipment", &"consumable", &"event", &"rule", &"lore"]],
	[&"research", [&"unlock_interface", &"research_entry"]],
	[&"talent", [&"tree"]],
	[&"profile", [&"qualification_level", &"history", &"statistics", &"milestone", &"title", &"badge"]],
	[&"collection_appearance", [&"unique_display", &"appearance_config", &"display_content", &"badge_title", &"settlement_display"]],
]
const WAIT_TIMEOUT_MS := 5000


func _initialize() -> void:
	call_deferred("_capture_matrix")


func _capture_matrix() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var output_dir := String(options.get("output-dir", "res://art23_long_term_matrix"))
	var output_path := output_dir if output_dir.is_absolute_path() else ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(output_path)

	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var capture_viewport := SubViewport.new()
	capture_viewport.name = "LongTermMatrixCaptureViewport"
	capture_viewport.size = Vector2i(width, height)
	capture_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.disable_3d = true
	root.add_child(capture_viewport)
	var design_root := Control.new()
	design_root.size = Vector2(1280, 720)
	design_root.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	capture_viewport.add_child(design_root)

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
	if not await _wait_until(
		func() -> bool:
			return (
				shell.is_inside_tree()
				and shell.get_selected_module_id() == &"task_archive"
				and shell.get_selected_secondary_id() == &"task"
			),
		"initial LongTerm workspace"
	):
		quit(2)
		return
	var captured := 0
	for raw_entry in MATRIX:
		var entry := raw_entry as Array
		var module_id := StringName(entry[0])
		shell.call("_apply_module_immediately", module_id)
		if not await _wait_until(
			func() -> bool:
				return (
					StringName(shell.get("displayed_module_id")) == module_id
					and StringName(shell.get("transition_state")) == shell.STATE_OPEN
				),
			"module %s" % String(module_id)
		):
			quit(2)
			return
		for raw_group_id in entry[1] as Array:
			var group_id := StringName(raw_group_id)
			shell.call("show_secondary", group_id)
			if not await _wait_until(
				func() -> bool:
					return (
						shell.get_selected_secondary_id() == group_id
						and not String(shell.get("current_workspace").get("kind", "")).is_empty()
					),
				"secondary %s/%s" % [String(module_id), String(group_id)]
			):
				quit(2)
				return
			if not await _wait_for_stable_layout(
				shell,
				"capture %s/%s" % [String(module_id), String(group_id)]
			):
				quit(2)
				return
			var image := capture_viewport.get_texture().get_image()
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
	quit(0 if captured == 25 else 2)


func _wait_until(predicate: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + WAIT_TIMEOUT_MS
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await process_frame
	push_error("ART23 matrix timed out waiting for semantic state: %s" % label)
	return false


func _wait_for_stable_layout(shell: Control, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + WAIT_TIMEOUT_MS
	var previous := ""
	var stable_submissions := 0
	while Time.get_ticks_msec() <= deadline:
		await process_frame
		var fingerprint := _visible_layout_fingerprint(shell)
		if not fingerprint.is_empty() and fingerprint == previous:
			stable_submissions += 1
		else:
			previous = fingerprint
			stable_submissions = 1 if not fingerprint.is_empty() else 0
		if stable_submissions >= 3:
			return true
	push_error("ART23 matrix layout did not stabilize: %s" % label)
	return false


func _visible_layout_fingerprint(node: Node) -> String:
	var records: Array[String] = []
	_collect_visible_layout(node, records)
	records.sort()
	return "|".join(records)


func _collect_visible_layout(node: Node, records: Array[String]) -> void:
	if node is Control:
		var control := node as Control
		if control.is_visible_in_tree():
			var rect := control.get_global_rect()
			var text_value := ""
			if control is Label:
				text_value = (control as Label).text
			elif control is Button:
				text_value = (control as Button).text
			records.append(
				"%s:%.2f,%.2f,%.2f,%.2f:%.3f:%s"
				% [
					String(control.get_path()),
					rect.position.x,
					rect.position.y,
					rect.size.x,
					rect.size.y,
					control.modulate.a,
					text_value,
				]
			)
	for child in node.get_children():
		_collect_visible_layout(child, records)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for argument in arguments:
		var token := String(argument)
		if not token.begins_with("--") or not token.contains("="):
			continue
		var separator := token.find("=")
		result[token.substr(2, separator - 2)] = token.substr(separator + 1)
	return result
