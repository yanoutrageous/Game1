extends Control
class_name ResultPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const ReadableFont := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const LEGACY_RESULT_VALIDATION_MARKERS := ["Outcome:", "Mode:", "Moves:", "Mine Hits:", "Monsters Defeated:", "Failure Pending Lost:", "Failure Salvaged Items:", "Carried Items:", "Carried Value:", "Safe Gold:", "Final HP:", "Final Pressure:", "Black Coin:", "Gold Coin:", "Warehouse Lite Items:", "Room Floor Lost:", "Settlement Log Entries:"]
const RESULT_BANNER_ASSET_BY_STATE := {
	&"success": &"ui.art24.ui.result_banner.success",
	&"failure": &"ui.art24.ui.result_banner.failure",
	&"failed": &"ui.art24.ui.result_banner.failure",
	&"abandon": &"ui.art24.ui.result_banner.abandoned",
	&"abandoned": &"ui.art24.ui.result_banner.abandoned",
}
const RESULT_BANNER_FALLBACK_ASSET := &"ui.art21.shared.panel.card.normal"

signal return_main_requested
signal return_deploy_requested
signal failure_salvage_confirmed(selected_instance_ids: Array)
signal retry_save_requested
signal discard_unsaved_result_requested

var result_title_art: TextureRect
var result_modal_art: NinePatchRect
var result_summary_art: NinePatchRect
var result_actions_art: NinePatchRect
var result_metrics_row: HBoxContainer
var result_metric_title_labels: Array[Label] = []
var result_metric_value_labels: Array[Label] = []
var result_items_scroll: ScrollContainer
var result_item_sections_box: VBoxContainer
var persistence_label: Label
var return_deploy_button: Button
var return_main_button: Button
var retry_save_button: Button
var discard_unsaved_button: Button
var salvage_panel: PanelContainer
var salvage_reason_label: Label
var salvage_consequence_label: Label
var salvage_capacity_label: Label
var salvage_candidates_box: VBoxContainer
var salvage_confirm_button: Button
var salvage_candidate_buttons: Dictionary = {}
var selected_salvage_ids: Array[String] = []
var salvage_capacity: int = 0
var salvage_has_candidates: bool = false
var current_layout_profile: Dictionary = {}
var current_result_model: Dictionary = {}
var discard_unsaved_confirmation_step: int = 0


func _ready() -> void:
	_ensure_backdrop()
	_ensure_actions()


func set_result_summary(title: String, summary: String) -> void:
	var title_node := get_node_or_null("ResultTitle") as Label
	var summary_node := get_node_or_null("ResultSummary") as Label

	if title_node != null:
		title_node.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		title_node.z_index = 4
		title_node.visible = true
		title_node.text = title

	if summary_node != null:
		summary_node.add_theme_font_override("font", ReadableFont)
		summary_node.add_theme_color_override("font_color", PresentationTheme.text_color())
		summary_node.add_theme_font_size_override("font_size", 13)
		summary_node.add_theme_constant_override("line_spacing", 2)
		summary_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_node.clip_text = true
		summary_node.z_index = 4
		summary_node.text = summary


func show_summary(snapshot: Dictionary) -> void:
	# G9 final consumes event_log, transaction_log, failure_salvage,
	# salvaged_item_count, settlement_log, and currency/item movement data.
	var model: Dictionary = RunUIViewModel.result_summary(snapshot)
	current_result_model = model.duplicate(true)
	set_result_summary(String(model.get("title", "结算")), String(model.get("summary", "")))
	_apply_result_title_plate(_result_state_from_snapshot(snapshot))
	_configure_result_metrics(model)
	_configure_result_item_sections(model)
	_configure_persistence_actions(model)
	_configure_failure_salvage(snapshot)
	visible = true
	Art10UISkinKitScript.play_panel_open(self)


func hide_result() -> void:
	visible = false
	selected_salvage_ids.clear()
	salvage_has_candidates = false
	current_result_model.clear()
	reset_discard_unsaved_confirmation()


