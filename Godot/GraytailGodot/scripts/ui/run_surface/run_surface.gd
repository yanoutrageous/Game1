extends Control
class_name RunSurface

const HUDScene := preload("res://scenes/ui/hud/hud.tscn")
const MiniMapScene := preload("res://scenes/ui/minimap/minimap_panel.tscn")
const PresentationTheme := preload("res://scripts/presentation/presentation_theme.gd")
const PresentationMapping := preload("res://scripts/presentation/presentation_mapping.gd")
const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")

signal interact_requested
signal inventory_requested
signal ground_loot_requested
signal map_requested(source: StringName)
signal combat_requested
signal extract_requested
signal pause_requested
signal encounter_option_selected(option_id: StringName, command_payload: Dictionary)

var hud: Hud
var minimap_panel: MiniMapPanel
var overlay_slot: Control
var modal_slot: Control
var feedback_slot: Control
var run_game_stage_root: Control
var run_room_viewport_root: Control
var run_left_info_rail_root: Control
var run_top_right_status_root: Control
var run_floating_info_root: Control
var run_interaction_prompt_root: Control
var run_action_overlay_root: Control
var run_overlay_root: Control
var run_modal_root: Control

var left_backdrop: PanelContainer
var center_backdrop: PanelContainer
var encounter_backdrop: PanelContainer
var right_backdrop: PanelContainer
var bottom_backdrop: PanelContainer
var resource_backdrop: PanelContainer
var room_background_layer: TextureRect
var scanner_text_mask: PanelContainer
var room_text_mask: PanelContainer
var threat_mask: PanelContainer
var event_mask: PanelContainer
var reward_mask: PanelContainer
var player_tag_mask: ColorRect
var room_hint_softener: ColorRect
var scanner_glow_layer: ColorRect
var room_glow_layer: ColorRect
var protocol_glow_layer: ColorRect
var bottom_key_glow_layer: ColorRect
var right_game_fill_layer: ColorRect
var left_rail_art: NinePatchRect
var status_card_art: NinePatchRect
var bottom_overlay_art: NinePatchRect
var player_sprite_layer: TextureRect
var scanner_title_label: Label
var scanner_summary_label: Label
var scanner_legend_label: Label
var scanner_detail_label: Label
var room_title_label: Label
var room_body_label: Label
var objective_label: Label
var player_tag_label: Label
var encounter_title_label: Label
var encounter_body_label: Label
var encounter_result_label: Label
var resource_label: Label
var right_title_label: Label
var right_body_label: Label
var event_label: Label
var reward_label: Label
var command_feedback_art: TextureRect
var command_feedback_label: Label
var layout_label: Label
var action_hint_label: Label
var encounter_options_box: VBoxContainer
var action_bar: HBoxContainer
var action_buttons: Dictionary = {}
var encounter_option_buttons: Array[Button] = []
var built := false

const LAYER_ROOM_BACKGROUND := 0
const LAYER_SCENE_TINT := 10
const LAYER_STRUCTURAL_PANEL := 30
const LAYER_PANEL_TEXTURE := 36
const LAYER_CONTENT_MASK := 44
const LAYER_CONTENT := 60
const LAYER_INTERACTION := 78
const LAYER_BOTTOM_BAR := 90
const LAYER_OVERLAY := 120
const LAYER_MODAL := 150


