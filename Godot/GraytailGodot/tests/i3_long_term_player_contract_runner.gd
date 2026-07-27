extends SceneTree

const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const M7TalentCatalogScript := preload("res://scripts/core/progression/m7_talent_catalog.gd")

var failures: Array[String] = []
var meta_actions: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var snapshot := _research_snapshot()
	_test_research_tree_projection(snapshot)
	_test_talent_tree_projection(snapshot)

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
	shell.call("apply_snapshot", snapshot)
	shell.call("_apply_module_immediately", &"research")
	shell.call("show_secondary", &"unlock_interface")
	await _frames(4)

	_test_research_tree_surface(shell)
	_test_talent_tree_surface(shell)
	_test_player_copy(shell)
	_test_task_archive_boundary(shell)
	_test_explicit_talent_transaction(shell)
	_test_explicit_research_transaction(shell)

	shell.queue_free()
	await _frames(2)
	_finish()


func _test_research_tree_projection(snapshot: Dictionary) -> void:
	var source_before := snapshot.duplicate(true)
	var model: Dictionary = LongTermModelScript.build_from_snapshot(&"research", snapshot, &"i3_long_term_contract")
	var definitions := M7ContentCatalogScript.research_definitions()
	var cards: Array = (model.get("m7_cards_by_group", {}) as Dictionary).get("research/unlock_interface", [])
	var contract: Dictionary = model.get("research_tree_contract", {})
	_check(snapshot == source_before, "Research tree projection mutated its source snapshot")
	_check(cards.size() == definitions.size(), "Research tree did not preserve every authoritative M7 research node")
	_check(StringName(contract.get("source", &"")) == &"m7_research_prerequisite", "Research tree source is not the existing M7 prerequisite chain")
	_check(not bool(contract.get("adds_talent_rules", true)), "Research tree presentation claims to add talent rules")
	_check(int(contract.get("node_count", -1)) == definitions.size(), "Research tree node count differs from the M7 catalog")
	_check(int(contract.get("edge_count", -1)) == maxi(0, definitions.size() - 1), "Research tree edge count differs from the M7 prerequisites")
	for index in range(mini(cards.size(), definitions.size())):
		var card := cards[index] as Dictionary
		var definition := definitions[index] as Dictionary
		_check(str(card.get("id", "")) == str(definition.get("id", "")), "Research tree changed an authoritative research id")
		_check(str(card.get("prerequisite_id", "")) == str(definition.get("prerequisite", "")), "Research tree changed an authoritative prerequisite")
		_check(StringName(card.get("presentation_kind", &"")) == &"research_unlock_node", "Research record is not projected as an unlock-tree node")
		_check(StringName(card.get("tree_source", &"")) == &"m7_research_prerequisite", "Research node does not declare its existing prerequisite source")
		_check(not bool(card.get("adds_talent_rules", true)), "Research node fabricates a talent rule")


func _test_talent_tree_projection(snapshot: Dictionary) -> void:
	var source_before := snapshot.duplicate(true)
	var model: Dictionary = LongTermModelScript.build_from_snapshot(&"talent", snapshot, &"i3r_talent_contract")
	var cards: Array = (model.get("m7_cards_by_group", {}) as Dictionary).get("talent/tree", [])
	var contract: Dictionary = model.get("talent_tree_contract", {})
	_check(snapshot == source_before, "Talent tree projection mutated its source snapshot")
	_check(cards.size() == M7TalentCatalogScript.definitions().size(), "Talent tree does not expose all six authoritative nodes")
	_check(StringName(contract.get("source", &"")) == &"m7_talent_catalog", "Talent tree does not use the authoritative talent catalog")
	_check(bool(contract.get("adds_talent_rules", false)), "Talent tree is still marked as a display-only research projection")
	_check(int(contract.get("branch_count", 0)) == 3 and int(contract.get("edge_count", 0)) == 3, "Talent tree branch or prerequisite topology changed")
	for raw_card in cards:
		var card := raw_card as Dictionary
		_check(StringName(card.get("presentation_kind", &"")) == &"talent_unlock_node", "Talent record is not projected as a talent node")
		_check(StringName(card.get("tree_source", &"")) == &"m7_talent_catalog", "Talent node lost its catalog authority")
		_check(str(card.get("effect_label", "")).strip_edges() != "", "Talent node hides its exact runtime effect")