func _ensure_backdrop() -> void:
	var backdrop := get_node_or_null("Backdrop") as ColorRect
	if backdrop == null:
		backdrop = ColorRect.new()
		backdrop.name = "Backdrop"
		backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(backdrop)
		move_child(backdrop, 0)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.66)
	backdrop.visible = true
	backdrop.z_index = 0
	result_modal_art = get_node_or_null("ResultModalFrame") as NinePatchRect
	if result_modal_art == null:
		var legacy_modal := get_node_or_null("ResultModalFrame") as TextureRect
		if legacy_modal != null:
			legacy_modal.name = "ResultModalFrameLegacy"
			legacy_modal.visible = false
		result_modal_art = NinePatchRect.new()
		result_modal_art.name = "ResultModalFrame"
		result_modal_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_modal_art.modulate = Color(1.0, 1.0, 1.0, 0.96)
		result_modal_art.patch_margin_left = 38
		result_modal_art.patch_margin_top = 38
		result_modal_art.patch_margin_right = 38
		result_modal_art.patch_margin_bottom = 38
		result_modal_art.draw_center = true
		add_child(result_modal_art)
	result_modal_art.z_index = 1
	var modal_texture := Art21UIPlacementContractScript.texture_for_slot(&"result", &"result_modal_frame", &"ui.art19.panel.terminal_main")
	if modal_texture != null:
		result_modal_art.texture = modal_texture
	result_summary_art = _ensure_modal_patch(&"ResultSummaryPanelArt", &"art21r2.modal.section.panel", 32, 0.96)
	# The legacy action-strip bitmap contains three painted slots. Result pages
	# expose exactly two real actions, so use a continuous framed section and
	# let the live buttons define the count instead of leaving a fake empty slot.
	result_actions_art = _ensure_modal_patch(&"ResultActionStripArt", &"art21r2.modal.section.panel", 32, 0.96)
	_ensure_result_metrics()
	_ensure_result_items()
	result_title_art = get_node_or_null("ResultTitlePlate") as TextureRect
	if result_title_art == null:
		result_title_art = TextureRect.new()
		result_title_art.name = "ResultTitlePlate"
		result_title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# UE stretches the state brush into its 300x130 banner slot. Keeping the
		# 260x147 source aspect made the visible title only ~212 px wide and left
		# an unintended empty band on both sides of the report.
		result_title_art.stretch_mode = TextureRect.STRETCH_SCALE
		result_title_art.modulate = Color(1.0, 1.0, 1.0, 0.94)
		add_child(result_title_art)
	result_title_art.z_index = 1
	var title_node := get_node_or_null("ResultTitle") as Label
	if title_node != null:
		title_node.z_index = 4
	var summary_node := get_node_or_null("ResultSummary") as Label
	if summary_node != null:
		summary_node.z_index = 4


func _ensure_result_metrics() -> void:
	if result_metrics_row != null:
		return
	result_metrics_row = HBoxContainer.new()
	result_metrics_row.name = "ResultMetricsRow"
	result_metrics_row.add_theme_constant_override("separation", 8)
	result_metrics_row.z_index = 4
	add_child(result_metrics_row)
	for index in range(3):
		var card := PanelContainer.new()
		card.name = "ResultMetricCard%d" % index
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.016, 0.043, 0.046, 0.94)
		card_style.border_color = Color(0.20, 0.50, 0.46, 0.78)
		card_style.border_width_left = 1
		card_style.border_width_top = 1
		card_style.border_width_right = 1
		card_style.border_width_bottom = 1
		card_style.content_margin_left = 8
		card_style.content_margin_top = 6
		card_style.content_margin_right = 8
		card_style.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", card_style)
		result_metrics_row.add_child(card)
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation", 1)
		card.add_child(stack)
		var metric_title := Label.new()
		metric_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		metric_title.add_theme_font_override("font", ReadableFont)
		metric_title.add_theme_font_size_override("font_size", 13)
		metric_title.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		stack.add_child(metric_title)
		result_metric_title_labels.append(metric_title)
		var metric_value := Label.new()
		metric_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		metric_value.add_theme_font_override("font", ReadableFont)
		metric_value.add_theme_font_size_override("font_size", 20)
		metric_value.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		stack.add_child(metric_value)
		result_metric_value_labels.append(metric_value)


func _configure_result_metrics(model: Dictionary) -> void:
	_ensure_result_metrics()
	var metrics: Array = model.get("currency_metrics", []) if model.get("currency_metrics", []) is Array else []
	for index in range(result_metric_title_labels.size()):
		var metric: Dictionary = metrics[index] if index < metrics.size() and metrics[index] is Dictionary else {}
		result_metric_title_labels[index].text = String(metric.get("label", ""))
		result_metric_value_labels[index].text = str(metric.get("value", 0))
		result_metric_value_labels[index].add_theme_color_override(
			"font_color",
			Color(0.95, 0.52, 0.35, 1.0) if StringName(metric.get("tone", &"positive")) == &"negative" else Color(0.43, 0.91, 0.74, 1.0)
		)
	result_metrics_row.visible = not bool(model.get("awaiting_salvage", false))


