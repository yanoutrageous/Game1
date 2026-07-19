extends RefCounted
class_name LongTermModel

const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const LongTermSnapshotScript := preload("res://scripts/ui/long_term/long_term_snapshot.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")
const CodexLiteModelScript := preload("res://scripts/ui/codex_lite/codex_lite_model.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")


static func build(selected_module_id: StringName = &"goals", source: StringName = &"long_term_shell") -> Dictionary:
	var modules: Array = LongTermTabModelScript.build_modules()
	var safe_module_id := selected_module_id
	if safe_module_id == &"":
		safe_module_id = LongTermTabModelScript.default_module_id()
	var current_module: Dictionary = LongTermTabModelScript.find_module(modules, safe_module_id)
	var current_module_id := StringName(current_module.get("id", LongTermTabModelScript.default_module_id()))
	var content_framework_modules: Array = LongTermContentFrameworkScript.build_modules()
	var current_content_preview: Dictionary = LongTermContentFrameworkScript.find_module(current_module_id)
	var module_summaries: Dictionary = LongTermTabModelScript.module_summaries(modules)
	var snapshot: Dictionary = LongTermSnapshotScript.default_snapshot(module_summaries, source)
	var placeholder_panel := _placeholder_panel(current_module, current_content_preview)
	var history_preview_panel := _history_preview_panel(snapshot)
	if current_module_id == &"profile":
		placeholder_panel["history_preview"] = history_preview_panel.duplicate(true)
	return {
		"selected_module_id": current_module_id,
		"overview_summary": _overview_summary(modules),
		"modules": modules.duplicate(true),
		"current_module": current_module.duplicate(true),
		"placeholder_panel": placeholder_panel,
		"snapshot_preview": snapshot.duplicate(true),
		"asset_domain_warehouse_view_preview": (snapshot.get("asset_domain_warehouse_view_preview", {}) as Dictionary).duplicate(true),
		"long_term_asset_interface_full_content_preview": (snapshot.get("long_term_asset_interface_full_content_preview", {}) as Dictionary).duplicate(true),
		"content_framework_preview": {
			"title": "G24 LongTerm content framework preview",
			"state": "framework",
			"modules": content_framework_modules.duplicate(true),
			"module_summaries": LongTermContentFrameworkScript.module_summaries(content_framework_modules),
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"current_content_preview": current_content_preview.duplicate(true),
		"content_cards": (current_content_preview.get("cards", []) as Array).duplicate(true),
		"event_slots_preview": (current_content_preview.get("event_slots_preview", []) as Array).duplicate(true),
		"event_flow_preview": (current_content_preview.get("event_flow_preview", {}) as Dictionary).duplicate(true),
		"reward_bundle_preview": (current_content_preview.get("reward_bundle_preview", {}) as Dictionary).duplicate(true),
		"red_dot_policy": (current_content_preview.get("red_dot_policy", {}) as Dictionary).duplicate(true),
		"jump_targets": (current_content_preview.get("jump_targets", []) as Array).duplicate(true),
		"asset_interface_preview": (current_content_preview.get("asset_interface_preview", {}) as Dictionary).duplicate(true),
		"art_slots_preview": (current_content_preview.get("art_slots_preview", []) as Array).duplicate(true),
		"history_preview_panel": history_preview_panel,
		"disabled_reason": str(current_module.get("reason", "")) if StringName(current_module.get("state", &"")) == LongTermTabModelScript.STATE_DISABLED else "",
		"next_stage_notes": _next_stage_notes(modules),
	}


static func build_from_snapshot(selected_module_id: StringName, app_snapshot: Dictionary = {}, source: StringName = &"app_shell_snapshot") -> Dictionary:
	var model: Dictionary = build(selected_module_id, source)
	var meta_summary: Dictionary = app_snapshot.get("meta_progress_summary", {})
	var latest_result: Dictionary = app_snapshot.get("last_result_snapshot", app_snapshot.get("result_snapshot", {}))
	var profile_runtime_panel := _profile_runtime_panel(meta_summary, latest_result)
	var codex_lite_model := CodexLiteModelScript.build(meta_summary)
	model["meta_progress_summary"] = meta_summary.duplicate(true)
	model["history_records"] = (meta_summary.get("history_records", []) as Array).duplicate(true)
	model["codex_lite_model"] = codex_lite_model.duplicate(true)
	model["latest_run_result_summary"] = _latest_run_result_summary(latest_result)
	model["profile_runtime_panel"] = profile_runtime_panel
	model["m7_cards_by_group"] = _m7_cards_by_group(meta_summary)
	model["m7_red_dot_state"] = (meta_summary.get("red_dot_state", {}) as Dictionary).duplicate(true)
	model["m7_real_module"] = selected_module_id != &"gacha"
	var panel: Dictionary = model.get("placeholder_panel", {})
	panel["profile_runtime_panel"] = profile_runtime_panel.duplicate(true)
	if selected_module_id == &"codex":
		panel["description"] = "Codex Lite reads discovered collectibles and monster samples from MetaProgress warehouse_items."
		panel["codex_lite_model"] = codex_lite_model.duplicate(true)
		panel["content_cards"] = _codex_cards(codex_lite_model)
		model["content_cards"] = panel["content_cards"]
		var current_content: Dictionary = model.get("current_content_preview", {})
		current_content["cards"] = panel["content_cards"]
		model["current_content_preview"] = current_content
	model["placeholder_panel"] = panel
	return model


static func _overview_summary(modules: Array) -> Dictionary:
	return {
		"title": "长期系统档案",
		"state": "foundation",
		"module_count": modules.size(),
		"message": "当前展示目标、图鉴、研究、角色、抽奖和收藏外观入口。",
		"modules": [
			"目标",
			"图鉴",
			"研究",
			"个人资历",
			"抽奖",
			"收藏 / 外观",
		],
	}


static func _placeholder_panel(module: Dictionary, content_preview: Dictionary = {}) -> Dictionary:
	return {
		"title": module.get("title", ""),
		"state": module.get("state", &"preview"),
		"description": module.get("description", ""),
		"reason": module.get("reason", ""),
		"summary": (module.get("summary", {}) as Dictionary).duplicate(true),
		"child_preview_groups": (module.get("child_preview_groups", []) as Array).duplicate(true),
		"link_preview": (module.get("link_preview", {}) as Dictionary).duplicate(true),
		"next_stage_note": module.get("next_stage_note", ""),
		"content_preview": content_preview.duplicate(true),
		"secondary_groups": (content_preview.get("secondary_groups", []) as Array).duplicate(true),
		"content_cards": (content_preview.get("cards", []) as Array).duplicate(true),
		"detail_preview": (content_preview.get("detail_preview", {}) as Dictionary).duplicate(true),
		"cross_links_preview": (content_preview.get("cross_links_preview", []) as Array).duplicate(true),
		"event_slots_preview": (content_preview.get("event_slots_preview", []) as Array).duplicate(true),
		"event_flow_preview": (content_preview.get("event_flow_preview", {}) as Dictionary).duplicate(true),
		"reward_bundle_preview": (content_preview.get("reward_bundle_preview", {}) as Dictionary).duplicate(true),
		"red_dot_policy": (content_preview.get("red_dot_policy", {}) as Dictionary).duplicate(true),
		"jump_targets": (content_preview.get("jump_targets", []) as Array).duplicate(true),
		"asset_interface_preview": (content_preview.get("asset_interface_preview", {}) as Dictionary).duplicate(true),
		"art_slots_preview": (content_preview.get("art_slots_preview", []) as Array).duplicate(true),
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _history_preview_panel(snapshot: Dictionary) -> Dictionary:
	var timeline: Dictionary = snapshot.get("history_timeline_preview", {})
	var records: Array = timeline.get("records", [])
	var first_record: Dictionary = records[0] if not records.is_empty() and records[0] is Dictionary else {}
	return {
		"title": "个人资历 / 历史战绩",
		"state": "display_only",
		"summary": str(first_record.get("summary_line", "HistoryRecordSnapshot preview")),
		"result_type": first_record.get("result_type", &"success"),
		"history_card_icon_key": str(first_record.get("history_card_icon_key", "history.card.preview")),
		"art_placeholder_id": str(first_record.get("art_placeholder_id", "history_record_placeholder")),
		"future_data_ref": str(first_record.get("future_data_ref", "future.history.snapshot")),
		"data_source_ref": str(first_record.get("data_source_ref", "preview.settlement.history")),
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _profile_runtime_panel(meta_summary: Dictionary = {}, latest_result: Dictionary = {}) -> Dictionary:
	return {
		"title": "M2 MetaProgress / History consumer",
		"profile_level": maxi(1, int(meta_summary.get("profile_level", 1))),
		"profile_exp": maxi(0, int(meta_summary.get("profile_exp", 0))),
		"gold": int(meta_summary.get("gold", 0)),
		"long_term_gold": int(meta_summary.get("long_term_gold", meta_summary.get("gold", 0))),
		"run_count": int(meta_summary.get("run_count", 0)),
		"extract_count": int(meta_summary.get("extract_count", 0)),
		"fail_count": int(meta_summary.get("fail_count", 0)),
		"abandon_count": int(meta_summary.get("abandon_count", 0)),
		"history_record_count": int(meta_summary.get("history_record_count", 0)),
		"warehouse_items_count": int(meta_summary.get("warehouse_items_count", 0)),
		"latest_result_id": str(latest_result.get("result_id", "")),
		"latest_outcome": str(latest_result.get("outcome", "")),
		"titles": (meta_summary.get("titles", []) as Array).duplicate(),
		"badges": (meta_summary.get("badges", []) as Array).duplicate(),
		"boundary": "长期页读取已提交的结算历史与 M7 局外进度；研究和领奖通过独立事务写入，不重算结算。",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _m7_cards_by_group(meta: Dictionary) -> Dictionary:
	var result := {
		"goals/task": _goal_cards(meta, "task", meta.get("task_definitions", []), meta.get("task_states", {})),
		"goals/achievement": _goal_cards(meta, "achievement", meta.get("achievement_definitions", []), meta.get("achievement_states", {})),
		"goals/commission_record": _commission_cards(meta),
		"research/unlock_interface": _research_cards(meta),
		"research/research_entry": _research_cards(meta),
		"profile/milestone": _milestone_cards(meta),
		"profile/title": _simple_owned_cards(meta.get("titles", []), "称号"),
		"profile/badge": _simple_owned_cards(meta.get("badges", []), "徽章"),
		"collection_appearance/unique_display": _collection_cards(meta),
		"collection_appearance/display_content": _collection_cards(meta),
		"collection_appearance/badge_title": _simple_owned_cards((meta.get("titles", []) as Array) + (meta.get("badges", []) as Array), "资历展示"),
	}
	for group_id in [&"map", &"monster", &"collectible", &"equipment", &"consumable", &"event", &"rule", &"lore"]:
		result["codex/%s" % String(group_id)] = _codex_group_cards(meta, group_id)
	return result


static func _goal_cards(meta: Dictionary, goal_kind: String, definitions_value: Variant, states_value: Variant) -> Array[Dictionary]:
	var definitions: Array = definitions_value if definitions_value is Array else []
	var states: Dictionary = states_value if states_value is Dictionary else {}
	var cards: Array[Dictionary] = []
	for raw_definition in definitions:
		if not raw_definition is Dictionary:
			continue
		var definition: Dictionary = raw_definition
		var goal_id := str(definition.get("id", ""))
		var state: Dictionary = states.get(goal_id, {})
		var status := str(state.get("status", "locked"))
		var reward: Dictionary = definition.get("reward", {})
		var card := {
			"id": goal_id,
			"title": str(definition.get("display_name", goal_id)),
			"state": _goal_status_label(status),
			"description": "%s\n奖励：%s" % [str(definition.get("description", "")), _reward_text(reward)],
			"sort_order": _goal_sort_order(status),
		}
		if status == "claimable":
			card["action"] = {"action": &"claim_goal", "goal_kind": goal_kind, "goal_id": goal_id}
			card["action_label"] = "领取奖励"
		cards.append(card)
	cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("sort_order", 9)) < int(b.get("sort_order", 9)))
	return cards


static func _commission_cards(meta: Dictionary) -> Array[Dictionary]:
	var definitions := {}
	for definition in M7ContentCatalogScript.commission_definitions():
		definitions[str(definition.get("id", ""))] = definition
	var history: Array = meta.get("commission_history", [])
	var cards: Array[Dictionary] = []
	for reverse_index in range(history.size() - 1, maxi(-1, history.size() - 8), -1):
		var record: Dictionary = history[reverse_index] if history[reverse_index] is Dictionary else {}
		var commission_id := str(record.get("commission_id", ""))
		var definition: Dictionary = definitions.get(commission_id, {})
		cards.append({
			"id": "commission_record_%d" % reverse_index,
			"title": str(definition.get("display_name", commission_id)),
			"state": "已完成" if bool(record.get("completed", false)) else "未完成",
			"description": "地图：%s；结局：%s" % [str(record.get("map_id", "未知")), str(record.get("outcome", "未知"))],
		})
	if cards.is_empty():
		cards.append({"title": "暂无委托记录", "state": "完成探索后登记", "description": "每局委托结果会在终局结算后写入。"})
	return cards


static func _research_cards(meta: Dictionary) -> Array[Dictionary]:
	var completed: Array = meta.get("research_completed_ids", [])
	var gold := int(meta.get("gold", 0))
	var cards: Array[Dictionary] = []
	for definition in M7ContentCatalogScript.research_definitions():
		var research_id := str(definition.get("id", ""))
		var prerequisite := str(definition.get("prerequisite", ""))
		var is_completed := completed.has(research_id)
		var prerequisite_met := prerequisite == "" or completed.has(prerequisite)
		var material_name := str(definition.get("material_item_id", ""))
		var has_material := false
		for raw_item in meta.get("warehouse_items", []):
			var warehouse_item: Dictionary = raw_item if raw_item is Dictionary else {}
			if str(warehouse_item.get("item_id", "")) == material_name:
				has_material = true
				break
		var material_definition := M7ContentCatalogScript.item_definition(material_name)
		if not material_definition.is_empty():
			material_name = str(material_definition.get("display_name", material_name))
		var can_complete := prerequisite_met and gold >= int(definition.get("gold_cost", 0)) and has_material
		var state := "已完成" if is_completed else ("可研究" if can_complete else ("前置未完成" if not prerequisite_met else ("材料不足" if not has_material else "金币不足")))
		var card := {
			"id": research_id,
			"title": str(definition.get("display_name", research_id)),
			"state": state,
			"description": "消耗：%d 金币 + %s ×1（当前 %d 金币）\n效果：%s" % [int(definition.get("gold_cost", 0)), material_name, gold, str(definition.get("effect", ""))],
		}
		if not is_completed and can_complete:
			card["action"] = {"action": &"complete_research", "research_id": research_id}
			card["action_label"] = "确认消耗并研究"
		cards.append(card)
	return cards


static func _codex_group_cards(meta: Dictionary, group_id: StringName) -> Array[Dictionary]:
	var discovered: Array = meta.get("codex_discoveries", [])
	var cards: Array[Dictionary] = []
	for entry_id in M7ContentCatalogScript.all_codex_entry_ids():
		if _codex_group_for_entry(entry_id) != group_id:
			continue
		var known := discovered.has(entry_id)
		var unknown_title := "未知条目"
		if group_id == &"monster":
			unknown_title = "未发现怪物样本"
		elif group_id == &"collectible":
			unknown_title = "未发现藏品"
		cards.append({
			"id": entry_id,
			"title": _codex_entry_title(entry_id) if known else unknown_title,
			"state": "已发现" if known else "未发现",
			"description": "该条目已永久登记，出售或消耗对应物品不会抹除记录。" if known else "在探索、回收或研究中首次接触后登记。",
			"sort_order": 0 if known else 1,
		})
	cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("sort_order", 1)) < int(b.get("sort_order", 1)))
	return cards


