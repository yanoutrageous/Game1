extends SceneTree

const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const SettingsManagerScript := preload("res://scripts/core/settings/settings_manager.gd")

const PASS_MARKER := "I3R_OUT_OF_RUN_PRODUCTION_JOURNEY=PASS"
const FAIL_MARKER := "I3R_OUT_OF_RUN_PRODUCTION_JOURNEY=FAIL"


class IsolatedDisplayAdapter:
	extends RefCounted

	var applications: Array[Dictionary] = []

	func apply_settings(settings: Dictionary, resolution_size: Vector2i) -> Dictionary:
		applications.append({
			"settings": settings.duplicate(true),
			"resolution_size": resolution_size,
		})
		return {"ok": true}


var failures: Array[String] = []
var evidence_rows: Array[Dictionary] = []
var evidence_dir := "user://tests/i3r_out_of_run_production_journey"
var screenshot_count := 0
var input_count := 0
var journey_started_msec := 0
var require_screenshots := false
var quit_scheduled := false

var main: Node
var run_scene: Node
var ui_shell: Control
var meta_progress_adapter
var settings_manager: Node
var display_adapter := IsolatedDisplayAdapter.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	evidence_dir = _option("evidence-dir", evidence_dir)
	require_screenshots = _bool_option("require-screenshots", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_dir))
	journey_started_msec = Time.get_ticks_msec()

	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main.tscn could not be loaded")
	if packed == null:
		_finish()
		return
	main = packed.instantiate()
	root.add_child(main)
	await _frames(12)
	run_scene = main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		_finish()
		return
	ui_shell = run_scene.get("ui_shell") as Control
	_require(ui_shell != null, "production AppShell is missing")
	if ui_shell == null:
		_finish()
		return

	await _bind_isolated_authority()
	await _checkpoint("01_main_menu", "production main.tscn ready with isolated player data")
	_require(_screen() == &"main_menu", "journey did not begin on the production main menu")

	await _settings_journey()
	await _deploy_journey()
	await _long_term_journey()
	_finish()


func _settings_journey() -> void:
	var settings_entry := _main_entry(&"settings")
	_require(settings_entry != null, "main menu settings entry is missing")
	if settings_entry == null:
		return
	await _click_control(settings_entry, "main.open_settings")
	_require(await _wait_screen(&"settings_shell", 3.0), "real pointer input did not open production settings")
	var panel := ui_shell.call("get_settings_panel") as Control
	_require(panel != null and panel.visible, "production settings panel is not visible")
	if panel == null:
		return
	await _checkpoint("02_settings_open", "settings transaction open")

	var reduce_motion := panel.get("reduce_motion_check") as CheckButton
	var apply_button := panel.get("apply_button") as Button
	var initial_reduce_motion := bool(settings_manager.call("get_applied_settings").get("reduce_motion", false))
	await _click_control(reduce_motion, "settings.toggle_reduce_motion")
	await _click_control(apply_button, "settings.apply_safe_change")
	var safe_applied := settings_manager.call("get_applied_settings") as Dictionary
	_require(
		bool(safe_applied.get("reduce_motion", initial_reduce_motion)) != initial_reduce_motion,
		"safe settings Apply did not reach the isolated authoritative manager"
	)
	_require(StringName(settings_manager.call("get_transaction_state")) == &"editing", "safe settings Apply did not settle back to editing")
	await _checkpoint("03_settings_safe_applied", "safe runtime setting applied and persisted")

	var window_mode := panel.get("window_mode_option") as OptionButton
	var original_window_mode := str(safe_applied.get("window_mode", "windowed"))
	var original_window_index := window_mode.selected
	await _choose_adjacent_option(window_mode, "settings.change_display_mode")
	_require(window_mode.selected != original_window_index, "pointer option input did not change the display-mode control")
	await _click_control(apply_button, "settings.apply_dangerous_display")
	_require(
		StringName(settings_manager.call("get_transaction_state")) == &"awaiting_confirmation",
		"dangerous display change did not enter confirmation authority"
	)
	_require((panel.get("confirmation_box") as Control).visible, "dangerous display confirmation is not visible")
	await _checkpoint("04_settings_display_confirmation", "dangerous display change awaits explicit keep/revert")
	var revert_button := panel.get("revert_button") as Button
	await _click_control(revert_button, "settings.revert_dangerous_display")
	_require(
		str((settings_manager.call("get_applied_settings") as Dictionary).get("window_mode", "")) == original_window_mode,
		"explicit display revert did not restore the prior authoritative mode"
	)
	_require(StringName(settings_manager.call("get_transaction_state")) == &"editing", "display revert did not return to editing")
	await _checkpoint("05_settings_display_reverted", "dangerous display preview rolled back")

	var master_slider := panel.get("master_volume_slider") as HSlider
	var applied_master := int((settings_manager.call("get_applied_settings") as Dictionary).get("master_volume", 80))
	var target_ratio := 0.20 if applied_master >= 50 else 0.80
	var slider_rect := master_slider.get_global_rect()
	await _click_point(
		Vector2(slider_rect.position.x + slider_rect.size.x * target_ratio, slider_rect.get_center().y),
		"settings.edit_without_apply"
	)
	_require(int(round(master_slider.value)) != applied_master, "unapplied settings edit did not change the visible control")
	await _checkpoint("06_settings_unapplied_edit", "visible edit ready for cancellation")
	await _tap_key(KEY_ESCAPE, "settings.cancel_transaction")
	_require(await _wait_screen(&"main_menu", 3.0), "Esc did not cancel settings and return to main")
	_require(
		int((settings_manager.call("get_applied_settings") as Dictionary).get("master_volume", -1)) == applied_master,
		"cancelled settings edit changed the authoritative master volume"
	)

	settings_entry = _main_entry(&"settings")
	await _click_control(settings_entry, "main.reopen_settings")
	_require(await _wait_screen(&"settings_shell", 3.0), "settings could not be reopened after cancellation")
	panel = ui_shell.call("get_settings_panel") as Control
	master_slider = panel.get("master_volume_slider") as HSlider
	_require(int(round(master_slider.value)) == applied_master, "reopened settings did not restore the applied value")
	await _tap_key(KEY_ESCAPE, "settings.close_after_cancel_proof")
	_require(await _wait_screen(&"main_menu", 3.0), "second settings close did not return to main")
	await _checkpoint("07_settings_cancelled_main", "cancelled draft stayed out of applied settings")