func build() -> void:
	if built:
		return
	built = true
	name = "RunSurface"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 180

	left_backdrop = _add_panel("RunScannerRail", PresentationTheme.panel_color(), PresentationTheme.color_for_key(&"ui.accent"))
	left_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.006, 0.014, 0.016, 0.72), PresentationTheme.color_for_key(&"ui.accent"), 2))
	Art10UISkinKitScript.apply_panel(left_backdrop, &"deep")
	left_rail_art = _add_nine_patch_from_ref("Art21RunLeftInfoRail", Art21UIPlacementContractScript.slot_ref(&"run_hud", &"left_info_rail", &"ui.art21.shared.panel.page_frame.normal"), 0.96, 14)
	center_backdrop = _add_panel("RunRoomSignalPanel", Color(0.006, 0.012, 0.014, 0.10), PresentationTheme.color_for_key(&"mini.normal"))
	center_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.006, 0.012, 0.014, 0.10), PresentationTheme.color_for_key(&"mini.normal"), 1))
	room_background_layer = _add_texture_rect_from_ref("RunRoomBackgroundFill", _room_background_ref(&"Normal"), 1.0)
	room_background_layer.visible = false
	encounter_backdrop = _add_panel("RunEncounterSlot", Color(0.018, 0.034, 0.038, 0.88), PresentationTheme.color_for_key(&"ui.warning"))
	encounter_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.006, 0.012, 0.014, 0.72), PresentationTheme.color_for_key(&"ui.accent"), 1))
	right_backdrop = _add_panel("RunProtocolRail", Color(0.035, 0.04, 0.042, 0.90), PresentationTheme.color_for_key(&"ui.warning"))
	right_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.006, 0.014, 0.016, 0.68), PresentationTheme.color_for_key(&"ui.warning"), 2))
	Art10UISkinKitScript.apply_panel(right_backdrop, &"summary")
	status_card_art = _add_nine_patch_from_ref("Art21RunStatusCard", Art21UIPlacementContractScript.slot_ref(&"run_hud", &"top_right_status_card", &"ui.art19.panel.deploy_summary"), 0.94, 12)
	bottom_backdrop = _add_panel("RunActionBarSurface", PresentationTheme.panel_color(), PresentationTheme.color_for_key(&"ui.accent"))
	bottom_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.006, 0.014, 0.016, 0.70), PresentationTheme.color_for_key(&"ui.accent"), 2))
	Art10UISkinKitScript.apply_panel(bottom_backdrop, &"summary")
	bottom_overlay_art = _add_nine_patch_from_ref("Art21RunBottomOverlay", Art21UIPlacementContractScript.slot_ref(&"run_hud", &"bottom_overlay", &"ui.art19.bar.summary_dark"), 0.96, 12)
	resource_backdrop = _add_panel("RunResourcePocket", Color(0.035, 0.055, 0.055, 0.92), PresentationTheme.color_for_key(&"mini.chest"))
	resource_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.006, 0.014, 0.016, 0.60), PresentationTheme.color_for_key(&"mini.chest"), 2))
	Art10UISkinKitScript.apply_panel(resource_backdrop, &"card")
	scanner_text_mask = _add_panel("RunScannerTextMask", Color(0.012, 0.026, 0.030, 0.72), PresentationTheme.color_for_key(&"ui.accent"))
	room_text_mask = _add_panel("RunRoomTextMask", Color(0.012, 0.026, 0.030, 0.82), PresentationTheme.color_for_key(&"mini.normal"))
	threat_mask = _add_panel("RunThreatMask", Color(0.040, 0.046, 0.042, 0.74), PresentationTheme.color_for_key(&"ui.warning"))
	event_mask = _add_panel("RunEventMask", Color(0.026, 0.042, 0.046, 0.68), PresentationTheme.color_for_key(&"ui.accent"))
	reward_mask = _add_panel("RunRewardMask", Color(0.036, 0.052, 0.046, 0.90), PresentationTheme.color_for_key(&"mini.chest"))
	player_tag_mask = _add_color_layer("RunPlayerTagMask", Color(0.004, 0.010, 0.012, 0.96))
	room_hint_softener = _add_color_layer("RunRoomHintSoftener", Color(0.0, 0.0, 0.0, 0.34))
	scanner_glow_layer = _add_color_layer("RunScannerGlow", Color(0.58, 0.93, 0.76, 0.08))
	room_glow_layer = _add_color_layer("RunRoomFocusGlow", Color(0.58, 0.93, 0.76, 0.025))
	protocol_glow_layer = _add_color_layer("RunProtocolWarningGlow", Color(0.94, 0.70, 0.28, 0.08))
	bottom_key_glow_layer = _add_color_layer("RunBottomKeyGlow", Color(0.58, 0.93, 0.76, 0.06))
	right_game_fill_layer = _add_color_layer("RunRightGameAreaFill", Color(0.012, 0.020, 0.022, 0.08))
	player_sprite_layer = _add_texture_rect_from_ref("RunPlayerSprite", Art09ManifestAssetMappingScript.player_sprite_ref(&"idle"), 1.0)
	if player_sprite_layer != null:
		player_sprite_layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		player_sprite_layer.visible = false

	scanner_title_label = _add_label("RunScannerTitle", "小地图", 18, PresentationTheme.color_for_key(&"ui.accent"))
	scanner_summary_label = _add_label("RunScannerSummary", "", 13, PresentationTheme.text_color())
	scanner_legend_label = _add_label("RunScannerLegend", "P 当前 | ? 未知 | F 标记 | X 撤离", 12, PresentationTheme.color_for_key(&"ui.muted"))

	scanner_detail_label = _add_label("RunScannerDetail", "已知 / 危险 / 撤离", 12, PresentationTheme.color_for_key(&"ui.muted"))

	minimap_panel = MiniMapScene.instantiate() as MiniMapPanel
	minimap_panel.name = "RunScannerMiniMap"
	minimap_panel.clip_contents = true
	minimap_panel.open_map_requested.connect(func() -> void: map_requested.emit(&"surface_minimap"))
	add_child(minimap_panel)

	room_title_label = _add_label("RunRoomTitle", "当前房间", 22, PresentationTheme.color_for_key(&"ui.accent"))
	room_body_label = _add_label("RunRoomBody", "等待探索快照。", 13, PresentationTheme.text_color())
	objective_label = _add_label("RunObjectiveLine", "目标：等待输入。", 13, PresentationTheme.color_for_key(&"ui.warning"))
	objective_label.visible = false
	player_tag_label = _add_label("RunPlayerTag", "回收员", 12, PresentationTheme.color_for_key(&"ui.accent"))

	encounter_title_label = _add_label("RunEncounterTitle", "遭遇提示", 18, PresentationTheme.color_for_key(&"ui.warning"))
	encounter_body_label = _add_label("RunEncounterBody", "等待遭遇公开信息。", 13, PresentationTheme.text_color())
	encounter_result_label = _add_label("RunEncounterResult", "最近结果：暂无遭遇结果。", 12, PresentationTheme.color_for_key(&"ui.muted"))
	encounter_options_box = VBoxContainer.new()
	encounter_options_box.name = "RunEncounterOptions"
	encounter_options_box.add_theme_constant_override("separation", 6)
	encounter_options_box.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(encounter_options_box)

	resource_label = _add_label("RunResourceSummary", "资源：等待数据", 13, PresentationTheme.text_color())

	right_title_label = _add_label("RunProtocolTitle", "协议状态", 18, PresentationTheme.color_for_key(&"ui.warning"))
	right_body_label = _add_label("RunProtocolBody", "协议：--\n压力：--\n危险：--", 13, PresentationTheme.text_color())
	event_label = _add_label("RunEventStatus", "事件：无待处理事件。", 13, PresentationTheme.text_color())
	reward_label = _add_label("RunRewardSummary", "奖励：等待记录。", 12, PresentationTheme.color_for_key(&"ui.muted"))
	reward_label.visible = false
	reward_mask.visible = false
	command_feedback_art = _add_texture_rect_from_ref("RunCommandFeedbackArt", Art21UIPlacementContractScript.slot_ref(&"run_hud", &"bottom_overlay", &"ui.art19.bar.summary_dark"), 0.94)
	command_feedback_art.stretch_mode = TextureRect.STRETCH_SCALE
	command_feedback_label = _add_label("RunCommandFeedback", "操作反馈：等待输入。", 13, PresentationTheme.color_for_key(&"ui.accent"))
	layout_label = _add_label("RunLayoutProfileStatus", "", 11, PresentationTheme.color_for_key(&"ui.muted"))
	layout_label.visible = false

	action_hint_label = _add_label("RunActionHint", "E 搜索  Q 背包  G 拾取  M 地图  Spc 清理  Esc 暂停", 12, PresentationTheme.color_for_key(&"ui.muted"))

	action_bar = HBoxContainer.new()
	action_bar.name = "RunBottomActionButtons"
	action_bar.add_theme_constant_override("separation", 3)
	add_child(action_bar)
	_add_action_button(&"interact", "搜索", func() -> void: interact_requested.emit())
	_add_action_button(&"inventory", "背包", func() -> void: inventory_requested.emit())
	_add_action_button(&"ground_loot", "拾取", func() -> void: ground_loot_requested.emit())
	_add_action_button(&"map", "地图", func() -> void: map_requested.emit(&"surface_button"))
	_add_action_button(&"combat", "清理", func() -> void: combat_requested.emit())
	_add_action_button(&"extract", "撤离", func() -> void: extract_requested.emit())
	_add_action_button(&"pause", "暂停", func() -> void: pause_requested.emit())

	hud = HUDScene.instantiate() as Hud
	hud.name = "RunSurfaceHUD"
	hud.visible = false
	add_child(hud)

	feedback_slot = _add_slot("RunFeedbackSlot")
	overlay_slot = _add_slot("RunOverlaySlot")
	modal_slot = _add_slot("RunModalSlot")
	_apply_layer_order()