func _ensure_result_items() -> void:
	if result_items_scroll != null:
		return
	result_items_scroll = ScrollContainer.new()
	result_items_scroll.name = "ResultItemSectionsScroll"
	result_items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	result_items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	result_items_scroll.z_index = 4
	add_child(result_items_scroll)
	result_item_sections_box = VBoxContainer.new()
	result_item_sections_box.name = "ResultItemSections"
	result_item_sections_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_item_sections_box.add_theme_constant_override("separation", 8)
	result_items_scroll.add_child(result_item_sections_box)
	persistence_label = Label.new()
	persistence_label.name = "ResultPersistenceStatus"
	persistence_label.add_theme_font_override("font", ReadableFont)
	persistence_label.add_theme_font_size_override("font_size", 13)
	persistence_label.add_theme_color_override("font_color", PresentationTheme.text_color())
	persistence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	persistence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	persistence_label.z_index = 4
	add_child(persistence_label)


func _configure_result_item_sections(model: Dictionary) -> void:
	_ensure_result_items()
	for child in result_item_sections_box.get_children():
		result_item_sections_box.remove_child(child)
		child.queue_free()
	var awaiting := bool(model.get("awaiting_salvage", false))
	result_items_scroll.visible = not awaiting
	if awaiting:
		return
	var sections: Array = model.get("item_sections", []) if model.get("item_sections", []) is Array else []
	var visible_section_count := 0
	for raw_section in sections:
		if not raw_section is Dictionary:
			continue
		var items: Array = raw_section.get("items", []) if raw_section.get("items", []) is Array else []
		if items.is_empty():
			continue
		_add_result_item_section(raw_section)
		visible_section_count += 1
	if visible_section_count == 0:
		var empty_notice := Label.new()
		empty_notice.name = "ResultItemsEmptyNotice"
		empty_notice.text = "本次没有需要列出的物资。"
		empty_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_notice.add_theme_font_override("font", ReadableFont)
		empty_notice.add_theme_font_size_override("font_size", 13)
		empty_notice.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		result_item_sections_box.add_child(empty_notice)


func _add_result_item_section(section: Dictionary) -> void:
	var section_box := VBoxContainer.new()
	section_box.add_theme_constant_override("separation", 4)
	result_item_sections_box.add_child(section_box)
	var items: Array = section.get("items", []) if section.get("items", []) is Array else []
	var heading := Label.new()
	heading.text = "%s · %d" % [String(section.get("title", "物资")), int(section.get("count", items.size()))]
	heading.add_theme_font_override("font", ReadableFont)
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
	section_box.add_child(heading)
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "无"
		empty_label.add_theme_font_override("font", ReadableFont)
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		section_box.add_child(empty_label)
		return
	for raw_item in items:
		if raw_item is Dictionary:
			section_box.add_child(_build_result_item_row(raw_item))