func _deploy_journey() -> void:
	var deploy_entry := _main_entry(&"deploy")
	_require(deploy_entry != null, "main menu deploy entry is missing")
	if deploy_entry == null:
		return
	await _click_control(deploy_entry, "main.open_deploy")
	_require(await _wait_screen(&"deploy_shell", 6.0), "real main-menu input did not complete the Deploy route")
	var deploy := ui_shell.call("get_deploy_page") as Control
	_require(deploy != null and deploy.visible, "production Deploy page is missing")
	if deploy == null:
		return
	await _checkpoint("08_deploy_open", "main-menu transition committed to production Deploy")

	var map_view := deploy.get("map_split_view") as Control
	_require(map_view != null and map_view.visible, "Deploy map split view is missing")
	if map_view != null:
		var scale_buttons := map_view.get("scale_buttons") as Dictionary
		var difficulty_buttons := map_view.get("difficulty_buttons") as Dictionary
		_require(not scale_buttons.is_empty(), "same-page map scale choices are empty")
		_require(not difficulty_buttons.is_empty(), "same-page difficulty choices are empty")
		var target_scale := _first_enabled_button_value(scale_buttons)
		if target_scale != null:
			await _click_control(target_scale, "deploy.map.choose_scale")
		difficulty_buttons = map_view.get("difficulty_buttons") as Dictionary
		var target_difficulty := _first_enabled_button_value(difficulty_buttons)
		if target_difficulty != null:
			await _click_control(target_difficulty, "deploy.map.preview_difficulty")
		var projection := map_view.call("projection_snapshot") as Dictionary
		_require(int(projection.get("scale_count", 0)) >= 1, "map projection lost its scale choices")
		_require(int(projection.get("difficulty_count", 0)) >= 1, "map projection lost same-page difficulty choices")
	await _checkpoint("09_deploy_map_difficulty", "map scale and difficulty visible in one workspace")

	await _click_control(_deploy_tab(deploy, &"warehouse"), "deploy.open_warehouse")
	_require(_deploy_tab_id(deploy) == &"warehouse", "warehouse tab did not become active")
	await _checkpoint("10_deploy_warehouse", "owned inventory and actions visible")
	var batch_entry := deploy.get("warehouse_batch_entry_button") as Button
	await _click_control(batch_entry, "warehouse.enter_batch_sale")
	var select_all := deploy.get("warehouse_batch_select_all_button") as Button
	await _click_control(select_all, "warehouse.select_all_sellable")
	var batch_snapshot := deploy.call("get_warehouse_batch_snapshot") as Dictionary
	_require(int(batch_snapshot.get("selected_count", 0)) == 2, "batch sale did not select the two deterministic sellable instances")
	var detail_primary := deploy.get("detail_primary_action_button") as Button
	await _click_control(detail_primary, "warehouse.open_batch_confirmation")
	var batch_modal := deploy.get("warehouse_batch_modal_layer") as Control
	_require(batch_modal != null and batch_modal.visible, "batch sale strong-confirm modal did not open")
	await _checkpoint("11_warehouse_batch_confirmation", "batch total visible before irreversible sale")
	var batch_cancel := deploy.get("warehouse_batch_modal_cancel_button") as Button
	await _click_control(batch_cancel, "warehouse.cancel_batch_confirmation")
	batch_snapshot = deploy.call("get_warehouse_batch_snapshot") as Dictionary
	_require(not bool(batch_snapshot.get("confirmation_visible", true)), "batch confirmation cancel did not close the modal")
	_require(int(batch_snapshot.get("selected_count", 0)) == 2, "batch confirmation cancel discarded checked items")
	detail_primary = deploy.get("detail_primary_action_button") as Button
	await _click_control(detail_primary, "warehouse.reopen_batch_confirmation")
	var batch_confirm := deploy.get("warehouse_batch_modal_confirm_button") as Button
	await _click_control(batch_confirm, "warehouse.confirm_batch_sale")
	_require(await _wait_until(func() -> bool:
		var snapshot := deploy.call("get_warehouse_batch_snapshot") as Dictionary
		return not bool(snapshot.get("active", true)) and int(meta_progress_adapter.data.get("gold", 0)) == 130
	, 4.0), "real batch confirmation did not commit through the production transaction")
	_require(_warehouse_ids(meta_progress_adapter.data) == ["unique"], "batch sale removed the wrong isolated warehouse instances")
	await _checkpoint("12_warehouse_batch_committed", "authoritative batch sale committed once")

	await _click_control(_deploy_tab(deploy, &"claim"), "deploy.open_claim")
	_require(_deploy_tab_id(deploy) == &"claim", "claim tab did not become active")
	_require(not (deploy.get("card_views") as Array).is_empty(), "claim page exposes no real entries")
	await _checkpoint("13_deploy_claim", "claim entries and detail available")

	await _click_control(_deploy_tab(deploy, &"objective"), "deploy.open_objective")
	_require(_deploy_tab_id(deploy) == &"objective", "current-run commission tab did not become active")
	await _click_control(_summary_button(deploy, &"objective"), "deploy.summary_objective")
	_require(StringName(deploy.get("active_summary_page")) == &"objective", "objective summary did not become active")
	await _checkpoint("14_deploy_objective", "current-run commission and objective summary available")

	await _click_control(_deploy_tab(deploy, &"loadout"), "deploy.open_loadout")
	_require(_deploy_tab_id(deploy) == &"loadout", "loadout tab did not become active")
	await _click_control(_summary_button(deploy, &"config"), "deploy.summary_loadout")
	_require(StringName(deploy.get("active_summary_page")) == &"config", "loadout summary did not become active")
	_require(_visible_summary_text(deploy) != "", "loadout summary contains no concrete player-facing content")
	await _click_control(_summary_button(deploy, &"effect"), "deploy.summary_run_effect")
	_require(StringName(deploy.get("active_summary_page")) == &"effect", "current-run effect summary did not become active")
	await _checkpoint("15_deploy_loadout_summary", "loadout and current-run summary pages available")

	var back_main := deploy.get_node_or_null("PrimaryActionRoot/DeployNavMain") as Button
	await _click_control(back_main, "deploy.return_main")
	_require(await _wait_screen(&"main_menu", 4.0), "Deploy main-menu control did not return to main")
	await _checkpoint("16_deploy_return_main", "Deploy journey returned through production navigation")


