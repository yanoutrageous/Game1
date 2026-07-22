extends SceneTree

var failures: Array[String] = []
var route_intents: Array[Dictionary] = []
var deploy_route_intents: Array[Dictionary] = []
var meta_actions: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)

	var shell_script := load("res://scripts/ui/long_term/long_term_shell.gd")
	_check(shell_script != null, "LongTermShell could not be loaded")
	if shell_script == null:
		_finish()
		return
	var shell := shell_script.new() as Control
	shell.name = "Art23RuntimeLongTerm"
	shell.size = Vector2(1280, 720)
	canvas.add_child(shell)
	shell.connect("navigation_intent_requested", _on_route_intent)
	shell.connect("meta_action_requested", _on_meta_action)
	shell.call("build")
	await _frames(20)

	_check((shell.get("tab_buttons") as Dictionary).size() == 5, "Production primary module count must be five")
	_check(not (shell.get("tab_buttons") as Dictionary).has(&"gacha"), "Unauthorised gacha module is still exposed")
	_check((shell.get("tab_buttons") as Dictionary).has(&"task_archive"), "Canonical task archive module is missing")
	_check(not (shell.get("character_frames") as Array).is_empty(), "Profile character presentation did not resolve a usable clip")
	var module_group := shell.get("module_group") as Control
	_check(module_group != null and module_group.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Module group blocks primary-tab mouse input")
	_check(shell.get_node_or_null("LongTermSceneCleanPlate") is TextureRect, "Clean archive room plate is missing")
	_check(shell.get_node_or_null("LongTermProfileFrame") is TextureRect, "Fixed profile frame is missing")
	_check(shell.get_node_or_null("LongTermPlayerSprite") is TextureRect, "Fixed player sprite is missing")
	_check(shell.get_node_or_null("LongTermArchiveLever") is Button, "Bottom-left archive lever is missing")
	_check(shell.get_node_or_null("LongTermModuleGroup/LongTermContentDetailBlock") is TextureRect, "Compatibility content detail block is missing")
	_check(shell.get_node_or_null("LongTermModuleGroup/LongTermContentListScroll") is ScrollContainer, "Scrollable module record list is missing")
	_check(shell.get("content_detail_title_label") is Label, "Compatibility content title label is missing")
	var readable_font := load("res://assets/fonts/NotoSansCJKsc-Regular.otf") as Font
	_check(readable_font != null, "Readable CJK body font is missing")
	_check((shell.get("content_detail_body_label") as Label).get_theme_font("font") == readable_font, "Body copy still uses the display pixel font")
	shell.call("_apply_module_immediately", &"codex")
	shell.call("show_secondary", &"monster")
	await _frames(3)
	for button_variant in shell.get("long_term_card_buttons") as Array:
		var button := button_variant as Button
		_check(button != null and not button.text.contains("Unknown") and button.text.contains("未发现怪物样本"), "Monster empty state is not localized or page-specific")
	shell.call("show_secondary", &"collectible")
	await _frames(3)
	for button_variant in shell.get("long_term_card_buttons") as Array:
		var button := button_variant as Button
		_check(button != null and not button.text.contains("Unknown") and button.text.contains("未发现藏品"), "Collectible empty state is not localized or page-specific")

	# Mouse/card selection must establish the focus layer used by the staged Esc contract.
	shell.call("_set_long_term_card_selected", 1)
	await _frames(1)
	var card_buttons := shell.get("long_term_card_buttons") as Array
	_check(get_root().gui_get_focus_owner() == card_buttons[1], "Selecting a card did not move focus into the card layer")
	_check(StringName(shell.call("_handle_cancel_focus_step")) == &"secondary", "First Esc step did not return card focus to secondary tabs")
	var selected_secondary := StringName(shell.call("get_selected_secondary_id"))
	var secondary_buttons := shell.get("secondary_buttons") as Dictionary
	_check(get_root().gui_get_focus_owner() == secondary_buttons[selected_secondary], "First Esc step did not focus the selected secondary tab")
	_check(StringName(shell.call("_handle_cancel_focus_step")) == &"primary", "Second Esc step did not return secondary focus to the primary module")
	var primary_buttons := shell.get("tab_buttons") as Dictionary
	_check(get_root().gui_get_focus_owner() == primary_buttons[&"codex"], "Second Esc step did not focus the selected primary module")
	_check(not bool(shell.call("_cancel_press_is_debounced", 1000)), "First Esc press was incorrectly debounced")
	_check(bool(shell.call("_cancel_press_is_debounced", 1001)), "Duplicate Escape press was not debounced")
	_check(not bool(shell.call("_cancel_press_is_debounced", 1600)), "A later intentional Escape press remained debounced")

	var expected := {
		&"task_archive": [&"task", &"achievement", &"commission_record"],
		&"codex": [&"map", &"monster", &"collectible", &"equipment", &"consumable", &"event", &"rule", &"lore"],
		&"research": [&"unlock_interface", &"research_entry"],
		&"profile": [&"qualification_level", &"history", &"statistics", &"milestone", &"title", &"badge"],
		&"collection_appearance": [&"unique_display", &"appearance_config", &"display_content", &"badge_title", &"settlement_display"],
	}
	var profile_node := shell.get_node("LongTermProfileFrame")
	var secondary_page_count := 0
	for module_id_variant in expected.keys():
		var module_id := StringName(module_id_variant)
		shell.call("show_module", module_id)
		await create_timer(0.82).timeout
		_check(StringName(shell.call("get_selected_module_id")) == module_id, "Primary module selection mismatch: " + String(module_id))
		_check(StringName(shell.get("displayed_module_id")) == module_id, "Displayed module did not settle: " + String(module_id))
		_check((shell.get("transition_state") as StringName) == &"OPEN", "Transition did not settle OPEN: " + String(module_id))
		_check(((shell.get("tab_buttons") as Dictionary)[module_id] as Button).button_pressed, "Primary module lacks selected state: " + String(module_id))
		_check(shell.get_node("LongTermProfileFrame") == profile_node, "Fixed profile column was rebuilt during switch")
		var ids: Array = shell.call("get_secondary_ids", module_id)
		_check(ids.size() == (expected[module_id] as Array).size(), "Secondary count mismatch: " + String(module_id))
		for group_id_variant in expected[module_id]:
			var group_id := StringName(group_id_variant)
			shell.call("show_secondary", group_id)
			await _frames(4)
			secondary_page_count += 1
			_check(StringName(shell.call("get_selected_secondary_id")) == group_id, "Secondary selection mismatch: %s/%s" % [String(module_id), String(group_id)])
			_check(((shell.get("secondary_buttons") as Dictionary)[group_id] as Button).button_pressed, "Secondary lacks selected state: %s/%s" % [String(module_id), String(group_id)])
			var record_count := int(shell.get("current_record_count"))
			var display_count := (shell.get("long_term_card_buttons") as Array).size()
			_check(display_count == maxi(1, record_count), "Secondary page lost records or padded fake cards: %s/%s records=%d display=%d" % [String(module_id), String(group_id), record_count, display_count])
			for card_variant in shell.get("current_content_cards") as Array:
				var card := card_variant as Dictionary
				_check(not str(card.get("title", "")).contains("预留档案位") and not str(card.get("title", "")).contains("暂无更多记录"), "Secondary page contains a fake padding card: %s/%s" % [String(module_id), String(group_id)])
			var title_label := shell.get("content_detail_title_label") as Label
			var body_label := shell.get("content_detail_body_label") as Label
			_check(not title_label.text.strip_edges().is_empty(), "Secondary title is empty: %s/%s" % [String(module_id), String(group_id)])
			_check(not body_label.text.strip_edges().is_empty(), "Secondary body is empty: %s/%s" % [String(module_id), String(group_id)])
	_check(secondary_page_count == 24, "Expected 24 production secondary pages, got %d" % secondary_page_count)

	shell.call("apply_snapshot", {
		"meta_progress_summary": {
			"profile_level": 12,
			"profile_exp": 3456,
			"run_count": 123,
			"extract_count": 45,
			"fail_count": 6,
			"long_term_gold": 987654,
			"gold": 987654,
			"warehouse_items": [],
			"warehouse_items_count": 0,
			"red_dot_state": {"claimable_rewards": 2},
		},
	})
	await _frames(3)
	_check((shell.get("profile_level_label") as Label).text == "等级 12", "Profile level remains hard-coded")
	_check((shell.get("profile_exp_value_label") as Label).text == "3456", "Absolute profile EXP is not bound")
	var stat_labels := shell.get("profile_stat_labels") as Array
	_check((stat_labels[0] as Label).text.contains("123"), "Run count is not bound")
	_check((stat_labels[3] as Label).text.contains("987,654"), "Long-term gold formatting or binding failed")
	_check(bool(shell.call("_module_has_red_dot", &"task_archive", {"claimable_rewards": 2})), "Claimable task reward indicator is missing")
	meta_actions.clear()
	shell.call("show_module", &"goals")
	await _frames(3)
	_check(StringName(shell.call("get_selected_module_id")) == &"task_archive", "goals alias did not normalize to task_archive")
	shell.call("show_module", &"tasks")
	await _frames(3)
	_check(StringName(shell.call("get_selected_module_id")) == &"task_archive", "tasks alias did not normalize to task_archive")
	_check(meta_actions.is_empty(), "Opening task archive emitted mark_viewed and could clear claimable rewards")

	var art23_contract := load("res://scripts/presentation/art23_long_term_asset_contract.gd")
	_check(
		StringName(art23_contract.asset_id(&"long_term.furniture.task_archive")) == &"ui.art23.long_term.furniture.goals",
		"Task archive furniture did not explicitly reuse the audited goals asset"
	)
	_check(
		StringName(art23_contract.asset_id(&"long_term.control.module.task_archive.selected")) == &"ui.art23.long_term.control.module.goals.selected",
		"Task archive module control did not explicitly reuse the audited goals asset"
	)
	var art25_contract := load("res://scripts/presentation/art25_content_asset_contract.gd")
	var sample_card := {"id": "task_daily_first_steps"}
	_check(
		StringName(art25_contract.long_term_visual_key("task_archive/task", sample_card)) == StringName(art25_contract.long_term_visual_key("goals/task", sample_card)),
		"Canonical and legacy task groups did not resolve to the same ART25 visual key"
	)
	var layout_contract := load("res://scripts/ui/long_term/long_term_layout_contract.gd")
	_check(
		Rect2(layout_contract.furniture_rect(&"gacha")) == Rect2(layout_contract.FURNITURE_DEFAULT),
		"Removed gacha route still exposes a dedicated production furniture layout"
	)

	shell.call("_request_appearance_settings")
	await create_timer(0.82).timeout
	_check(StringName(shell.call("get_selected_module_id")) == &"collection_appearance", "Appearance button did not route to collection module")
	_check(StringName(shell.call("get_selected_secondary_id")) == &"unique_display", "Collection archive button did not route to unique_display")

	shell.call("set_archive_collapsed", true, false)
	_check((shell.get("module_group") as Control).position == Vector2(0, 610), "Collapsed module group does not clear the room")
	_check((shell.get_node("LongTermProfileFrame") as CanvasItem).visible, "Collapse hides the fixed profile")
	shell.call("set_archive_collapsed", false, false)
	_check((shell.get("module_group") as Control).position == Vector2.ZERO, "Expanded module group does not restore exactly")
	await create_timer(0.82).timeout
	_check(StringName(shell.get("displayed_module_id")) == &"collection_appearance", "Expand did not preserve the routed collection module")
	_check(StringName(shell.call("get_selected_secondary_id")) == &"unique_display", "Expand did not preserve the collection archive page")

	shell.call("show_module", &"task_archive")
	shell.call("show_module", &"codex")
	shell.call("show_module", &"profile")
	shell.call("show_module", &"goals")
	await create_timer(1.15).timeout
	_check(StringName(shell.get("displayed_module_id")) == &"task_archive", "Rapid switching did not keep the normalized latest target")
	_check((shell.get("transition_state") as StringName) == &"OPEN", "Rapid switching left the state machine unsettled")

	shell.call("_request_deploy")
	shell.call("_request_back_to_main")
	await _frames(2)
	_check(route_intents.size() == 2, "Navigation plaques did not emit both route intents")

	var deploy_shell_script := load("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
	var deploy_shell := deploy_shell_script.new() as Control
	deploy_shell.connect("navigation_intent_requested", _on_deploy_route_intent)
	deploy_shell.call("_request_long_term")
	_check(deploy_route_intents.size() == 1, "Deploy long-term plaque did not emit a route intent")
	if deploy_route_intents.size() == 1:
		var deploy_payload := deploy_route_intents[0].get("payload", {}) as Dictionary
		_check(StringName(deploy_payload.get("module_id", &"")) == &"task_archive", "Deploy long-term route did not default to task_archive")
	deploy_shell.free()

	_finish()


func _on_route_intent(intent: Dictionary) -> void:
	route_intents.append(intent.duplicate(true))


func _on_deploy_route_intent(intent: Dictionary) -> void:
	deploy_route_intents.append(intent.duplicate(true))


func _on_meta_action(action: Dictionary) -> void:
	meta_actions.append(action.duplicate(true))


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("ART23_LONG_TERM_RUNTIME=PASS primary_modules=5 secondary_pages=24 canonical=task_archive workspace=scrollable states=OPEN,CLOSED,OPENING,CLOSING,SWITCHING")
		quit(0)
		return
	for failure in failures:
		push_error("ART23: " + failure)
	print("ART23_LONG_TERM_RUNTIME=FAIL failures=%d" % failures.size())
	quit(1)
