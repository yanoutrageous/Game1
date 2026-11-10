extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var shell := load("res://scripts/ui/app_shell/app_shell.gd").new() as Control
	root.add_child(shell)
	shell.build()
	var main := shell.call("get_main_page") as Control
	main.set_process(false)
	var visuals := main.get_node_or_null("MainMenuVisuals")
	_check(visuals != null, "Production menu is missing the layered visual component")
	if visuals != null:
		_check((visuals.get("layers") as Array).size() == 18, "Environment must retain all 18 independent layers")
		var flag := main.get_node("DecorationRoot/MainMenuDungeonFlag") as TextureRect
		var world := main.get_node("BackgroundRoot/MainMenuSceneCleanPlate") as TextureRect
		_check(flag.z_index < world.z_index and not flag.z_as_relative, "Flag cloth must render behind the fixed pole")
		_check(flag.self_modulate.a == 0.0 and flag.get_child_count() == 1, "Old flag frame must not duplicate the isolated cloth")
		var cloth := flag.get_child(0) as MeshInstance2D
		_check(cloth.texture.resource_path.ends_with("dungeon_flag_cloth.png"), "Flag mesh includes old pole pixels")
		var material := cloth.material as ShaderMaterial
		var start := float(material.get_shader_parameter("scene_time"))
		for step in range(120):
			main.call("_process", 1.0 / 120.0)
			_check(is_equal_approx(float(material.get_shader_parameter("scene_time")), start + float(step + 1) / 120.0), "Environment clock skipped or accelerated a frame")
		main.call("set_reduced_motion_enabled", true)
		var frozen := float(material.get_shader_parameter("scene_time"))
		main.call("_process", 0.5)
		_check(is_equal_approx(float(material.get_shader_parameter("scene_time")), frozen), "Reduced motion must freeze the mesh")
		_check(flag.visible and not (main.get_node("FloatingInfoRoot/MainMenuChimneySmoke") as TextureRect).visible, "Reduced motion must retain cloth and hide ambient particles")
		main.call("set_reduced_motion_enabled", false)
		main.call("set_page_active", false)
		main.call("_process", 0.5)
		_check(is_equal_approx(float(material.get_shader_parameter("scene_time")), frozen), "Inactive page must stop the environment clock")
		main.call("set_page_active", true)
		main.set_process(false)
		for entry_id in [&"deploy", &"long_term", &"settings", &"exit_game"]:
			var board := main.get_node("PrimaryActionRoot/MainMenuBoard_%s" % entry_id) as TextureRect
			var label := main.get_node("PrimaryActionRoot/MainMenuBoardLabel_%s" % entry_id) as Label
			var font := label.get_theme_font("font")
			var board_material := board.material as ShaderMaterial
			var label_material := label.material as ShaderMaterial
			_check(board_material != null and label_material != null, "%s board and lettering need a common perspective" % entry_id)
			if board_material != null and label_material != null:
				_check(board_material.get_shader_parameter("plane") == label_material.get_shader_parameter("plane"), "%s lettering drifts off its board plane" % entry_id)
			for ui_scale in [1.0, 1.25, 1.5]:
				main.call("set_ui_scale_factor", ui_scale)
				main.call("_set_focus_state", entry_id)
				_check(label.get_theme_font("font") == font, "UI scaling must preserve the original font")
				_check(not label.text.is_empty() and label.visible, "Projected label must remain live game text")
				var hit := main.get_node("PrimaryActionRoot/MainMenuEntry_%s" % entry_id) as Button
				var center := visuals.call("project_rack_point", board.position + board.size * 0.5) as Vector2
				_check(hit.get_rect().has_point(center), "%s projected board center is outside its input target" % entry_id)
		# Drain the deferred default focus scheduled by page reactivation first.
		await process_frame
		main.call("set_ui_scale_factor", 1.0)
		main.call("_set_focus_state", &"settings")
		var edge_motion := InputEventMouseMotion.new()
		edge_motion.position = Vector2(1068, 513)
		edge_motion.global_position = edge_motion.position
		Input.parse_input_event(edge_motion)
		await process_frame
		_check(main.get("current_focus") == &"exit_game", "Visible exit-board upper edge incorrectly targets %s" % main.get("current_focus"))
	main.call("set_page_active", false)
	shell.queue_free()
	await process_frame
	if failures.is_empty():
		print("I5_MAIN_MENU_VISUALS=PASS layers=18 clock_steps=120 ui_scales=3 entries=4 reduced_motion=PASS lifecycle=PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("I5_MAIN_MENU_VISUALS=FAIL count=%d" % failures.size())
		quit(1)