func _long_term_journey() -> void:
	var long_term_entry := _main_entry(&"long_term")
	_require(long_term_entry != null, "main menu long-term entry is missing")
	if long_term_entry == null:
		return
	await _click_control(long_term_entry, "main.open_long_term")
	_require(await _wait_screen(&"long_term_shell", 6.0), "real main-menu input did not complete the LongTerm route")
	var long_term := ui_shell.call("get_long_term_page") as Control
	_require(long_term != null and long_term.visible, "production LongTerm page is missing")
	if long_term == null:
		return
	_require(await _wait_long_term_module(long_term, &"task_archive", 3.0), "task archive did not settle")
	await _checkpoint("17_long_term_tasks", "task archive workspace available")

	await _click_control(_long_term_tab(long_term, &"talent"), "long_term.open_talent")
	_require(await _wait_long_term_module(long_term, &"talent", 4.0), "talent module did not settle")
	_require(StringName(long_term.call("get_selected_secondary_id")) == &"tree", "talent tree page is not active")
	await _checkpoint("18_long_term_talent", "talent tree workspace available")

	await _click_control(_long_term_tab(long_term, &"profile"), "long_term.open_profile")
	_require(await _wait_long_term_module(long_term, &"profile", 4.0), "profile module did not settle")
	var history_button := (long_term.get("secondary_buttons") as Dictionary).get(&"history") as Button
	await _click_control(history_button, "long_term.open_history")
	_require(StringName(long_term.call("get_selected_secondary_id")) == &"history", "history archive page did not become active")
	var cards := long_term.get("long_term_card_buttons") as Array
	_require(not cards.is_empty(), "isolated history fixture did not reach the player archive")
	if not cards.is_empty():
		await _click_control(cards[0] as Button, "long_term.focus_history_record")
	await _checkpoint("19_long_term_archive", "character history archive available")

	await _seconds(0.70)
	await _tap_key(KEY_ESCAPE, "long_term.escape_to_secondary")
	_require(_focus_in_buttons(long_term.get("secondary_button_order") as Array), "first Esc did not return record focus to secondary navigation")
	await _checkpoint("20_long_term_focus_secondary", "Esc restored secondary-page focus")
	await _seconds(0.70)
	await _tap_key(KEY_ESCAPE, "long_term.escape_to_primary")
	_require(_focus_in_buttons(long_term.get("tab_button_order") as Array), "second Esc did not return focus to primary modules")
	await _checkpoint("21_long_term_focus_primary", "Esc restored primary-module focus")
	await _seconds(0.70)
	await _tap_key(KEY_ESCAPE, "long_term.escape_to_main")
	_require(await _wait_screen(&"main_menu", 4.0), "third staged Esc did not return LongTerm to main")
	await _checkpoint("22_final_main", "out-of-run journey returned to production main menu")


