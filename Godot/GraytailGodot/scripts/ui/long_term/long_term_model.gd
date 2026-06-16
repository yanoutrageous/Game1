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
	return {
		"selected_module_id": StringName(current_module.get("id", LongTermTabModelScript.default_module_id())),
		"overview_summary": _overview_summary(modules),
		"modules": modules.duplicate(true),
		"current_module": current_module.duplicate(true),
		"placeholder_panel": _placeholder_panel(current_module),
		"snapshot_preview": snapshot.duplicate(true),
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


static func _next_stage_notes(modules: Array) -> Array:
	var notes := []
	for module: Dictionary in modules:
		notes.append("%s：%s" % [String(module.get("title", "")), String(module.get("next_stage_note", ""))])
	return notes