static func _codex_group_for_entry(entry_id: String) -> StringName:
	if entry_id.begins_with("map:"):
		return &"map"
	if entry_id.begins_with("monster:"):
		return &"monster"
	if entry_id.begins_with("event:"):
		return &"event"
	if entry_id.begins_with("rule:"):
		return &"rule"
	if entry_id.begins_with("unique:"):
		return &"lore"
	if entry_id.begins_with("item:"):
		var definition := M7ContentCatalogScript.item_definition(entry_id.trim_prefix("item:"))
		match str(definition.get("item_type", "")):
			"collectible": return &"collectible"
			"equipment": return &"equipment"
			"consumable": return &"consumable"
		return &"lore"
	return &"lore"


static func _codex_entry_title(entry_id: String) -> String:
	var raw_id := entry_id.get_slice(":", 1)
	if entry_id.begins_with("map:"):
		return str(M7ContentCatalogScript.map_definition(raw_id).get("display_name", raw_id))
	if entry_id.begins_with("item:"):
		return str(M7ContentCatalogScript.item_definition(raw_id).get("display_name", raw_id))
	var known_names := {
		"slime": "史莱姆", "slimeling": "幼体史莱姆", "bat": "洞穴蝠", "drone": "废旧无人机",
		"trader": "旅商", "dice": "骰子局", "altar": "祭坛", "trap": "机关",
		"mines_and_movement": "雷房与移动", "extraction_right": "撤离权", "protocol_pressure": "协议压力",
		"backpack_and_salvage": "背包与抢救", "settlement_outcomes": "终局结算",
	}
	return str(known_names.get(raw_id, "未解读记录"))