func apply_surface_model(model: Dictionary) -> void:
	if not built:
		build()
	scanner_title_label.text = "小地图"
	scanner_legend_label.text = "生命 100  |  战力 0\n黑币 0  |  金币 0"
	scanner_detail_label.text = "背包  Q 展开"
	scanner_summary_label.text = ""
	room_title_label.text = ""
	room_body_label.text = ""
	objective_label.text = ""
	objective_label.visible = false
	room_background_layer.visible = false
	player_sprite_layer.visible = false
	resource_label.text = _resource_copy(model)
	var danger_key := StringName(model.get("danger_theme_key", &"ui.warning"))
	right_title_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(danger_key, PresentationTheme.color_for_key(&"ui.warning")))
	right_body_label.text = _threat_copy(model)
	event_label.text = "事件\n%s" % _compact_line(String(model.get("event_summary", "无待处理事件。")), 14)
	reward_label.text = "奖励\n%s" % _compact_line(String(model.get("reward_summary", "等待记录。")), 14)
	command_feedback_label.text = _feedback_copy(String(model.get("command_feedback", "等待输入。")))
	command_feedback_art.visible = false
	command_feedback_label.visible = false

	var status_text := _lines_text(model.get("status_lines", []), "", 3, 18)
	if status_text != "":
		right_body_label.text = "协议\n%s" % _compact_line(status_text.replace("\n", " / "), 28)
	right_body_label.tooltip_text = "%s\n%s\n%s\n%s" % [
		String(model.get("map_domain_summary", "")),
		String(model.get("run_flow_summary", "")),
		String(model.get("room_common_rule_summary", "")),
		String(model.get("rule_effect_modifier_summary", "")),
	]
	event_label.text = "事件\n%s" % _compact_line(String(model.get("event_summary", event_label.text)), 14)
	event_label.tooltip_text = String(model.get("event_panel_summary", event_label.text))
	reward_label.text = "奖励\n%s" % _compact_line(String(model.get("reward_summary", reward_label.text)), 14)
	reward_label.tooltip_text = String(model.get("loot_panel_summary", reward_label.text))
	action_hint_label.text = ""

	var profile: Dictionary = model.get("layout_profile", {})
	layout_label.text = ""
	_apply_actions(model.get("action_buttons", []))
	_apply_encounter_section(model.get("encounter_section", {}))
	_apply_art10_text_refresh()


