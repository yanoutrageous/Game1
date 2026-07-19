extends Control
class_name ResultPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const LEGACY_RESULT_VALIDATION_MARKERS := ["Outcome:", "Mode:", "Moves:", "Mine Hits:", "Monsters Defeated:", "Failure Pending Lost:", "Failure Salvaged Items:", "Carried Items:", "Carried Value:", "Safe Gold:", "Final HP:", "Final Pressure:", "Black Coin:", "Gold Coin:", "Warehouse Lite Items:", "Room Floor Lost:", "Settlement Log Entries:"]

signal return_main_requested
signal return_deploy_requested
signal failure_salvage_confirmed(selected_instance_ids: Array)

var result_title_art: TextureRect
var result_modal_art: NinePatchRect
var result_summary_art: NinePatchRect
var result_actions_art: NinePatchRect
var salvage_panel: PanelContainer
var salvage_capacity_label: Label
var salvage_candidates_box: VBoxContainer
var salvage_confirm_button: Button
var salvage_candidate_buttons: Dictionary = {}
var selected_salvage_ids: Array[String] = []
var salvage_capacity: int = 0


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
	set_result_summary(String(model.get("title", "结算")), String(model.get("summary", "")))
	_apply_result_title_plate(_result_state_from_snapshot(snapshot))
	_configure_failure_salvage(snapshot)
	visible = true
	Art10UISkinKitScript.play_panel_open(self)


func hide_result() -> void:
	visible = false
	selected_salvage_ids.clear()


func _ensure_backdrop() -> void:
	var backdrop := get_node_or_null("Backdrop") as ColorRect
	if backdrop != null:
		backdrop.color = Color(0, 0, 0, 0)
		backdrop.visible = false
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
		move_child(result_modal_art, 0)
	var modal_texture := Art21UIPlacementContractScript.texture_for_slot(&"result", &"result_modal_frame", &"ui.art19.panel.terminal_main")
	if modal_texture != null:
		result_modal_art.texture = modal_texture
	result_summary_art = _ensure_modal_patch(&"ResultSummaryPanelArt", &"art21r2.modal.section.panel", 32, 0.96)
	result_actions_art = _ensure_modal_patch(&"ResultActionStripArt", &"art21r2.modal.action_strip", 34, 0.96)
	result_title_art = get_node_or_null("ResultTitlePlate") as TextureRect
	if result_title_art == null:
		result_title_art = TextureRect.new()
		result_title_art.name = "ResultTitlePlate"
		result_title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		result_title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		result_title_art.modulate = Color(1.0, 1.0, 1.0, 0.94)
		add_child(result_title_art)
	result_title_art.z_index = 1
	var title_node := get_node_or_null("ResultTitle") as Label
	if title_node != null:
		title_node.z_index = 4
	var summary_node := get_node_or_null("ResultSummary") as Label
	if summary_node != null:
		summary_node.z_index = 4


func _ensure_actions() -> void:
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

	var main_button := Button.new()
	main_button.name = "ResultReturnMainButton"
	main_button.text = "返回主界面"
	main_button.tooltip_text = "关闭本次结算记录并返回主界面。"
	main_button.custom_minimum_size = Vector2(170, 40)
	_apply_art21r2_modal_button(main_button, &"art21r2.modal.button.secondary", &"secondary", 13)
	main_button.pressed.connect(func() -> void: return_main_requested.emit())
	actions.add_child(main_button)

	var deploy_button := Button.new()
	deploy_button.name = "ResultReturnDeployButton"
	deploy_button.text = "返回出发页"
	deploy_button.tooltip_text = "关闭本次结算记录并返回出发页，准备下一次探索。"
	deploy_button.custom_minimum_size = Vector2(170, 40)
	_apply_art21r2_modal_button(deploy_button, &"art21r2.modal.button.primary", &"primary", 13)
	deploy_button.pressed.connect(func() -> void: return_deploy_requested.emit())
	actions.add_child(deploy_button)
	_ensure_salvage_panel()


