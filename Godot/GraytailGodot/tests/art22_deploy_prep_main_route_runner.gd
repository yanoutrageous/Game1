extends SceneTree

var failures: Array[String] = []
var page_change_count := 0
var last_page: StringName = &""


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
	await _frames(12)

	var run_scene := main.get_node_or_null("RunScene")
	_check(run_scene != null, "main.tscn does not contain the real RunScene host")
	if run_scene == null:
		_finish()
		return

	var app_shell := run_scene.get("ui_shell") as Control
	_check(app_shell != null, "RunScene did not build AppShell")
	_check(app_shell != null and app_shell.name == "AppShell", "RunScene is not using the AppShell presentation host")
	if app_shell == null:
		_finish()
		return
	app_shell.connect("page_changed", _on_page_changed)

	var main_menu := app_shell.get_node_or_null("MainMenuShell") as Control
	var deploy_page := app_shell.get_node_or_null("DeployPrepShell") as Control
	_check(main_menu != null and main_menu.visible, "Actual startup route is not the main menu")
	_check(deploy_page != null, "Actual AppShell is missing DeployPrepShell")
	if main_menu == null or deploy_page == null:
		_finish()
		return

	var deploy_button := main_menu.get_node_or_null("PrimaryActionRoot/MainMenuEntry_deploy") as Button
	_check(deploy_button != null, "Main-menu exploration entry is missing")
	if deploy_button == null:
		_finish()
		return

	deploy_button.emit_signal("pressed")
	var playing: Dictionary = app_shell.call("get_navigation_transition_snapshot")
	_check(StringName(playing.get("state", &"")) == &"playing", "Deploy route did not enter coordinator PLAYING")
	_check(StringName(playing.get("profile_id", &"")) == &"enter_cave", "Deploy route did not use enter_cave")
	_check(StringName(run_scene.get("screen_state")) == &"main_menu", "Deploy route changed screen before presentation completion")
	_check(not deploy_page.visible and page_change_count == 0, "Deploy route committed before presentation completion")
	# AppShell owns the route commit; MainMenuShell only advances presentation.
	main_menu.call("_process", 1.2)
	await _frames(8)

	_check(StringName(run_scene.get("screen_state")) == &"deploy_shell", "Main-menu exploration entry did not reach deploy_shell")
	_check(deploy_page.visible, "DeployPrepShell is hidden after the actual main-menu route")
	_check(not main_menu.visible, "MainMenuShell remained visible over DeployPrepShell")
	var settled: Dictionary = app_shell.call("get_navigation_transition_snapshot")
	var last_result := settled.get("last_result", {}) as Dictionary
	_check(StringName(settled.get("state", &"")) == &"idle", "Deploy coordinator did not settle IDLE")
	_check(StringName(last_result.get("outcome", &"")) == &"committed" and int(last_result.get("commit_count", 0)) == 1, "Deploy route did not commit exactly once")
	_check(page_change_count == 1 and last_page == &"deploy_prep", "Deploy route emitted duplicate or false page changes")
	_check(deploy_page.get_node_or_null("BackgroundRoot/DeployPrepSceneCleanPlate") is TextureRect, "Actual deploy route is missing the ART22 clean plate")
	_check(deploy_page.get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployParchment") is TextureRect, "Actual deploy route is missing the ART22 parchment")
	_check(deploy_page.get_node_or_null("SideStatusRoot/DeploySummaryBoard") is TextureRect, "Actual deploy route is missing the ART22 hanging summary")
	_check((deploy_page.get("tab_buttons") as Dictionary).size() == 5, "Actual deploy route does not expose five ART22 primary tabs")
	_check((deploy_page.get("filter_buttons") as Dictionary).size() == 6, "Actual default map route does not expose six map filters")

	_finish()


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _on_page_changed(page_id: StringName, _payload: Dictionary) -> void:
	page_change_count += 1
	last_page = page_id


func _finish() -> void:
	if failures.is_empty():
		print("ART22_DEPLOY_PREP_MAIN_ROUTE=PASS host=main.tscn route=main_menu_to_deploy shell=DeployPrepShell")
		quit(0)
		return
	for failure in failures:
		push_error("ART22 main-route failure: " + failure)
	print("ART22_DEPLOY_PREP_MAIN_ROUTE=FAIL count=%d" % failures.size())
	quit(1)
