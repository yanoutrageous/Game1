extends RefCounted
class_name WarehouseLiteModel

const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")


static func build(meta_summary: Dictionary = {}) -> Dictionary:
	var model := M3RItemUsabilityModelScript.build_warehouse_lite(meta_summary)
	model["ui_title"] = "Warehouse Lite"
	model["ui_summary"] = "Real stored items from MetaProgress warehouse_items."
	model["player_entry"] = "DeployPrep warehouse tab"
	model["no_persistence"] = true
	return model


static func summary_lines(model: Dictionary = {}) -> Array[String]:
	var lines: Array[String] = []
	var group_counts: Dictionary = model.get("group_counts", {})
	lines.append("Items: %d" % int(model.get("item_count", 0)))
	lines.append("Equipment %d / Consumable %d" % [
		int(group_counts.get("equipment", 0)),
		int(group_counts.get("consumable", 0)),
	])
	lines.append("Collectible %d / Special %d" % [
		int(group_counts.get("collectible", 0)),
		int(group_counts.get("special", 0)),
	])
	var selected_equipment: Array = model.get("selected_equipment", [])
	var selected_consumables: Array = model.get("selected_consumables", [])
	lines.append("Selected equipment: %d" % selected_equipment.size())
	lines.append("Selected consumables: %d" % selected_consumables.size())
	return lines
