extends SceneTree

const RouteController := preload("res://scripts/core/run/run_scene_route_controller.gd")
const AppShellScript := preload("res://scripts/ui/app_shell/app_shell.gd")
const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const PageRouterScript := preload("res://scripts/ui/app_shell/page_router.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const RuntimeTextureCacheScript := preload("res://scripts/presentation/runtime_texture_cache.gd")


class FakeContext:
	extends RefCounted
	var run_active: bool = false
	var phase: StringName = &"idle"


class FakeCommandBus:
	extends RefCounted
	var context := FakeContext.new()
	var result: Dictionary = {}
	var dispatch_count: int = 0
	var activate_on_dispatch := false
	var phase_after_dispatch: StringName = &"running"

	func dispatch(_command_id: StringName, _payload: Dictionary = {}) -> Dictionary:
		dispatch_count += 1
		if activate_on_dispatch and bool(result.get("ok", false)):
			context.run_active = true
			context.phase = phase_after_dispatch
		return result.duplicate(true)


var admission_call_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_expect_blocked_without_bus(failures)
	_expect_failed_admission_does_not_commit(failures)
	_expect_failed_command_stays_outside_run(failures)
	_expect_non_running_runtime_stays_outside_run(failures)
	_expect_running_runtime_routes_once_and_deduplicates(failures)
	_expect_active_run_projection_is_canonical_and_locked(failures)
	await _expect_production_run_scene_admission_wiring(failures)
	await _expect_shell_return_and_hidden_page_lifecycle(failures)
	if failures.is_empty():
		print("I2_ROUTE_AUTHORITY_LIFECYCLE=PASS command_failure=no_route duplicate=deduplicated return=main hidden_pages=paused active_run=canonical_locked")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("I2_ROUTE_AUTHORITY_LIFECYCLE=FAIL count=%d" % failures.size())
	quit(1)


func _expect_blocked_without_bus(failures: Array[String]) -> void:
	var route := RouteController.start_from_payload({}, null)
	_expect(not bool(route.get("ok", true)), "missing bus must reject", failures)
	_expect(not bool(route.get("command_dispatched", true)), "missing bus must not dispatch", failures)
	_expect(not bool(route.get("run_screen_requested", true)), "missing bus must not request Run", failures)
	_expect(not bool(route.get("player_reset_requested", true)), "missing bus must not reset player", failures)


func _expect_failed_admission_does_not_commit(failures: Array[String]) -> void:
	var bus := FakeCommandBus.new()
	bus.result = {"ok": true, "status": &"run_started"}
	bus.activate_on_dispatch = true
	admission_call_count = 0
	var route := RouteController.start_from_payload({}, bus, Callable(self, "_rejecting_admission"))
	_expect(admission_call_count == 1, "run admission must execute exactly once", failures)
	_expect(bus.dispatch_count == 0, "failed run admission must not dispatch a command", failures)
	_expect(not bus.context.run_active and bus.context.phase == &"idle", "failed run admission must leave authority inactive", failures)
	_expect(not bool(route.get("ok", true)), "failed run admission must reject route", failures)
	_expect(not bool(route.get("command_dispatched", true)), "failed run admission must report no dispatch", failures)
	_expect(StringName(route.get("reason_code", &"")) == &"combat_actor_assets_unavailable", "failed run admission needs the asset failure reason", failures)
	_expect(not bool(route.get("run_screen_requested", true)), "failed run admission must stay outside Run", failures)


func _rejecting_admission() -> Dictionary:
	admission_call_count += 1
	return {
		"ok": false,
		"reason_code": &"combat_actor_assets_unavailable",
		"cached": 70,
		"declared": 71,
	}


func _expect_failed_command_stays_outside_run(failures: Array[String]) -> void:
	var bus := FakeCommandBus.new()
	bus.result = {"ok": false, "reason_code": &"invalid_run_start_config"}
	var route := RouteController.start_from_payload({}, bus)
	_expect(bus.dispatch_count == 1, "failed route must dispatch exactly once", failures)
	_expect(bool(route.get("command_dispatched", false)), "failed command must report its dispatch", failures)
	_expect(not bool(route.get("ok", true)), "failed command must reject route", failures)
	_expect(not bool(route.get("run_screen_requested", true)), "failed command must stay on Deploy", failures)
	_expect(not bool(route.get("player_reset_requested", true)), "failed command must keep player position", failures)


func _expect_non_running_runtime_stays_outside_run(failures: Array[String]) -> void:
	var bus := FakeCommandBus.new()
	bus.result = {"ok": true, "status": &"run_started"}
	bus.activate_on_dispatch = true
	bus.phase_after_dispatch = &"event"
	var route := RouteController.start_from_payload({}, bus)
	_expect(bus.dispatch_count == 1, "non-running route must dispatch exactly once", failures)
	_expect(not bool(route.get("ok", true)), "non-running runtime must reject route commit", failures)
	_expect(StringName(route.get("reason_code", &"")) == &"runtime_not_running_after_start", "non-running route needs stable reason", failures)
	_expect(not bool(route.get("run_screen_requested", true)), "non-running runtime must not show Run", failures)
	_expect(not bool(route.get("player_reset_requested", true)), "non-running runtime must not reset player", failures)


func _expect_running_runtime_routes_once_and_deduplicates(failures: Array[String]) -> void:
	var bus := FakeCommandBus.new()
	bus.result = {"ok": true, "status": &"run_started"}
	bus.activate_on_dispatch = true
	bus.phase_after_dispatch = &"running"
	var route := RouteController.start_from_payload({}, bus)
	_expect(bus.dispatch_count == 1, "successful route must dispatch exactly once", failures)
	_expect(bool(route.get("ok", false)), "running runtime must accept route", failures)
	_expect(bool(route.get("run_screen_requested", false)), "running runtime must request Run", failures)
	_expect(bool(route.get("player_reset_requested", false)), "running runtime may reset local player", failures)
	var duplicate := RouteController.start_from_payload({}, bus)
	_expect(bus.dispatch_count == 1, "duplicate start must not dispatch a second command", failures)
	_expect(not bool(duplicate.get("ok", true)), "duplicate start must be rejected", failures)
	_expect(not bool(duplicate.get("command_dispatched", true)), "duplicate start must report no dispatch", failures)
	_expect(StringName(duplicate.get("reason_code", &"")) == &"active_run_start_already_committed", "duplicate start needs stable reason", failures)
	_expect(not bool(duplicate.get("player_reset_requested", true)), "duplicate start must not reset player", failures)


func _expect_active_run_projection_is_canonical_and_locked(failures: Array[String]) -> void:
	var canonical_source := DeployConfigScript.default_config()
	var canonical := DeployConfigScript.build_run_start_config(canonical_source)
	var canonical_equipment := {
		"instance_id": "canonical-equipment",
		"item_id": "eq_old_vest",
		"item_type": "equipment",
		"can_equip": true,
		"equipment_slot": "body",
		"weight": 0,
	}
	var canonical_consumable := {
		"instance_id": "canonical-consumable",
		"item_id": "con_ration",
		"item_type": "consumable",
		"can_consume": true,
		"weight": 1,
	}
	canonical["selected_equipment_items"] = [canonical_equipment]
	canonical["selected_consumable_items"] = [canonical_consumable]
	canonical["selected_equipment_ids"] = ["canonical-equipment"]
	canonical["selected_consumable_ids"] = ["canonical-consumable"]
	canonical["selected_loadout"] = ["canonical-equipment"]
	canonical["carried_consumables"] = ["canonical-consumable"]
	canonical["selected_objective_id"] = &"commission_recover_supply"
	canonical["selected_objective_label"] = "Canonical objective"
	canonical["selected_objective_summary"] = "Canonical objective summary"
	var draft := canonical_source.duplicate(true)
	draft["map_config_id"] = "local-map-tamper"
	draft["selected_objective_id"] = &"local_objective_tamper"
	draft["selected_equipment_ids"] = ["local-equipment-tamper"]
	draft["selected_consumable_ids"] = ["local-consumable-tamper"]
	var locked := DeployConfigScript.with_active_run_config(draft, canonical)
	_expect(bool(locked.get("active_run_locked", false)), "active run config must be locked", failures)
	_expect(str(locked.get("map_config_id", "")) == str(canonical.get("map_config_id", "")), "active run map must use canonical config", failures)
	_expect(StringName(locked.get("selected_objective_id", &"")) == StringName(canonical.get("selected_objective_id", &"")), "active run objective must use canonical config", failures)
	_expect(locked.get("selected_equipment_ids", []) == canonical.get("selected_equipment_ids", []), "active run equipment must use canonical config", failures)
	_expect(locked.get("selected_consumable_ids", []) == canonical.get("selected_consumable_ids", []), "active run consumables must use canonical config", failures)
	var locked_before := locked.duplicate(true)
	var map_rewrite := DeployConfigScript.apply_card_action(locked, &"map", &"m7_map_local_rewrite")
	_expect(not bool(map_rewrite.get("changed", true)), "active run map rewrite must be blocked", failures)
	_expect(StringName(map_rewrite.get("reason_code", &"")) == &"active_run_locked", "active run map rewrite needs lock reason", failures)
	_expect(map_rewrite.get("config", {}) == locked_before, "blocked map rewrite must preserve config", failures)
	var objective_rewrite := DeployConfigScript.apply_card_action(locked, &"objective", &"m7_commission_local_rewrite")
	_expect(not bool(objective_rewrite.get("changed", true)), "active run objective rewrite must be blocked", failures)
	var emitted := DeployConfigScript.build_run_start_config(locked)
	_expect(str(emitted.get("map_config_id", "")) == str(canonical.get("map_config_id", "")), "locked run-start map must remain canonical", failures)
	_expect(emitted.get("selected_equipment_ids", []) == canonical.get("selected_equipment_ids", []), "locked run-start loadout must remain canonical", failures)


func _expect_production_run_scene_admission_wiring(failures: Array[String]) -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_expect(packed != null, "production main scene could not be loaded for route integration", failures)
	if packed == null:
		return
	var production_main := packed.instantiate()
	root.add_child(production_main)
	await _frames(3)
	var run_scene := production_main.get_node_or_null("RunScene")
	_expect(run_scene != null, "production RunScene is missing for route integration", failures)
	if run_scene == null:
		production_main.queue_free()
		await _frames(3)
		return
	var context: Variant = run_scene.get("run_context")
	_expect(context != null and not bool(context.run_active), "production route integration did not start inactive", failures)
	run_scene.call("_start_run_from_route", NavigationIntentScript.make_run(
		&"i2_route_integration",
		{"route_mode": &"demo_run", "entry_id": &"i2_route_integration", "uses_existing_route": true}
	))
	await _frames(3)
	var admission: Dictionary = run_scene.get("last_combat_texture_preflight_report")
	var show_check: Dictionary = run_scene.get("last_combat_texture_prewarm_report")
	_expect(bool(admission.get("ok", false)) and int(admission.get("cached", -1)) == 71, "production RunScene did not execute the 71-texture admission preflight", failures)
	_expect(context != null and bool(context.run_active) and StringName(context.phase) == &"running", "production route did not commit running authority after admission", failures)
	_expect(StringName(run_scene.get("screen_state")) == &"run", "production route did not expose Run after admission", failures)
	_expect(bool(show_check.get("ok", false)) and int(show_check.get("already_cached", -1)) == 71 and int(show_check.get("loaded", -1)) == 0, "production show-time verification was not load-idempotent", failures)
	var room_runtime_view: Variant = run_scene.get("room_runtime_view")
	if room_runtime_view != null:
		room_runtime_view.call("clear_runtime")
	var in_run_runtime: Variant = run_scene.get("in_run_runtime")
	if in_run_runtime != null:
		in_run_runtime.call("bind", null)
	var command_bus: Variant = run_scene.get("command_bus")
	if command_bus != null:
		command_bus.call("bind_runtime_controller", null)
	production_main.queue_free()
	await _frames(6)
	RuntimeTextureCacheScript.clear_for_tests()
	await _frames(2)


func _expect_shell_return_and_hidden_page_lifecycle(failures: Array[String]) -> void:
	root.size = Vector2i(1280, 720)
	var shell := AppShellScript.new() as AppShell
	root.add_child(shell)
	shell.build()
	await _frames(3)
	var main := shell.get_main_page()
	var deploy := shell.get_deploy_page()
	var long_term := shell.get_long_term_page()
	_expect(shell.get_visible_page_id() == PageRouterScript.PAGE_MAIN_MENU, "AppShell must start on main", failures)
	_expect(bool(main.call("is_page_active")), "main must be active on entry", failures)
	_expect(not bool(deploy.call("is_page_active")) and not bool(long_term.call("is_page_active")), "hidden pages must start inactive", failures)
	_expect(PageRouterScript.screen_state_for_page(shell.get_visible_page_id()) == PageRouterScript.SCREEN_MAIN_MENU, "main page must map to RunScene main state", failures)
	main.call("_grab_default_focus")
	await _frames(1)
	shell.call("_on_navigation_intent_requested", NavigationIntentScript.make_deploy(&"i2_runner", {"tab": &"config"}))
	await _frames(3)
	_expect(shell.get_visible_page_id() == PageRouterScript.PAGE_DEPLOY_PREP, "deploy intent must expose deploy page", failures)
	_expect(PageRouterScript.screen_state_for_page(shell.get_visible_page_id()) == PageRouterScript.SCREEN_DEPLOY, "deploy page must map to RunScene deploy state", failures)
	_expect(not bool(main.call("is_page_active")) and bool(deploy.call("is_page_active")), "deploy route must deactivate main", failures)
	_expect(not main.is_processing() and not main.is_processing_unhandled_input(), "hidden main must stop process/input", failures)
	var main_clock := float(main.get("scene_elapsed"))
	await create_timer(0.06).timeout
	await _frames(2)
	_expect(is_equal_approx(float(main.get("scene_elapsed")), main_clock), "hidden main clock must stop", failures)
	var focus := root.gui_get_focus_owner()
	_expect(focus == null or not (focus == main or main.is_ancestor_of(focus)), "hidden main must release focus", failures)
	deploy.call("_request_back_to_main")
	await _frames(3)
	_expect(shell.get_visible_page_id() == PageRouterScript.PAGE_MAIN_MENU, "deploy return must restore main", failures)
	_expect(PageRouterScript.screen_state_for_page(shell.get_visible_page_id()) == PageRouterScript.SCREEN_MAIN_MENU, "returned page must map to RunScene main state", failures)
	shell.call("_on_navigation_intent_requested", NavigationIntentScript.make(NavigationIntentScript.TARGET_SETTINGS, &"i2_runner"))
	await _frames(2)
	_expect(shell.get_visible_page_id() == PageRouterScript.PAGE_SETTINGS_PLACEHOLDER, "settings intent must expose settings", failures)
	var settings_close := shell.get_node_or_null("SettingsOverlay/SettingsCloseButton") as Button
	_expect(settings_close != null, "settings close button missing", failures)
	if settings_close != null:
		settings_close.pressed.emit()
		await _frames(2)
		_expect(shell.get_visible_page_id() == PageRouterScript.PAGE_MAIN_MENU, "settings close must restore main page authority", failures)
		_expect(PageRouterScript.screen_state_for_page(shell.get_visible_page_id()) == PageRouterScript.SCREEN_MAIN_MENU, "settings close must restore RunScene main mapping", failures)
	shell.call("_on_navigation_intent_requested", NavigationIntentScript.make_deploy(&"i2_runner", {"tab": &"config"}))
	await _frames(2)
	deploy.call("set_parchment_collapsed", true, true)
	await _frames(1)
	shell.call("_on_navigation_intent_requested", NavigationIntentScript.make_long_term(&"i2_runner", &"goals"))
	await _frames(2)
	var deploy_tween: Variant = deploy.get("collapse_tween")
	_expect(deploy_tween == null or not deploy_tween.is_valid(), "hidden deploy tween must stop", failures)
	var deploy_clock := float(deploy.get("scene_elapsed"))
	await create_timer(0.06).timeout
	await _frames(2)
	_expect(is_equal_approx(float(deploy.get("scene_elapsed")), deploy_clock), "hidden deploy clock must stop", failures)
	long_term.call("show_module", &"codex")
	await _frames(1)
	shell.show_main()
	await _frames(2)
	var long_tween: Variant = long_term.get("module_tween")
	_expect(long_tween == null or not long_tween.is_valid(), "hidden long-term tween must stop", failures)
	var long_clock := float(long_term.get("ambient_elapsed"))
	await create_timer(0.06).timeout
	await _frames(2)
	_expect(is_equal_approx(float(long_term.get("ambient_elapsed")), long_clock), "hidden long-term clock must stop", failures)
	shell.show_long_term(&"codex")
	await _frames(2)
	long_term.call("show_module", &"research")
	await create_timer(0.85).timeout
	await _frames(2)
	_expect(StringName(long_term.get("displayed_module_id")) == &"research", "reopened long-term page must complete a new switch", failures)
	_expect(not bool(long_term.get("switch_running")), "reopened long-term switch must not inherit a stale coroutine lock", failures)
	_expect(StringName(long_term.get("transition_state")) == &"OPEN", "reopened long-term switch must settle open", failures)
	shell.show_main()
	await _frames(2)
	shell.visible = false
	shell.set_shell_active(false)
	await _frames(2)
	_expect(shell.get_visible_page_id() == &"", "hidden AppShell must expose no visible page", failures)
	_expect(not bool(main.call("is_page_active")) and not bool(deploy.call("is_page_active")) and not bool(long_term.call("is_page_active")), "hidden AppShell must deactivate every page", failures)
	shell.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
