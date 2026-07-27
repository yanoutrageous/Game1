extends SceneTree

const SkinKit := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const SettingsPanelScript := preload("res://scripts/ui/settings/settings_panel.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const WorldContextPopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")

const CAPTURE_SIZE := Vector2i(1600, 1200)


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = CAPTURE_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.gui_embed_subwindows = true

	var canvas := Control.new()
	canvas.size = Vector2(CAPTURE_SIZE)
	SkinKit.apply_player_ui_theme(canvas)
	root.add_child(canvas)

	var backdrop := ColorRect.new()
	backdrop.size = canvas.size
	backdrop.color = Color(0.012, 0.024, 0.027, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(backdrop)

	var settings := SettingsPanelScript.new() as PanelContainer
	canvas.add_child(settings)
	await process_frame
	settings.show()
	settings.position = Vector2(28, 28)
	settings.size = Vector2(610, maxf(470.0, settings.get_combined_minimum_size().y))
	var status := settings.get("status_label") as Label
	status.text = "FusionPixel 已作为玩家界面的统一默认字体；较少使用的缺字由 Noto 字形回退补齐。"
	var confirmation_box := settings.get("confirmation_box") as VBoxContainer
	var confirmation_label := settings.get("confirmation_label") as Label
	confirmation_label.text = "是否保留当前显示设置？倒计时结束前可以确认，也可以恢复原设置。"
	confirmation_box.show()

	var option_note := Label.new()
	option_note.position = Vector2(690, 126)
	option_note.size = Vector2(700, 34)
	option_note.text = "OptionButton 弹出列表：真实 PopupMenu 的 get_theme_font 已通过 FusionPixel 主字体断言。"
	option_note.add_theme_color_override(&"font_color", Color(0.70, 0.86, 0.80, 1.0))
	canvas.add_child(option_note)

	var native_tooltip := PopupPanel.new()
	native_tooltip.name = "NativeTooltipCapture"
	native_tooltip.theme = SkinKit.player_ui_theme()
	native_tooltip.theme_type_variation = &"TooltipPanel"
	native_tooltip.position = Vector2i(690, 32)
	native_tooltip.size = Vector2i(830, 76)
	native_tooltip.transient = false
	native_tooltip.exclusive = false
	canvas.add_child(native_tooltip)
	var native_tooltip_label := Label.new()
	native_tooltip_label.theme_type_variation = &"TooltipLabel"
	native_tooltip_label.text = "原生 TooltipLabel：所有提示文字继承 FusionPixel 主字体与共享像素边框；长中文完整显示，不覆盖相邻控件。"
	native_tooltip_label.custom_minimum_size = Vector2(790, 52)
	native_tooltip_label.size = Vector2(790, 52)
	native_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	native_tooltip_label.clip_text = false
	native_tooltip.add_child(native_tooltip_label)
	native_tooltip.show()
	await process_frame
	native_tooltip.position = Vector2i(690, 32)
	native_tooltip.size = Vector2i(830, 76)

	var world_popup := WorldContextPopupScript.new() as PanelContainer
	canvas.add_child(world_popup)
	await process_frame
	world_popup.set_process(false)
	world_popup.show()
	(world_popup.get("title_label") as Label).text = "附近物资箱"
	(world_popup.get("hint_label") as Label).text = "靠近后按交互键打开；界面保持在世界物体旁边，不遮挡角色与攻击判定区域。"
	(world_popup.get("primary_button") as Button).text = "打开物资箱"
	var world_status := world_popup.get("status_label") as Label
	world_status.text = "空间足够，可以直接拾取。"
	world_status.show()
	await process_frame
	world_popup.size = world_popup.get_combined_minimum_size()
	world_popup.position = Vector2(1120, 172)

	var inventory := InventoryPanelScript.new() as PanelContainer
	canvas.add_child(inventory)
	await process_frame
	inventory.position = Vector2(690, 380)
	inventory.size = Vector2(860, 554)
	inventory.call("apply_snapshot", {
		"inventory_items": [{
			"instance_id": "font_capture_item",
			"item_id": "sealed_observation_compass",
			"display_name": "密封观测罗盘",
			"rarity": &"tier_5",
			"weight": 3,
			"quantity": 1,
			"short_description": "罗盘记录穿过的回廊与异常回声；真实物品详情完整留在像素边框的安全内容区内。",
			"can_consume": false,
		}],
		"equipped_items": [],
		"backpack_used": 3,
		"backpack_capacity": 12,
		"black_coin": 4,
		"gold_coin": 28,
	})
	inventory.show()
	var item_button := inventory.find_child("InventoryItemButton", true, false) as Button
	if item_button != null:
		item_button.mouse_entered.emit()
	for _index in range(4):
		await process_frame

	var item_detail := inventory.get("tooltip_label") as Label
	if item_detail == null or not item_detail.text.contains("罗盘记录"):
		_fail("真实 InventoryPanel hover 详情未出现")
		return
	var detail_scroll := inventory.get("detail_scroll") as ScrollContainer
	if detail_scroll == null or detail_scroll.size.y + 0.01 < item_detail.size.y:
		_fail("真实物品详情滚动视口未完整容纳当前长中文: scroll=%s label=%s" % [
			detail_scroll.size if detail_scroll != null else Vector2.ZERO,
			item_detail.size,
		])
		return
	print(
		"I3R_CAPTURE_DETAIL_METRICS visible=%s label=%s scroll=%s text=%s color=%s" % [
			item_detail.is_visible_in_tree(),
			item_detail.get_global_rect(),
			detail_scroll.get_global_rect() if detail_scroll != null else Rect2(),
			item_detail.text,
			item_detail.get_theme_color(&"font_color"),
		]
	)
	var regions := {
		"settings": settings.get_global_rect(),
		"tooltip": Rect2(Vector2(native_tooltip.position), Vector2(native_tooltip.size)),
		"world": world_popup.get_global_rect(),
		"inventory": inventory.get_global_rect(),
	}
	if not _regions_are_separate(regions):
		return
	var detail_rect := item_detail.get_global_rect()
	if detail_rect.position.x < 0.0 or detail_rect.position.y < 0.0 or detail_rect.end.x > CAPTURE_SIZE.x or detail_rect.end.y > CAPTURE_SIZE.y:
		_fail("真实物品详情超出画布: %s" % detail_rect)
		return

	for _index in range(6):
		await process_frame
	var output := _output_path()
	var image := root.get_texture().get_image()
	if image == null:
		_fail("渲染器未返回截图")
		return
	var result := image.save_png(output)
	if result != OK:
		_fail("保存截图失败: %s" % error_string(result))
		return
	print("I3R_UI_FONT_CAPTURE=PASS output=%s detail=%s regions=%s" % [output, detail_rect, regions])
	quit(0)


func _regions_are_separate(regions: Dictionary) -> bool:
	var names := regions.keys()
	for left_index in range(names.size()):
		for right_index in range(left_index + 1, names.size()):
			var left_name := String(names[left_index])
			var right_name := String(names[right_index])
			var left_rect := regions[left_name] as Rect2
			var right_rect := regions[right_name] as Rect2
			if left_rect.intersects(right_rect):
				_fail("截图区域重叠: %s=%s %s=%s" % [left_name, left_rect, right_name, right_rect])
				return false
	return true


func _fail(message: String) -> void:
	push_error("I3R UI font capture: " + message)
	quit(2)


func _output_path() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			return argument.trim_prefix("--output=")
	return "res://i3r_ui_font_capture.png"