static func _collection_cards(meta: Dictionary) -> Array[Dictionary]:
	var discovered: Array = meta.get("collection_discoveries", [])
	var completed: Array = meta.get("completed_collection_set_ids", [])
	var cards: Array[Dictionary] = []
	for definition in M7ContentCatalogScript.collection_sets():
		var item_ids: Array = definition.get("item_ids", [])
		var count := 0
		for item_id in item_ids:
			if discovered.has(str(item_id)):
				count += 1
		var set_id := str(definition.get("id", ""))
		cards.append({
			"id": set_id,
			"title": str(definition.get("display_name", set_id)),
			"state": "已完成" if completed.has(set_id) else "%d / %d" % [count, item_ids.size()],
			"description": "按曾经成功回收过的藏品累计；出售实体不会降低收集进度。",
		})
	return cards


static func _milestone_cards(meta: Dictionary) -> Array[Dictionary]:
	var exp_value := int(meta.get("profile_exp", 0))
	var cards: Array[Dictionary] = []
	for definition in M7ContentCatalogScript.profile_levels():
		var threshold := int(definition.get("exp", 0))
		cards.append({
			"title": "Lv.%d · %s" % [int(definition.get("level", 1)), str(definition.get("title", "回收员"))],
			"state": "已达成" if exp_value >= threshold else "还需 %d 经验" % (threshold - exp_value),
			"description": "资历经验阈值：%d。%s" % [threshold, "徽章：%s" % str(definition.get("badge", "")) if definition.has("badge") else ""],
		})
	return cards


