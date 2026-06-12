extends PanelContainer
class_name InventoryPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")

signal drop_item_requested(instance_id: String)
signal close_requested

var title_label: Label
var summary_label: Label
var item_list: VBoxContainer
var tooltip_label: Label
var last_result_label: Label


func _ready() -> void:
	build()


func build() -> void:
	name = "InventoryPanel"
	visible = false
	offset_left = 390.0
	offset_top = 98.0
	offset_right = 930.0
	offset_bottom = 610.0
	if get_child_count() > 0:
		return
	var root := VBoxContainer.new()
	root.name = "InventoryPanelContent"
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	header.name = "InventoryPanelHeader"
	root.add_child(header)
	title_label = Label.new()
	title_label.name = "InventoryPanelTitle"
	title_label.text = "背包"
	title_label.add_theme_font_size_override("font_size", 20)
	header.add_child(title_label)
	var close_button := Button.new()
	close_button.name = "InventoryCloseButton"
	close_button.text = "关闭"
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)

	summary_label = Label.new()
	summary_label.name = "InventorySummary"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(summary_label)

	item_list = VBoxContainer.new()
	item_list.name = "InventoryItemList"
	item_list.custom_minimum_size = Vector2(500, 210)
	root.add_child(item_list)

	tooltip_label = Label.new()
	tooltip_label.name = "InventoryItemTooltip"
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.custom_minimum_size = Vector2(500, 120)
	root.add_child(tooltip_label)

	last_result_label = Label.new()
	last_result_label.name = "InventoryCommandResult"
	last_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(last_result_label)


func apply_snapshot(snapshot: Dictionary) -> void:
	if summary_label == null:
		build()
	var inventory_items: Array = _array_from(snapshot, "inventory_items")
	var equipped_items: Array = _array_from(snapshot, "equipped_items")
	summary_label.text = "容量：%s/%s | 黑币：%s | 金币：%s | 背包物品：%s | 已装备：%s" % [
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		snapshot.get("black_coin", 0),
		snapshot.get("gold_coin", 0),
		inventory_items.size(),
		equipped_items.size(),
	]
	for child in item_list.get_children():
		child.queue_free()
	if inventory_items.is_empty() and equipped_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "背包为空。搜索、宝箱、怪物或事件奖励可生成物品。"
		item_list.add_child(empty_label)
	else:
		for item: Dictionary in inventory_items:
			_add_item_row(item, true)
		for item: Dictionary in equipped_items:
			_add_item_row(item, false)
	if tooltip_label != null:
		tooltip_label.text = "选择物品可查看说明。已装备物品默认不占容量；G9 不实现完整装备 UI。"


func show_command_result(result: Dictionary) -> void:
	if last_result_label == null:
		return
	last_result_label.text = RunUIViewModel.command_result_text(result)


func show_panel() -> void:
	visible = true


func hide_panel() -> void:
	visible = false


func apply_layout_profile(profile: Dictionary) -> void:
	var profile_id: StringName = StringName(profile.get("profile_id", &"desktop"))
	if profile_id == &"narrow":
		offset_left = 20.0
		offset_top = 88.0
		offset_right = 600.0
		offset_bottom = 650.0
	else:
		offset_left = 390.0
		offset_top = 98.0
		offset_right = 930.0
		offset_bottom = 610.0


func _add_item_row(item: Dictionary, can_drop: bool) -> void:
	var row := HBoxContainer.new()
	row.name = "InventoryItemRow"
	item_list.add_child(row)
	var item_button := Button.new()
	item_button.name = "InventoryItemButton"
	item_button.text = RunUIViewModel.item_display_line(item)
	item_button.custom_minimum_size = Vector2(380, 30)
	item_button.pressed.connect(func() -> void: tooltip_label.text = RunUIViewModel.item_tooltip(item))
	row.add_child(item_button)
	var drop_button := Button.new()
	drop_button.name = "InventoryDropButton"
	drop_button.text = "丢弃"
	drop_button.disabled = not can_drop
	var instance_id: String = String(item.get("instance_id", ""))
	drop_button.pressed.connect(func() -> void: drop_item_requested.emit(instance_id))
	row.add_child(drop_button)


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []
