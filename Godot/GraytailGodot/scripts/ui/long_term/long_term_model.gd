extends RefCounted
class_name LongTermModel

const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const LongTermSnapshotScript := preload("res://scripts/ui/long_term/long_term_snapshot.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")
const CodexLiteModelScript := preload("res://scripts/ui/codex_lite/codex_lite_model.gd")


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
	model["codex_lite_model"] = codex_lite_model.duplicate(true)
	model["latest_run_result_summary"] = _latest_run_result_summary(latest_result)
	model["profile_runtime_panel"] = profile_runtime_panel
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
		"title": "闀挎湡绯荤粺鍐呭妗嗘灦",
		"state": "foundation",
		"module_count": modules.size(),
		"message": "LongTerm keeps six primary modules, with secondary groups, cards, slots, and art/data keys. M3R upgrades the Codex module to consume Codex Lite from real warehouse_items.",
		"modules": [
			"鐩爣",
			"鍥鹃壌",
			"鐮旂┒",
			"涓汉璧勫巻",
			"鎶藉",
			"鏀惰棌 / 澶栬",
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
		"title": "涓汉璧勫巻 / 鍘嗗彶鎴樼哗 preview",
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
		"gold": int(meta_summary.get("gold", 0)),
		"run_count": int(meta_summary.get("run_count", 0)),
		"extract_count": int(meta_summary.get("extract_count", 0)),
		"fail_count": int(meta_summary.get("fail_count", 0)),
		"warehouse_items_count": int(meta_summary.get("warehouse_items_count", 0)),
		"latest_result_id": str(latest_result.get("result_id", "")),
		"latest_outcome": str(latest_result.get("outcome", "")),
		"boundary": "LongTerm consumes MetaProgress summary and latest RunResult display-only; it does not write history, rewards, objectives, assets, or save data.",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


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
	for entry in discovered.slice(0, 6):
		if entry is Dictionary:
			var item: Dictionary = entry
			cards.append({
				"id": "codex_lite_%s" % str(item.get("codex_id", item.get("item_id", cards.size()))),
				"title": str(item.get("display_name", "Codex Entry")),
				"description": str(item.get("summary", "")),
				"state": "discovered",
				"group": "Codex Lite",
			})
	var undiscovered: Array = codex_lite_model.get("undiscovered_entries", [])
	for entry in undiscovered.slice(0, maxi(0, 6 - cards.size())):
		if entry is Dictionary:
			var item: Dictionary = entry
			cards.append({
				"id": "codex_lite_unknown_%s" % str(item.get("codex_id", cards.size())),
				"title": str(item.get("display_name", "Unknown Entry")),
				"description": str(item.get("summary", "")),
				"state": "undiscovered",
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


static func _next_stage_notes(modules: Array) -> Array:
	var notes := []
	for module: Dictionary in modules:
		notes.append("%s: %s" % [str(module.get("title", "")), str(module.get("next_stage_note", ""))])
	return notes
