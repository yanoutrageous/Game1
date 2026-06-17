extends RefCounted
class_name LongTermModel

const LongTermSnapshotScript := preload("res://scripts/ui/long_term/long_term_snapshot.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")


static func build(selected_module_id: StringName = &"goals", source: StringName = &"long_term_shell") -> Dictionary:
	var modules: Array = LongTermTabModelScript.build_modules()
	var safe_module_id := selected_module_id
	if safe_module_id == &"":
		safe_module_id = LongTermTabModelScript.default_module_id()
	var current_module: Dictionary = LongTermTabModelScript.find_module(modules, safe_module_id)
	var module_summaries: Dictionary = LongTermTabModelScript.module_summaries(modules)
	var snapshot: Dictionary = LongTermSnapshotScript.default_snapshot(module_summaries, source)
	var placeholder_panel := _placeholder_panel(current_module)
	var history_preview_panel := _history_preview_panel(snapshot)
	if StringName(current_module.get("id", &"")) == &"profile":
		placeholder_panel["history_preview"] = history_preview_panel.duplicate(true)
	return {
		"selected_module_id": StringName(current_module.get("id", LongTermTabModelScript.default_module_id())),
		"overview_summary": _overview_summary(modules),
		"modules": modules.duplicate(true),
		"current_module": current_module.duplicate(true),
		"placeholder_panel": placeholder_panel,
		"snapshot_preview": snapshot.duplicate(true),
		"history_preview_panel": history_preview_panel,
		"disabled_reason": String(current_module.get("reason", "")) if StringName(current_module.get("state", &"")) == LongTermTabModelScript.STATE_DISABLED else "",
		"next_stage_notes": _next_stage_notes(modules),
	}


static func _overview_summary(modules: Array) -> Dictionary:
	return {
		"title": "长期系统壳层",
		"state": "foundation",
		"module_count": modules.size(),
		"message": "G19 固定为六个一级模块，只展示 placeholder / preview / disabled 状态。",
		"modules": [
			"目标",
			"图鉴",
			"研究",
			"个人资历",
			"抽奖",
			"收藏 / 外观",
		],
	}


static func _placeholder_panel(module: Dictionary) -> Dictionary:
	return {
		"title": module.get("title", ""),
		"state": module.get("state", &"preview"),
		"description": module.get("description", ""),
		"reason": module.get("reason", ""),
		"summary": (module.get("summary", {}) as Dictionary).duplicate(true),
		"child_preview_groups": (module.get("child_preview_groups", []) as Array).duplicate(true),
		"link_preview": (module.get("link_preview", {}) as Dictionary).duplicate(true),
		"next_stage_note": module.get("next_stage_note", ""),
	}


static func _history_preview_panel(snapshot: Dictionary) -> Dictionary:
	var timeline: Dictionary = snapshot.get("history_timeline_preview", {})
	var records: Array = timeline.get("records", [])
	var first_record: Dictionary = records[0] if not records.is_empty() and records[0] is Dictionary else {}
	return {
		"title": "个人资历 / 历史战绩 preview",
		"state": "display_only",
		"summary": String(first_record.get("summary_line", "HistoryRecordSnapshot preview")),
		"result_type": first_record.get("result_type", &"success"),
		"history_card_icon_key": String(first_record.get("history_card_icon_key", "history.card.preview")),
		"art_placeholder_id": String(first_record.get("art_placeholder_id", "history_record_placeholder")),
		"future_data_ref": String(first_record.get("future_data_ref", "future.history.snapshot")),
		"data_source_ref": String(first_record.get("data_source_ref", "preview.settlement.history")),
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _next_stage_notes(modules: Array) -> Array:
	var notes := []
	for module: Dictionary in modules:
		notes.append("%s：%s" % [String(module.get("title", "")), String(module.get("next_stage_note", ""))])
	return notes