func apply_layout_profile(profile: Dictionary) -> void:
	if not built:
		build()
	var supported_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
	if supported_size.x <= 0 or supported_size.y <= 0:
		supported_size = Vector2i(1280, 720)
	var is_low: bool = bool(profile.get("is_low_resolution", false))
	var is_high: bool = bool(profile.get("is_high_resolution", false))
	if hud != null:
		hud.visible = false
	var width: float = float(supported_size.x)
	var height: float = float(supported_size.y)
	var margin: float = 14.0 if is_low else 18.0
	var left_width: float = UILayerContractScript.run_left_width(profile)
	var gameplay_left: float = left_width
	var gameplay_width: float = max(1.0, width - gameplay_left)
	var rail_content_left: float = margin + 12.0
	var rail_content_width: float = max(220.0, left_width - rail_content_left - margin)
	var right_card_width: float = 210.0 if is_low else (270.0 if is_high else 244.0)
	var right_card_height: float = 96.0 if is_low else (126.0 if is_high else 110.0)
	var bottom_info_height: float = 34.0 if is_low else 40.0
	var bottom_key_height: float = 66.0 if is_low else 72.0
	var center_left: float = gameplay_left
	var center_width: float = gameplay_width
	var right_left: float = width - right_card_width - margin
	var right_content_left: float = right_left + margin
	var right_content_width: float = right_card_width - margin * 2.0
	var scanner_map_top: float = margin + 44.0
	var scanner_map_height: float = min(height * 0.52, max(250.0, rail_content_width * 1.06))
	var scanner_stats_top: float = scanner_map_top + scanner_map_height + 12.0
	var backpack_top: float = scanner_stats_top + (102.0 if is_low else 118.0)
	var bottom_key_left: float = gameplay_left + margin
	var bottom_key_width: float = max(420.0, gameplay_width - margin * 2.0)
	var bottom_key_top: float = height - bottom_key_height - margin
	var bottom_info_top: float = bottom_key_top - bottom_info_height - 10.0
	var bottom_info_width: float = min(bottom_key_width * 0.74, 680.0 if is_high else 620.0)
	var bottom_info_left: float = gameplay_left + gameplay_width * 0.5 - bottom_info_width * 0.5
	var encounter_width: float = 164.0 if is_low else 196.0
	var encounter_height: float = 44.0 if is_low else 50.0
	var encounter_left: float = clampf(gameplay_left + gameplay_width * 0.58, gameplay_left + margin, width - encounter_width - margin)
	var encounter_top: float = clampf(height * 0.52 - encounter_height * 0.5, margin + 110.0, bottom_info_top - encounter_height - 12.0)
	var gameplay_square_size: float = min(gameplay_width - margin * 2.0, height - margin * 2.0)
	gameplay_square_size = max(320.0 if is_low else 420.0, gameplay_square_size)
	var gameplay_square_left: float = gameplay_left + max(margin, (gameplay_width - gameplay_square_size) * 0.5)
	if gameplay_square_left + gameplay_square_size > width - margin:
		gameplay_square_left = max(gameplay_left + margin, width - margin - gameplay_square_size)
	var gameplay_square_top: float = margin
	var room_info_width: float = min(gameplay_square_size - 48.0, 420.0 if is_high else 340.0)
	encounter_left = clampf(gameplay_square_left + gameplay_square_size * 0.58, gameplay_square_left + 20.0, gameplay_square_left + gameplay_square_size - encounter_width - 20.0)
	encounter_top = clampf(gameplay_square_top + gameplay_square_size * 0.68, gameplay_square_top + 120.0, gameplay_square_top + gameplay_square_size - encounter_height - 24.0)

	_set_rect(left_backdrop, Rect2(0, 0, left_width, height))
	_set_rect(left_rail_art, Rect2(0, 0, left_width, height))
	_set_rect(right_backdrop, Rect2(right_left, margin, right_card_width, right_card_height))
	_set_rect(status_card_art, Rect2(right_left, margin, right_card_width, right_card_height))
	_set_rect(center_backdrop, Rect2(0, 0, 0, 0))
	_set_rect(room_background_layer, Rect2(0, 0, 0, 0))
	_set_rect(encounter_backdrop, Rect2(encounter_left, encounter_top, encounter_width, encounter_height))
	_set_rect(bottom_backdrop, Rect2(bottom_key_left, bottom_key_top, bottom_key_width, bottom_key_height))
	_set_rect(bottom_overlay_art, Rect2(bottom_key_left, bottom_key_top, bottom_key_width, bottom_key_height))
	_set_rect(resource_backdrop, Rect2(rail_content_left, scanner_stats_top, rail_content_width, 92.0 if is_low else 104.0))
	_set_rect(scanner_text_mask, Rect2(rail_content_left, backpack_top, rail_content_width, 48.0))
	_set_rect(room_text_mask, Rect2(0, 0, 0, 0))
	_set_rect(threat_mask, Rect2(right_content_left, margin + 34.0, right_content_width, 42.0 if is_low else 50.0))
	_set_rect(event_mask, Rect2(right_content_left, margin + (78.0 if is_low else 90.0), right_content_width, 24.0 if is_low else 30.0))
	_set_rect(reward_mask, Rect2(0, 0, 0, 0))
	_set_rect(player_sprite_layer, Rect2(0, 0, 0, 0))
	_set_rect(player_tag_mask, Rect2(0, 0, 0, 0))
	_set_rect(room_hint_softener, Rect2(0, 0, 0, 0))
	_set_rect(scanner_glow_layer, Rect2(0, 0, 0, 0))
	_set_rect(room_glow_layer, Rect2(0, 0, 0, 0))
	_set_rect(protocol_glow_layer, Rect2(right_content_left, margin + 30.0, right_content_width, right_card_height - 44.0))
	_set_rect(bottom_key_glow_layer, Rect2(bottom_key_left + 8.0, bottom_key_top + 8.0, bottom_key_width - 16.0, bottom_key_height - 16.0))
	_set_rect(right_game_fill_layer, Rect2(0, 0, 0, 0))
	left_backdrop.visible = false
	left_rail_art.visible = true
	right_backdrop.visible = false
	status_card_art.visible = true
	bottom_backdrop.visible = false
	bottom_overlay_art.visible = true
	encounter_backdrop.visible = false
	center_backdrop.visible = false
	room_background_layer.visible = false
	player_sprite_layer.visible = false
	resource_backdrop.visible = false
	scanner_text_mask.visible = false
	threat_mask.visible = false
	event_mask.visible = false
	room_glow_layer.visible = false
	room_text_mask.visible = false
	room_hint_softener.visible = false
	player_tag_mask.visible = false
	protocol_glow_layer.visible = false
	bottom_key_glow_layer.visible = false
	right_game_fill_layer.visible = false

	_set_rect(scanner_title_label, Rect2(rail_content_left, margin, rail_content_width, 28))
	_set_rect(scanner_summary_label, Rect2(0, 0, 0, 0))
	_set_rect(minimap_panel, Rect2(rail_content_left, scanner_map_top, rail_content_width, scanner_map_height))
	minimap_panel.apply_layout_profile(profile)
	_set_rect(scanner_legend_label, Rect2(rail_content_left + 8.0, scanner_stats_top + 10.0, rail_content_width - 16.0, 48.0))
	_set_rect(scanner_detail_label, Rect2(rail_content_left + 8.0, backpack_top + 10.0, rail_content_width - 16.0, 24.0))

	_set_rect(room_title_label, Rect2(gameplay_square_left + 26.0, gameplay_square_top + 22.0, room_info_width - 28.0, 24.0))
	_set_rect(room_body_label, Rect2(0, 0, 0, 0))
	_set_rect(objective_label, Rect2(0, 0, 0, 0))
	_set_rect(player_tag_label, Rect2(0, 0, 0, 0))
	_set_rect(encounter_title_label, Rect2(0, 0, 0, 0))
	_set_rect(encounter_body_label, Rect2(0, 0, 0, 0))
	_set_rect(encounter_options_box, Rect2(bottom_info_left + bottom_info_width - encounter_width, bottom_info_top + 4.0, encounter_width, bottom_info_height - 8.0))
	_set_rect(encounter_result_label, Rect2(0, 0, 0, 0))
	_set_rect(resource_label, Rect2(rail_content_left + 8.0, scanner_stats_top + 62.0, rail_content_width - 16.0, 26.0))

	_set_rect(right_title_label, Rect2(right_content_left, margin, right_content_width, 30))
	_set_rect(right_body_label, Rect2(right_content_left + 10.0, margin + 40.0, right_content_width - 20.0, 36.0 if is_low else 44.0))
	_set_rect(event_label, Rect2(right_content_left + 10.0, margin + (76.0 if is_low else 88.0), right_content_width - 20.0, 22.0))
	_set_rect(reward_label, Rect2(0, 0, 0, 0))
	_set_rect(command_feedback_art, Rect2(bottom_info_left, bottom_info_top, bottom_info_width, bottom_info_height))
	_set_rect(command_feedback_label, Rect2(bottom_info_left + 18.0, bottom_info_top + 7.0, bottom_info_width - 36.0, bottom_info_height - 12.0))
	_set_rect(layout_label, Rect2(right_content_left, height - 46.0, right_content_width, 24))
	layout_label.visible = false

	_set_rect(action_hint_label, Rect2(0, 0, 0, 0))
	action_hint_label.visible = false
	_set_rect(action_bar, Rect2(bottom_key_left + 12.0, bottom_key_top + 10.0, bottom_key_width - 24.0, bottom_key_height - 18.0))
	_set_rect(feedback_slot, Rect2(0, 0, width, height))
	_set_rect(overlay_slot, Rect2(0, 0, width, height))
	_set_rect(modal_slot, Rect2(0, 0, width, height))


