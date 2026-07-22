extends SceneTree

var failures: Array[String] = []
var page_change_count := 0
var last_page: StringName = &""
var last_payload: Dictionary = {}


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
	app_shell.connect("page_changed", _on_page_changed)

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
	var playing: Dictionary = app_shell.call("get_navigation_transition_snapshot")
	_check(StringName(playing.get("state", &"")) == &"playing", "Long-term route did not enter coordinator PLAYING")
	_check(StringName(playing.get("profile_id", &"")) == &"descend", "Long-term route did not use descend")
	_check(StringName(run_scene.get("screen_state")) == &"main_menu", "Long-term route changed screen before presentation completion")
	_check(not long_term.visible and page_change_count == 0, "Long-term route committed before presentation completion")
	main_menu.call("_process", 1.2)
	await _frames(10)

	_check(StringName(run_scene.get("screen_state")) == &"long_term_shell", "main-menu entry did not reach long_term_shell")
	_check(long_term.visible, "LongTermShell is hidden after actual route")
	_check(not main_menu.visible, "MainMenuShell remained visible over LongTermShell")
	var settled: Dictionary = app_shell.call("get_navigation_transition_snapshot")
	var last_result := settled.get("last_result", {}) as Dictionary
	_check(StringName(settled.get("state", &"")) == &"idle", "Long-term coordinator did not settle IDLE")
	_check(StringName(last_result.get("outcome", &"")) == &"committed" and int(last_result.get("commit_count", 0)) == 1, "Long-term route did not commit exactly once")
	_check(page_change_count == 1 and last_page == &"long_term", "Long-term route emitted duplicate or false page changes")
	_check(long_term.get_node_or_null("LongTermSceneCleanPlate") is TextureRect, "actual route is missing ART23 clean room")
	_check(long_term.get_node_or_null("LongTermProfileFrame") is TextureRect, "actual route is missing fixed profile frame")
	_check(long_term.get_node_or_null("LongTermModuleGroup/LongTermModuleFurniture") is TextureRect, "actual route is missing module furniture")
	_check(long_term.get("tab_buttons").size() == 5, "actual route does not expose five authorised primary modules")
	_check(not long_term.get("tab_buttons").has(&"gacha"), "actual route still exposes unauthorised gacha")
	_check(long_term.get("secondary_buttons").size() == 3, "actual default task archive route does not expose three secondary pages")
	_check(StringName(long_term.get("displayed_module_id")) == &"task_archive", "actual long-term route did not select task_archive")
	_check(StringName(last_payload.get("module_id", &"")) == &"task_archive", "main-menu route payload was not normalized to task_archive")
	_check(StringName(last_payload.get("entry_id", &"")) == &"task_archive", "main-menu route entry alias was not normalized")

	_finish()


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _on_page_changed(page_id: StringName, payload: Dictionary) -> void:
	page_change_count += 1
	last_page = page_id
	last_payload = payload.duplicate(true)


func _finish() -> void:
	if failures.is_empty():
		print("ART23_LONG_TERM_MAIN_ROUTE=PASS host=main.tscn route=main_menu_to_long_term shell=LongTermShell modules=5 canonical=task_archive")
		quit(0)
		return
	for failure in failures:
		push_error("ART23 main-route failure: " + failure)
	print("ART23_LONG_TERM_MAIN_ROUTE=FAIL count=%d" % failures.size())
	quit(1)
