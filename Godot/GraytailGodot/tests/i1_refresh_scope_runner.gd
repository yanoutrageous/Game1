extends SceneTree

const RunSceneRefreshControllerScript := preload("res://scripts/core/run/run_scene_refresh_controller.gd")
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


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	_exercise_run_scene_refresh_controller(canvas)

	var app_shell_script := load("res://scripts/ui/app_shell/app_shell.gd") as Script
	_require(app_shell_script != null and app_shell_script.can_instantiate(), "AppShell could not be instantiated")
	if app_shell_script == null or not app_shell_script.can_instantiate():
		_finish()
		return

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

	shell.visible = false
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