func _test_research_tree_surface(shell: Control) -> void:
	var tabs := shell.get("tab_buttons") as Dictionary
	_check((tabs[&"research"] as Button).text.contains("研究解锁"), "Research primary tab is not named for the existing unlock chain")
	_check((shell.get("content_list_header_label") as Label).text == "研究解锁树", "Research chain is still presented as a generic list")
	_check((shell.get("content_detail_header_label") as Label).text == "节点条件与效果", "Research detail does not pair conditions with effects")
	_check((shell.get("content_detail_title_label") as Label).text.contains("解锁树"), "Research workspace title does not identify the unlock tree")
	var scroll := shell.get("content_list_scroll") as ScrollContainer
	_check(scroll.size.x >= 320.0 and scroll.size.y >= 320.0, "Long-term list viewport did not gain usable information density")
	var buttons := shell.get("long_term_card_buttons") as Array
	_check(buttons.size() == M7ContentCatalogScript.research_definitions().size(), "Research tree surface lost nodes")
	for index in range(buttons.size()):
		var button := buttons[index] as Button
		var card: Dictionary = button.get("card_data")
		_check(bool(card.get("tree_view", false)), "Research unlock node is rendered as a generic card")
		_check(button.custom_minimum_size.y <= 60.0, "Long-term record rows remain too sparse")
		_check(button.get_node_or_null("ResearchTreeNode") is Control, "Research unlock node lacks a visible tree marker")
		if index > 0:
			_check(button.get_node_or_null("ResearchTreeParentEdge") is Control, "Dependent research node lacks a parent edge")


func _test_talent_tree_surface(shell: Control) -> void:
	shell.call("_apply_module_immediately", &"talent")
	shell.call("show_secondary", &"tree")
	var tabs := shell.get("tab_buttons") as Dictionary
	_check(tabs.has(&"talent") and (tabs[&"talent"] as Button).text.contains("天赋"), "Talent is not a separate primary module")
	_check((shell.get("content_list_header_label") as Label).text == "三分支天赋树", "Talent page is still presented as a research list")
	_check((shell.get("long_term_card_buttons") as Array).size() == 6, "Talent tree surface lost authoritative nodes")
	for raw_button in shell.get("long_term_card_buttons") as Array:
		var card: Dictionary = (raw_button as Button).get("card_data")
		_check(bool(card.get("tree_view", false)), "Talent node is rendered as a generic archive card")
	_check((shell.get("content_action_button") as Button).visible, "Available talent root lacks explicit confirmation")


func _test_player_copy(shell: Control) -> void:
	for module_id in [&"task_archive", &"codex", &"research", &"talent", &"profile", &"collection_appearance"]:
		shell.call("_apply_module_immediately", module_id)
		for group_id in shell.call("get_secondary_ids", module_id):
			shell.call("show_secondary", StringName(group_id))
			var visible_copy := "\n".join(_visible_copy(shell))
			var lowered := visible_copy.to_lower()
			_check(not lowered.contains("preview"), "Player copy exposes preview in %s/%s" % [String(module_id), String(group_id)])
			_check(not lowered.contains("display-only") and not lowered.contains("display_only"), "Player copy exposes display-only in %s/%s" % [String(module_id), String(group_id)])
			_check(not visible_copy.contains("接口"), "Player copy exposes an interface note in %s/%s" % [String(module_id), String(group_id)])
			_check(not visible_copy.contains("后续阶段"), "Player copy exposes a later-stage note in %s/%s" % [String(module_id), String(group_id)])
			_check(not _contains_stage_code(visible_copy), "Player copy exposes a G-stage code in %s/%s" % [String(module_id), String(group_id)])


func _test_task_archive_boundary(shell: Control) -> void:
	shell.call("_apply_module_immediately", &"task_archive")
	_check((shell.get("tab_buttons") as Dictionary).has(&"task_archive"), "Task archive disappeared when research became an unlock tree")
	_check((shell.get("tab_buttons") as Dictionary).has(&"talent"), "Authoritative talent module is not reachable")
	_check(shell.call("get_secondary_ids", &"talent") == [&"tree"], "Talent module is being represented by a research page")
	_check(shell.call("get_secondary_ids", &"task_archive") == [&"task", &"achievement", &"commission_record"], "Task archive boundary changed")
	shell.call("show_secondary", &"task")
	var task_cards := shell.get("current_content_cards") as Array
	_check(task_cards.size() == 1 and str((task_cards[0] as Dictionary).get("id", "")) == "task_one", "Task archive no longer reads the real task record")
	if task_cards.size() == 1:
		var facts: Array = (task_cards[0] as Dictionary).get("facts", [])
		var fact_copy := "\n".join(facts)
		_check(fact_copy.contains("类型：任务"), "Task detail omits its player-facing type")
		_check(fact_copy.contains("状态：进行中"), "Task detail omits its current state")
		_check(fact_copy.contains("进度：1 / 2"), "Task detail omits authoritative progress")
		_check(fact_copy.contains("奖励：20 金币"), "Task detail omits its reward")
		_check(fact_copy.contains("领取方式：达成后手动领取"), "Task detail omits its claim rule")


func _test_explicit_research_transaction(shell: Control) -> void:
	shell.call("_apply_module_immediately", &"research")
	shell.call("show_secondary", &"unlock_interface")
	meta_actions.clear()
	shell.call("_preview_long_term_card", 1)
	shell.call("_set_long_term_card_selected", 1)
	_check(meta_actions.is_empty(), "Research hover, focus or selection emitted a transaction")
	var action_button := shell.get("content_action_button") as Button
	_check(action_button.visible and not action_button.disabled, "Authoritatively available research node has no explicit confirmation")
	shell.call("_on_content_action_pressed")
	shell.call("_on_content_action_pressed")
	_check(meta_actions.size() == 1, "Research confirmation was not emitted exactly once")
	if meta_actions.size() == 1:
		_check(StringName(meta_actions[0].get("action", &"")) == &"complete_research", "Research tree changed the existing transaction kind")
		_check(str(meta_actions[0].get("research_id", "")) == "research_protocol_formula", "Research tree changed the transaction target")