static func _simple_owned_cards(values_value: Variant, empty_label: String) -> Array[Dictionary]:
	var values: Array = values_value if values_value is Array else []
	var cards: Array[Dictionary] = []
	for value in values:
		cards.append({"title": str(value), "state": "已获得", "description": "随资历进度永久登记。"})
	if cards.is_empty():
		cards.append({"title": "暂无%s" % empty_label, "state": "未获得", "description": "达到对应资历阈值后登记。"})
	return cards


static func _goal_sort_order(status: String) -> int:
	match status:
		"claimable": return 0
		"active": return 1
		"claimed": return 2
	return 3


static func _goal_status_label(status: String) -> String:
	match status:
		"claimable": return "可领取"
		"active": return "进行中"
		"claimed": return "已领取"
	return "未解锁"


static func _reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	if int(reward.get("gold", 0)) > 0:
		parts.append("%d 金币" % int(reward.get("gold", 0)))
	if int(reward.get("exp", 0)) > 0:
		parts.append("%d 经验" % int(reward.get("exp", 0)))
	for item_id in reward.get("items", []):
		var definition := M7ContentCatalogScript.item_definition(str(item_id))
		parts.append(str(definition.get("display_name", item_id)))
	return "、".join(parts) if not parts.is_empty() else "无"