func _build_result_item_row(item_model: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 36)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0.016, 0.043, 0.046, 0.90)
	row_style.border_color = Color(0.20, 0.50, 0.46, 0.58)
	row_style.border_width_left = 1
	row_style.border_width_top = 1
	row_style.border_width_right = 1
	row_style.border_width_bottom = 1
	row_style.content_margin_left = 8
	row_style.content_margin_right = 8
	row_style.content_margin_top = 5
	row_style.content_margin_bottom = 5
	row.add_theme_stylebox_override("panel", row_style)
	row.tooltip_text = String(item_model.get("short_description", ""))
	row.set_meta("instance_id", String(item_model.get("instance_id", "")))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	row.add_child(line)
	var name_label := Label.new()
	name_label.text = String(item_model.get("display_name", "未命名物资"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_override("font", ReadableFont)
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", PresentationTheme.text_color())
	line.add_child(name_label)
	var rarity: Dictionary = item_model.get("rarity", {}) if item_model.get("rarity", {}) is Dictionary else {}
	var rarity_label := Label.new()
	rarity_label.text = String(rarity.get("display_text", "[?] 未鉴定"))
	rarity_label.add_theme_font_override("font", ReadableFont)
	rarity_label.add_theme_font_size_override("font_size", 13)
	rarity_label.add_theme_color_override("font_color", rarity.get("color", PresentationTheme.color_for_key(&"ui.muted")))
	line.add_child(rarity_label)
	var weight_label := Label.new()
	weight_label.text = "重 %d" % int(item_model.get("weight", 0))
	weight_label.add_theme_font_override("font", ReadableFont)
	weight_label.add_theme_font_size_override("font_size", 13)
	weight_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
	line.add_child(weight_label)
	return row


func _ensure_actions() -> void:
	if return_deploy_button != null:
		return
	var actions := get_node_or_null("ResultActions") as HBoxContainer
	if actions == null:
		actions = HBoxContainer.new()
		actions.name = "ResultActions"
		actions.offset_left = 24.0
		actions.offset_top = 386.0
		actions.offset_right = 600.0
		actions.offset_bottom = 430.0
		actions.add_theme_constant_override("separation", 14)
		actions.z_index = 4
		add_child(actions)

	return_deploy_button = Button.new()
	return_deploy_button.name = "ResultReturnDeployButton"
	return_deploy_button.text = "返回出发整备"
	return_deploy_button.tooltip_text = "关闭本次结算并返回出发整备。"
	return_deploy_button.custom_minimum_size = Vector2(170, 40)
	return_deploy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_art21r2_modal_button(return_deploy_button, &"art21r2.modal.button.primary", &"primary", 13)
	return_deploy_button.pressed.connect(func() -> void:
		if normal_exit_allowed():
			return_deploy_requested.emit()
	)
	actions.add_child(return_deploy_button)

	return_main_button = Button.new()
	return_main_button.name = "ResultReturnMainButton"
	return_main_button.text = "返回菜单"
	return_main_button.tooltip_text = "关闭本次结算并返回主界面。"
	return_main_button.custom_minimum_size = Vector2(170, 40)
	return_main_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_art21r2_modal_button(return_main_button, &"art21r2.modal.button.secondary", &"secondary", 13)
	return_main_button.pressed.connect(func() -> void:
		if normal_exit_allowed():
			return_main_requested.emit()
	)
	actions.add_child(return_main_button)

	retry_save_button = Button.new()
	retry_save_button.name = "ResultRetrySaveButton"
	retry_save_button.text = "重试保存"
	retry_save_button.tooltip_text = "使用同一份结算结果再次尝试保存。"
	retry_save_button.custom_minimum_size = Vector2(170, 40)
	retry_save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_art21r2_modal_button(retry_save_button, &"art21r2.modal.button.primary", &"primary", 13)
	retry_save_button.pressed.connect(func() -> void:
		if retry_save_allowed() and not retry_save_button.disabled:
			retry_save_button.disabled = true
			retry_save_requested.emit()
	)
	actions.add_child(retry_save_button)

	discard_unsaved_button = Button.new()
	discard_unsaved_button.name = "ResultDiscardUnsavedButton"
	discard_unsaved_button.text = "放弃未保存结果"
	discard_unsaved_button.tooltip_text = "本次结果尚未保存；需要再次确认才会返回出发页。"
	discard_unsaved_button.custom_minimum_size = Vector2(190, 40)
	discard_unsaved_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_art21r2_modal_button(discard_unsaved_button, &"art21r2.modal.button.secondary", &"danger", 13)
	discard_unsaved_button.pressed.connect(_request_discard_unsaved_result)
	actions.add_child(discard_unsaved_button)
	_ensure_salvage_panel()


func _configure_persistence_actions(model: Dictionary) -> void:
	_ensure_actions()
	_ensure_result_items()
	reset_discard_unsaved_confirmation()
	var awaiting := bool(model.get("awaiting_salvage", false))
	var can_exit := bool(model.get("normal_exit_allowed", false))
	var can_retry := bool(model.get("retry_save_allowed", false))
	var can_discard := bool(model.get("discard_unsaved_allowed", false))
	if persistence_label != null:
		persistence_label.text = String(model.get("persistence_text", "本次结果尚未保存。"))
		persistence_label.visible = not awaiting
	if return_deploy_button != null:
		return_deploy_button.visible = can_exit and not awaiting
		return_deploy_button.disabled = not can_exit
	if return_main_button != null:
		return_main_button.visible = can_exit and not awaiting
		return_main_button.disabled = not can_exit
	if retry_save_button != null:
		retry_save_button.visible = can_retry and not awaiting
		retry_save_button.disabled = not can_retry
	if discard_unsaved_button != null:
		discard_unsaved_button.visible = can_discard and not awaiting
		discard_unsaved_button.disabled = not can_discard


func normal_exit_allowed() -> bool:
	return bool(current_result_model.get("normal_exit_allowed", false))


func retry_save_allowed() -> bool:
	return bool(current_result_model.get("retry_save_allowed", false))


func discard_unsaved_allowed() -> bool:
	return bool(current_result_model.get("discard_unsaved_allowed", false))


func mark_retry_complete() -> void:
	if retry_save_button != null:
		retry_save_button.disabled = not retry_save_allowed()
	var focus_target: Control
	if normal_exit_allowed() and return_deploy_button != null and return_deploy_button.is_visible_in_tree() and not return_deploy_button.disabled:
		focus_target = return_deploy_button
	elif retry_save_allowed() and retry_save_button != null and retry_save_button.is_visible_in_tree() and not retry_save_button.disabled:
		focus_target = retry_save_button
	if focus_target != null:
		focus_target.call_deferred("grab_focus")


func preferred_focus_control() -> Control:
	if salvage_panel != null and salvage_panel.visible and salvage_confirm_button != null and salvage_confirm_button.is_visible_in_tree() and not salvage_confirm_button.disabled:
		return salvage_confirm_button
	if retry_save_button != null and retry_save_button.is_visible_in_tree() and not retry_save_button.disabled:
		return retry_save_button
	if return_deploy_button != null and return_deploy_button.is_visible_in_tree() and not return_deploy_button.disabled:
		return return_deploy_button
	if return_main_button != null and return_main_button.is_visible_in_tree() and not return_main_button.disabled:
		return return_main_button
	if discard_unsaved_button != null and discard_unsaved_button.is_visible_in_tree() and not discard_unsaved_button.disabled:
		return discard_unsaved_button
	return null


func reset_discard_unsaved_confirmation() -> void:
	discard_unsaved_confirmation_step = 0
	if discard_unsaved_button != null:
		discard_unsaved_button.text = "放弃未保存结果"
		discard_unsaved_button.disabled = not discard_unsaved_allowed()


func _request_discard_unsaved_result() -> void:
	if not discard_unsaved_allowed() or discard_unsaved_button == null or discard_unsaved_button.disabled:
		return
	if discard_unsaved_confirmation_step == 0:
		discard_unsaved_confirmation_step = 1
		discard_unsaved_button.text = "再次确认：放弃并返回"
		if persistence_label != null:
			persistence_label.text = "结果仍未保存。再次确认将放弃本次未保存结果并返回出发页。"
		return
	discard_unsaved_button.disabled = true
	discard_unsaved_result_requested.emit()


func _ensure_salvage_panel() -> void:
	if salvage_panel != null:
		return
	salvage_panel = PanelContainer.new()
	salvage_panel.name = "FailureSalvagePanel"
	salvage_panel.z_index = 5
	salvage_panel.visible = false
	var salvage_style := StyleBoxFlat.new()
	salvage_style.bg_color = Color(0.012, 0.025, 0.028, 0.96)
	salvage_style.border_color = Color(0.62, 0.22, 0.18, 0.88)
	salvage_style.border_width_left = 1
	salvage_style.border_width_top = 1
	salvage_style.border_width_right = 1
	salvage_style.border_width_bottom = 1
	salvage_style.content_margin_left = 14
	salvage_style.content_margin_top = 12
	salvage_style.content_margin_right = 14
	salvage_style.content_margin_bottom = 12
	salvage_panel.add_theme_stylebox_override("panel", salvage_style)
	add_child(salvage_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	salvage_panel.add_child(content)
	var heading := Label.new()
	heading.text = "选择要保全的非消耗品"
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color(0.96, 0.72, 0.34, 1.0))
	content.add_child(heading)
	salvage_reason_label = Label.new()
	salvage_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	salvage_reason_label.add_theme_font_override("font", ReadableFont)
	salvage_reason_label.add_theme_color_override("font_color", PresentationTheme.text_color())
	content.add_child(salvage_reason_label)
	salvage_consequence_label = Label.new()
	salvage_consequence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	salvage_consequence_label.add_theme_font_override("font", ReadableFont)
	salvage_consequence_label.add_theme_font_size_override("font_size", 12)
	salvage_consequence_label.add_theme_color_override("font_color", Color(0.95, 0.66, 0.43, 1.0))
	content.add_child(salvage_consequence_label)
	salvage_capacity_label = Label.new()
	salvage_capacity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	salvage_capacity_label.add_theme_font_override("font", ReadableFont)
	salvage_capacity_label.add_theme_color_override("font_color", PresentationTheme.text_color())
	content.add_child(salvage_capacity_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 92)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	salvage_candidates_box = VBoxContainer.new()
	salvage_candidates_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(salvage_candidates_box)
	salvage_confirm_button = Button.new()
	salvage_confirm_button.text = "确认保全并完成结算"
	salvage_confirm_button.tooltip_text = "确认后将所选物资带回仓库；未选择物资与所有消耗品将无法带回。"
	salvage_confirm_button.custom_minimum_size = Vector2(0, 44)
	_apply_art21r2_modal_button(salvage_confirm_button, &"art21r2.modal.button.primary", &"primary", 13)
	salvage_confirm_button.pressed.connect(_confirm_failure_salvage)
	content.add_child(salvage_confirm_button)


func _configure_failure_salvage(snapshot: Dictionary) -> void:
	_ensure_salvage_panel()
	var settlement: Dictionary = snapshot.get("settlement", {})
	var awaiting := bool(settlement.get("requires_salvage_selection", false)) and not bool(settlement.get("finalized", false))
	var actions := get_node_or_null("ResultActions") as HBoxContainer
	var summary_node := get_node_or_null("ResultSummary") as Label
	if actions != null:
		actions.visible = not awaiting
	if result_actions_art != null:
		result_actions_art.visible = false
	if result_metrics_row != null:
		result_metrics_row.visible = not awaiting
	if result_items_scroll != null:
		result_items_scroll.visible = not awaiting
	if persistence_label != null:
		persistence_label.visible = not awaiting
	if result_summary_art != null:
		result_summary_art.visible = false
	if summary_node != null:
		summary_node.visible = not awaiting
	if salvage_panel != null:
		salvage_panel.visible = awaiting
	if not awaiting:
		selected_salvage_ids.clear()
		if not current_layout_profile.is_empty():
			apply_layout_profile(current_layout_profile)
		return
	if salvage_confirm_button != null:
		salvage_confirm_button.disabled = false
	selected_salvage_ids.clear()
	salvage_capacity = int(settlement.get("salvage_capacity", 0))
	if salvage_reason_label != null:
		salvage_reason_label.text = String(current_result_model.get("reason_text", "本次探索未能完成。"))
	if salvage_consequence_label != null:
		salvage_consequence_label.text = "黑资损失 %d；已锁定收益保留 %d。" % [
			int(settlement.get("black_coin_lost", 0)),
			int(settlement.get("safe_yield_retained", settlement.get("safe_yield", 0))),
		]
	for child in salvage_candidates_box.get_children():
		child.queue_free()
	salvage_candidate_buttons.clear()
	var candidates: Array = settlement.get("settlement_pool", [])
	salvage_has_candidates = not candidates.is_empty()
	if candidates.is_empty():
		var empty_label := Label.new()
		empty_label.text = "没有可保全的非消耗品；可以直接确认结算。"
		empty_label.add_theme_font_override("font", ReadableFont)
		salvage_candidates_box.add_child(empty_label)
	for raw_item in candidates:
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		var item_model := RunUIViewModel.result_item_model(item)
		var instance_id := String(item_model.get("instance_id", ""))
		var rarity: Dictionary = item_model.get("rarity", {}) if item_model.get("rarity", {}) is Dictionary else {}
		var button := Button.new()
		button.toggle_mode = true
		button.text = "%s  ·  %s  ·  重量 %d" % [
			String(item_model.get("display_name", "未命名物资")),
			String(rarity.get("display_text", "[?] 未鉴定")),
			int(item_model.get("weight", 0)),
		]
		button.tooltip_text = String(item_model.get("short_description", ""))
		button.custom_minimum_size = Vector2(0, 42)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_art21r2_modal_button(button, &"art21r2.modal.item_row.normal", &"secondary", 13, 10)
		button.add_theme_font_override("font", ReadableFont)
		button.set_meta("instance_id", instance_id)
		button.set_meta("weight", int(item_model.get("weight", 0)))
		button.toggled.connect(func(pressed: bool) -> void: _toggle_salvage_item(instance_id, pressed))
		salvage_candidate_buttons[instance_id] = button
		salvage_candidates_box.add_child(button)
	_refresh_salvage_controls()
	if not current_layout_profile.is_empty():
		apply_layout_profile(current_layout_profile)


func _toggle_salvage_item(instance_id: String, pressed: bool) -> void:
	if pressed:
		if not selected_salvage_ids.has(instance_id):
			selected_salvage_ids.append(instance_id)
	else:
		selected_salvage_ids.erase(instance_id)
	_refresh_salvage_controls()


func _refresh_salvage_controls() -> void:
	var used := 0
	for instance_id in selected_salvage_ids:
		var selected_button := salvage_candidate_buttons.get(instance_id) as Button
		if selected_button != null:
			used += int(selected_button.get_meta("weight", 1))
	for instance_id in salvage_candidate_buttons.keys():
		var button := salvage_candidate_buttons[instance_id] as Button
		if button == null:
			continue
		var is_selected := selected_salvage_ids.has(String(instance_id))
		button.set_pressed_no_signal(is_selected)
		button.disabled = not is_selected and used + int(button.get_meta("weight", 1)) > salvage_capacity
	if salvage_capacity_label != null:
		salvage_capacity_label.text = "保全容量：%d / %d；已选 %d 件，未选 %d 件。所有消耗品都无法带回。" % [
			used,
			salvage_capacity,
			selected_salvage_ids.size(),
			maxi(0, salvage_candidate_buttons.size() - selected_salvage_ids.size()),
		]


func _confirm_failure_salvage() -> void:
	if salvage_confirm_button != null:
		salvage_confirm_button.disabled = true
	failure_salvage_confirmed.emit(selected_salvage_ids.duplicate())


func requires_salvage_confirmation() -> bool:
	return salvage_panel != null and salvage_panel.visible


func apply_layout_profile(profile: Dictionary) -> void:
	current_layout_profile = profile.duplicate(true)
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var summary_node := get_node_or_null("ResultSummary") as Label
	if summary_node != null:
		summary_node.add_theme_font_size_override("font_size", 14 if is_low else (16 if is_high else 14))
		summary_node.add_theme_constant_override("line_spacing", 3 if is_low else (5 if is_high else 4))
		summary_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary_node.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var viewport_size := UILayerContractScript.viewport_size_from_profile(profile)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size
	var awaiting_salvage := salvage_panel != null and salvage_panel.visible
	# The larger pre-final report is reserved for a real candidate list. When
	# there is nothing to preserve, keep the confirmation step but use the same
	# compact report footprint as the final outcomes instead of showing a large
	# empty selection well.
	var rect := _main_game_modal_rect(profile, awaiting_salvage and salvage_has_candidates)
	var backdrop := get_node_or_null("Backdrop") as ColorRect
	if backdrop != null:
		backdrop.visible = true
		backdrop.position = Vector2.ZERO
		backdrop.size = viewport_size
	if result_modal_art != null:
		_set_absolute_rect(result_modal_art, rect)
	if result_title_art != null:
		var banner_size := Vector2(300, 130)
		_set_absolute_rect(result_title_art, Rect2(Vector2(rect.position.x + (rect.size.x - banner_size.x) * 0.5, rect.position.y + 20.0), banner_size))
	var title_node := get_node_or_null("ResultTitle") as Label
	if title_node != null:
		_set_absolute_rect(title_node, Rect2(rect.position + Vector2(34.0, 52.0), Vector2(rect.size.x - 68.0, 42.0)))
		title_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var summary_top := rect.position.y + 160.0
	var action_strip_top := rect.end.y - 68.0
	var summary_height := 54.0
	var metrics_top := summary_top + summary_height + 8.0
	var metrics_height := 64.0
	var persistence_height := 38.0
	var persistence_top := action_strip_top - persistence_height - 8.0
	var items_top := metrics_top + metrics_height + 8.0
	if result_summary_art != null:
		result_summary_art.visible = false
	if result_metrics_row != null:
		result_metrics_row.visible = not awaiting_salvage
		_set_absolute_rect(result_metrics_row, Rect2(Vector2(rect.position.x + 34.0, metrics_top), Vector2(rect.size.x - 68.0, metrics_height)))
	if summary_node != null:
		_set_absolute_rect(summary_node, Rect2(Vector2(rect.position.x + 34.0, summary_top), Vector2(rect.size.x - 68.0, summary_height)))
	if result_items_scroll != null:
		result_items_scroll.visible = not awaiting_salvage
		_set_absolute_rect(result_items_scroll, Rect2(
			Vector2(rect.position.x + 34.0, items_top),
			Vector2(rect.size.x - 68.0, max(72.0, persistence_top - items_top - 8.0))
		))
	if persistence_label != null:
		persistence_label.visible = not awaiting_salvage
		_set_absolute_rect(persistence_label, Rect2(Vector2(rect.position.x + 34.0, persistence_top), Vector2(rect.size.x - 68.0, persistence_height)))
	if result_actions_art != null:
		result_actions_art.visible = false
	var actions := get_node_or_null("ResultActions") as HBoxContainer
	if actions != null:
		_set_absolute_rect(actions, Rect2(Vector2(rect.position.x + 34.0, action_strip_top), Vector2(rect.size.x - 68.0, 42.0)))
	if salvage_panel != null:
		_set_absolute_rect(salvage_panel, Rect2(Vector2(rect.position.x + 34.0, summary_top), Vector2(rect.size.x - 68.0, max(230.0, rect.end.y - summary_top - 34.0))))


func _set_absolute_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y


func _main_game_modal_rect(profile: Dictionary, salvage_state: bool = false) -> Rect2:
	var viewport_size := UILayerContractScript.viewport_size_from_profile(profile)
	var width: float = maxf(1.0, viewport_size.x)
	var height: float = maxf(1.0, viewport_size.y)
	var is_high := bool(profile.get("is_high_resolution", false))
	var modal_width := 620.0 if salvage_state else 680.0
	var modal_height := 600.0 if salvage_state else 660.0
	if is_high:
		modal_width *= 1.12
		modal_height *= 1.12
	modal_width = minf(modal_width, width - 48.0)
	modal_height = minf(modal_height, height - 48.0)
	var x: float = (width - modal_width) * 0.5
	var y: float = (height - modal_height) * 0.5
	return Rect2(x, y, modal_width, modal_height)


func _apply_result_title_plate(state: StringName) -> void:
	if result_title_art == null:
		_ensure_backdrop()
	var asset_id: StringName = RESULT_BANNER_ASSET_BY_STATE.get(state, &"")
	var texture := Art09ManifestAssetMappingScript.resolve_texture(
		Art09ManifestAssetMappingScript.asset_ref(
			asset_id,
			RESULT_BANNER_FALLBACK_ASSET,
			&"result_banner",
			state
		)
	)
	if texture != null and result_title_art != null:
		result_title_art.texture = texture
		result_title_art.visible = true
	var title_node := get_node_or_null("ResultTitle") as Label
	if title_node != null:
		# ART24 result banners are intentionally text-free. Keep the localized live
		# title visible for every state instead of relying on legacy baked copy.
		title_node.visible = true


func _result_state_from_snapshot(snapshot: Dictionary) -> StringName:
	var outcome := String(snapshot.get("outcome", ""))
	var settlement_outcome := String(snapshot.get("settlement_outcome", ""))
	var settlement_variant: Variant = snapshot.get("settlement", {})
	if settlement_variant is Dictionary:
		var settlement: Dictionary = settlement_variant
		settlement_outcome = String(settlement.get("outcome", settlement_outcome))
	if outcome == "Extracted" or settlement_outcome == "success":
		return &"success"
	if outcome == "Failed" or settlement_outcome == "failure":
		return &"failure"
	if outcome == "Abandoned" or settlement_outcome == "abandon":
		return &"abandon"
	return &"extract_confirm"


func _ensure_modal_patch(node_name: StringName, visual_key: StringName, margin: int, alpha: float) -> NinePatchRect:
	var patch := get_node_or_null(String(node_name)) as NinePatchRect
	if patch == null:
		patch = NinePatchRect.new()
		patch.name = String(node_name)
		patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		patch.patch_margin_left = margin
		patch.patch_margin_top = margin
		patch.patch_margin_right = margin
		patch.patch_margin_bottom = margin
		patch.draw_center = true
		add_child(patch)
	patch.texture = Art21UIPlacementContractScript.texture_for_visual_key(visual_key, &"ui.art19.panel.terminal_main")
	patch.modulate = Color(1.0, 1.0, 1.0, alpha)
	patch.z_index = 1
	return patch


func _apply_art21r2_modal_button(button: Button, visual_key: StringName, tone: StringName, font_size_value: int, padding: int = 8, texture_margin: int = 18) -> void:
	Art10UISkinKitScript.apply_button(button, tone, font_size_value)
	var style := Art21UIPlacementContractScript.style_box_for_visual_key(visual_key, &"ui.art19.button.dark", padding, texture_margin)
	if style == null:
		return
	var normal := style.duplicate() as StyleBoxTexture
	var hover := style.duplicate() as StyleBoxTexture
	var pressed := style.duplicate() as StyleBoxTexture
	var disabled := style.duplicate() as StyleBoxTexture
	if tone == &"danger":
		normal.modulate_color = Color(1.08, 0.46, 0.40, 1.0)
		hover.modulate_color = Color(1.18, 0.58, 0.48, 1.0)
		pressed.modulate_color = Color(0.94, 0.34, 0.30, 1.0)
		button.add_theme_color_override("font_color", Color(1.0, 0.78, 0.72, 1.0))
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.86, 1.0))
	else:
		hover.modulate_color = Color(1.14, 1.12, 0.92, 1.0) if tone == &"primary" else Color(0.88, 1.12, 1.10, 1.0)
		pressed.modulate_color = Color(0.92, 0.92, 0.86, 1.0)
	disabled.modulate_color = Color(0.48, 0.50, 0.48, 0.82)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", _result_button_focus_style(tone, padding))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.96, 0.78, 1.0) if tone != &"danger" else Color(1.0, 0.94, 0.90, 1.0))
	button.set_meta(&"result_action_tone", tone)


func _result_button_focus_style(tone: StringName, padding: int) -> StyleBoxFlat:
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.07, 0.10, 0.085, 0.99)
	focus.border_color = Color(0.34, 0.92, 0.78, 1.0)
	if tone == &"primary":
		focus.bg_color = Color(0.14, 0.105, 0.035, 0.99)
		focus.border_color = Color(1.0, 0.78, 0.24, 1.0)
	elif tone == &"danger":
		focus.bg_color = Color(0.19, 0.035, 0.028, 0.99)
		focus.border_color = Color(1.0, 0.32, 0.22, 1.0)
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(4)
	focus.content_margin_left = padding
	focus.content_margin_top = padding
	focus.content_margin_right = padding
	focus.content_margin_bottom = padding
	return focus
