extends SceneTree

var failures: Array[String] = []
var meta_actions: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var shell_script := load("res://scripts/ui/long_term/long_term_shell.gd")
	_check(shell_script != null, "LongTermShell failed to load")
	if shell_script == null:
		_finish()
		return
	var shell := shell_script.new() as Control
	shell.size = Vector2(1280, 720)
	root.add_child(shell)
	shell.connect("meta_action_requested", _on_meta_action)
	shell.call("build")
	await _frames(8)

	var snapshot := _workspace_snapshot()
	var snapshot_before := snapshot.duplicate(true)
	shell.call("apply_snapshot", snapshot)
	await _frames(4)

	_test_all_secondary_workspaces(shell)
	_test_zero_one_many(shell)
	await _test_fifty_history_records(shell)
	_test_read_only_selection_and_explicit_actions(shell)
	_test_red_dot_refresh_and_view_transaction(shell)
	_test_unknown_codex_privacy(shell)
	_check(snapshot == snapshot_before, "Workspace projection mutated its source snapshot")
	_finish()


func _test_all_secondary_workspaces(shell: Control) -> void:
	var expected := {
		&"task_archive": [&"task", &"achievement", &"commission_record"],
		&"codex": [&"map", &"monster", &"collectible", &"equipment", &"consumable", &"event", &"rule", &"lore"],
		&"research": [&"unlock_interface", &"research_entry"],
		&"profile": [&"qualification_level", &"history", &"statistics", &"milestone", &"title", &"badge"],
		&"collection_appearance": [&"unique_display", &"appearance_config", &"display_content", &"badge_title", &"settlement_display"],
	}
	var reached := 0
	for module_variant in expected.keys():
		var module_id := StringName(module_variant)
		shell.call("_apply_module_immediately", module_id)
		for group_variant in expected[module_id]:
			var group_id := StringName(group_variant)
			shell.call("show_secondary", group_id)
			var records := int(shell.get("current_record_count"))
			var cards := shell.get("current_content_cards") as Array
			_check(cards.size() == maxi(1, records), "Record reachability mismatch: %s/%s" % [String(module_id), String(group_id)])
			_check(not (shell.get("content_detail_title_label") as Label).text.strip_edges().is_empty(), "Workspace title missing: %s/%s" % [String(module_id), String(group_id)])
			_check(not (shell.get("content_detail_body_label") as Label).text.strip_edges().is_empty(), "Workspace summary missing: %s/%s" % [String(module_id), String(group_id)])
			for raw_card in cards:
				var card := raw_card as Dictionary
				var title := str(card.get("title", ""))
				_check(not title.contains("预留档案位") and not title.contains("暂无更多记录"), "Fake padding card found: %s/%s" % [String(module_id), String(group_id)])
			reached += 1
	_check(reached == 24, "Not all 24 secondary workspaces were reachable")


func _test_zero_one_many(shell: Control) -> void:
	shell.call("_apply_module_immediately", &"collection_appearance")
	shell.call("show_secondary", &"appearance_config")
	_check(int(shell.get("current_record_count")) == 0, "Appearance archive should honestly expose zero configurable records")
	var empty_cards := shell.get("current_content_cards") as Array
	_check(empty_cards.size() == 1 and bool((empty_cards[0] as Dictionary).get("empty_state", false)), "Zero records did not produce one honest empty state")
	_check((shell.get("content_record_body_label") as Label).text.contains("没有可配置的角色外观"), "Appearance empty state implies unsupported equip authority")

	shell.call("_apply_module_immediately", &"task_archive")
	shell.call("show_secondary", &"task")
	_check(int(shell.get("current_record_count")) == 1, "Single task record was not projected exactly once")
	_check((shell.get("long_term_card_buttons") as Array).size() == 1, "Single task record was padded")

	shell.call("_apply_module_immediately", &"profile")
	shell.call("show_secondary", &"statistics")
	_check(int(shell.get("current_record_count")) == 5, "Profile statistics did not expose all real counters")
	_check((shell.get("long_term_card_buttons") as Array).size() == 5, "Many-record workspace truncated statistics")


