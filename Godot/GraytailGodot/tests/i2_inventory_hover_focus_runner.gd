extends SceneTree

const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const GroundLootPanelScript := preload("res://scripts/ui/ground_loot/ground_loot_panel.gd")
const ItemRarityDescriptorScript := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

const PASS_MARKER := "I2_INVENTORY_HOVER_FOCUS=PASS"
const FAIL_MARKER := "I2_INVENTORY_HOVER_FOCUS=FAIL"

var failures: Array[String] = []
var inventory_drop_count := 0
var inventory_use_count := 0
var ground_pickup_count := 0
var ground_replace_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var item := _sample_item()

	var inventory = InventoryPanelScript.new()
	host.add_child(inventory)
	inventory.drop_item_requested.connect(_on_inventory_drop)
	inventory.use_item_requested.connect(_on_inventory_use)
	inventory.apply_layout_profile(_profile())
	inventory.apply_snapshot(_inventory_snapshot([item]))
	inventory.show_panel()
	await _frames(3)
	var inventory_item := inventory.find_child("InventoryItemButton", true, false) as Button
	var inventory_drop := inventory.find_child("InventoryDropButton", true, false) as Button
	var inventory_use := inventory.find_child("InventoryUseButton", true, false) as Button
	_require(inventory_item != null and inventory_drop != null and inventory_use != null, "inventory item actions are missing")
	if inventory_item != null:
		inventory_item.mouse_entered.emit()
		await process_frame
		_assert_detail(inventory.get("tooltip_label") as Label, "inventory hover")
		_require(inventory_drop_count == 0 and inventory_use_count == 0, "inventory hover emitted an action")
		inventory_item.grab_focus()
		await process_frame
		_assert_detail(inventory.get("tooltip_label") as Label, "inventory focus")
		_require(inventory_drop_count == 0 and inventory_use_count == 0, "inventory focus emitted an action")
		_require(String(inventory_item.get_meta("rarity_display_text", "")) == "[T6] 秘藏", "inventory rarity metadata drifted")
		_require(String(inventory_item.get_meta("rarity_border_token", "")) != "", "inventory rarity border token is missing")
		_assert_rarity_marker(inventory_item, "InventoryItemRarityMarker", item, "inventory")
	if inventory_use != null:
		inventory_use.grab_focus()
		inventory.apply_snapshot(_inventory_snapshot([item]))
		await _frames(2)
		_assert_inventory_focus(inventory, "i2_hover_focus_instance", &"use", "use action snapshot rebuild")
	inventory_drop = inventory.find_child("InventoryDropButton", true, false) as Button
	if inventory_drop != null:
		inventory_drop.grab_focus()
		inventory.apply_snapshot(_inventory_snapshot([item]))
		await _frames(2)
		_assert_inventory_focus(inventory, "i2_hover_focus_instance", &"drop", "drop action snapshot rebuild")
		inventory.apply_snapshot(_inventory_snapshot([]))
		await _frames(2)
		var fallback_focus := inventory.get_viewport().gui_get_focus_owner()
		_require(fallback_focus == inventory.get("close_button"), "removed item did not fall back to the inventory preferred focus")
	inventory.apply_snapshot(_inventory_snapshot([item]))
	await _frames(2)
	inventory_use = inventory.find_child("InventoryUseButton", true, false) as Button
	inventory_drop = inventory.find_child("InventoryDropButton", true, false) as Button
	if inventory_use != null:
		inventory_use.pressed.emit()
	if inventory_drop != null:
		inventory_drop.pressed.emit()
	_require(inventory_use_count == 1 and inventory_drop_count == 1, "inventory explicit actions did not emit exactly once")
	inventory.show_command_result({"ok": true, "accepted": true})
	_require(not String((inventory.get("last_result_label") as Label).text).contains("操作完成"), "inventory leaked engineering success copy")
	_assert_detail_scroll(inventory.get("detail_scroll") as ScrollContainer, inventory.get("tooltip_label") as Label, "inventory")

	var ground = GroundLootPanelScript.new()
	host.add_child(ground)
	ground.pickup_item_requested.connect(_on_ground_pickup)
	ground.replace_item_requested.connect(_on_ground_replace)
	ground.apply_layout_profile(_profile())
	ground.apply_snapshot({
		"room_floor_items": [item],
		"backpack_used": 4,
		"backpack_capacity": 12,
		"backpack_remaining": 8,
	})
	ground.show_panel()
	await _frames(3)
	var ground_item := ground.find_child("GroundLootItemButton", true, false) as Button
	var pickup := ground.find_child("GroundLootPickupButton", true, false) as Button
	var replace := ground.find_child("GroundLootReplaceButton", true, false) as Button
	_require(ground_item != null and pickup != null and replace != null, "ground-loot item actions are missing")
	if ground_item != null:
		ground_item.mouse_entered.emit()
		await process_frame
		_assert_detail(ground.get("tooltip_label") as Label, "ground hover")
		ground_item.grab_focus()
		await process_frame
		_assert_detail(ground.get("tooltip_label") as Label, "ground focus")
		_require(ground_pickup_count == 0 and ground_replace_count == 0, "ground hover/focus emitted an action")
		_assert_rarity_marker(ground_item, "GroundLootItemRarityMarker", item, "ground")
	if pickup != null:
		pickup.pressed.emit()
	if replace != null:
		replace.pressed.emit()
	_require(ground_pickup_count == 1 and ground_replace_count == 1, "ground explicit actions did not emit exactly once")
	ground.show_command_result({"ok": false, "accepted": false, "reason": &"blocked_capacity"})
	var ground_result := ground.get("last_result_label") as Label
	_require(ground_result != null and ground_result.text.contains("无法执行"), "ground blocked result is not player-facing")
	_require(ground_result == null or not ground_result.text.contains("command"), "ground result leaked command copy")
	_assert_detail_scroll(ground.get("detail_scroll") as ScrollContainer, ground.get("tooltip_label") as Label, "ground")

	host.queue_free()
	await _frames(3)
	_finish()


