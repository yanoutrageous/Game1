extends Control
class_name ResultPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const LEGACY_RESULT_VALIDATION_MARKERS := ["Outcome:", "Mode:", "Moves:", "Mine Hits:", "Monsters Defeated:", "Failure Pending Lost:", "Failure Salvaged Items:", "Carried Items:", "Carried Value:", "Safe Gold:", "Final HP:", "Final Pressure:", "Black Coin:", "Gold Coin:", "Warehouse Lite Items:", "Room Floor Lost:", "Settlement Log Entries:"]

signal return_main_requested
signal return_deploy_requested

var result_title_art: TextureRect
var result_modal_art: NinePatchRect
var result_summary_art: NinePatchRect
var result_actions_art: NinePatchRect


func _ready() -> void:
	_ensure_backdrop()
	_ensure_actions()


func set_result_summary(title: String, summary: String) -> void:
	var title_node := get_node_or_null("ResultTitle") as Label
	var summary_node := get_node_or_null("ResultSummary") as Label

	if title_node != null:
		title_node.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		title_node.z_index = 4
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
	visible = true
	Art10UISkinKitScript.play_panel_open(self)


func hide_result() -> void:
	visible = false


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
	if get_node_or_null("ResultActions") != null:
		return
	var actions := HBoxContainer.new()
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


func apply_layout_profile(profile: Dictionary) -> void:
	var profile_id: StringName = StringName(profile.get("profile_id", &"desktop"))
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var summary_node := get_node_or_null("ResultSummary") as Label
	if summary_node != null:
		summary_node.add_theme_font_size_override("font_size", 12 if is_low else (15 if is_high else 13))
		summary_node.add_theme_constant_override("line_spacing", 1 if is_low else (3 if is_high else 2))
	if profile_id == &"narrow" or is_low:
		position = Vector2(18, 70)
		size = Vector2(560, 520)
	elif is_high:
		position = Vector2(300, 82)
		size = Vector2(680, 480)
	else:
		position = Vector2(330, 96)
		size = Vector2(620, 440)
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
		result_title_art.size = Vector2(260 if is_low else (330 if is_high else 310), 76)
	var title_node := get_node_or_null("ResultTitle") as Label
	if title_node != null:
		title_node.position = Vector2(58, 30)
		title_node.size = Vector2(220 if is_low else (280 if is_high else 260), 30)
	var summary_top := 108.0
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


func _apply_result_title_plate(state: StringName) -> void:
	if result_title_art == null:
		_ensure_backdrop()
	var texture := Art21UIPlacementContractScript.texture_for_visual_key(&"art21r2.modal.title_plate", &"ui.result.title.extraction_success")
	if texture == null:
		texture = Art09ManifestAssetMappingScript.resolve_texture(PresentationMappingScript.result_title_ref(state))
	if texture != null and result_title_art != null:
		result_title_art.texture = texture
		result_title_art.visible = true


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