func _test_fifty_history_records(shell: Control) -> void:
	shell.call("_apply_module_immediately", &"profile")
	shell.call("show_secondary", &"history")
	await _frames(3)
	var cards := shell.get("current_content_cards") as Array
	var buttons := shell.get("long_term_card_buttons") as Array
	_check(int(shell.get("current_record_count")) == 50, "History record count was truncated")
	_check(cards.size() == 50 and buttons.size() == 50, "Not all 50 history records are reachable in the scroll list")
	_check(str((cards[0] as Dictionary).get("id", "")).contains("result_49"), "History newest-first order is wrong")
	_check(str((cards[49] as Dictionary).get("id", "")).contains("result_00"), "Oldest retained history record is unreachable")
	shell.call("_set_long_term_card_selected", 49)
	await _frames(3)
	_check((shell.get("content_record_title_label") as Label).text.contains("测试矿区 00"), "Selecting the oldest record did not synchronize details")
	_check(not (shell.get("content_record_facts_label") as Label).text.contains("result_00"), "Player details exposed an internal result id")
	_check((shell.get("content_list_scroll") as ScrollContainer).scroll_vertical > 0, "Keyboard focus did not scroll the oldest record into view")


func _test_read_only_selection_and_explicit_actions(shell: Control) -> void:
	var base_snapshot := _workspace_snapshot()
	shell.call("apply_snapshot", base_snapshot)
	meta_actions.clear()
	shell.call("_apply_module_immediately", &"task_archive")
	shell.call("show_secondary", &"task")
	shell.call("_preview_long_term_card", 0)
	shell.call("_set_long_term_card_selected", 0)
	_check(meta_actions.is_empty(), "Hover/focus/selection emitted a domain action")
	shell.call("_on_content_action_pressed")
	shell.call("_on_content_action_pressed")
	_check(meta_actions.size() == 1 and StringName(meta_actions[0].get("action", &"")) == &"claim_goal", "Task claim was not explicit and exactly once")
	var claim_request := meta_actions[0]
	_check(str(claim_request.get("request_id", "")).begins_with("long_term:"), "Task claim did not establish a page-owned request id")
	_check(StringName(claim_request.get("source_page", &"")) == &"long_term", "Task claim source page was not explicit")
	var claim_tx: Dictionary = shell.call("get_meta_transaction_snapshot")
	_check(bool(claim_tx.get("pending", false)) and str((claim_tx.get("pending_request", {}) as Dictionary).get("target_id", "")) == "task:task_one", "Task claim pending identity is incomplete")

	# Pending is global to destructive LongTerm actions: navigating to another
	# actionable record must not allow a second transaction to overlap it.
	shell.call("_apply_module_immediately", &"research")
	shell.call("show_secondary", &"unlock_interface")
	shell.call("_set_long_term_card_selected", 0)
	_check((shell.get("content_action_button") as Button).disabled, "A different LongTerm record re-enabled an overlapping transaction")
	shell.call("_on_content_action_pressed")
	_check(meta_actions.size() == 1, "A second LongTerm transaction overlapped the pending claim")
	shell.call("_apply_module_immediately", &"task_archive")
	shell.call("show_secondary", &"task")

	# RunScene applies the authoritative snapshot before returning the result.
	# Refresh must preserve pending until the exact four-field envelope arrives.
	shell.call("apply_snapshot", base_snapshot)
	var stale_claim := _meta_result(claim_request, false, &"not_claimable")
	stale_claim["request_id"] = "stale:claim"
	_check(not bool(shell.call("apply_meta_action_result", stale_claim)), "Stale claim result was accepted")
	_check(bool((shell.call("get_meta_transaction_snapshot") as Dictionary).get("pending", false)), "Stale claim result cleared pending")
	var wrong_target_claim := _meta_result(claim_request, false, &"not_claimable")
	wrong_target_claim["target_id"] = "task:other"
	_check(not bool(shell.call("apply_meta_action_result", wrong_target_claim)), "Wrong-target claim result was accepted")
	var claim_failure := _meta_result(claim_request, false, &"not_claimable")
	_check(bool(shell.call("apply_meta_action_result", claim_failure)), "Matching claim failure was not accepted")
	_check(not bool((shell.call("get_meta_transaction_snapshot") as Dictionary).get("pending", true)), "Matching claim failure did not clear pending")
	_check(not (shell.get("content_action_button") as Button).disabled, "Claim failure did not restore the action")
	_check((shell.get("content_record_state_label") as Label).text == "当前尚未满足领取条件。", "Claim failure did not show player-facing feedback")
	_check(not bool(shell.call("apply_meta_action_result", claim_failure)), "Duplicate claim result was accepted twice")

	meta_actions.clear()
	shell.call("_on_content_action_pressed")
	var claim_retry := meta_actions[0]
	_check(str(claim_retry.get("request_id", "")) != str(claim_request.get("request_id", "")), "Claim retry reused a completed request id")
	var claimed_snapshot := _workspace_snapshot()
	(claimed_snapshot["meta_progress_summary"] as Dictionary)["task_states"] = {"task_one": {"status": "claimed", "progress": 1, "target": 1}}
	shell.call("apply_snapshot", claimed_snapshot)
	_check(bool((shell.call("get_meta_transaction_snapshot") as Dictionary).get("pending", false)), "Authoritative success snapshot cleared pending before result delivery")
	_check(bool(shell.call("apply_meta_action_result", _meta_result(claim_retry, true, &"claimed"))), "Matching claim success was not accepted")
	_check((shell.get("content_record_state_label") as Label).text.contains("奖励已领取"), "Claim success feedback was lost after snapshot refresh")

	var research_snapshot := _workspace_snapshot()
	var research_meta := research_snapshot["meta_progress_summary"] as Dictionary
	research_meta["research_completed_ids"] = ["research_anomaly_structure"]
	research_meta["warehouse_items"] = [{"instance_id": "material_2", "item_id": "sp_altar_residue"}]
	shell.call("apply_snapshot", research_snapshot)
	shell.call("_apply_module_immediately", &"research")
	shell.call("show_secondary", &"unlock_interface")
	meta_actions.clear()
	shell.call("_preview_long_term_card", 0)
	shell.call("_set_long_term_card_selected", 0)
	_check(meta_actions.is_empty(), "Research display selection emitted a domain action")
	var research_buttons := shell.get("long_term_card_buttons") as Array
	var action_button := shell.get("content_action_button") as Button
	_check(not action_button.visible, "Completed research exposed an action")
	_check((research_buttons[0] as Button).focus_neighbor_right == (research_buttons[0] as Button).get_path_to(research_buttons[0] as Button), "Non-actionable research record points to a hidden action")
	shell.call("_set_long_term_card_selected", 1)
	_check(action_button.visible and not action_button.disabled, "Later actionable research record did not expose its action")
	_check((research_buttons[1] as Button).focus_neighbor_right == (research_buttons[1] as Button).get_path_to(action_button), "Gamepad focus cannot reach a later record's action")
	shell.call("_on_content_action_pressed")
	shell.call("_on_content_action_pressed")
	_check(meta_actions.size() == 1 and StringName(meta_actions[0].get("action", &"")) == &"complete_research", "Research confirmation was not explicit and exactly once")
	var research_request := meta_actions[0]
	_check(str((shell.call("get_meta_transaction_snapshot") as Dictionary).get("pending_request", {}).get("target_id", "")) == "research_protocol_formula", "Research pending target is incorrect")
	shell.call("apply_snapshot", research_snapshot)
	_check(bool(shell.call("apply_meta_action_result", _meta_result(research_request, false, &"material_missing_or_configured"))), "Matching research failure was not accepted")
	_check(action_button.visible and not action_button.disabled, "Research failure did not restore the selected action")
	_check((shell.get("content_record_state_label") as Label).text.contains("所需材料不足"), "Research failure did not show player-facing feedback")