func show_command_feedback(result: Dictionary) -> void:
	if command_feedback_label == null or result.is_empty():
		return
	var accepted := bool(result.get("accepted", result.get("ok", false)))
	if accepted:
		command_feedback_art.visible = false
		command_feedback_label.visible = false
		return
	command_feedback_art.visible = true
	command_feedback_label.visible = true
	var text := RunUIViewModel.command_result_text(result)
	if text == "":
		text = "操作完成。" if accepted else "操作受阻。"
	command_feedback_label.text = _feedback_copy(text)
	var feedback_state := &"neutral"
	if not accepted:
		feedback_state = &"warning"
	_apply_texture_ref(command_feedback_art, Art21UIPlacementContractScript.slot_ref(&"run_hud", &"bottom_overlay", &"ui.art19.bar.summary_dark"), 0.82)
	var pulse_state := &"ready"
	if not accepted:
		pulse_state = &"warning"
	Art10UISkinKitScript.play_feedback_pulse(command_feedback_label, pulse_state)
	Art10UISkinKitScript.play_feedback_pulse(command_feedback_art, pulse_state, 0.42)


func get_hud() -> Hud:
	if not built:
		build()
	return hud


func get_minimap_panel() -> MiniMapPanel:
	if not built:
		build()
	return minimap_panel


func get_overlay_slot() -> Control:
	if not built:
		build()
	return overlay_slot


func get_modal_slot() -> Control:
	if not built:
		build()
	return modal_slot


func get_feedback_slot() -> Control:
	if not built:
		build()
	return feedback_slot


