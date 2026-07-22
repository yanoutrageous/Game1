extends SceneTree

const ResultPanelScene := preload("res://scenes/ui/result/result_panel.tscn")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const RESULT_BANNER_PATH_BY_STATE := {
	&"success": "res://assets/art24/ui/result_banner_success.png",
	&"failure": "res://assets/art24/ui/result_banner_failure.png",
	&"abandon": "res://assets/art24/ui/result_banner_abandoned.png",
}

const RESOLUTIONS := [
	&"1280x720",
	&"1366x768",
	&"1600x900",
	&"1920x1080",
	&"2560x1440",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for resolution_id: StringName in RESOLUTIONS:
		var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
		var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
		profile["actual_viewport_size"] = viewport_size
		root.size = viewport_size
		for state_id in [&"success", &"failure_empty", &"failure_pending", &"failure_selected", &"failure_capacity_blocked", &"failure_final", &"abandon", &"save_failed"]:
			var canvas := Control.new()
			canvas.size = viewport_size
			root.add_child(canvas)
			var panel := ResultPanelScene.instantiate() as ResultPanel
			canvas.add_child(panel)
			await _frames(2)
			panel.apply_layout_profile(profile)
			panel.show_summary(_snapshot_for(state_id))
			await _frames(3)
			if state_id == &"failure_selected":
				panel.call("_toggle_salvage_item", "art24-result-probe-item-0", true)
			elif state_id == &"failure_capacity_blocked":
				for index in range(4):
					panel.call("_toggle_salvage_item", "art24-result-probe-item-%d" % index, true)
			await _frames(1)
			var focus_targets: Array[Button] = []
			for candidate in [panel.return_deploy_button, panel.return_main_button, panel.retry_save_button, panel.discard_unsaved_button]:
				if candidate != null and candidate.is_visible_in_tree() and not candidate.disabled:
					focus_targets.append(candidate)
			for focus_target in focus_targets:
				focus_target.grab_focus()
				await _frames(1)
				if root.gui_get_focus_owner() != focus_target:
					failures.append("%s focus could not reach %s" % [state_id, focus_target.name])
			_assert_state(panel, StringName("%s-%s" % [resolution_id, state_id]), viewport_size, state_id, failures)
			canvas.queue_free()
			await _frames(2)
	if failures.is_empty():
		print("ART24_RESULT_PANEL_SCENE=PASS resolutions=5 states=success,failure_empty,failure_pending,failure_selected,failure_capacity_blocked,failure_final,abandon,save_failed focus=visible danger=preserved item_sections=whole")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("ART24_RESULT_PANEL_SCENE=FAIL failures=%d" % failures.size())
		quit(2)


func _assert_state(panel: ResultPanel, state_id: StringName, viewport_size: Vector2i, visual_state: StringName, failures: Array[String]) -> void:
	var panel_rect := panel.get_global_rect()
	if panel_rect.position.x < -0.5 or panel_rect.position.y < -0.5 or panel_rect.end.x > viewport_size.x + 0.5 or panel_rect.end.y > viewport_size.y + 0.5:
		failures.append("%s panel=%s viewport=%s" % [state_id, panel_rect, viewport_size])
	var pending := visual_state in [&"failure_empty", &"failure_pending", &"failure_selected", &"failure_capacity_blocked"]
	var unsaved := visual_state == &"save_failed"
	var result_state := &"success" if visual_state == &"success" else (&"abandon" if visual_state == &"abandon" else &"failure")
	var banner := panel.get_node("ResultTitlePlate") as TextureRect
	var expected_banner_path := String(RESULT_BANNER_PATH_BY_STATE[result_state])
	if banner.texture == null or banner.texture.resource_path != expected_banner_path:
		failures.append("%s banner=%s expected=%s" % [state_id, "<null>" if banner.texture == null else banner.texture.resource_path, expected_banner_path])
	var live_title := panel.get_node("ResultTitle") as Label
	if not live_title.visible or live_title.text.strip_edges() == "":
		failures.append("%s dynamic localized result title is not visible" % state_id)
	var metrics := panel.get_node("ResultMetricsRow") as Control
	var actions := panel.get_node("ResultActions") as Control
	var action_art := panel.get_node("ResultActionStripArt") as Control
	if metrics.visible == pending or actions.visible == pending or action_art.visible:
		failures.append("%s result/salvage visibility hierarchy is inverted" % state_id)
	if pending:
		var salvage := panel.get_node("FailureSalvagePanel") as Control
		var modal := panel.get_node("ResultModalFrame") as Control
		var confirm := panel.salvage_confirm_button as Button
		if not salvage.visible:
			failures.append("%s salvage panel hidden" % state_id)
		var confirm_rect := confirm.get_global_rect()
		if confirm_rect.position.x < panel_rect.position.x - 0.5 or confirm_rect.position.y < panel_rect.position.y - 0.5 or confirm_rect.end.x > panel_rect.end.x + 0.5 or confirm_rect.end.y > panel_rect.end.y + 0.5:
			failures.append("%s confirm=%s salvage=%s salvage_min=%s panel=%s" % [state_id, confirm_rect, salvage.get_global_rect(), salvage.get_combined_minimum_size(), panel_rect])
		if confirm.get_global_rect().size.y < 42.0:
			failures.append("%s salvage confirm height=%s" % [state_id, confirm.get_global_rect().size.y])
		if not confirm.is_visible_in_tree() or confirm.disabled or confirm.focus_mode != Control.FOCUS_ALL:
			failures.append("%s salvage confirm is not a reachable primary action" % state_id)
		var candidates := panel.salvage_candidates_box.get_children()
		if visual_state == &"failure_empty":
			if candidates.is_empty() or candidates[0] is Button:
				failures.append("%s empty salvage explanation missing" % state_id)
		else:
			if modal.size.x < 550.0:
				failures.append("%s candidate salvage report is too narrow: %s" % [state_id, modal.size])
			if candidates.is_empty() or not (candidates[0] is Button):
				failures.append("%s salvage candidate missing" % state_id)
			elif (candidates[0] as Button).get_global_rect().size.y < 40.0:
				failures.append("%s salvage candidate height=%s" % [state_id, (candidates[0] as Button).get_global_rect().size.y])
			elif (candidates[0] as Button).focus_mode != Control.FOCUS_ALL:
				failures.append("%s salvage candidate is not keyboard focusable" % state_id)
		if visual_state == &"failure_selected" and not panel.selected_salvage_ids.has("art24-result-probe-item-0"):
			failures.append("%s selected salvage item was not retained" % state_id)
		if visual_state == &"failure_capacity_blocked":
			if candidates.size() < 5 or not (candidates[4] as Button).disabled:
				failures.append("%s over-capacity candidate was not disabled" % state_id)
			if panel.salvage_capacity_label.text.find("4 / 4") < 0:
				failures.append("%s capacity feedback=%s" % [state_id, panel.salvage_capacity_label.text])
	else:
		for path in ["ResultModalFrame", "ResultTitlePlate", "ResultSummary", "ResultMetricsRow", "ResultItemSectionsScroll", "ResultPersistenceStatus", "ResultActions"]:
			_assert_inside(panel.get_node(path) as Control, panel_rect, state_id, failures)
		if banner.size.x < 298.0 or banner.size.y < 128.0:
			failures.append("%s banner_size=%s" % [state_id, banner.size])
		var summary := panel.get_node("ResultSummary") as Label
		if summary.text.find(" source ") >= 0 or summary.text.find(" event ") >= 0:
			failures.append("%s player summary exposes raw diagnostic codes" % state_id)
		var items_scroll := panel.get_node("ResultItemSectionsScroll") as ScrollContainer
		if items_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_AUTO:
			failures.append("%s result item sections cannot scroll vertically" % state_id)
		if visual_state == &"success":
			var vertical_bar := items_scroll.get_v_scroll_bar()
			if vertical_bar.max_value <= vertical_bar.page:
				failures.append("%s overflowing result items did not produce a reachable scroll range" % state_id)
		if visual_state == &"abandon" and _has_partially_visible_section(panel):
			failures.append("%s initial item viewport contains a half-clipped section" % state_id)
		if unsaved:
			for button in [panel.return_deploy_button, panel.return_main_button]:
				if button.visible or not button.disabled:
					failures.append("%s normal exit action %s leaked into unsaved state" % [state_id, button.name])
			for button in [panel.retry_save_button, panel.discard_unsaved_button]:
				if not button.is_visible_in_tree() or button.disabled or button.focus_mode != Control.FOCUS_ALL:
					failures.append("%s unsaved-result action %s is not reachable" % [state_id, button.name])
				_assert_visible_focus_style(button, state_id, failures)
			if StringName(panel.discard_unsaved_button.get_meta(&"result_action_tone", &"")) != &"danger":
				failures.append("%s discard action lost danger tone metadata" % state_id)
			var discard_normal := panel.discard_unsaved_button.get_theme_stylebox("normal") as StyleBoxTexture
			if discard_normal == null or discard_normal.modulate_color.r <= discard_normal.modulate_color.g * 1.5:
				failures.append("%s discard action is not visually separated as dangerous" % state_id)
		else:
			for button in [panel.return_deploy_button, panel.return_main_button]:
				if not button.is_visible_in_tree() or button.disabled or button.focus_mode != Control.FOCUS_ALL:
					failures.append("%s saved-result exit action %s is not reachable" % [state_id, button.name])
				_assert_visible_focus_style(button, state_id, failures)
			for button in [panel.retry_save_button, panel.discard_unsaved_button]:
				if button.visible or not button.disabled:
					failures.append("%s unsaved-result action %s leaked into committed state" % [state_id, button.name])


func _assert_visible_focus_style(button: Button, state_id: StringName, failures: Array[String]) -> void:
	var focus_style := button.get_theme_stylebox("focus") as StyleBoxFlat
	if focus_style == null or focus_style.border_width_left < 3 or focus_style.border_color.a < 0.95:
		failures.append("%s action %s has no high-contrast focus frame" % [state_id, button.name])


func _has_partially_visible_section(panel: ResultPanel) -> bool:
	var scroll := panel.get_node("ResultItemSectionsScroll") as ScrollContainer
	var sections := panel.get_node("ResultItemSectionsScroll/ResultItemSections") as VBoxContainer
	var viewport_rect := scroll.get_global_rect()
	for child in sections.get_children():
		if not (child is Control) or not (child as Control).visible:
			continue
		var section_rect := (child as Control).get_global_rect()
		var intersects := section_rect.end.y > viewport_rect.position.y + 0.5 and section_rect.position.y < viewport_rect.end.y - 0.5
		if intersects and (section_rect.position.y < viewport_rect.position.y - 0.5 or section_rect.end.y > viewport_rect.end.y + 0.5):
			return true
	return false


func _assert_inside(control: Control, parent_rect: Rect2, state_id: StringName, failures: Array[String]) -> void:
	var rect := control.get_global_rect()
	if rect.position.x < parent_rect.position.x - 0.5 or rect.position.y < parent_rect.position.y - 0.5 or rect.end.x > parent_rect.end.x + 0.5 or rect.end.y > parent_rect.end.y + 0.5:
		failures.append("%s %s=%s outside=%s" % [state_id, control.name, rect, parent_rect])


func _snapshot_for(state_id: StringName) -> Dictionary:
	var technical_events := [
		{"sequence": 1, "event_type": &"room_entered", "source": "debug_command"},
		{"sequence": 2, "event_type": &"item_gained", "source": "run_context"},
	]
	var technical_transactions := [
		{"sequence": 1, "kind": &"item_move", "source": "settlement"},
	]
	var item := {
		"instance_id": "art24-result-probe-item-0",
		"item_id": "debug_m5_test_cache",
		"display_name": "调试回收箱",
		"short_description": "用于验证保全候选布局。",
		"weight": 1,
		"rarity": &"tier_3",
	}
	match state_id:
		&"success":
			var warehouse_items: Array[Dictionary] = []
			for index in range(12):
				var warehouse_item := item.duplicate(true)
				warehouse_item["instance_id"] = "art24-result-probe-item-%d" % index
				warehouse_item["display_name"] = "调试回收箱 %d" % (index + 1)
				warehouse_items.append(warehouse_item)
			return {
				"outcome": "Extracted",
				"settlement": {"outcome": "success", "black_coin_converted": 36, "gold_coin_gained": 36, "warehouse_items": warehouse_items, "salvaged_items": [], "lost_item_count": 0, "cleared_consumable_count": 1, "finalized": true},
				"event_log": technical_events,
				"transaction_log": technical_transactions,
				"meta_progress_commit": {"status": &"committed"},
			}
		&"failure_pending", &"failure_selected", &"failure_capacity_blocked":
			var pool: Array[Dictionary] = []
			for index in range(5):
				var candidate := item.duplicate(true)
				candidate["instance_id"] = "art24-result-probe-item-%d" % index
				candidate["display_name"] = "调试回收箱 %d" % (index + 1)
				pool.append(candidate)
			return {
				"outcome": "Failed",
				"settlement": {"outcome": "failure", "black_coin_lost": 36, "gold_coin_gained": 0, "warehouse_items": [], "salvaged_items": [], "lost_item_count": 0, "cleared_consumable_count": 0, "requires_salvage_selection": true, "finalized": false, "salvage_capacity": 4, "settlement_pool": pool},
				"event_log": technical_events,
				"transaction_log": technical_transactions,
				"meta_progress_commit": {"status": &"awaiting_salvage_confirmation"},
			}
		&"failure_empty":
			return {
				"outcome": "Failed",
				"settlement": {"outcome": "failure", "black_coin_lost": 0, "gold_coin_gained": 0, "warehouse_items": [], "salvaged_items": [], "lost_item_count": 0, "cleared_consumable_count": 0, "requires_salvage_selection": true, "finalized": false, "salvage_capacity": 4, "settlement_pool": []},
				"event_log": technical_events,
				"transaction_log": technical_transactions,
				"meta_progress_commit": {"status": &"awaiting_salvage_confirmation"},
			}
		&"failure_final":
			return {
				"outcome": "Failed",
				"settlement": {"outcome": "failure", "black_coin_lost": 36, "gold_coin_gained": 0, "warehouse_items": [], "salvaged_items": [item], "lost_item_count": 2, "cleared_consumable_count": 1, "requires_salvage_selection": false, "finalized": true},
				"event_log": technical_events,
				"transaction_log": technical_transactions,
				"meta_progress_commit": {"status": &"committed"},
			}
		&"save_failed":
			var lost_item := item.duplicate(true)
			lost_item["instance_id"] = "art24-save-failed-lost"
			lost_item["display_name"] = "未能带回的继电器"
			return {
				"outcome": "Failed",
				"terminal_reason_code": &"runtime_combat_defeat",
				"settlement": {"outcome": "failure", "black_coin_lost": 18, "gold_coin_gained": 0, "warehouse_items": [], "salvaged_items": [item], "lost_items": [lost_item], "lost_item_count": 1, "finalized": true},
				"persistence_state": &"save_failed",
				"normal_exit_allowed": false,
				"retry_save_allowed": true,
				"discard_unsaved_allowed": true,
				"event_log": technical_events,
				"transaction_log": technical_transactions,
				"meta_progress_commit": {"ok": false, "status": &"save_failed", "committed": false},
			}
		_:
			var abandon_lost := item.duplicate(true)
			abandon_lost["instance_id"] = "art24-abandon-lost"
			abandon_lost["display_name"] = "旧式继电器"
			var abandon_floor := item.duplicate(true)
			abandon_floor["instance_id"] = "art24-abandon-floor"
			abandon_floor["display_name"] = "遗落线圈"
			var abandon_consumable := item.duplicate(true)
			abandon_consumable["instance_id"] = "art24-abandon-consumable"
			abandon_consumable["display_name"] = "应急药剂"
			abandon_consumable["item_type"] = &"consumable"
			return {
				"outcome": "Abandoned",
				"terminal_reason_code": &"player_abandoned",
				"settlement": {"outcome": "abandon", "black_coin_lost": 12, "gold_coin_gained": 0, "warehouse_items": [], "salvaged_items": [], "lost_items": [abandon_lost], "room_floor_lost_items": [abandon_floor], "cleared_consumables": [abandon_consumable], "lost_item_count": 1, "cleared_consumable_count": 1, "finalized": true},
				"event_log": technical_events,
				"transaction_log": technical_transactions,
				"meta_progress_commit": {"status": &"committed"},
			}


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame
