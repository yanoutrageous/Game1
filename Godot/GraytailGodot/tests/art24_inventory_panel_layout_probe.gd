extends SceneTree

const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const RunUIViewModelScript := preload("res://scripts/ui/shell/run_ui_view_model.gd")

const RESOLUTIONS := [
	&"1280x720",
	&"1366x768",
	&"1600x900",
	&"1920x1080",
	&"2560x1440",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var panel: InventoryPanel = InventoryPanelScript.new()
	for resolution_id: StringName in RESOLUTIONS:
		var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
		var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
		profile["actual_viewport_size"] = viewport_size
		var rect: Rect2 = panel.call("_main_game_modal_rect", profile, 0.0)
		var margin := 18.0 if bool(profile.get("is_low_resolution", false)) else 24.0
		var left_width := UILayerContractScript.run_left_width(profile)
		if rect.position.x < left_width + margin - 0.5:
			failures.append("%s drawer overlaps left rail: %s" % [resolution_id, rect])
		if rect.end.x > float(viewport_size.x) - margin + 0.5:
			failures.append("%s drawer escapes right safe edge: %s" % [resolution_id, rect])
		if rect.end.y > float(viewport_size.y) - (72.0 if bool(profile.get("is_low_resolution", false)) else 92.0) + 0.5:
			failures.append("%s drawer overlaps hotbar: %s" % [resolution_id, rect])
		if rect.size.x > 760.5 or rect.size.x < minf(500.0, float(viewport_size.x) - left_width - margin * 2.0) - 0.5:
			failures.append("%s drawer width outside budget: %.1f" % [resolution_id, rect.size.x])
		if rect.size.x > (float(viewport_size.x) - left_width - margin * 2.0) * 0.72:
			failures.append("%s drawer still dominates gameplay lane: %.1f" % [resolution_id, rect.size.x])
	var item := {
		"display_name": "温热条款",
		"item_type": &"collectible",
		"rarity": &"tier_4",
		"weight": 2,
		"base_value": 34,
		"collectible_level": 4,
		"tags": ["collectible", "level_4"],
	}
	var presentation: Dictionary = RunUIViewModelScript.item_presentation(item)
	var tooltip := RunUIViewModelScript.item_tooltip(item)
	if tooltip.contains("collectible") or tooltip.contains("level_4") or tooltip.contains("标签："):
		failures.append("raw item tags leaked into tooltip: %s" % tooltip)
	if String(presentation.get("type_label", "")) != "藏品":
		failures.append("player-facing item classification missing from shared descriptor: %s" % presentation)
	if not tooltip.contains("珍贵") or not tooltip.contains("收藏等级：4"):
		failures.append("player-facing rarity or collection level missing: %s" % tooltip)
	panel.free()
	if failures.is_empty():
		print("ART24_INVENTORY_PANEL_LAYOUT=PASS resolutions=5 rail=preserved hotbar=reserved")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(2)