func _bind_isolated_authority() -> void:
	var meta_path := "%s/fixture_meta_progress.json" % evidence_dir
	_remove_storage_family(meta_path)
	meta_progress_adapter = MetaProgressAdapterScript.new()
	meta_progress_adapter.set_active_profile_path(meta_path, "i3r5_out_of_run_journey")
	meta_progress_adapter.data["gold"] = 100
	meta_progress_adapter.data["warehouse_items"] = [
		_item("col_01", "sale_a", {"display_name": "旧铜线", "base_value": 11}),
		_item("col_02", "sale_b", {"display_name": "标准挂签", "base_value": 19}),
		_item("col_03", "unique", {
			"display_name": "唯一纪念章",
			"base_value": 99,
			"can_sell": false,
			"is_unique": true,
			"rarity": &"unique",
		}),
	]
	meta_progress_adapter.data["run_count"] = 3
	meta_progress_adapter.data["extract_count"] = 2
	meta_progress_adapter.data["history_records"] = [_history_fixture()]
	_require(meta_progress_adapter.save(), "isolated authoritative meta fixture could not be persisted")
	run_scene.set("meta_progress_adapter", meta_progress_adapter)
	run_scene.get("runtime_controller").bind_meta_progress_adapter(meta_progress_adapter)

	var settings_path := "%s/fixture_settings.cfg" % evidence_dir
	_remove_storage_family(settings_path)
	settings_manager = SettingsManagerScript.new(settings_path, display_adapter)
	settings_manager.name = "I3R5IsolatedSettingsManager"
	run_scene.add_child(settings_manager)
	await _frames(3)
	ui_shell.call("bind_settings_manager", settings_manager)
	ui_shell.call("apply_snapshot", {
		"run_active": false,
		"meta_progress_summary": meta_progress_adapter.get_summary(),
	})
	await _frames(5)