func _test_red_dot_refresh_and_view_transaction(shell: Control) -> void:
	var unread_snapshot := _workspace_snapshot()
	(unread_snapshot["meta_progress_summary"] as Dictionary)["red_dot_state"] = {"new_codex": 2}
	shell.call("apply_snapshot", unread_snapshot)
	var tabs := shell.get("tab_buttons") as Dictionary
	_check((tabs[&"codex"] as Button).text.begins_with("● "), "Snapshot refresh did not update the Codex red dot")
	meta_actions.clear()
	shell.call("_mark_current_module_viewed", &"codex")
	_check(meta_actions.size() == 1 and StringName(meta_actions[0].get("action", &"")) == &"mark_viewed", "Codex viewed request was not emitted")
	var view_request := meta_actions[0]
	_check(int((shell.call("get_meta_transaction_snapshot") as Dictionary).get("pending_background_count", 0)) == 1, "Viewed request was not correlated independently")
	var stale_view := _meta_result(view_request, false, &"save_failed")
	stale_view["request_id"] = "stale:view"
	_check(not bool(shell.call("apply_meta_action_result", stale_view)), "Stale viewed result was accepted")
	_check(int((shell.call("get_meta_transaction_snapshot") as Dictionary).get("pending_background_count", 0)) == 1, "Stale viewed result cleared the background request")
	_check(bool(shell.call("apply_meta_action_result", _meta_result(view_request, false, &"save_failed"))), "Matching viewed failure was not accepted")
	_check((tabs[&"codex"] as Button).text.begins_with("● "), "Viewed save failure incorrectly cleared the red dot")

	meta_actions.clear()
	shell.call("_mark_current_module_viewed", &"codex")
	var view_retry := meta_actions[0]
	var read_snapshot := _workspace_snapshot()
	(read_snapshot["meta_progress_summary"] as Dictionary)["red_dot_state"] = {"new_codex": 0}
	shell.call("apply_snapshot", read_snapshot)
	_check(not (tabs[&"codex"] as Button).text.begins_with("● "), "Snapshot refresh left a stale Codex red dot")
	_check(bool(shell.call("apply_meta_action_result", _meta_result(view_retry, true, &"viewed"))), "Matching viewed success was not accepted")


func _test_unknown_codex_privacy(shell: Control) -> void:
	shell.call("apply_snapshot", _workspace_snapshot())
	shell.call("_apply_module_immediately", &"codex")
	shell.call("show_secondary", &"monster")
	var cards := shell.get("current_content_cards") as Array
	_check(not cards.is_empty(), "Unknown Codex fixture has no records")
	for raw_card in cards:
		var card := raw_card as Dictionary
		_check(card.get("known", true) == false, "Unknown Codex fixture unexpectedly exposed a known record")
		_check(StringName(card.get("visual_key", &"")) == &"art25.long_term.unknown", "Unknown Codex record exposed its real artwork")
		var player_copy := "%s %s %s %s" % [card.get("title", ""), card.get("state", ""), card.get("description", ""), " ".join(card.get("facts", []))]
		_check(not player_copy.contains("monster:") and not player_copy.contains("档案编号"), "Unknown Codex record exposed its internal id")
	_check(not (shell.get("content_record_facts_label") as Label).text.contains("monster:"), "Rendered Codex detail exposed an internal id")


func _meta_result(request: Dictionary, ok: bool, status: StringName) -> Dictionary:
	var action := StringName(request.get("action", &""))
	var target_id := ""
	match action:
		&"claim_goal": target_id = "%s:%s" % [str(request.get("goal_kind", "")), str(request.get("goal_id", ""))]
		&"complete_research": target_id = str(request.get("research_id", ""))
		&"mark_viewed": target_id = str(request.get("view_kind", ""))
	return {
		"request_id": str(request.get("request_id", "")),
		"source_page": StringName(request.get("source_page", &"")),
		"action": action,
		"target_id": target_id,
		"ok": ok,
		"status": status,
		"duplicate": false,
		"result": {"ok": ok, "status": status},
		"meta_progress_summary": {},
	}


func _workspace_snapshot() -> Dictionary:
	var history: Array = []
	for index in range(50):
		history.append({
			"history_id": "result_%02d" % index,
			"result_id": "result_%02d" % index,
			"outcome": "success" if index % 2 == 0 else "failure",
			"map_display_name": "测试矿区 %02d" % index,
			"difficulty_label": "普通",
			"commission_label": "路线勘察",
			"gold_delta": index,
		})
	return {
		"meta_progress_summary": {
			"profile_level": 3,
			"profile_exp": 320,
			"run_count": 50,
			"extract_count": 25,
			"fail_count": 20,
			"abandon_count": 5,
			"gold": 100,
			"long_term_gold": 100,
			"history_records": history,
			"history_record_count": history.size(),
			"task_definitions": [{
				"id": "task_one",
				"display_name": "单条可领取任务",
				"description": "只用于验证一条真实记录。",
				"reward": {"gold": 20},
			}],
			"task_states": {"task_one": {"status": "claimable", "progress": 1, "target": 1}},
			"achievement_definitions": [],
			"achievement_states": {},
			"commission_history": [],
			"research_completed_ids": [],
			"warehouse_items": [{"instance_id": "material_1", "item_id": "mon_old_gear_set"}],
			"codex_discoveries": [],
			"collection_discoveries": [],
			"completed_collection_set_ids": [],
			"titles": ["新进回收员", "初级回收员", "异常处理员"],
			"badges": ["异常处理员徽章"],
			"red_dot_state": {},
		},
	}


func _on_meta_action(action: Dictionary) -> void:
	meta_actions.append(action.duplicate(true))


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("I2_LONG_TERM_MODULE_WORKSPACE=PASS pages=24 records=0,1,many,50 selection_actions=0 explicit_actions=once")
		quit(0)
		return
	for failure in failures:
		push_error("I2 long-term workspace: " + failure)
	print("I2_LONG_TERM_MODULE_WORKSPACE=FAIL failures=%d" % failures.size())
	quit(1)