func _test_explicit_talent_transaction(shell: Control) -> void:
	shell.call("_apply_module_immediately", &"talent")
	shell.call("show_secondary", &"tree")
	meta_actions.clear()
	shell.call("_preview_long_term_card", 0)
	shell.call("_set_long_term_card_selected", 0)
	_check(meta_actions.is_empty(), "Talent hover, focus or selection emitted a transaction")
	var action_button := shell.get("content_action_button") as Button
	_check(action_button.visible and not action_button.disabled, "Available talent root has no explicit confirmation")
	shell.call("_on_content_action_pressed")
	shell.call("_on_content_action_pressed")
	_check(meta_actions.size() == 1, "Talent confirmation was not emitted exactly once")
	if meta_actions.size() != 1:
		return
	var request := meta_actions[0]
	var talent_id := str(request.get("talent_id", ""))
	_check(StringName(request.get("action", &"")) == &"unlock_talent", "Talent tree did not submit the unlock_talent transaction")
	_check(talent_id == M7TalentCatalogScript.TALENT_CARRY_RIGGING, "Talent tree changed the selected catalog target")
	_check(str(request.get("request_id", "")).begins_with("long_term:"), "Talent transaction lacks a request_id")
	_check(StringName(request.get("source_page", &"")) == &"long_term", "Talent transaction lost its source page")
	var accepted := bool(shell.call("apply_meta_action_result", {
		"request_id": request.get("request_id", ""),
		"source_page": request.get("source_page", &""),
		"action": &"unlock_talent",
		"target_id": talent_id,
		"ok": true,
		"status": &"talent_unlocked",
		"result": {"ok": true, "status": &"talent_unlocked", "talent_id": talent_id},
	}))
	_check(accepted and not bool((shell.call("get_meta_transaction_snapshot") as Dictionary).get("pending", true)), "Matching talent envelope did not clear the pending UI transaction")


func _research_snapshot() -> Dictionary:
	var research_catalog: Array[Dictionary] = []
	for raw_definition in M7ContentCatalogScript.research_definitions():
		var definition := (raw_definition as Dictionary).duplicate(true)
		var research_id := str(definition.get("id", ""))
		definition["completed"] = research_id == "research_anomaly_structure"
		definition["prerequisite_met"] = research_id != "research_extraction_signal"
		definition["has_material"] = research_id == "research_protocol_formula"
		definition["affordable"] = true
		definition["can_complete"] = research_id == "research_protocol_formula"
		research_catalog.append(definition)
	return {
		"meta_progress_summary": {
			"profile_level": 4,
			"profile_exp": 520,
			"run_count": 12,
			"extract_count": 7,
			"fail_count": 3,
			"abandon_count": 2,
			"gold": 200,
			"long_term_gold": 200,
			"research_completed_ids": ["research_anomaly_structure"],
			"research_catalog": research_catalog,
			"warehouse_items": [{"instance_id": "material_2", "item_id": "sp_altar_residue"}],
			"task_definitions": [{"id": "task_one", "display_name": "真实任务", "description": "来自基地档案。", "reward": {"gold": 20}}],
			"task_states": {"task_one": {"status": "active", "progress": 1, "target": 2}},
			"achievement_definitions": [],
			"achievement_states": {},
			"commission_history": [],
			"codex_discoveries": [],
			"collection_discoveries": [],
			"completed_collection_set_ids": [],
			"history_records": [],
			"titles": ["初级回收员"],
			"badges": [],
			"red_dot_state": {"research_available": 1},
		},
	}


func _visible_copy(node: Node) -> Array[String]:
	var result: Array[String] = []
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return result
	if node is Label:
		var label_text := (node as Label).text.strip_edges()
		if label_text != "":
			result.append(label_text)
	elif node is Button:
		var button_text := (node as Button).text.strip_edges()
		if button_text != "":
			result.append(button_text)
	for child in node.get_children():
		result.append_array(_visible_copy(child))
	return result


func _contains_stage_code(text: String) -> bool:
	var regex := RegEx.new()
	regex.compile("(^|[^A-Za-z0-9])G[0-9]{1,3}([^A-Za-z0-9]|$)")
	return regex.search(text) != null


func _on_meta_action(action: Dictionary) -> void:
	meta_actions.append(action.duplicate(true))


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I3_LONG_TERM_PLAYER_CONTRACT=PASS source=m7_research_prerequisite talent_rules=6 tree_nodes=3 player_copy=clean")
		quit(0)
		return
	for failure in failures:
		push_error("I3 long-term player contract: " + failure)
	print("I3_LONG_TERM_PLAYER_CONTRACT=FAIL failures=%d" % failures.size())
	quit(1)
