extends SceneTree

const RunSceneRefreshControllerScript := preload("res://scripts/core/run/run_scene_refresh_controller.gd")
const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const PASS_MARKER := "I1_REFRESH_SCOPE=PASS"
const FAIL_MARKER := "I1_REFRESH_SCOPE=FAIL"
const PAGE_MAIN := &"main_menu"
const PAGE_DEPLOY := &"deploy_prep"
const PAGE_LONG_TERM := &"long_term"

var failures: Array[String] = []


class CombatSurfaceProbe:
	extends Control
	var refresh_count: int = 0
	var latest_snapshot: Dictionary = {}

	func apply_combat_snapshot(snapshot: Dictionary) -> void:
		refresh_count += 1
		latest_snapshot = snapshot.duplicate(true)


class CombatHUDProbe:
	extends Control
	var refresh_count: int = 0

	func apply_view_model(_view_model: Variant) -> void:
		refresh_count += 1


class CombatRuntimeProbe:
	extends RefCounted
	var snapshot_count: int = 0

	func build_read_only_snapshot() -> Dictionary:
		snapshot_count += 1
		return {"probe": &"combat_runtime"}


class ControlledTextureLoader:
	extends ResourceFormatLoader
	var release := Semaphore.new()
	var texture := PlaceholderTexture2D.new()
	var fail := false

	func _get_recognized_extensions() -> PackedStringArray:
		return PackedStringArray(["i1warm"])

	func _handles_type(type: StringName) -> bool:
		return type == &"Texture2D"

	func _get_resource_type(_path: String) -> String:
		return "Texture2D" if _path.get_extension() == "i1warm" else ""

	func _exists(_path: String) -> bool:
		return _path.get_extension() == "i1warm"

	func _load(_path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
		release.wait()
		return ERR_CANT_OPEN if fail else texture


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	_exercise_run_scene_refresh_controller(canvas)
	_exercise_long_term_catalog()

	var app_shell_script := load("res://scripts/ui/app_shell/app_shell.gd") as Script
	_require(app_shell_script != null and app_shell_script.can_instantiate(), "AppShell could not be instantiated")
	if app_shell_script == null or not app_shell_script.can_instantiate():
		_finish()
		return
	await _exercise_idle_resource_prewarm(canvas, app_shell_script)
	await _exercise_pending_prewarm_release(canvas, app_shell_script)
	_require(Engine.print_error_messages, "controlled failure fixture left engine diagnostics disabled")
	await _exercise_owned_page_lifecycle(canvas, app_shell_script)

	var shell := app_shell_script.new() as Control
	canvas.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.call("build")
	await process_frame

	var main_page := shell.call("get_main_page") as Control
	var deploy_page := shell.call("get_deploy_page") as Control
	var long_term_page := shell.call("get_long_term_page") as Control
	_require(main_page != null and deploy_page != null and long_term_page != null, "AppShell pages were not built")
	if main_page == null or deploy_page == null or long_term_page == null:
		canvas.queue_free()
		await process_frame
		_finish()
		return

	_assert_counts(shell, 0, 0, 0, "initial")

	shell.call("apply_snapshot", _snapshot(1, false))
	_assert_counts(shell, 1, 0, 0, "visible main apply")
	_require_equal(_page_marker(main_page, &"current_snapshot"), 1, "main latest snapshot")
	_require_equal(_page_marker(deploy_page, &"current_snapshot"), -1, "hidden deploy stayed untouched")
	_require_equal(_page_marker(long_term_page, &"current_app_snapshot"), -1, "hidden long-term stayed untouched")

	shell.call("show_deploy", &"config")
	_assert_counts(shell, 1, 1, 0, "deploy switch catch-up")
	_require_equal(_page_marker(deploy_page, &"current_snapshot"), 1, "deploy caught latest snapshot")

	shell.call("apply_snapshot", _snapshot(2, false))
	_assert_counts(shell, 1, 2, 0, "visible deploy apply")
	_require_equal(_page_marker(deploy_page, &"current_snapshot"), 2, "deploy received visible update")
	_require_equal(_page_marker(main_page, &"current_snapshot"), 1, "hidden main avoided deploy update")

	shell.call("show_long_term", &"goals")
	_assert_counts(shell, 1, 2, 1, "long-term switch catch-up")
	_require_equal(_page_marker(long_term_page, &"current_app_snapshot"), 2, "long-term caught latest snapshot")

	shell.call("apply_snapshot", _snapshot(3, false))
	_assert_counts(shell, 1, 2, 2, "visible long-term apply")
	_require_equal(_page_marker(long_term_page, &"current_app_snapshot"), 3, "long-term received visible update")

	var card_grid := long_term_page.get("card_grid_container") as Control
	var settled_cards := card_grid.get_children()
	shell.visible = false
	_require(card_grid.get_children() == settled_cards, "hiding a settled long-term page rebuilt its content cards")
	shell.call("apply_snapshot", _snapshot(4, true))
	_assert_counts(shell, 1, 2, 2, "hidden shell cache only")
	_require_equal(_page_marker(main_page, &"current_snapshot"), 1, "hidden shell kept main untouched")
	_require_equal(_page_marker(deploy_page, &"current_snapshot"), 2, "hidden shell kept deploy untouched")
	_require_equal(_page_marker(long_term_page, &"current_app_snapshot"), 3, "hidden shell kept long-term untouched")

	shell.visible = true
	shell.call("show_main")
	_assert_counts(shell, 2, 2, 2, "main catch-up after hidden")
	_require_equal(_page_marker(main_page, &"current_snapshot"), 4, "main caught hidden snapshot")
	shell.call("show_deploy", &"config")
	_assert_counts(shell, 2, 3, 2, "deploy catches hidden snapshot once")
	_require_equal(_page_marker(deploy_page, &"current_snapshot"), 4, "deploy caught hidden snapshot")
	shell.call("show_long_term", &"goals")
	_assert_counts(shell, 2, 3, 3, "long-term catches hidden snapshot once")
	_require_equal(_page_marker(long_term_page, &"current_app_snapshot"), 4, "long-term caught hidden snapshot")

	var diagnostic_copy: Dictionary = shell.call("get_snapshot_refresh_counts")
	diagnostic_copy[PAGE_MAIN] = 999
	_require_equal(_refresh_count(shell, PAGE_MAIN), 2, "diagnostic counts are read-only copies")

	shell.call("_show_exit_confirm")
	var exit_body := shell.get("exit_confirm_body") as Label
	_require(exit_body != null, "exit confirmation body is missing")
	if exit_body != null:
		_require(exit_body.text.contains("当前不保证重新启动后能够恢复本次探索"), "exit copy still implies cross-process recovery")
		_require(not exit_body.text.contains("下次进入后应从出发探索页继续"), "legacy recovery promise remains in exit copy")

	canvas.queue_free()
	await process_frame
	_finish()


func _exercise_idle_resource_prewarm(canvas: Control, shell_script: Script) -> void:
	var shell := shell_script.new() as Control
	canvas.add_child(shell)
	shell.call("build")
	var content_db := root.get_node("ContentDB")
	var target_record: Dictionary = content_db.call("get_asset", &"ui.art22.deploy_prep.panel.parchment")
	var path := str(target_record.get("godot_path", ""))
	_require(not path.is_empty(), "prewarm fixture asset missing")
	shell.visible = false
	var deadline := Time.get_ticks_msec() + 400
	while Time.get_ticks_msec() < deadline:
		await process_frame
	_require(not ResourceLoader.has_cached(path), "hidden shell started unrelated resource prewarm")
	shell.visible = true
	shell.call("show_main")
	deadline = Time.get_ticks_msec() + 5000
	while not ResourceLoader.has_cached(path) and Time.get_ticks_msec() < deadline:
		await process_frame
	_require(ResourceLoader.has_cached(path), "idle main menu did not prewarm Deploy resources")
	_require(shell.get_node_or_null("DeployPrepShell") == null and shell.get_node_or_null("LongTermShell") == null, "resource prewarm constructed full pages on the main thread")
	_require(shell.call("get_visible_page_id") == PAGE_MAIN, "resource prewarm changed the active route")
	var queued := (shell.get("_prewarm_queue") as Array).size()
	shell.visible = false
	deadline = Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < deadline:
		await process_frame
	_require((shell.get("_prewarm_queue") as Array).size() == queued, "hidden shell advanced unrelated prewarm requests")
	var released_shell: WeakRef = weakref(shell)
	shell.queue_free()
	await process_frame
	await process_frame
	_require(released_shell.get_ref() == null, "prewarm completion retained its released shell")
	_require(not ResourceLoader.has_cached(path), "released shell retained prewarmed page textures")


func _exercise_pending_prewarm_release(canvas: Control, shell_script: Script) -> void:
	var loader := ControlledTextureLoader.new()
	ResourceLoader.add_resource_format_loader(loader, true)
	var shell := shell_script.new() as Control
	canvas.add_child(shell)
	shell.call("build")
	var path := "user://overlapping_shell_prewarm.i1warm"
	_queue_controlled_prewarm(shell, path)
	var first_worker := shell.get("_prewarm_thread") as Thread
	_require(first_worker != null and first_worker.is_alive(), "controlled load did not remain pending")
	shell.call("build")
	_queue_controlled_prewarm(shell, path)
	var second_worker := shell.get("_prewarm_thread") as Thread
	var released_shell: WeakRef = weakref(shell)
	shell.queue_free()
	await process_frame
	loader.release.post()
	var deadline := Time.get_ticks_msec() + 2000
	while (first_worker.is_started() or second_worker.is_started()) and Time.get_ticks_msec() < deadline:
		await process_frame
	_require(not first_worker.is_started() and not second_worker.is_started(), "repeated release left a worker unjoined")
	_require(released_shell.get_ref() == null, "pending worker retained its released shell")
	ResourceLoader.remove_resource_format_loader(loader)

	loader = ControlledTextureLoader.new()
	loader.fail = true
	ResourceLoader.add_resource_format_loader(loader, true)
	shell = shell_script.new() as Control
	canvas.add_child(shell)
	shell.call("build")
	path = "user://failed_shell_prewarm.i1warm"
	var previous_error_output := Engine.print_error_messages
	# Only this controlled I/O failure is injected; completion, collection and no retained result are asserted.
	Engine.print_error_messages = false
	_queue_controlled_prewarm(shell, path)
	var failed_worker := shell.get("_prewarm_thread") as Thread
	shell.set_process(false)
	loader.release.post()
	deadline = Time.get_ticks_msec() + 2000
	while failed_worker.is_alive() and Time.get_ticks_msec() < deadline:
		await process_frame
	_require(not failed_worker.is_alive() and failed_worker.is_started(), "failure fixture did not finish before collection")
	shell.call("_process", 0.0)
	_require(not failed_worker.is_started() and shell.get("_prewarm_thread") == null, "failed worker was abandoned without joining")
	_require((shell.get("_prewarm_resources") as Array).is_empty(), "failed worker retained a resource")
	Engine.print_error_messages = previous_error_output
	shell.queue_free()
	await process_frame
	ResourceLoader.remove_resource_format_loader(loader)


func _queue_controlled_prewarm(shell: Control, path: String) -> void:
	var queue: Array[Dictionary] = [{"page": PAGE_DEPLOY, "path": path}]
	shell.set("_prewarm_queue", queue)
	shell.set("_prewarm_queued", true)
	shell.set("_prewarm_after_msec", 0)
	shell.call("_process", 0.0)


func _exercise_owned_page_lifecycle(canvas: Control, shell_script: Script) -> void:
	var shell := shell_script.new() as Control
	canvas.add_child(shell)
	shell.call("build")
	await process_frame
	_require(shell.get_node_or_null("DeployPrepShell") == null, "startup constructed unopened Deploy")
	_require(shell.get_node_or_null("LongTermShell") == null, "startup constructed unopened LongTerm")
	shell.call("apply_snapshot", _snapshot(31, false))
	shell.visible = false
	shell.call("apply_snapshot", _snapshot(32, false))
	_require(not bool(shell.call("apply_meta_action_result", {"source_page": PAGE_DEPLOY})), "unopened page accepted an unsolicited result")
	_require(shell.get_node_or_null("DeployPrepShell") == null and shell.get_node_or_null("LongTermShell") == null, "passive snapshot/result delivery constructed unopened pages")
	shell.visible = true
	shell.call("show_main")
	var manager := shell.call("get_bound_settings_manager") as Node
	manager.call("begin_transaction")
	_require(bool(manager.call("set_draft_value", &"ui_scale_percent", 125)), "settings rejected pre-creation UI scale")
	_require(bool(manager.call("apply_draft")), "settings did not apply before page creation")
	var main := shell.call("get_main_page") as Control
	var entry := main.find_child("MainMenuEntry_deploy", true, false) as Button
	_require(entry != null, "real main-menu Deploy entry missing")
	if entry != null:
		entry.pressed.emit()
	var deploy := shell.get_node_or_null("DeployPrepShell") as Control
	_require(deploy != null, "navigation did not prepare Deploy")
	if deploy != null:
		_require(not deploy.visible and not bool(deploy.call("is_page_active")), "prepared page became visible/active before commit")
		_require(is_equal_approx(float(deploy.call("get_ui_scale_factor")), 1.25), "lazy Deploy did not inherit current UI scale")
		_require_equal(_page_marker(deploy, &"current_snapshot"), 32, "prepared page was built from stale defaults instead of its initial snapshot")
		_require(shell.call("get_visible_page_id") == PAGE_MAIN, "prepare changed route authority")
		var cancel := InputEventAction.new()
		cancel.action = &"cancel"
		cancel.pressed = true
		_require(bool(shell.call("handle_cancel_event", cancel)), "prepared navigation did not accept cancel")
		await process_frame
		_require(shell.call("get_visible_page_id") == PAGE_MAIN and not deploy.visible, "cancel committed the prepared target")
		_require(root.gui_get_focus_owner() == entry, "cancel did not restore source entry focus")
		entry.pressed.emit()
		_require(shell.call("get_deploy_page") == deploy, "retry after cancel replaced its prepared page")
		main.call("_process", 1.2)
		await process_frame
		_require(deploy.visible and bool(deploy.call("is_page_active")), "committed target did not activate")
		_require_equal(_page_marker(deploy, &"current_snapshot"), 32, "first visit did not receive latest hidden snapshot")
		shell.call("show_main")
		shell.call("show_deploy", &"warehouse")
		_require(shell.call("get_deploy_page") == deploy, "re-entry replaced the retained Deploy instance")
		_require_equal(_refresh_count(shell, PAGE_DEPLOY), 1, "unchanged re-entry reapplied snapshot")
	manager.call("begin_transaction")
	_require(bool(manager.call("set_draft_value", &"reduce_motion", true)), "settings rejected pre-creation reduced motion")
	_require(bool(manager.call("apply_draft")), "settings did not apply reduced motion before page creation")
	var long_term := shell.call("get_long_term_page") as Control
	_require(long_term != null and not long_term.visible and not bool(long_term.call("is_page_active")), "explicit access did not prepare an inactive LongTerm")
	_require(is_equal_approx(float(long_term.call("get_ui_scale_factor")), 1.25) and bool(long_term.call("is_reduced_motion_enabled")), "lazy LongTerm did not inherit changed settings")
	_require_equal(_page_marker(long_term, &"current_app_snapshot"), 32, "LongTerm preparation omitted initial snapshot")
	shell.call("show_long_term", &"task_archive")
	_require_equal(_page_marker(long_term, &"current_app_snapshot"), 32, "first LongTerm visit lost latest snapshot")
	var old_pages := [weakref(main), weakref(deploy), weakref(long_term)]
	shell.call("build")
	await process_frame
	await process_frame
	for old_page: WeakRef in old_pages:
		_require(old_page.get_ref() == null, "shell rebuild retained an old page")
	_require(shell.get_node_or_null("DeployPrepShell") == null and shell.get_node_or_null("LongTermShell") == null, "rebuild eagerly recreated inactive pages")
	var rebuilt_main: WeakRef = weakref(shell.call("get_main_page"))
	manager.call("begin_transaction")
	manager.call("set_draft_value", &"ui_scale_percent", 100)
	manager.call("set_draft_value", &"reduce_motion", false)
	_require(bool(manager.call("apply_draft")), "settings did not reset after lifecycle fixture")
	shell.queue_free()
	await process_frame
	_require(rebuilt_main.get_ref() == null, "shell release retained its owned page")


func _exercise_long_term_catalog() -> void:
	var build_samples: Array[int] = []
	var lookup_samples: Array[int] = []
	for index in range(16):
		var started := Time.get_ticks_usec()
		LongTermContentFrameworkScript.build_modules()
		build_samples.append(Time.get_ticks_usec() - started)
		started = Time.get_ticks_usec()
		LongTermContentFrameworkScript.find_module(&"task_archive")
		lookup_samples.append(Time.get_ticks_usec() - started)
	build_samples.sort()
	lookup_samples.sort()
	_require(lookup_samples[8] * 2 < build_samples[8], "one-module lookup still costs at least half of constructing the entire catalog: %d/%d usec" % [lookup_samples[8], build_samples[8]])
	var modules := LongTermContentFrameworkScript.build_modules()
	modules[0]["secondary_groups"][0]["title"] = "caller mutation"
	var module := LongTermContentFrameworkScript.find_module(&"task_archive")
	_require(module["secondary_groups"][0]["title"] == "任务", "catalog callers share mutable nested module data")
	module["secondary_groups"].clear()
	_require(LongTermContentFrameworkScript.find_module(&"task_archive")["secondary_groups"].size() == 3, "lookup caller mutation damaged the shared catalog")
	_require(LongTermContentFrameworkScript.find_module(&"unknown")["module_id"] == &"task_archive", "unknown module no longer falls back to task archive")


func _exercise_run_scene_refresh_controller(canvas: Control) -> void:
	var surface := CombatSurfaceProbe.new()
	var hud_probe := CombatHUDProbe.new()
	var diagnostics_panel := Control.new()
	var debug_label := Label.new()
	canvas.add_child(surface)
	canvas.add_child(hud_probe)
	canvas.add_child(diagnostics_panel)
	canvas.add_child(debug_label)

	var runtime := CombatRuntimeProbe.new()
	var shell_snapshot_count: Array[int] = [0]
	var diagnostics_refresh_count: Array[int] = [0]
	var shell_snapshot_provider := func() -> Dictionary:
		shell_snapshot_count[0] += 1
		return {"probe": &"shell"}
	var diagnostics_apply := func(snapshot: Dictionary) -> void:
		if snapshot.get("probe", &"") == &"shell":
			diagnostics_refresh_count[0] += 1

	var controller := RunSceneRefreshControllerScript.new()
	controller.bind_targets(
		RefCounted.new(),
		runtime,
		surface,
		hud_probe,
		func(snapshot: Dictionary) -> Dictionary:
			return snapshot,
		diagnostics_panel,
		debug_label,
		shell_snapshot_provider,
		diagnostics_apply
	)
	var authority: Dictionary = controller.describe_authority()
	_require(StringName(authority.get("owner", &"")) == &"RunSceneRefreshController", "refresh helper authority owner is missing")
	_require(bool(authority.get("routes_display_refresh_scope", false)), "refresh helper does not own display scope routing")
	_require(bool(authority.get("owns_refresh_metrics", false)), "refresh helper does not own refresh metrics")
	_require(StringName(authority.get("full_layout_refresh_owner", &"")) == &"RunScene", "full layout refresh authority moved out of RunScene")
	_require(not bool(authority.get("mutates_game_state", true)), "refresh helper claims gameplay state mutation authority")

	surface.visible = false
	hud_probe.visible = false
	diagnostics_panel.visible = false
	debug_label.visible = false
	debug_label.text = "unchanged"
	controller.route_state_change({"_change_scope": &"combat", "last_message": "hidden"}, Callable())
	_require_equal(surface.refresh_count, 0, "hidden combat surface skipped")
	_require_equal(hud_probe.refresh_count, 0, "hidden legacy HUD skipped")
	_require_equal(diagnostics_refresh_count[0], 0, "hidden diagnostics skipped")
	_require_equal(shell_snapshot_count[0], 0, "hidden diagnostics avoided shell snapshot rebuild")
	_require_equal(debug_label.text, "unchanged", "hidden debug label skipped")

	surface.visible = true
	hud_probe.visible = true
	diagnostics_panel.visible = true
	debug_label.visible = true
	controller.route_state_change({"_change_scope": &"combat", "last_message": "visible", "hp": 9, "max_hp": 10}, Callable())
	_require_equal(surface.refresh_count, 1, "visible combat surface refreshed once")
	_require_equal(hud_probe.refresh_count, 1, "visible legacy HUD refreshed once")
	_require_equal(diagnostics_refresh_count[0], 1, "visible diagnostics refreshed once")
	_require_equal(shell_snapshot_count[0], 1, "visible diagnostics requested one shell snapshot")
	_require_equal(debug_label.text, "visible", "visible debug label received combat message")
	_require(not surface.latest_snapshot.has("_change_scope"), "presentation snapshot leaked internal change scope")
	_require(StringName((surface.latest_snapshot.get("combat_runtime", {}) as Dictionary).get("probe", &"")) == &"combat_runtime", "combat runtime snapshot was not attached")

	var full_refresh_count: Array[int] = [0]
	controller.route_state_change({"_change_scope": &"all"}, func() -> void:
		full_refresh_count[0] += 1
	)
	_require_equal(full_refresh_count[0], 1, "non-combat state change delegated one full refresh")
	var metrics: Dictionary = controller.get_metrics()
	_require_equal(int(metrics.get("combat_count", -1)), 2, "combat refresh metric count")
	_require_equal(int(metrics.get("full_count", -1)), 1, "full refresh metric count")
	_require(StringName(metrics.get("last_scope", &"")) == &"full", "last refresh scope metric")
	metrics["combat_count"] = 999
	_require_equal(int(controller.get_metrics().get("combat_count", -1)), 2, "refresh metrics are read-only copies")

	controller.reset_metrics()
	var reset_metrics: Dictionary = controller.get_metrics()
	_require_equal(int(reset_metrics.get("combat_count", -1)), 0, "combat metric reset")
	_require_equal(int(reset_metrics.get("full_count", -1)), 0, "full metric reset")
	_require(StringName(reset_metrics.get("last_scope", &"")) == &"none", "last scope metric reset")

	surface.queue_free()
	hud_probe.queue_free()
	diagnostics_panel.queue_free()
	debug_label.queue_free()


func _snapshot(marker: int, run_active: bool) -> Dictionary:
	return {
		"i1_refresh_marker": marker,
		"run_active": run_active,
	}


func _page_marker(page: Object, property_name: StringName) -> int:
	var value: Variant = page.get(property_name)
	if not (value is Dictionary):
		return -1
	return int((value as Dictionary).get("i1_refresh_marker", -1))


func _assert_counts(shell: Object, main_count: int, deploy_count: int, long_term_count: int, label: String) -> void:
	_require_equal(_refresh_count(shell, PAGE_MAIN), main_count, "%s main refreshes" % label)
	_require_equal(_refresh_count(shell, PAGE_DEPLOY), deploy_count, "%s deploy refreshes" % label)
	_require_equal(_refresh_count(shell, PAGE_LONG_TERM), long_term_count, "%s long-term refreshes" % label)


func _refresh_count(shell: Object, page_id: StringName) -> int:
	var counts: Dictionary = shell.call("get_snapshot_refresh_counts")
	return int(counts.get(page_id, -1))


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s expected=%s actual=%s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(PASS_MARKER)
		print("I1_REFRESH_SCOPE_DETAILS main=2 deploy=3 long_term=3 hidden=cache_only")
		quit(0)
		return
	for failure in failures:
		print("I1_REFRESH_SCOPE_FAILURE %s" % failure)
	print(FAIL_MARKER)
	quit(1)