static func _latest_run_result_summary(latest_result: Dictionary = {}) -> Dictionary:
	var run_result: Dictionary = latest_result.get("run_result", latest_result.get("RunResult", {}))
	return {
		"result_id": str(latest_result.get("result_id", "")),
		"outcome": str(latest_result.get("outcome", "")),
		"run_id": str(latest_result.get("run_id", run_result.get("run_id", ""))),
		"settlement_reads_run_result_only": bool(latest_result.get("settlement_reads_run_result_only", run_result.get("settlement_reads_run_result_only", true))),
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _codex_cards(codex_lite_model: Dictionary) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var discovered: Array = codex_lite_model.get("discovered_entries", [])
	for entry in discovered.slice(0, 12):
		if entry is Dictionary:
			var item: Dictionary = entry
			cards.append({
				"id": "codex_lite_%s" % str(item.get("codex_id", item.get("item_id", cards.size()))),
				"title": str(item.get("display_name", "Codex Entry")),
				"description": str(item.get("summary", "")),
				"state": "discovered",
				"codex_kind": _codex_kind(item),
				"group": "Codex Lite",
			})
	var undiscovered: Array = codex_lite_model.get("undiscovered_entries", [])
	for entry in undiscovered.slice(0, 12):
		if entry is Dictionary:
			var item: Dictionary = entry
			cards.append({
				"id": "codex_lite_unknown_%s" % str(item.get("codex_id", cards.size())),
				"title": str(item.get("display_name", "Unknown Entry")),
				"description": str(item.get("summary", "")),
				"state": "undiscovered",
				"codex_kind": _codex_kind(item),
				"group": "Codex Lite",
			})
	if cards.is_empty():
		cards.append({
			"id": "codex_lite_empty",
			"title": "No discovery yet",
			"description": "Recover collectibles or monster samples into warehouse_items to discover entries.",
			"state": "empty",
			"group": "Codex Lite",
		})
	return cards


static func _codex_kind(item: Dictionary) -> StringName:
	var tags: Array = item.get("tags", [])
	var source := StringName(item.get("source", &""))
	if source == &"monster" or tags.has("monster") or tags.has("sample") or tags.has("trophy"):
		return &"monster"
	return &"collectible"


static func _next_stage_notes(modules: Array) -> Array:
	var notes := []
	for module: Dictionary in modules:
		notes.append("%s: %s" % [str(module.get("title", "")), str(module.get("next_stage_note", ""))])
	return notes