func _item(item_id: String, instance_id: String, overrides: Dictionary = {}) -> Dictionary:
	var item := M7ContentCatalogScript.item_definition(item_id)
	item["item_id"] = item_id
	item["instance_id"] = instance_id
	for key in overrides:
		item[key] = overrides[key]
	return item


func _history_fixture() -> Dictionary:
	return {
		"history_id": "i3r5-archive-1",
		"result_id": "i3r5-archive-1",
		"run_id": "i3r5-run-1",
		"outcome": "Extracted",
		"terminal_reason_code": &"runtime_extract",
		"mode": "standard_run",
		"map_config_id": "classic_10x10_standard",
		"map_display_name": "标准矿区",
		"difficulty": "standard",
		"difficulty_label": "标准",
		"commission_id": "commission_recover_supply",
		"commission_label": "补给回收",
		"seed": 13,
		"recorded_at_unix": 1767225600,
		"carried_equipment": [],
		"carried_consumables": [],
		"extracted_items": [_item("col_01", "history_col", {"display_name": "旧铜线"})],
		"salvaged_items": [],
		"lost_items": [],
		"room_floor_lost_items": [],
		"cleared_consumables": [],
		"black_coin_converted": 8,
		"black_coin_lost": 0,
		"safe_yield_retained": 2,
		"gold_delta": 10,
		"settlement_log": [],
	}


func _main_entry(entry_id: StringName) -> Button:
	var main_page := ui_shell.call("get_main_page") as Control if ui_shell != null else null
	return main_page.find_child("MainMenuEntry_%s" % String(entry_id), true, false) as Button if main_page != null else null


func _deploy_tab(deploy: Control, tab_id: StringName) -> Button:
	return (deploy.get("tab_buttons") as Dictionary).get(tab_id) as Button if deploy != null else null


func _summary_button(deploy: Control, page_id: StringName) -> Button:
	return (deploy.get("summary_buttons") as Dictionary).get(page_id) as Button if deploy != null else null


func _long_term_tab(long_term: Control, module_id: StringName) -> Button:
	return (long_term.get("tab_buttons") as Dictionary).get(module_id) as Button if long_term != null else null


func _deploy_tab_id(deploy: Control) -> StringName:
	var model := deploy.get("current_model") as Dictionary if deploy != null else {}
	return StringName(model.get("active_tab", &""))


func _visible_summary_text(deploy: Control) -> String:
	var lines: Array[String] = []
	for raw_label in deploy.get("summary_row_labels") as Array:
		var label := raw_label as Label
		if label != null and label.visible and not label.text.strip_edges().is_empty():
			lines.append(label.text.strip_edges())
	return "\n".join(lines)


func _first_enabled_button_value(buttons: Dictionary) -> Button:
	for raw in buttons.values():
		var button := raw as Button
		if button != null and button.visible and not button.disabled:
			return button
	return null


func _focus_in_buttons(buttons: Array) -> bool:
	var focus := root.gui_get_focus_owner()
	return focus != null and buttons.has(focus)


func _wait_long_term_module(long_term: Control, module_id: StringName, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool:
		return (
			StringName(long_term.get("displayed_module_id")) == module_id
			and not bool(long_term.get("switch_running"))
		)
	, timeout_seconds)