func _sample_item() -> Dictionary:
	return {
		"instance_id": "i2_hover_focus_instance",
		"item_id": "raw_internal_item_id",
		"display_name": "沉星罗盘",
		"rarity": &"tier_6",
		"weight": 4,
		"quantity": 3,
		"collectible_level": 6,
		"short_description": "指针会记录穿过的回廊与回声。".repeat(10),
		"can_consume": true,
	}


func _inventory_snapshot(items: Array) -> Dictionary:
	return {
		"inventory_items": items,
		"equipped_items": [],
		"backpack_used": 4 if not items.is_empty() else 0,
		"backpack_capacity": 12,
	}


func _profile() -> Dictionary:
	var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(&"1280x720")
	profile["actual_viewport_size"] = Vector2i(1280, 720)
	return profile


func _assert_detail(label: Label, context: String) -> void:
	_require(label != null, "%s detail label is missing" % context)
	if label == null:
		return
	var text := label.text
	for expected: String in ["沉星罗盘", "[T6] 秘藏", "重量：4", "数量：3", "指针会记录"]:
		_require(text.contains(expected), "%s detail is missing %s" % [context, expected])
	var first_lines := text.split("\n").slice(0, 3)
	_require("\n".join(first_lines).contains("收藏等级：6"), "%s first three detail lines omitted collectible level" % context)
	for forbidden: String in ["tier_6", "raw_internal_item_id", "选择物品", "操作完成"]:
		_require(not text.contains(forbidden), "%s leaked %s" % [context, forbidden])


func _assert_rarity_marker(button: Button, marker_name: String, item: Dictionary, context: String) -> void:
	_require(button.get_theme_stylebox(&"normal") is StyleBoxTexture, "%s fixture did not exercise the production texture-backed row" % context)
	var marker := button.find_child(marker_name, false, false) as ColorRect
	_require(marker != null, "%s texture-backed row omitted its independent rarity marker" % context)
	if marker == null:
		return
	var expected_color: Color = ItemRarityDescriptorScript.describe_item(item).get("color", Color.TRANSPARENT)
	_require(marker.color.is_equal_approx(expected_color), "%s rarity marker color drifted from the shared descriptor" % context)
	_require(marker.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s rarity marker intercepted item input" % context)
	_require(marker.anchor_bottom == 1.0 and marker.offset_right - marker.offset_left >= 4.0, "%s rarity marker is not a visible vertical strip" % context)
	_require(marker.is_visible_in_tree() and marker.size.x >= 4.0 and marker.size.y >= 16.0, "%s rarity marker has no visible runtime footprint" % context)


func _assert_detail_scroll(scroll: ScrollContainer, label: Label, context: String) -> void:
	_require(scroll != null, "%s long detail scroll is missing" % context)
	_require(label != null and label.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s detail does not wrap" % context)
	_require(label != null and not label.clip_text, "%s detail remains clipped" % context)


func _assert_inventory_focus(inventory: Control, instance_id: String, item_action: StringName, context: String) -> void:
	var focus_owner := inventory.get_viewport().gui_get_focus_owner()
	_require(focus_owner != null and inventory.is_ancestor_of(focus_owner), "%s did not keep focus inside inventory" % context)
	if focus_owner == null:
		return
	_require(String(focus_owner.get_meta("item_instance_id", "")) == instance_id, "%s did not restore the stable item instance" % context)
	_require(StringName(focus_owner.get_meta("item_action", &"")) == item_action, "%s did not restore the item action" % context)


func _on_inventory_drop(_instance_id: String) -> void:
	inventory_drop_count += 1


func _on_inventory_use(_instance_id: String) -> void:
	inventory_use_count += 1


func _on_ground_pickup(_instance_id: String) -> void:
	ground_pickup_count += 1


func _on_ground_replace(_instance_id: String) -> void:
	ground_replace_count += 1


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s surfaces=2 hover_commands=0 focus_commands=0 actions=4 snapshot_focus=stable_item_action fallback=preferred rarity_marker=independent collectible_level=authoritative" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I2 inventory hover/focus failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
