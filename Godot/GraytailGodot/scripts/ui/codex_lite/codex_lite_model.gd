extends RefCounted
class_name CodexLiteModel

const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")


static func build(meta_summary: Dictionary = {}) -> Dictionary:
	var model := M3RItemUsabilityModelScript.build_codex_lite(meta_summary)
	model["ui_title"] = "Codex Lite"
	model["ui_summary"] = "Discoveries derived from warehouse_items."
	model["player_entry"] = "LongTerm codex module"
	model["no_persistence"] = true
	return model


static func summary_lines(model: Dictionary = {}) -> Array[String]:
	var lines: Array[String] = []
	lines.append("Discovered: %d" % int(model.get("discovered_count", 0)))
	lines.append("Visible entries: %d" % int(model.get("total_visible_count", 0)))
	var discovered: Array = model.get("discovered_entries", [])
	for entry in discovered.slice(0, 3):
		if entry is Dictionary:
			lines.append("- %s" % str((entry as Dictionary).get("display_name", "entry")))
	if discovered.is_empty():
		lines.append("- No discovered item yet")
	return lines