func apply_legacy_modal_style(panel: PanelContainer, theme_key: StringName = &"ui.accent") -> void:
	if panel == null:
		return
	var accent := PresentationTheme.color_for_key(theme_key, PresentationTheme.color_for_key(&"ui.accent"))
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.028, 0.032, 0.96), accent, 2))
	_style_modal_children(panel)


func _apply_layer_order() -> void:
	_establish_run_layer_roots()
	for root in _run_layer_roots():
		if root == null:
			continue
		var root_name := StringName(root.name)
		if root_name == &"RunRoomViewportRoot":
			root.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UILayerContractScript.apply_local_layer(root, 0)
		else:
			UILayerContractScript.configure_root(root, UILayerContractScript.run_root_role(root_name))
		for child in root.get_children():
			UILayerContractScript.apply_local_layer(child, _local_run_layer_for_node(child))


func _establish_run_layer_roots() -> void:
	run_game_stage_root = UILayerContractScript.ensure_root(self, &"RunGameStageRoot", &"gameplay_viewport")
	run_room_viewport_root = UILayerContractScript.ensure_root(run_game_stage_root, &"RunRoomViewportRoot", &"gameplay_viewport")
	run_room_viewport_root.z_as_relative = true
	run_room_viewport_root.z_index = 0
	run_left_info_rail_root = UILayerContractScript.ensure_root(self, &"RunLeftInfoRailRoot", &"content_panel")
	run_top_right_status_root = UILayerContractScript.ensure_root(self, &"RunTopRightStatusRoot", &"status_card")
	run_floating_info_root = UILayerContractScript.ensure_root(self, &"RunFloatingInfoRoot", &"floating_info")
	run_interaction_prompt_root = UILayerContractScript.ensure_root(self, &"RunInteractionPromptRoot", &"floating_info")
	run_action_overlay_root = UILayerContractScript.ensure_root(self, &"RunActionOverlayRoot", &"action_bar")
	run_overlay_root = UILayerContractScript.ensure_root(self, &"RunOverlayRoot", &"overlay")
	run_modal_root = UILayerContractScript.ensure_root(self, &"RunModalRoot", &"modal")

	for child in get_children().duplicate():
		if UILayerContractScript.is_run_root_name(StringName(child.name)):
			continue
		var target_root := _run_target_root_for_node(child)
		if target_root == null:
			continue
		remove_child(child)
		target_root.add_child(child)

	for root_name_variant in UILayerContractScript.RUN_ROOT_ORDER:
		var root_name := StringName(root_name_variant)
		var root := get_node_or_null(String(root_name)) as Control
		if root != null and root.get_parent() == self:
			move_child(root, get_child_count() - 1)


func _run_layer_roots() -> Array:
	return [
		run_game_stage_root,
		run_room_viewport_root,
		run_left_info_rail_root,
		run_top_right_status_root,
		run_floating_info_root,
		run_interaction_prompt_root,
		run_action_overlay_root,
		run_overlay_root,
		run_modal_root,
	]


func _run_target_root_for_node(node: Node) -> Control:
	var target_name := UILayerContractScript.run_root_for_node(node)
	match target_name:
		&"RunRoomViewportRoot":
			return run_room_viewport_root
		&"RunLeftInfoRailRoot":
			return run_left_info_rail_root
		&"RunTopRightStatusRoot":
			return run_top_right_status_root
		&"RunFloatingInfoRoot":
			return run_floating_info_root
		&"RunInteractionPromptRoot":
			return run_interaction_prompt_root
		&"RunActionOverlayRoot":
			return run_action_overlay_root
		&"RunOverlayRoot":
			return run_overlay_root
		&"RunModalRoot":
			return run_modal_root
		_:
			return run_room_viewport_root


func _local_run_layer_for_node(node: Node) -> int:
	var node_name := String(node.name)
	if node_name.find("BackgroundFill") >= 0:
		return 0
	if node_name.find("PlayerSprite") >= 0:
		return 4
	if node_name.find("MiniMap") >= 0:
		return 5
	if node_name.find("SignalPanel") >= 0 or node_name.find("GameAreaFill") >= 0:
		return 1
	if node_name.find("Glow") >= 0 or node_name.find("Softener") >= 0:
		return 2
	if node_name.find("Mask") >= 0 or node_name.find("Backdrop") >= 0 or node_name.find("Rail") >= 0 or node_name.find("Surface") >= 0 or node_name.find("Pocket") >= 0 or node_name.find("Slot") >= 0:
		return 0
	if node is Label or node is Button or node is Container:
		return 4
	return 1


func _set_layer(item: Variant, layer: int) -> void:
	if not (item is CanvasItem):
		return
	var canvas_item := item as CanvasItem
	canvas_item.z_as_relative = false
	canvas_item.z_index = layer


func apply_legacy_button_style(button: Button, tone: StringName = &"secondary") -> void:
	if button == null:
		return
	_apply_action_button_style(button, tone, not button.disabled)


func _add_panel(node_name: String, color: Color, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(color, border_color, 1))
	Art10UISkinKitScript.apply_panel(panel, &"surface")
	add_child(panel)
	return panel


func _add_color_layer(node_name: String, color: Color) -> ColorRect:
	var layer := ColorRect.new()
	layer.name = node_name
	layer.color = color
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	return layer


func _add_label(node_name: String, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	Art10UISkinKitScript.apply_label(label, font_size, color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _add_texture_rect_from_ref(node_name: String, asset_ref: Dictionary, alpha: float = 1.0) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.modulate = Color(1.0, 1.0, 1.0, alpha)
	_apply_texture_ref(texture_rect, asset_ref, alpha)
	add_child(texture_rect)
	return texture_rect


func _add_nine_patch_from_ref(node_name: String, asset_ref: Dictionary, alpha: float = 1.0, margin: int = 12) -> NinePatchRect:
	var frame := NinePatchRect.new()
	frame.name = node_name
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.modulate = Color(1.0, 1.0, 1.0, alpha)
	frame.texture = Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	frame.set_patch_margin(SIDE_LEFT, margin)
	frame.set_patch_margin(SIDE_TOP, margin)
	frame.set_patch_margin(SIDE_RIGHT, margin)
	frame.set_patch_margin(SIDE_BOTTOM, margin)
	add_child(frame)
	return frame


func _apply_texture_ref(texture_rect: TextureRect, asset_ref: Dictionary, alpha: float = 1.0) -> void:
	if texture_rect == null:
		return
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture != null:
		texture_rect.texture = texture
	texture_rect.modulate = Color(1.0, 1.0, 1.0, alpha)


func _room_background_ref(room_type: StringName) -> Dictionary:
	var visual := PresentationMapping.room_visual_from_snapshot({"current_room": room_type})
	return Art09ManifestAssetMappingScript.asset_ref(
		StringName(visual.get("background_asset_id", &"room.background.normal")),
		&"room.background.normal",
		&"room_background",
		room_type
	)


func _add_action_button(action_id: StringName, label: String, callback: Callable) -> void:
	var button := Art10UISkinKitScript.make_bottom_key_button(label, _key_label_for_action(action_id))
	button.name = "RunAction_%s" % String(action_id)
	button.custom_minimum_size = Vector2(86, 36)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	button.add_theme_font_size_override("font_size", 12)
	_apply_action_button_style(button, &"secondary", true)
	_apply_key_prompt_icon(button, action_id)
	action_bar.add_child(button)
	action_buttons[action_id] = button


func _apply_key_prompt_icon(button: Button, action_id: StringName) -> void:
	if button == null:
		return
	button.icon = null


func _add_slot(node_name: String) -> Control:
	var slot := Control.new()
	slot.name = node_name
	slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot)
	return slot


func _apply_actions(actions: Variant) -> void:
	if not (actions is Array):
		return
	for action in actions:
		if not (action is Dictionary):
			continue
		var action_data: Dictionary = action
		var action_id := StringName(action_data.get("id", &""))
		if not action_buttons.has(action_id):
			continue
		var button: Button = action_buttons[action_id]
		button.text = "%s %s" % [_key_label_for_action(action_id), _short_action_label(action_id, String(action_data.get("label", button.text)))]
		var enabled := bool(action_data.get("enabled", true))
		var description := String(action_data.get("description", ""))
		var disabled_reason := String(action_data.get("disabled_reason", ""))
		button.disabled = not enabled
		button.tooltip_text = ""
		_apply_action_button_style(button, StringName(action_data.get("tone", &"secondary")), enabled)
		_apply_key_prompt_icon(button, action_id)


func _key_label_for_action(action_id: StringName) -> String:
	match action_id:
		&"interact":
			return "E"
		&"inventory":
			return "Q"
		&"ground_loot":
			return "G"
		&"map":
			return "M"
		&"combat":
			return "Spc"
		&"extract":
			return "T"
		&"pause":
			return "Esc"
		_:
			return ""


func _short_action_label(action_id: StringName, fallback: String) -> String:
	match action_id:
		&"interact":
			return "搜索"
		&"inventory":
			return "背包"
		&"ground_loot":
			return "拾取"
		&"map":
			return "地图"
		&"combat":
			return "清理"
		&"extract":
			return "撤离"
		&"pause":
			return "暂停"
		_:
			return fallback


func _apply_encounter_section(section_variant: Variant) -> void:
	var section := _dict_variant(section_variant)
	encounter_title_label.text = _compact_line(String(section.get("title", "事件行动")), 10)
	encounter_body_label.text = _compact_line(String(section.get("body", "当前无公开信息。")), 22)
	encounter_result_label.text = "结果  %s" % _compact_line(String(section.get("result_summary", "暂无结果。")), 18)
	_clear_encounter_option_buttons()
	var options := _array_variant(section.get("options", []))
	for option_variant in options:
		if not (option_variant is Dictionary):
			continue
		var option: Dictionary = option_variant
		var button := Button.new()
		var option_id := StringName(option.get("id", &""))
		var disabled := bool(option.get("disabled", false))
		var requires_confirm := bool(option.get("requires_confirm", false))
		var title := String(option.get("title", String(option_id)))
		button.name = "RunEncounterOption_%s" % String(option_id)
		button.text = "%s%s" % [_compact_line(title, 9), "  确认" if requires_confirm else ""]
		button.custom_minimum_size = Vector2(176, 28)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = disabled
		button.tooltip_text = _encounter_option_tooltip(option)
		button.add_theme_font_size_override("font_size", 12)
		Art10UISkinKitScript.apply_transparent_button(button, &"primary" if not disabled else &"secondary", 12, &"key", 0)
		if not disabled:
			var payload := _dict_variant(option.get("command_payload", {}))
			button.pressed.connect(_on_encounter_option_pressed.bind(option_id, payload))
		encounter_options_box.add_child(button)
		encounter_option_buttons.append(button)
	encounter_backdrop.visible = false
	encounter_options_box.visible = not encounter_option_buttons.is_empty()
	if encounter_option_buttons.is_empty():
		return
		var placeholder := Label.new()
		placeholder.name = "RunEncounterOptionPlaceholder"
		placeholder.text = "暂无可执行行动。"
		placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		placeholder.add_theme_font_size_override("font_size", 12)
		placeholder.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		Art10UISkinKitScript.apply_label(placeholder, 12, PresentationTheme.color_for_key(&"ui.muted"))
		encounter_options_box.add_child(placeholder)


func _encounter_option_tooltip(option: Dictionary) -> String:
	var summary := String(option.get("summary", ""))
	var disabled := bool(option.get("disabled", false))
	if disabled:
		var reason := String(option.get("disabled_reason", ""))
		if reason != "":
			return "%s\n禁用：%s" % [summary, reason]
	return summary


func _on_encounter_option_pressed(option_id: StringName, command_payload: Dictionary) -> void:
	if option_id == &"" or not command_payload.has("option_id"):
		return
	encounter_option_selected.emit(option_id, command_payload.duplicate(true))


func _clear_encounter_option_buttons() -> void:
	for child in encounter_options_box.get_children():
		encounter_options_box.remove_child(child)
		child.queue_free()
	encounter_option_buttons.clear()


func _apply_art10_text_refresh() -> void:
	for label in [
		scanner_title_label,
		scanner_summary_label,
		scanner_legend_label,
		scanner_detail_label,
		room_title_label,
		room_body_label,
		objective_label,
		player_tag_label,
		encounter_title_label,
		encounter_body_label,
		encounter_result_label,
		resource_label,
		right_title_label,
		right_body_label,
		event_label,
		reward_label,
		command_feedback_label,
		layout_label,
		action_hint_label,
	]:
		if label is Label:
			Art10UISkinKitScript.apply_label_token(label, &"hud_small", &"text")
			label.clip_text = true
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for title_label in [scanner_title_label, room_title_label, encounter_title_label, right_title_label]:
		if title_label is Label:
			Art10UISkinKitScript.apply_label_token(title_label, &"hud", &"accent")
			title_label.clip_text = true
			title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if command_feedback_label is Label:
		command_feedback_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		command_feedback_label.clip_text = true
		command_feedback_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for left_label in [scanner_summary_label, scanner_legend_label, scanner_detail_label, resource_label]:
		if left_label is Label:
			left_label.clip_text = true
			left_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for action_id in action_buttons.keys():
		var action_button := action_buttons[action_id] as Button
		action_button.custom_minimum_size = Vector2(86, 36)
		_apply_action_button_style(action_button, &"secondary", not action_button.disabled)
		_apply_key_prompt_icon(action_button, StringName(action_id))
	for button in encounter_option_buttons:
		Art10UISkinKitScript.apply_transparent_button(button, &"primary" if button != null and not button.disabled else &"secondary", 12, &"key", 0)


func _array_variant(raw: Variant) -> Array:
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _dict_variant(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


func _panel_style(color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _apply_action_button_style(button: Button, tone: StringName, enabled: bool) -> void:
	Art10UISkinKitScript.apply_transparent_button(button, tone, 13, &"key", 0)
	button.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.70, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.82, 0.45, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.68, 0.64, 0.52, 0.96))
	button.modulate = Color(1, 1, 1, 1) if enabled else Color(0.86, 0.86, 0.80, 1)


func _tone_color(tone: StringName) -> Color:
	match tone:
		&"primary":
			return PresentationTheme.color_for_key(&"ui.accent")
		&"danger":
			return PresentationTheme.color_for_key(&"ui.danger")
		&"warning":
			return PresentationTheme.color_for_key(&"ui.warning")
		_:
			return PresentationTheme.color_for_key(&"ui.muted")


func _style_modal_children(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.add_theme_color_override("font_color", PresentationTheme.text_color())
	elif node is Button:
		var button := node as Button
		_apply_action_button_style(button, &"secondary", not button.disabled)
	for child in node.get_children():
		_style_modal_children(child)


func _lines_text(lines: Variant, fallback: String, max_lines: int = 4, max_chars: int = 24) -> String:
	if not (lines is Array):
		return fallback
	var typed_lines: Array = lines
	if typed_lines.is_empty():
		return fallback
	var text := ""
	var visible_count: int = mini(typed_lines.size(), max_lines)
	for index in range(visible_count):
		if index > 0:
			text += "\n"
		text += _shorten_copy(String(typed_lines[index]), max_chars)
	if typed_lines.size() > visible_count:
		text += "\n更多已收起"
	return Art10UISkinKitScript.sanitize_player_copy(text)


func _shorten_copy(text: String, max_chars: int) -> String:
	return Art10UISkinKitScript.short_summary(text, max_chars)


func _compact_line(text: String, max_chars: int) -> String:
	return Art10UISkinKitScript.short_summary(text, max_chars)


func _feedback_copy(text: String) -> String:
	var summary := _compact_line(text, 26)
	if summary == "":
		summary = "待命"
	return summary


func _threat_copy(model: Dictionary) -> String:
	return "威胁\n协议 %s | 压力 %s/100\n%s" % [
		model.get("protocol_level", "--"),
		model.get("pressure", "--"),
		_compact_line(String(model.get("danger_label", "--")), 12),
	]


func _resource_copy(model: Dictionary) -> String:
	return "物资  暂无待回收"


func _set_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