func _ensure_salvage_panel() -> void:
	if salvage_panel != null:
		return
	salvage_panel = PanelContainer.new()
	salvage_panel.name = "FailureSalvagePanel"
	salvage_panel.z_index = 5
	salvage_panel.visible = false
	add_child(salvage_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	salvage_panel.add_child(content)
	var heading := Label.new()
	heading.text = "选择要保全的非消耗品"
	heading.add_theme_font_size_override("font_size", 16)
	content.add_child(heading)
	salvage_capacity_label = Label.new()
	salvage_capacity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(salvage_capacity_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	salvage_candidates_box = VBoxContainer.new()
	salvage_candidates_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(salvage_candidates_box)
	salvage_confirm_button = Button.new()
	salvage_confirm_button.text = "确认保全并完成结算"
	salvage_confirm_button.tooltip_text = "确认后写入仓库；未选择物品与所有消耗品将清除。"
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
	if summary_node != null:
		summary_node.visible = not awaiting
	if salvage_panel != null:
		salvage_panel.visible = awaiting
	if not awaiting:
		selected_salvage_ids.clear()
		return
	if salvage_confirm_button != null:
		salvage_confirm_button.disabled = false
	selected_salvage_ids.clear()
	salvage_capacity = int(settlement.get("salvage_capacity", 0))
	for child in salvage_candidates_box.get_children():
		child.queue_free()
	salvage_candidate_buttons.clear()
	var candidates: Array = settlement.get("settlement_pool", [])
	if candidates.is_empty():
		var empty_label := Label.new()
		empty_label.text = "没有可保全的非消耗品；可以直接确认结算。"
		salvage_candidates_box.add_child(empty_label)
	for raw_item in candidates:
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		var instance_id := String(item.get("instance_id", ""))
		var button := Button.new()
		button.toggle_mode = true
		button.text = "%s  ·  重量 %d" % [String(item.get("display_name", item.get("item_id", "物品"))), int(item.get("weight", 1))]
		button.tooltip_text = String(item.get("short_description", ""))
		button.set_meta("instance_id", instance_id)
		button.set_meta("weight", int(item.get("weight", 1)))
		button.toggled.connect(func(pressed: bool) -> void: _toggle_salvage_item(instance_id, pressed))
		salvage_candidate_buttons[instance_id] = button
		salvage_candidates_box.add_child(button)
	_refresh_salvage_controls()


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
		salvage_capacity_label.text = "保全容量：%d / %d。所有携入或局内获得的消耗品都会清除，不会返还仓库。" % [used, salvage_capacity]


func _confirm_failure_salvage() -> void:
	if salvage_confirm_button != null:
		salvage_confirm_button.disabled = true
	failure_salvage_confirmed.emit(selected_salvage_ids.duplicate())


func requires_salvage_confirmation() -> bool:
	return salvage_panel != null and salvage_panel.visible


func apply_layout_profile(profile: Dictionary) -> void:
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var summary_node := get_node_or_null("ResultSummary") as Label
	if summary_node != null:
		summary_node.add_theme_font_size_override("font_size", 12 if is_low else (15 if is_high else 13))
		summary_node.add_theme_constant_override("line_spacing", 1 if is_low else (3 if is_high else 2))
	var rect := _main_game_modal_rect(profile)
	position = rect.position
	size = rect.size
	var backdrop := get_node_or_null("Backdrop") as ColorRect
	if backdrop != null:
		backdrop.visible = false
		backdrop.color = Color(0, 0, 0, 0)
		backdrop.size = size + Vector2(16, 16)
	if result_modal_art != null:
		result_modal_art.position = Vector2.ZERO
		result_modal_art.size = size
	if result_title_art != null:
		result_title_art.position = Vector2(24, 10)
		result_title_art.size = Vector2(250 if is_low else (340 if is_high else 300), 104 if is_low else 112)
	var title_node := get_node_or_null("ResultTitle") as Label
	if title_node != null:
		title_node.position = Vector2(58, 30)
		title_node.size = Vector2(220 if is_low else (280 if is_high else 260), 30)
	var summary_top := 126.0 if not is_low else 116.0
	var action_strip_top := size.y - 86.0
	if result_summary_art != null:
		result_summary_art.position = Vector2(28, summary_top)
		result_summary_art.size = Vector2(size.x - 56.0, max(120.0, action_strip_top - summary_top - 12.0))
	if summary_node != null:
		summary_node.position = Vector2(48, summary_top + 18.0)
		summary_node.size = Vector2(size.x - 96.0, max(88.0, action_strip_top - summary_top - 48.0))
	if result_actions_art != null:
		result_actions_art.position = Vector2(34, action_strip_top)
		result_actions_art.size = Vector2(size.x - 68.0, 66)
	var actions := get_node_or_null("ResultActions") as HBoxContainer
	if actions != null:
		actions.offset_left = 58.0
		actions.offset_top = size.y - 68.0
		actions.offset_right = size.x - 58.0
		actions.offset_bottom = size.y - 22.0
	if salvage_panel != null:
		salvage_panel.position = Vector2(48, summary_top + 14.0)
		salvage_panel.size = Vector2(size.x - 96.0, max(150.0, action_strip_top - summary_top - 28.0))


func _main_game_modal_rect(profile: Dictionary) -> Rect2:
	var viewport_size := UILayerContractScript.viewport_size_from_profile(profile)
	var width: float = maxf(1.0, viewport_size.x)
	var height: float = maxf(1.0, viewport_size.y)
	var is_low := bool(profile.get("is_low_resolution", false))
	var margin: float = 18.0 if is_low else 24.0
	var left_width: float = min(UILayerContractScript.run_left_width(profile), width * 0.42)
	var gameplay_left: float = left_width + margin
	var gameplay_width: float = maxf(260.0, width - gameplay_left - margin)
	var modal_width: float = clampf(gameplay_width * 0.82, 430.0, 660.0)
	if modal_width > gameplay_width:
		modal_width = maxf(260.0, gameplay_width)
	var bottom_reserve: float = 72.0 if is_low else 92.0
	var modal_height: float = clampf(height * 0.68, 360.0, 500.0)
	modal_height = min(modal_height, maxf(300.0, height - margin * 2.0 - bottom_reserve))
	var x: float = gameplay_left + maxf(0.0, (gameplay_width - modal_width) * 0.5)
	var y: float = margin + maxf(0.0, (height - bottom_reserve - modal_height) * 0.45)
	y = clampf(y, margin + 46.0, maxf(margin + 46.0, height - bottom_reserve - modal_height))
	return Rect2(x, y, modal_width, modal_height)


func _apply_result_title_plate(state: StringName) -> void:
	if result_title_art == null:
		_ensure_backdrop()
	var texture := Art09ManifestAssetMappingScript.resolve_texture(PresentationMappingScript.result_title_ref(state))
	var uses_state_title := texture != null
	if texture == null:
		texture = Art21UIPlacementContractScript.texture_for_visual_key(&"art21r2.modal.title_plate", &"ui.result.title.extraction_success")
	if texture != null and result_title_art != null:
		result_title_art.texture = texture
		result_title_art.visible = true
	var title_node := get_node_or_null("ResultTitle") as Label
	if title_node != null:
		title_node.visible = not uses_state_title


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
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style.duplicate())
	button.add_theme_stylebox_override("pressed", style.duplicate())
	button.add_theme_stylebox_override("disabled", style.duplicate())
	button.add_theme_stylebox_override("focus", Art10UISkinKitScript.transparent_style_box(padding))
