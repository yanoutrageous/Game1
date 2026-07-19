extends Node

const ResultPanelScene := preload("res://scenes/ui/result/result_panel.tscn")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

const RESOLUTIONS := [
	&"1280x720",
	&"1366x768",
	&"1600x900",
	&"1920x1080",
	&"2560x1440",
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for resolution_id: StringName in RESOLUTIONS:
		var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
		var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
		profile["actual_viewport_size"] = viewport_size
		get_window().size = viewport_size
		for state_id in [&"success", &"failure_empty", &"failure_pending", &"failure_selected", &"failure_capacity_blocked", &"failure_final", &"abandon"]:
			var canvas := Control.new()
			canvas.size = viewport_size
			get_window().add_child(canvas)
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
			_assert_state(panel, StringName("%s-%s" % [resolution_id, state_id]), viewport_size, state_id, failures)
			canvas.queue_free()
			await _frames(2)
	if failures.is_empty():
		print("ART24_RESULT_PANEL_SCENE=PASS resolutions=5 states=success,failure_empty,failure_pending,failure_selected,failure_capacity_blocked,failure_final,abandon")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("ART24_RESULT_PANEL_SCENE=FAIL failures=%d" % failures.size())
		get_tree().quit(2)


func _assert_state(panel: ResultPanel, state_id: StringName, viewport_size: Vector2i, visual_state: StringName, failures: Array[String]) -> void:
	var panel_rect := panel.get_global_rect()
	if panel_rect.position.x < -0.5 or panel_rect.position.y < -0.5 or panel_rect.end.x > viewport_size.x + 0.5 or panel_rect.end.y > viewport_size.y + 0.5:
		failures.append("%s panel=%s viewport=%s" % [state_id, panel_rect, viewport_size])
	var pending := visual_state in [&"failure_empty", &"failure_pending", &"failure_selected", &"failure_capacity_blocked"]
	var metrics := panel.get_node("ResultMetricsRow") as Control
	var actions := panel.get_node("ResultActions") as Control
	var action_art := panel.get_node("ResultActionStripArt") as Control
	if metrics.visible or actions.visible == pending or action_art.visible:
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
		var candidates := panel.salvage_candidates_box.get_children()
		if visual_state == &"failure_empty":
			if modal.size.x >= 540.0:
				failures.append("%s empty salvage report is not compact: %s" % [state_id, modal.size])
			if candidates.is_empty() or candidates[0] is Button:
				failures.append("%s empty salvage explanation missing" % state_id)
		else:
			if modal.size.x < 550.0:
				failures.append("%s candidate salvage report is too narrow: %s" % [state_id, modal.size])
			if candidates.is_empty() or not (candidates[0] is Button):
				failures.append("%s salvage candidate missing" % state_id)
			elif (candidates[0] as Button).get_global_rect().size.y < 40.0:
				failures.append("%s salvage candidate height=%s" % [state_id, (candidates[0] as Button).get_global_rect().size.y])
		if visual_state == &"failure_selected" and not panel.selected_salvage_ids.has("art24-result-probe-item-0"):
			failures.append("%s selected salvage item was not retained" % state_id)
		if visual_state == &"failure_capacity_blocked":
			if candidates.size() < 5 or not (candidates[4] as Button).disabled:
				failures.append("%s over-capacity candidate was not disabled" % state_id)
			if panel.salvage_capacity_label.text.find("4 / 4") < 0:
				failures.append("%s capacity feedback=%s" % [state_id, panel.salvage_capacity_label.text])
	else:
		for path in ["ResultModalFrame", "ResultTitlePlate", "ResultSummary", "ResultActions"]:
			_assert_inside(panel.get_node(path) as Control, panel_rect, state_id, failures)
		var banner := panel.get_node("ResultTitlePlate") as Control
		if banner.size.x < 298.0 or banner.size.y < 128.0:
			failures.append("%s banner_size=%s" % [state_id, banner.size])
		var summary := panel.get_node("ResultSummary") as Label
		if summary.text.find(" source ") >= 0 or summary.text.find(" event ") >= 0:
			failures.append("%s player summary exposes raw diagnostic codes" % state_id)


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
	}
	match state_id:
		&"success":
			return {
				"outcome": "Extracted",
				"settlement": {"outcome": "success", "black_coin_converted": 36, "gold_coin_gained": 36, "warehouse_items": [item], "salvaged_items": [], "lost_item_count": 0, "cleared_consumable_count": 1, "finalized": true},
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
		_:
			return {
				"outcome": "Abandoned",
				"settlement": {"outcome": "abandon", "black_coin_lost": 12, "gold_coin_gained": 0, "warehouse_items": [], "salvaged_items": [], "lost_item_count": 1, "cleared_consumable_count": 0, "finalized": true},
				"event_log": technical_events,
				"transaction_log": technical_transactions,
			}


func _frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame
