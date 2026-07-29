extends SceneTree

const LongTermShellScript := preload("res://scripts/ui/long_term/long_term_shell.gd")
const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")

const PASS_MARKER := "I4_LONG_TERM_NAVIGATION=PASS"
const FAIL_MARKER := "I4_LONG_TERM_NAVIGATION=FAIL"

var failures: Array[String] = []
var meta_actions: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var shell := LongTermShellScript.new()
	host.add_child(shell)
	shell.meta_action_requested.connect(_on_meta_action)
	var snapshot := _snapshot()
	shell.build(LongTermModelScript.build_from_snapshot(&"task_archive", snapshot, &"i4_test"))
	shell.apply_snapshot(snapshot)
	shell.set_reduced_motion_enabled(true)
	await _wait_until(
		func() -> bool: return (shell.get("tab_buttons") as Dictionary).size() == 6,
		"long-term shell ready"
	)

	meta_actions.clear()
	shell.show_module(&"codex")
	await _wait_until(
		func() -> bool: return StringName(shell.get("displayed_module_id")) == &"codex",
		"ordinary codex module open"
	)
	var secondary_scroll := shell.get("secondary_scroll") as ScrollContainer
	var secondary_buttons := shell.get("secondary_button_order") as Array
	_expect(secondary_buttons.size() == 8, "codex did not expose all eight secondary pages")
	if secondary_scroll != null:
		var secondary_viewport := secondary_scroll.get_global_rect()
		for raw_button in secondary_buttons:
			var secondary_button := raw_button as Button
			_expect(
				secondary_button != null
				and _rect_encloses(secondary_viewport, secondary_button.get_global_rect()),
				"codex secondary page is clipped from the initial pointer-visible row"
			)
	_expect(meta_actions.is_empty(), "opening a module acknowledged unread content before a concrete card was opened")
	var codex_tab := (shell.get("tab_buttons") as Dictionary).get(&"codex", null) as Button
	_expect(codex_tab != null and codex_tab.text.begins_with("● "), "ordinary module open hid the authoritative unread marker")

	var codex_route := shell.notification_route_for_module(&"codex")
	_expect(StringName(codex_route.get("secondary_id", &"")) == &"monster", "codex notification did not resolve its concrete category")
	_expect(str(codex_route.get("card_id", "")) == "monster:slime", "codex notification did not resolve its concrete card")
	var open_result := shell.open_notification(codex_route)
	_expect(bool(open_result.get("ok", false)), "concrete codex notification route failed")
	_expect(shell.get_selected_module_id() == &"codex" and shell.get_selected_secondary_id() == &"monster", "notification route stopped at the module level")
	var codex_group_key := "codex/monster"
	_expect(
		str((shell.get("selected_content_card_id_by_group") as Dictionary).get(codex_group_key, "")) == "monster:slime",
		"notification route did not select the unread card"
	)
	_expect(
		meta_actions.size() == 1
		and StringName(meta_actions[0].get("action", &"")) == &"mark_viewed"
		and str(meta_actions[0].get("view_kind", "")) == "codex",
		"concrete unread card did not request one correlated acknowledgement"
	)

	shell.call("_apply_module_immediately", &"profile")
	shell.show_secondary(&"history")
	await _wait_until(
		func() -> bool:
			return (
				shell.get_selected_module_id() == &"profile"
				and shell.get_selected_secondary_id() == &"history"
				and (shell.get("current_content_cards") as Array).size() == 50
				and str(shell.get_meta("last_scroll_restore_group", "")) == "profile/history"
			),
		"profile history page"
	)
	shell.call("_set_long_term_card_selected", 30)
	var history_card_id := str((shell.get("current_content_cards") as Array)[30].get("id", ""))
	await _wait_until(
		func() -> bool: return (shell.get("content_list_scroll") as ScrollContainer).scroll_vertical > 0,
		"history selection scrolled into view"
	)
	var stored_scroll := (shell.get("content_list_scroll") as ScrollContainer).scroll_vertical
	shell.clear_navigation_history()
	meta_actions.clear()
	shell.call("_on_module_tab_pressed", &"codex")
	await _wait_until(
		func() -> bool:
			return (
				shell.get_selected_module_id() == &"codex"
				and shell.get_selected_secondary_id() == &"monster"
				and str((shell.get("selected_content_card_id_by_group") as Dictionary).get("codex/monster", "")) == "monster:slime"
			),
		"red-dot tab direct route"
	)
	var navigation := shell.get_navigation_snapshot()
	_expect(int(navigation.get("history_depth", 0)) == 1, "player page transition did not create one history entry")
	_expect(StringName(shell.call("_handle_cancel_focus_step")) == &"history", "Back did not consume page history before focus-layer fallback")
	await _wait_until(
		func() -> bool:
			var restored_scroll := (shell.get("content_list_scroll") as ScrollContainer).scroll_vertical
			return (
				shell.get_selected_module_id() == &"profile"
				and shell.get_selected_secondary_id() == &"history"
				and str((shell.get("selected_content_card_id_by_group") as Dictionary).get("profile/history", "")) == history_card_id
				and abs(restored_scroll - stored_scroll) <= 2
			),
		"Back restored page filter, card, and scroll"
	)
	await _wait_until(
		func() -> bool:
			var focus_owner := root.gui_get_focus_owner()
			return focus_owner != null and focus_owner in (shell.get("long_term_card_buttons") as Array),
		"Back restored controller focus"
	)

	var actions_before_missing := meta_actions.size()
	var missing_result := shell.open_notification({
		"module_id": &"codex",
		"secondary_id": &"monster",
		"card_id": "monster:missing",
		"view_kind": &"codex",
	})
	_expect(StringName(missing_result.get("status", &"")) == &"notification_target_unavailable", "missing notification target did not fail closed")
	_expect(meta_actions.size() == actions_before_missing, "missing notification target was acknowledged as read")
	_expect((shell.get("content_record_state_label") as Label).text.contains("目标条目当前不可用"), "missing target did not explain the navigation blocker")

	host.queue_free()
	await host.tree_exited
	_finish()


func _snapshot() -> Dictionary:
	var history: Array[Dictionary] = []
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
			"unread_history_ids": ["result_49"],
			"task_definitions": [],
			"task_states": {},
			"achievement_definitions": [],
			"achievement_states": {},
			"commission_history": [],
			"research_completed_ids": [],
			"warehouse_items": [],
			"codex_discoveries": ["monster:slime"],
			"unread_codex_ids": ["monster:slime"],
			"collection_discoveries": [],
			"completed_collection_set_ids": [],
			"unread_collection_set_ids": [],
			"titles": ["新进回收员"],
			"badges": [],
			"red_dot_state": {
				"new_codex": 1,
				"new_history": 1,
			},
		},
	}


func _wait_until(predicate: Callable, label: String, max_polls: int = 180) -> void:
	for _poll_index in range(max_polls):
		if bool(predicate.call()):
			return
		await process_frame
	failures.append("timed out waiting for semantic state: %s" % label)


func _on_meta_action(action: Dictionary) -> void:
	meta_actions.append(action.duplicate(true))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _rect_encloses(outer: Rect2, inner: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x - 0.5
		and inner.position.y >= outer.position.y - 0.5
		and inner.end.x <= outer.end.x + 0.5
		and inner.end.y <= outer.end.y + 0.5
	)


func _finish() -> void:
	if failures.is_empty():
		print("%s notification=card unread=explicit history=module,filter,card,scroll focus=restored" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("%s count=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
