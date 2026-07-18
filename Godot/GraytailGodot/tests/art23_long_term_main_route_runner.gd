extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	_check(main_scene != null, "main.tscn could not be loaded")
	if main_scene == null:
		_finish()
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await _frames(14)

	var run_scene := main.get_node_or_null("RunScene")
	_check(run_scene != null, "main.tscn does not contain the real RunScene host")
	if run_scene == null:
		_finish()
		return

	var app_shell := run_scene.get("ui_shell") as Control
	_check(app_shell != null, "RunScene did not build AppShell")
	_check(app_shell != null and app_shell.name == "AppShell", "RunScene is not using AppShell")
	if app_shell == null:
		_finish()
		return

	var main_menu := app_shell.get_node_or_null("MainMenuShell") as Control
	var long_term := app_shell.get_node_or_null("LongTermShell") as Control
	_check(main_menu != null and main_menu.visible, "actual startup route is not main menu")
	_check(long_term != null, "actual AppShell is missing LongTermShell")
	if main_menu == null or long_term == null:
		_finish()
		return

	var long_term_button := main_menu.get_node_or_null("PrimaryActionRoot/MainMenuEntry_long_term") as Button
	_check(long_term_button != null, "main-menu long-term entry is missing")
	if long_term_button == null:
		_finish()
		return

	long_term_button.emit_signal("pressed")
	main_menu.call("_process", 1.2)
	await _frames(10)

	_check(StringName(run_scene.get("screen_state")) == &"long_term_shell", "main-menu entry did not reach long_term_shell")
	_check(long_term.visible, "LongTermShell is hidden after actual route")
	_check(not main_menu.visible, "MainMenuShell remained visible over LongTermShell")
	_check(long_term.get_node_or_null("LongTermSceneCleanPlate") is TextureRect, "actual route is missing ART23 clean room")
	_check(long_term.get_node_or_null("LongTermProfileFrame") is TextureRect, "actual route is missing fixed profile frame")
	_check(long_term.get_node_or_null("LongTermModuleGroup/LongTermModuleFurniture") is TextureRect, "actual route is missing module furniture")
	_check(long_term.get("tab_buttons").size() == 6, "actual route does not expose six ART23 primary modules")
	_check(long_term.get("secondary_buttons").size() == 3, "actual default goals route does not expose three secondary pages")
	_check(StringName(long_term.get("displayed_module_id")) == &"goals", "actual long-term route did not select goals")

	_finish()


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("ART23_LONG_TERM_MAIN_ROUTE=PASS host=main.tscn route=main_menu_to_long_term shell=LongTermShell modules=6")
		quit(0)
		return
	for failure in failures:
		push_error("ART23 main-route failure: " + failure)
	print("ART23_LONG_TERM_MAIN_ROUTE=FAIL count=%d" % failures.size())
	quit(1)