func _warehouse_ids(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw in source.get("warehouse_items", []) as Array:
		if raw is Dictionary:
			result.append(str((raw as Dictionary).get("instance_id", "")))
	result.sort()
	return result


func _screen() -> StringName:
	return StringName(run_scene.get("screen_state")) if run_scene != null else &""


func _wait_screen(expected: StringName, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool: return _screen() == expected, timeout_seconds)


func _wait_until(condition: Callable, timeout_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() <= deadline:
		if bool(condition.call()):
			return true
		await process_frame
	return bool(condition.call())


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _seconds(duration: float) -> void:
	await create_timer(duration).timeout


func _choose_adjacent_option(option: OptionButton, action: String) -> void:
	if option == null or option.item_count < 2:
		_require(false, "cannot change missing/single-value option for %s" % action)
		return
	var target_index := option.selected + 1 if option.selected + 1 < option.item_count else option.selected - 1
	await _click_control(option, action + ".open")
	var popup := option.get_popup()
	_require(popup != null and popup.visible, "option popup did not open for %s" % action)
	if popup == null or not popup.visible:
		return
	var row_height := float(popup.size.y) / float(option.item_count)
	var target_point := Vector2(popup.position) + Vector2(
		float(popup.size.x) * 0.5,
		row_height * (float(target_index) + 0.5)
	)
	await _click_point(target_point, action + ".select")


func _tap_key(keycode: int, action: String) -> void:
	_record_input(action, {"transport": "keyboard", "keycode": keycode})
	_parse_key(keycode, true)
	await process_frame
	_parse_key(keycode, false)
	await _frames(3)


func _parse_key(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.unicode = keycode if keycode >= 32 and keycode <= 126 else 0
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)


func _click_control(control: Control, action: String) -> void:
	if control == null:
		_require(false, "cannot click missing control for %s" % action)
		return
	_require(control.is_visible_in_tree(), "cannot click hidden control for %s" % action)
	_require(not (control is BaseButton and (control as BaseButton).disabled), "cannot click disabled control for %s" % action)
	if not control.is_visible_in_tree() or (control is BaseButton and (control as BaseButton).disabled):
		return
	await _click_point(control.get_global_rect().get_center(), action)


func _click_point(point: Vector2, action: String) -> void:
	_record_input(action, {"transport": "pointer", "x": point.x, "y": point.y})
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _frames(3)


func _record_input(action: String, detail: Dictionary) -> void:
	input_count += 1
	var row := _evidence_snapshot(action, "input")
	row["input"] = detail.duplicate(true)
	evidence_rows.append(row)


func _checkpoint(id: String, feedback: String) -> void:
	await _frames(2)
	var screenshot_path := "%s/%s.png" % [evidence_dir, id]
	var screenshot_status := "unavailable"
	if DisplayServer.get_name() != "headless":
		var image := root.get_texture().get_image()
		if image != null and image.get_width() > 0 and image.get_height() > 0:
			var absolute_path := ProjectSettings.globalize_path(screenshot_path)
			DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
			if image.save_png(absolute_path) == OK:
				screenshot_count += 1
				screenshot_status = screenshot_path
	var row := _evidence_snapshot(id, "checkpoint")
	row["visible_feedback"] = feedback
	row["screenshot"] = screenshot_status
	evidence_rows.append(row)


func _evidence_snapshot(action: String, kind: String) -> Dictionary:
	var deploy := ui_shell.call("get_deploy_page") as Control if ui_shell != null else null
	var long_term := ui_shell.call("get_long_term_page") as Control if ui_shell != null else null
	var panel := ui_shell.call("get_settings_panel") as Control if ui_shell != null else null
	var map_view := deploy.get("map_split_view") as Control if deploy != null else null
	var focus := root.gui_get_focus_owner()
	return {
		"sequence": evidence_rows.size() + 1,
		"elapsed_msec": Time.get_ticks_msec() - journey_started_msec,
		"kind": kind,
		"action": action,
		"screen": String(_screen()),
		"page": String(ui_shell.call("get_visible_page_id")) if ui_shell != null else "",
		"focus": String(focus.name) if focus != null else "",
		"settings_state": String(settings_manager.call("get_transaction_state")) if settings_manager != null else "",
		"deploy_tab": String(_deploy_tab_id(deploy)),
		"deploy_summary": StringName(deploy.get("active_summary_page")) if deploy != null else &"",
		"map": map_view.call("projection_snapshot") if map_view != null else {},
		"warehouse_batch": deploy.call("get_warehouse_batch_snapshot") if deploy != null else {},
		"long_term_module": StringName(long_term.get("displayed_module_id")) if long_term != null else &"",
		"long_term_secondary": long_term.call("get_selected_secondary_id") if long_term != null else &"",
		"gold": int(meta_progress_adapter.data.get("gold", 0)) if meta_progress_adapter != null else 0,
		"warehouse_ids": _warehouse_ids(meta_progress_adapter.data) if meta_progress_adapter != null else [],
	}


func _option(name: String, fallback: String) -> String:
	var prefix := "--%s=" % name
	for raw in OS.get_cmdline_user_args():
		var argument := String(raw)
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback


func _bool_option(name: String, fallback: bool) -> bool:
	return _option(name, "true" if fallback else "false").to_lower() in ["1", "true", "yes", "on"]


func _remove_storage_family(path: String) -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		var absolute_path := ProjectSettings.globalize_path(path + suffix)
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(absolute_path)


func _write_evidence() -> String:
	var json_path := "%s/journey.json" % evidence_dir
	var csv_path := "%s/journey.csv" % evidence_dir
	var json_absolute := ProjectSettings.globalize_path(json_path)
	var csv_absolute := ProjectSettings.globalize_path(csv_path)
	_write_evidence_csv(csv_absolute)
	var file := FileAccess.open(json_absolute, FileAccess.WRITE)
	if file == null:
		failures.append("could not write journey evidence JSON")
		return json_absolute
	file.store_string(JSON.stringify({
		"contract": "I3R.5 production main.tscn out-of-run player journey",
		"production_entry": "res://scenes/main/main.tscn",
		"input_transport": "Input.parse_input_event",
		"forbidden_shortcuts_used": false,
		"direct_setup_exceptions": ["isolated meta fixture", "isolated settings manager/display adapter"],
		"duration_msec": Time.get_ticks_msec() - journey_started_msec,
		"checkpoint_count": _checkpoint_count(),
		"screenshot_count": screenshot_count,
		"input_count": input_count,
		"csv_evidence": csv_absolute,
		"display_adapter_apply_count": display_adapter.applications.size(),
		"steps": evidence_rows,
		"failures": failures,
	}, "\t"))
	file.close()
	return json_absolute


func _write_evidence_csv(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write journey evidence CSV")
		return
	file.store_csv_line(PackedStringArray([
		"sequence", "elapsed_msec", "kind", "action", "screen", "page", "focus",
		"settings_state", "deploy_tab", "deploy_summary", "long_term_module",
		"long_term_secondary", "gold", "warehouse_ids", "input_json",
		"visible_feedback", "screenshot",
	]))
	for row in evidence_rows:
		file.store_csv_line(PackedStringArray([
			str(row.get("sequence", "")),
			str(row.get("elapsed_msec", "")),
			str(row.get("kind", "")),
			str(row.get("action", "")),
			str(row.get("screen", "")),
			str(row.get("page", "")),
			str(row.get("focus", "")),
			str(row.get("settings_state", "")),
			str(row.get("deploy_tab", "")),
			str(row.get("deploy_summary", "")),
			str(row.get("long_term_module", "")),
			str(row.get("long_term_secondary", "")),
			str(row.get("gold", "")),
			JSON.stringify(row.get("warehouse_ids", [])),
			JSON.stringify(row.get("input", {})),
			str(row.get("visible_feedback", "")),
			str(row.get("screenshot", "")),
		]))
	file.close()


func _checkpoint_count() -> int:
	var count := 0
	for row in evidence_rows:
		if str(row.get("kind", "")) == "checkpoint":
			count += 1
	return count


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	var checkpoint_count := _checkpoint_count()
	_require(checkpoint_count == 22, "production out-of-run journey did not emit exactly 22 checkpoints")
	if require_screenshots:
		_require(screenshot_count == checkpoint_count, "rendered journey did not capture every checkpoint")
	var evidence_path := _write_evidence()
	var csv_path := ProjectSettings.globalize_path("%s/journey.csv" % evidence_dir)
	_dispose_main()
	if failures.is_empty():
		print(
			"%s production=main.tscn checkpoints=%d screenshots=%d inputs=%d settings=apply,cancel,display_revert deploy=map+warehouse+claim+objective+loadout batch=cancel_then_confirm long_term=task+talent+archive escape=secondary,primary,main evidence=%s csv=%s"
			% [PASS_MARKER, checkpoint_count, screenshot_count, input_count, evidence_path, csv_path]
		)
		_schedule_quit(0)
		return
	for failure in failures:
		push_error("I3R.5 out-of-run production journey failure: " + failure)
	print("%s failures=%d checkpoints=%d screenshots=%d inputs=%d evidence=%s" % [
		FAIL_MARKER, failures.size(), checkpoint_count, screenshot_count, input_count, evidence_path,
	])
	_schedule_quit(1)


func _dispose_main() -> void:
	if main != null and is_instance_valid(main):
		main.free()
	main = null
	run_scene = null
	ui_shell = null
	settings_manager = null
	meta_progress_adapter = null


func _schedule_quit(exit_code: int) -> void:
	if quit_scheduled:
		return
	quit_scheduled = true
	call_deferred("_quit_after_cleanup", exit_code)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	await process_frame
	quit(exit_code)
