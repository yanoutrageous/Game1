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
const Art24ItemVisualCatalog := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const ItemRarityDescriptor := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const RunSurfaceModelScript := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")
const PROTOCOL_LEVEL_ASSET_PREFIX := "ui.art24.ui.protocol.level_"
const PROTOCOL_LEVEL_FALLBACK_ASSET := &"ui.art24.ui.protocol.level_5"
const PROTOCOL_PRESSURE_MAX := 100.0
const COMMAND_FEEDBACK_TOAST_SECONDS := 2.2
const STATUS_CARD_FRAME_PATH := "res://assets/ui/art21r2/run_hud/ui_art21r2_run_status_card_frame.png"
const REDUNDANT_ENCOUNTER_OPTION_IDS := [&"search", &"open_chest", &"attack_basic"]
const EVENT_MODAL_ENCOUNTER_TYPES := [&"trader", &"dice", &"altar", &"trap"]
const FOCUSED_MODAL_IDS := [
	&"event",
	&"loot_result",
	&"extract_confirm",
	&"combat_flee_confirm",
	&"pause",
	&"settings",
	&"abandon_confirm",
	&"inventory",
	&"map",
	&"result",
]
const PROTOCOL_LEVEL_COLORS := {
	1: Color(0.94, 0.22, 0.18, 0.96),
	2: Color(0.96, 0.44, 0.18, 0.96),
	3: Color(0.96, 0.68, 0.20, 0.96),
	4: Color(0.48, 0.78, 0.54, 0.96),
	5: Color(0.28, 0.82, 0.58, 0.96),
}

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
var protocol_level_plate: TextureRect
var protocol_pressure_track: ColorRect
var protocol_pressure_fill: ColorRect
var bottom_key_glow_layer: ColorRect
var right_game_fill_layer: ColorRect
var left_rail_art: NinePatchRect
var status_card_art: NinePatchRect
var bottom_overlay_art: NinePatchRect
var mine_risk_tag_art: TextureRect
var player_sprite_layer: TextureRect
var scanner_title_label: Label
var scanner_summary_label: Label
var scanner_legend_label: Label
var scanner_detail_label: Label
var backpack_scroll: ScrollContainer
var backpack_strip: GridContainer
var backpack_empty_watermark: TextureRect
var backpack_detail_label: Label
var backpack_capacity_label: Label
var room_title_label: Label
var room_body_label: Label
var objective_label: Label
var player_tag_label: Label
var encounter_title_label: Label
var encounter_body_label: Label
var encounter_result_label: Label
var resource_label: Label
var mine_risk_label: Label
var right_title_label: Label
var right_body_label: Label
var event_label: Label
var reward_label: Label
var command_feedback_art: TextureRect
var command_feedback_label: Label
var layout_label: Label
var action_hint_label: Label
var encounter_options_box: GridContainer
var action_bar: HBoxContainer
var action_buttons: Dictionary = {}
var active_modal_visibility_policy: StringName = &""
var encounter_option_buttons: Array[Button] = []
var action_guidance_data: Dictionary = {}
var default_action_guidance := ""
var active_guidance_action: StringName = &""
var encounter_option_base_rect := Rect2()
var last_backpack_signature := "__uninitialized__"
var current_protocol_level := 5
var current_protocol_pressure := 0.0
var command_feedback_time_remaining := 0.0
var built := false
var current_layout_profile: Dictionary = {}
var ui_scale_factor := 1.0

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
	ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	Art10UISkinKitScript.apply_player_ui_theme(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 180

	left_backdrop = _add_panel("RunScannerRail", PresentationTheme.panel_color(), PresentationTheme.color_for_key(&"ui.accent"))
	left_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.006, 0.014, 0.016, 0.72), PresentationTheme.color_for_key(&"ui.accent"), 2))
	Art10UISkinKitScript.apply_panel(left_backdrop, &"deep")
	left_rail_art = _add_nine_patch_from_ref("Art21RunLeftInfoRail", Art21UIPlacementContractScript.slot_ref(&"run_hud", &"left_info_rail", &"ui.art21.shared.panel.page_frame.normal"), 0.96, 14)
	_apply_art24_frame(left_rail_art, "res://assets/art24/ui/ue/ui_panel_left.png", 20)
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
	_apply_art24_frame(status_card_art, STATUS_CARD_FRAME_PATH, 12)
	protocol_level_plate = _add_texture_rect_from_ref("RunProtocolLevelPlate", _protocol_level_ref(5), 0.48)
	protocol_level_plate.stretch_mode = TextureRect.STRETCH_SCALE
	protocol_level_plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	protocol_pressure_track = _add_color_layer("RunProtocolPressureTrack", Color(0.01, 0.02, 0.022, 0.92))
	protocol_pressure_fill = _add_color_layer("RunProtocolPressureFill", _protocol_level_color(5))
	bottom_backdrop = _add_panel("RunActionBarSurface", PresentationTheme.panel_color(), PresentationTheme.color_for_key(&"ui.accent"))
	bottom_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.006, 0.014, 0.016, 0.70), PresentationTheme.color_for_key(&"ui.accent"), 2))
	Art10UISkinKitScript.apply_panel(bottom_backdrop, &"summary")
	bottom_overlay_art = _add_nine_patch_from_ref("Art21RunBottomOverlay", Art21UIPlacementContractScript.slot_ref(&"run_hud", &"bottom_overlay", &"ui.art19.bar.summary_dark"), 0.96, 12)
	_apply_art24_frame(bottom_overlay_art, "res://assets/art24/ui/ue/ui_bottom_bar.png", 20)
	mine_risk_tag_art = _add_texture_rect_from_ref(
		"RunMineRiskTagArt",
		Art09ManifestAssetMappingScript.asset_ref(
			&"ui.art24.ui.ue.ui_mine_risk_tag",
			&"ui.hud.mine_risk_tag",
			&"mine_risk_tag",
			&"known"
		),
		1.0
	)
	mine_risk_tag_art.stretch_mode = TextureRect.STRETCH_SCALE
	mine_risk_tag_art.visible = false
	resource_backdrop = _add_panel("RunResourcePocket", Color(0.035, 0.055, 0.055, 0.92), PresentationTheme.color_for_key(&"mini.chest"))
	resource_backdrop.add_theme_stylebox_override("panel", _interior_band_style(Color(0.006, 0.014, 0.016, 0.44)))
	scanner_text_mask = _add_panel("RunScannerTextMask", Color(0.012, 0.026, 0.030, 0.72), PresentationTheme.color_for_key(&"ui.accent"))
	scanner_text_mask.add_theme_stylebox_override("panel", _interior_band_style(Color(0.006, 0.014, 0.016, 0.34)))
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
	scanner_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scanner_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scanner_title_label.add_theme_color_override("font_outline_color", Color(0.005, 0.01, 0.012, 0.98))
	scanner_title_label.add_theme_constant_override("outline_size", 2)
	scanner_summary_label = _add_label("RunScannerSummary", "", 13, PresentationTheme.text_color())
	scanner_legend_label = _add_label("RunScannerLegend", "P 当前 | ? 未知 | F 标记 | X 撤离", 13, PresentationTheme.color_for_key(&"ui.muted"))

	scanner_detail_label = _add_label("RunScannerDetail", "已知 / 危险 / 撤离", 13, PresentationTheme.color_for_key(&"ui.muted"))
	backpack_scroll = ScrollContainer.new()
	backpack_scroll.name = "RunBackpackScroll"
	backpack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	backpack_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	backpack_scroll.follow_focus = true
	backpack_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backpack_scroll)
	backpack_strip = GridContainer.new()
	backpack_strip.name = "RunBackpackStrip"
	backpack_strip.columns = 1
	backpack_strip.add_theme_constant_override("h_separation", 0)
	backpack_strip.add_theme_constant_override("v_separation", 4)
	backpack_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backpack_strip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	backpack_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	backpack_scroll.add_child(backpack_strip)
	backpack_empty_watermark = TextureRect.new()
	backpack_empty_watermark.name = "RunBackpackEmptyWatermark"
	backpack_empty_watermark.texture = load("res://assets/art24/ui/ue/ui_icon_backpack.png") as Texture2D
	backpack_empty_watermark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backpack_empty_watermark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	backpack_empty_watermark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backpack_empty_watermark.modulate = Color(0.58, 0.72, 0.64, 0.16)
	backpack_empty_watermark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backpack_empty_watermark)
	backpack_detail_label = _add_label("RunBackpackDetail", "暂无物资", 13, PresentationTheme.color_for_key(&"ui.muted"))
	backpack_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	backpack_detail_label.max_lines_visible = 3
	backpack_detail_label.clip_text = true
	backpack_capacity_label = _add_label("RunBackpackCapacity", "0 / 0", 13, PresentationTheme.color_for_key(&"ui.muted"))
	backpack_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	backpack_capacity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	minimap_panel = MiniMapScene.instantiate() as MiniMapPanel
	minimap_panel.name = "RunScannerMiniMap"
	minimap_panel.clip_contents = true
	minimap_panel.open_map_requested.connect(func() -> void: map_requested.emit(&"surface_minimap"))
	add_child(minimap_panel)

	room_title_label = _add_label("RunRoomTitle", "当前房间", 22, PresentationTheme.color_for_key(&"ui.accent"))
	room_body_label = _add_label("RunRoomBody", "等待探索快照。", 13, PresentationTheme.text_color())
	room_body_label.visible = false
	objective_label = _add_label("RunObjectiveLine", "目标：等待输入。", 13, PresentationTheme.color_for_key(&"ui.warning"))
	objective_label.visible = false
	player_tag_label = _add_label("RunPlayerTag", "回收员", 12, PresentationTheme.color_for_key(&"ui.accent"))
	player_tag_label.visible = false

	encounter_title_label = _add_label("RunEncounterTitle", "遭遇提示", 18, PresentationTheme.color_for_key(&"ui.warning"))
	encounter_body_label = _add_label("RunEncounterBody", "当前没有可处理的目标。", 13, PresentationTheme.text_color())
	encounter_result_label = _add_label("RunEncounterResult", "最近结果：暂无遭遇结果。", 12, PresentationTheme.color_for_key(&"ui.muted"))
	# These labels are retained as compatibility probes only. Encounter choices
	# now live in a bounded option strip or focused world modal; a zero-width
	# visible label wraps one glyph per line and can leak at the viewport edge.
	encounter_title_label.visible = false
	encounter_body_label.visible = false
	encounter_result_label.visible = false
	encounter_options_box = GridContainer.new()
	encounter_options_box.name = "RunEncounterOptions"
	encounter_options_box.columns = 1
	encounter_options_box.add_theme_constant_override("h_separation", 6)
	encounter_options_box.add_theme_constant_override("v_separation", 6)
	encounter_options_box.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(encounter_options_box)

	resource_label = _add_label("RunResourceSummary", "资源：等待数据", 13, PresentationTheme.text_color())
	# Keep the historical resource_label property as a read-only compatibility
	# probe, but present the authoritative count in the UE-aligned plate below
	# the room. The left rail must not duplicate the same risk signal.
	resource_label.visible = false
	mine_risk_label = _add_label("RunMineRiskText", "", 16, Color(0.91, 0.87, 0.78, 1.0))
	mine_risk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mine_risk_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mine_risk_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	mine_risk_label.clip_text = false
	mine_risk_label.visible = false

	right_title_label = _add_label("RunProtocolTitle", "协议状态", 18, PresentationTheme.color_for_key(&"ui.warning"))
	right_body_label = _add_label("RunProtocolBody", "协议：--\n压力：--\n危险：--", 13, PresentationTheme.text_color())
	event_label = _add_label("RunEventStatus", "事件：无待处理事件。", 13, PresentationTheme.text_color())
	reward_label = _add_label("RunRewardSummary", "奖励：等待记录。", 12, PresentationTheme.color_for_key(&"ui.muted"))
	reward_label.visible = false
	reward_mask.visible = false
	# The run bottom-bar brush contains several painted key slots. Reusing it for
	# player guidance created fake empty controls underneath live copy, so the
	# information band uses the approved continuous modal section instead.
	command_feedback_art = _add_texture_rect_from_ref("RunCommandFeedbackArt", Art21UIPlacementContractScript.component_ref(&"art21r2.modal.section.panel", &"ui.art19.bar.summary_dark"), 0.94)
	command_feedback_art.stretch_mode = TextureRect.STRETCH_SCALE
	command_feedback_label = _add_label("RunCommandFeedback", "等待行动。", 13, PresentationTheme.color_for_key(&"ui.accent"))
	command_feedback_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	command_feedback_label.clip_text = true
	command_feedback_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	command_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	command_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	command_feedback_label.add_theme_color_override("font_outline_color", Color(0.005, 0.01, 0.012, 0.98))
	command_feedback_label.add_theme_constant_override("outline_size", 3)
	command_feedback_art.visible = false
	command_feedback_label.visible = false
	layout_label = _add_label("RunLayoutProfileStatus", "", 11, PresentationTheme.color_for_key(&"ui.muted"))
	layout_label.visible = false

	action_hint_label = _add_label("RunActionHint", _default_action_hint_text(), 13, PresentationTheme.color_for_key(&"ui.muted"))
	action_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	action_hint_label.clip_text = true
	action_hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	action_hint_label.visible = false

	action_bar = HBoxContainer.new()
	action_bar.name = "RunBottomActionButtons"
	action_bar.add_theme_constant_override("separation", 3)
	add_child(action_bar)
	_add_action_button(&"interact", "搜索", func() -> void: interact_requested.emit())
	_add_action_button(&"inventory", "背包", func() -> void: inventory_requested.emit())
	_add_action_button(&"ground_loot", "拾取", func() -> void: ground_loot_requested.emit())
	_add_action_button(&"map", "地图", func() -> void: map_requested.emit(&"surface_button"))
	_add_action_button(&"combat", "攻击", func() -> void: combat_requested.emit())
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
	_update_protocol_presentation(5, 0)


func _process(delta: float) -> void:
	advance_command_feedback(delta)


func apply_surface_model(model: Dictionary) -> void:
	if not built:
		build()
	scanner_title_label.text = "区域扫描图"
	scanner_legend_label.text = _resource_lines(String(model.get("resource_summary", "")))
	scanner_detail_label.text = "作业包  %s 展开" % SemanticActionHintScript.current_binding_label(&"open_inventory")
	_refresh_backpack_strip(model.get("backpack_items", []))
	backpack_capacity_label.text = "负重 %s / %s" % [model.get("backpack_used", 0), model.get("backpack_capacity", 0)]
	scanner_summary_label.text = ""
	room_title_label.text = ""
	room_body_label.text = ""
	objective_label.text = ""
	objective_label.visible = false
	room_background_layer.visible = false
	player_sprite_layer.visible = false
	var mine_risk := _dict_variant(model.get("mine_risk", {}))
	_update_mine_risk_presentation(mine_risk.get("count", -1))
	var protocol_level := clampi(int(model.get("protocol_level", 5)), 1, 5)
	var protocol_title := String(model.get("protocol_title", RunSurfaceModelScript.protocol_title_for_level(protocol_level)))
	right_title_label.text = "协议 %s" % protocol_level
	right_body_label.text = "%s · 压力 %s/100" % [protocol_title, model.get("pressure", "--")]
	_update_protocol_presentation(model.get("protocol_level", 5), model.get("pressure", 0))
	event_label.text = ""
	event_label.visible = false
	reward_label.text = "奖励\n%s" % _compact_line(String(model.get("reward_summary", "等待记录。")), 14)
	if command_feedback_time_remaining <= 0.0:
		command_feedback_art.visible = false
		command_feedback_label.visible = false

	var status_text := _lines_text(model.get("status_lines", []), "", 3, 18)
	right_body_label.tooltip_text = status_text
	event_label.text = ""
	event_label.visible = false
	event_label.tooltip_text = String(model.get("event_panel_summary", ""))
	reward_label.text = "奖励\n%s" % _compact_line(String(model.get("reward_summary", reward_label.text)), 14)
	reward_label.tooltip_text = String(model.get("loot_panel_summary", reward_label.text))
	var action_data: Variant = model.get("action_buttons", [])
	default_action_guidance = _player_action_hint(String(model.get("action_hint", "")), action_data)
	action_hint_label.text = default_action_guidance
	action_hint_label.visible = false

	var profile: Dictionary = model.get("layout_profile", {})
	layout_label.text = ""
	_apply_actions(action_data)
	_apply_encounter_section(model.get("encounter_section", {}))
	_apply_art10_text_refresh()
	_apply_ue_readability_tokens(profile)
	# Shared typography tokens intentionally reset title accents. Re-apply the
	# protocol's authoritative level color after those generic tokens so room
	# danger styling cannot replace it.
	_update_protocol_presentation(model.get("protocol_level", 5), model.get("pressure", 0))


func apply_combat_snapshot(snapshot: Dictionary) -> void:
	if not built:
		return
	scanner_legend_label.text = _resource_lines(
		"生命 %s/%s | 作业强度 %s | 待结算黑币 %s | 安全金币 %s" % [
			snapshot.get("hp", 0),
			snapshot.get("max_hp", 0),
			snapshot.get("power", 0),
			snapshot.get("black_coin", 0),
			snapshot.get("gold_coin", 0),
		]
	)
	var combat_runtime: Dictionary = snapshot.get("combat_runtime", {})
	var alive_enemies := 0
	for raw_enemy in (combat_runtime.get("enemies", []) as Array):
		if raw_enemy is Dictionary and int((raw_enemy as Dictionary).get("hp", 0)) > 0:
			alive_enemies += 1
	var protocol_level := clampi(int(snapshot.get("protocol_level", 5)), 1, 5)
	right_title_label.text = "协议 %s" % protocol_level
	right_body_label.text = "%s · 压力 %s/100" % [
		RunSurfaceModelScript.protocol_title_for_level(protocol_level),
		snapshot.get("pressure", 0),
	]
	right_body_label.tooltip_text = "当前威胁：%d · 生命 %s/%s" % [
		alive_enemies,
		snapshot.get("hp", 0),
		snapshot.get("max_hp", 0),
	]
	_update_protocol_presentation(snapshot.get("protocol_level", 5), snapshot.get("pressure", 0))
	var adjacent := int(snapshot.get("adjacent_mines", -1)) if snapshot.has("adjacent_mines") else -1
	_update_mine_risk_presentation(adjacent)


func apply_combat_attack_state(attack_input: Dictionary) -> void:
	var combat_button := action_buttons.get(&"combat") as Button
	if combat_button == null:
		return
	if attack_input.is_empty():
		combat_button.modulate = Color.WHITE
		combat_button.remove_meta("attack_cooldown_remaining")
		return
	var ready := bool(attack_input.get("ready", false))
	var buffer_window_open := bool(attack_input.get("buffer_window_open", false))
	var cooldown_remaining := maxf(
		0.0,
		float(attack_input.get("cooldown_remaining_seconds", 0.0))
	)
	combat_button.set_meta("attack_cooldown_remaining", cooldown_remaining)
	combat_button.set_meta("attack_ready", ready)
	combat_button.set_meta("attack_buffer_window_open", buffer_window_open)
	combat_button.modulate = (
		Color.WHITE
		if ready or buffer_window_open
		else Color(0.52, 0.56, 0.52, 0.86)
	)
	if cooldown_remaining > 0.0:
		combat_button.tooltip_text = "攻击冷却 %.1f 秒" % cooldown_remaining


func _update_mine_risk_presentation(adjacent_value: Variant) -> void:
	var descriptor := RunSurfaceModelScript.mine_risk_descriptor(adjacent_value)
	var adjacent := int(descriptor.get("count", -1))
	var known := bool(descriptor.get("known", false)) and adjacent >= 0 and adjacent <= 8
	# Historical runners inspect this property; keeping it synchronized does not
	# make the duplicate left-rail copy visible.
	if resource_label != null:
		resource_label.text = String(descriptor.get("display_text", "周围雷险 ? · 未知"))
		resource_label.visible = false
	if mine_risk_label != null:
		mine_risk_label.text = "周围雷险：%d" % adjacent if known else ""
		mine_risk_label.tooltip_text = "数字表示当前区域周围八格中的雷险数量；斜向区域也会计入。"
		mine_risk_label.visible = known
		mine_risk_label.set_meta("adjacent_mine_count", adjacent)
	if mine_risk_tag_art != null:
		mine_risk_tag_art.visible = known
		mine_risk_tag_art.set_meta("adjacent_mine_count", adjacent)


func set_ui_scale_factor(value: float) -> void:
	ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value)
	Art10UISkinKitScript.apply_player_ui_theme(self)
	if not current_layout_profile.is_empty():
		current_layout_profile["ui_scale_factor"] = ui_scale_factor
		apply_layout_profile(current_layout_profile)
	_refresh_action_button_visibility()


func apply_modal_visibility_policy(modal_id: StringName) -> void:
	active_modal_visibility_policy = modal_id
	var suppress_footer := modal_id in FOCUSED_MODAL_IDS
	var suppress_all_hud := modal_id == &"result"
	if suppress_footer:
		clear_command_feedback()
	if run_floating_info_root != null:
		run_floating_info_root.visible = not suppress_footer
	if run_interaction_prompt_root != null:
		run_interaction_prompt_root.visible = not suppress_footer
	if run_action_overlay_root != null:
		run_action_overlay_root.visible = not suppress_footer
	if run_left_info_rail_root != null:
		run_left_info_rail_root.visible = not suppress_all_hud
	if run_top_right_status_root != null:
		run_top_right_status_root.visible = not suppress_all_hud
	# Keep the concrete frame/decorations synchronized as well. Some production
	# capture fixtures re-apply layout after the layer roots are established;
	# explicit visibility prevents a re-shown status-card shell from surviving
	# underneath a terminal result modal.
	for status_node in [
		status_card_art,
		protocol_pressure_track,
		protocol_pressure_fill,
		protocol_glow_layer,
		right_title_label,
		right_body_label,
	]:
		if status_node is CanvasItem:
			(status_node as CanvasItem).visible = not suppress_all_hud


func modal_visibility_snapshot() -> Dictionary:
	return {
		"modal_id": active_modal_visibility_policy,
		"left_rail_visible": run_left_info_rail_root == null or run_left_info_rail_root.visible,
		"status_visible": run_top_right_status_root == null or run_top_right_status_root.visible,
		"status_card_art_visible": status_card_art == null or status_card_art.visible,
		"protocol_decoration_visible": protocol_glow_layer == null or protocol_glow_layer.visible,
		"floating_info_visible": run_floating_info_root == null or run_floating_info_root.visible,
		"interaction_prompt_visible": run_interaction_prompt_root == null or run_interaction_prompt_root.visible,
		"action_bar_visible": run_action_overlay_root == null or run_action_overlay_root.visible,
	}


func apply_layout_profile(profile: Dictionary) -> void:
	if not built:
		build()
	current_layout_profile = profile.duplicate(true)
	ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(
		float(current_layout_profile.get("ui_scale_factor", ui_scale_factor))
	)
	current_layout_profile["ui_scale_factor"] = ui_scale_factor
	profile = current_layout_profile
	var viewport_size := UILayerContractScript.viewport_size_from_profile(profile)
	var is_low: bool = bool(profile.get("is_low_resolution", false))
	var is_high: bool = bool(profile.get("is_high_resolution", false))
	if hud != null:
		hud.visible = false
	var width: float = maxf(1.0, viewport_size.x)
	var height: float = maxf(1.0, viewport_size.y)
	var ui_scale_step := (ui_scale_factor - 1.0) / 0.5
	# UE widget constants are authored against a 1920x1080 presentation. Scale
	# those HUD-only dimensions to the active viewport instead of copying 720 px
	# widths verbatim into the 1280x720 Godot target.
	var ue_reference_scale: float = minf(width / 1920.0, height / 1080.0)
	ue_reference_scale = clampf(ue_reference_scale, 0.60, 1.34)
	var margin: float = 10.0 if is_low else 12.0
	var left_width: float = UILayerContractScript.run_left_width(profile)
	var gameplay_left: float = left_width
	var gameplay_width: float = max(1.0, width - gameplay_left)
	var rail_content_left: float = margin + 12.0
	var rail_content_width: float = max(220.0, left_width - rail_content_left - margin)
	var right_card_size := UILayerContractScript.run_status_card_size(profile)
	var right_card_width: float = right_card_size.x
	var right_card_height: float = right_card_size.y
	# The stable footer contains only the mine-risk plate and the action dock.
	# Command feedback is a short overlay toast and must not reserve a third band.
	var footer_geometry := UILayerContractScript.run_footer_geometry(profile)
	var bottom_key_height: float = float(footer_geometry.get("key_height", 40.0))
	var center_left: float = gameplay_left
	var center_width: float = gameplay_width
	var right_left: float = width - right_card_width - margin
	var right_content_left: float = right_left + margin
	var right_content_width: float = right_card_width - margin * 2.0
	var scanner_title_height := 28.0 + 14.0 * ui_scale_step
	var scanner_title_top := 24.0 + 4.0 * ui_scale_step
	var scanner_map_top: float = scanner_title_top + scanner_title_height + 8.0
	var scanner_map_height: float = minf(rail_content_width, 300.0 * ue_reference_scale)
	var scanner_stats_top: float = scanner_map_top + scanner_map_height + 10.0
	var stats_height: float = (84.0 if is_low else 94.0) + 10.0 * ui_scale_step
	var backpack_top: float = scanner_stats_top + stats_height + 10.0
	var backpack_panel_height: float = maxf(192.0, height - backpack_top - 28.0)
	# The quick bag is a true scroll surface. Reserve stable detail and burden
	# bands, then let every real item remain reachable inside the remaining rail.
	var backpack_scroll_height: float = maxf(56.0, backpack_panel_height - 136.0 - 20.0 * ui_scale_step)
	var preferred_key_width := (620.0 if is_low else 720.0) + 80.0 * ui_scale_step
	var bottom_key_width: float = minf(preferred_key_width, gameplay_width - margin * 3.0)
	bottom_key_width = maxf(minf(520.0, gameplay_width - margin * 3.0), bottom_key_width)
	var bottom_key_left: float = gameplay_left + (gameplay_width - bottom_key_width) * 0.5
	var bottom_key_top: float = float(footer_geometry.get("key_top", height - bottom_key_height - 8.0))
	var mine_risk_height: float = float(footer_geometry.get("mine_risk_height", 40.0))
	var mine_risk_top: float = float(footer_geometry.get("mine_risk_top", bottom_key_top - mine_risk_height - 4.0))
	var mine_risk_width: float = (220.0 if is_low else (258.0 if is_high else 236.0)) + 24.0 * ui_scale_step
	var mine_risk_left: float = gameplay_left + (gameplay_width - mine_risk_width) * 0.5
	var preferred_encounter_width: float = 400.0 if is_low else (480.0 if is_high else 440.0)
	var encounter_width: float = minf(preferred_encounter_width, maxf(220.0, gameplay_width * 0.38))
	var encounter_height: float = 70.0
	var encounter_left: float = clampf(gameplay_left + gameplay_width * 0.58, gameplay_left + margin, width - encounter_width - margin)
	var encounter_top: float = clampf(height * 0.52 - encounter_height * 0.5, margin + 110.0, mine_risk_top - encounter_height - 12.0)
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
	_set_rect(protocol_level_plate, Rect2())
	var protocol_left_padding := maxf(18.0, right_card_width * 0.18)
	var protocol_right_padding := maxf(14.0, right_card_width * 0.07)
	var protocol_bottom_padding := maxf(18.0, right_card_height * 0.18)
	var protocol_copy_left := right_left + protocol_left_padding
	var protocol_copy_width := maxf(1.0, right_card_width - protocol_left_padding - protocol_right_padding)
	var protocol_track_rect := Rect2(
		protocol_copy_left,
		margin + right_card_height - protocol_bottom_padding - 6.0,
		protocol_copy_width,
		6.0
	)
	_set_rect(protocol_pressure_track, protocol_track_rect)
	_set_rect(protocol_pressure_fill, Rect2(protocol_track_rect.position, Vector2(protocol_track_rect.size.x * current_protocol_pressure / PROTOCOL_PRESSURE_MAX, protocol_track_rect.size.y)))
	_set_rect(center_backdrop, Rect2(0, 0, 0, 0))
	_set_rect(room_background_layer, Rect2(0, 0, 0, 0))
	_set_rect(encounter_backdrop, Rect2(encounter_left, encounter_top, encounter_width, encounter_height))
	_set_rect(bottom_backdrop, Rect2(bottom_key_left, bottom_key_top, bottom_key_width, bottom_key_height))
	_set_rect(bottom_overlay_art, Rect2(bottom_key_left, bottom_key_top, bottom_key_width, bottom_key_height))
	_set_rect(mine_risk_tag_art, Rect2(mine_risk_left, mine_risk_top, mine_risk_width, mine_risk_height))
	_set_rect(resource_backdrop, Rect2(rail_content_left, scanner_stats_top, rail_content_width, stats_height))
	_set_rect(scanner_text_mask, Rect2(rail_content_left, backpack_top, rail_content_width, backpack_panel_height))
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
	# The generated level plate is a second framed rectangle. Layering it inside
	# the audited protocol panel caused the double/plastic border reported by the
	# player; keep its asset binding for governance tests but do not render it.
	protocol_level_plate.visible = false
	protocol_pressure_track.visible = true
	protocol_pressure_fill.visible = true
	bottom_backdrop.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.024, 0.027, 0.98), Color(0.58, 0.39, 0.16, 0.96), 2))
	bottom_backdrop.visible = true
	bottom_overlay_art.visible = true
	encounter_backdrop.visible = false
	center_backdrop.visible = false
	room_background_layer.visible = false
	player_sprite_layer.visible = false
	resource_backdrop.visible = true
	scanner_text_mask.visible = true
	threat_mask.visible = false
	event_mask.visible = false
	room_glow_layer.visible = false
	room_text_mask.visible = false
	room_hint_softener.visible = false
	player_tag_mask.visible = false
	protocol_glow_layer.visible = true
	bottom_key_glow_layer.visible = false
	right_game_fill_layer.visible = false

	_set_rect(scanner_title_label, Rect2(rail_content_left + 2.0, scanner_title_top, rail_content_width - 4.0, scanner_title_height))
	_set_rect(scanner_summary_label, Rect2(0, 0, 0, 0))
	_set_rect(minimap_panel, Rect2(rail_content_left, scanner_map_top, rail_content_width, scanner_map_height))
	minimap_panel.apply_layout_profile(profile)
	_set_rect(scanner_legend_label, Rect2(rail_content_left + 10.0, scanner_stats_top + 8.0, rail_content_width - 20.0, stats_height - 16.0))
	_set_rect(scanner_detail_label, Rect2(rail_content_left + 10.0, backpack_top + 10.0, rail_content_width - 20.0, 20.0 + 6.0 * ui_scale_step))
	var backpack_scroll_rect := Rect2(rail_content_left + 10.0, backpack_top + 40.0, rail_content_width - 20.0, backpack_scroll_height)
	_set_rect(backpack_scroll, backpack_scroll_rect)
	backpack_strip.custom_minimum_size = Vector2(maxf(80.0, backpack_scroll_rect.size.x - 12.0), 0.0)
	_set_rect(backpack_empty_watermark, Rect2(backpack_scroll_rect.position + Vector2(10.0, 4.0), backpack_scroll_rect.size - Vector2(20.0, 8.0)))
	_set_rect(backpack_detail_label, Rect2(rail_content_left + 10.0, backpack_scroll_rect.end.y + 6.0, rail_content_width - 20.0, 52.0))
	var backpack_capacity_height := 20.0 + 10.0 * ui_scale_step
	_set_rect(
		backpack_capacity_label,
		Rect2(
			rail_content_left + 10.0,
			backpack_top + backpack_panel_height - backpack_capacity_height - 10.0,
			rail_content_width - 20.0,
			backpack_capacity_height
		)
	)

	_set_rect(room_title_label, Rect2(gameplay_square_left + 26.0, gameplay_square_top + 22.0, room_info_width - 28.0, 24.0))
	_set_rect(room_body_label, Rect2(0, 0, 0, 0))
	_set_rect(objective_label, Rect2(0, 0, 0, 0))
	_set_rect(player_tag_label, Rect2(0, 0, 0, 0))
	_set_rect(encounter_title_label, Rect2(0, 0, 0, 0))
	_set_rect(encounter_body_label, Rect2(0, 0, 0, 0))
	var encounter_option_rect := Rect2(encounter_left, encounter_top, encounter_width, encounter_height)
	encounter_option_base_rect = encounter_option_rect
	_set_rect(encounter_backdrop, encounter_option_rect)
	_set_rect(encounter_options_box, Rect2(
		encounter_option_rect.position + Vector2(5.0, 5.0),
		encounter_option_rect.size - Vector2(10.0, 10.0)
	))
	_set_rect(encounter_result_label, Rect2(0, 0, 0, 0))
	_set_rect(resource_label, Rect2())
	resource_label.visible = false
	var mine_icon_reserve := mine_risk_width * 0.27
	_set_rect(
		mine_risk_label,
		Rect2(
			mine_risk_left + mine_icon_reserve,
			mine_risk_top + 2.0,
			mine_risk_width - mine_icon_reserve - 10.0,
			mine_risk_height - 4.0
		)
	)

	var right_title_height := 24.0 + 18.0 * ui_scale_step
	var right_title_top := margin + maxf(12.0, right_card_height * 0.10)
	var protocol_copy_bottom := protocol_track_rect.position.y - 4.0
	_set_rect(right_title_label, Rect2(protocol_copy_left, right_title_top, protocol_copy_width, right_title_height))
	_set_rect(
		right_body_label,
		Rect2(
			protocol_copy_left,
			right_title_top + right_title_height + 2.0,
			protocol_copy_width,
			maxf(1.0, protocol_copy_bottom - (right_title_top + right_title_height + 2.0))
		)
	)
	_set_rect(event_label, Rect2(0, 0, 0, 0))
	event_label.visible = false
	_set_rect(reward_label, Rect2(0, 0, 0, 0))
	var toast_height := 36.0 + 8.0 * ui_scale_step
	var toast_width := minf(gameplay_width - margin * 4.0, 520.0 + 80.0 * ui_scale_step)
	var toast_left := gameplay_left + (gameplay_width - toast_width) * 0.5
	var toast_top := mine_risk_top - toast_height - 8.0
	_set_rect(command_feedback_art, Rect2(toast_left, toast_top, toast_width, toast_height))
	_set_rect(command_feedback_label, Rect2(toast_left + 18.0, toast_top + 4.0, toast_width - 36.0, toast_height - 8.0))
	_set_rect(layout_label, Rect2(right_content_left, height - 46.0, right_content_width, 24))
	layout_label.visible = false

	_set_rect(action_hint_label, Rect2())
	action_hint_label.visible = false
	_set_rect(action_bar, Rect2(bottom_key_left + 12.0, bottom_key_top + 4.0, bottom_key_width - 24.0, bottom_key_height - 8.0))
	var action_count := maxi(1, action_buttons.size())
	var action_button_width := maxf(0.0, (action_bar.size.x - float(action_count - 1) * 4.0) / float(action_count))
	for button_value in action_buttons.values():
		var action_button := button_value as Button
		if action_button != null:
			action_button.custom_minimum_size = Vector2(action_button_width, maxf(28.0, action_bar.size.y))
	_refresh_action_button_visibility()
	action_bar.z_as_relative = true
	action_bar.z_index = 20
	_set_rect(feedback_slot, Rect2(0, 0, width, height))
	_set_rect(overlay_slot, Rect2(0, 0, width, height))
	_set_rect(modal_slot, Rect2(0, 0, width, height))
	if active_modal_visibility_policy != &"":
		apply_modal_visibility_policy(active_modal_visibility_policy)


func show_command_feedback(result: Dictionary) -> void:
	if command_feedback_label == null or result.is_empty():
		return
	var accepted := bool(result.get("accepted", result.get("ok", false)))
	var successful := accepted and bool(result.get("ok", accepted))
	# A successful action already changes an authoritative player-facing
	# consumer: the world object, context card, inventory/result panel, or combat
	# state. Repeating it in a HUD strip competes with the room and mine-risk
	# focus. Keep its audio/haptic cue and reserve this fallback for rejection.
	if successful:
		clear_command_feedback()
		return
	var text := RunUIViewModel.command_result_text(result)
	if text == "":
		text = "" if accepted else "当前条件不足，请查看下方行动条件。"
	var feedback_copy := _feedback_copy(text)
	command_feedback_label.text = feedback_copy
	command_feedback_label.visible = feedback_copy != ""
	# The former full-width framed "action completed" bar is intentionally
	# retired. A short unframed rejection remains readable without becoming a
	# second permanent HUD layer.
	command_feedback_art.visible = false
	if not command_feedback_label.visible:
		command_feedback_time_remaining = 0.0
		return
	command_feedback_time_remaining = COMMAND_FEEDBACK_TOAST_SECONDS
	Art10UISkinKitScript.play_feedback_pulse(command_feedback_label, &"warning")


func clear_command_feedback() -> void:
	command_feedback_time_remaining = 0.0
	if command_feedback_art != null:
		command_feedback_art.visible = false
	if command_feedback_label != null:
		command_feedback_label.visible = false


func advance_command_feedback(delta: float) -> void:
	if command_feedback_time_remaining <= 0.0:
		return
	command_feedback_time_remaining = maxf(0.0, command_feedback_time_remaining - maxf(0.0, delta))
	if command_feedback_time_remaining > 0.0:
		return
	if command_feedback_art != null:
		command_feedback_art.visible = false
	if command_feedback_label != null:
		command_feedback_label.visible = false


func _refresh_backpack_strip(items_variant: Variant) -> void:
	if backpack_strip == null:
		return
	var items: Array = items_variant if items_variant is Array else []
	if backpack_empty_watermark != null:
		backpack_empty_watermark.visible = items.is_empty()
		backpack_empty_watermark.modulate.a = 0.14
	var signature_parts: Array[String] = []
	for item_variant in items:
		if item_variant is Dictionary:
			var item: Dictionary = item_variant
			var presentation := RunUIViewModel.item_presentation(item)
			signature_parts.append("%s:%s:%s:%s:%s:%s:%s" % [
				str(item.get("instance_ids", [item.get("instance_id", "")])),
				presentation.get("display_name", "未命名物资"),
				presentation.get("quantity", 1),
				presentation.get("weight", 0),
				presentation.get("rarity_text", "[?] 未鉴定"),
				presentation.get("collectible_level", 0),
				presentation.get("short_description", ""),
			])
	var signature := ",".join(signature_parts)
	if signature == last_backpack_signature and backpack_strip.get_child_count() > 0:
		return
	last_backpack_signature = signature
	for child in backpack_strip.get_children():
		backpack_strip.remove_child(child)
		child.queue_free()
	if items.is_empty():
		if backpack_detail_label != null:
			backpack_detail_label.text = "暂无物资"
			backpack_detail_label.tooltip_text = ""
		return
	var first_item: Dictionary = {}
	for index in range(items.size()):
		if not (items[index] is Dictionary):
			continue
		var item: Dictionary = (items[index] as Dictionary).duplicate(true)
		if first_item.is_empty():
			first_item = item.duplicate(true)
		var presentation := RunUIViewModel.item_presentation(item)
		var rarity: Dictionary = presentation.get("rarity", {})
		var rarity_color: Color = rarity.get("color", PresentationTheme.color_for_key(&"ui.muted"))
		var item_meta: Array[String] = [String(presentation.get("rarity_text", "[?] 未鉴定"))]
		var collectible_level_text := String(presentation.get("collectible_level_text", ""))
		if collectible_level_text != "":
			item_meta.append(collectible_level_text)
		item_meta.append("%s重" % presentation.get("weight", 0))
		var slot := Button.new()
		slot.name = "BackpackItem%d" % index
		slot.custom_minimum_size = Vector2(0, 50)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.focus_mode = Control.FOCUS_ALL
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.text = "%s ×%d\n%s" % [
			_compact_line(String(presentation.get("display_name", "未命名物资")), 8),
			int(presentation.get("quantity", 1)),
			" · ".join(item_meta),
		]
		slot.tooltip_text = String(presentation.get("detail_text", "尚未选择物品。"))
		slot.icon = Art24ItemVisualCatalog.texture_for(item)
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.add_theme_constant_override("icon_max_width", 34)
		slot.add_theme_font_size_override("font_size", 13)
		slot.add_theme_color_override("font_color", PresentationTheme.text_color())
		slot.add_theme_color_override("font_hover_color", PresentationTheme.text_color())
		slot.add_theme_color_override("font_focus_color", PresentationTheme.text_color())
		var neutral_border := Color(0.20, 0.50, 0.46, 0.58)
		slot.add_theme_stylebox_override("normal", _panel_style(Color(0.012, 0.022, 0.026, 0.94), neutral_border, 1))
		slot.add_theme_stylebox_override("hover", _panel_style(Color(0.024, 0.044, 0.048, 0.98), neutral_border.lightened(0.12), 1))
		slot.add_theme_stylebox_override("focus", _panel_style(Color(0.024, 0.044, 0.048, 0.98), PresentationTheme.color_for_key(&"ui.accent"), 2))
		slot.add_theme_stylebox_override("pressed", _panel_style(Color(0.018, 0.034, 0.038, 0.98), neutral_border, 1))
		slot.set_meta("item_instance_id", String(item.get("instance_id", "")))
		slot.set_meta("item_instance_ids", (item.get("instance_ids", []) as Array).duplicate())
		slot.set_meta("item_stack_key", String(item.get("stack_key", "")))
		slot.set_meta("rarity_border_token", StringName(rarity.get("border_token", &"rarity.border.unknown")))
		slot.set_meta("collectible_level", int(presentation.get("collectible_level", 0)))
		var rarity_marker := ColorRect.new()
		rarity_marker.name = "BackpackItemRarityMarker"
		rarity_marker.color = rarity_color
		rarity_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rarity_marker.anchor_bottom = 1.0
		rarity_marker.offset_left = 3.0
		rarity_marker.offset_top = 5.0
		rarity_marker.offset_right = 7.0
		rarity_marker.offset_bottom = -5.0
		rarity_marker.set_meta("rarity_border_token", StringName(rarity.get("border_token", &"rarity.border.unknown")))
		slot.add_child(rarity_marker)
		slot.mouse_entered.connect(_show_backpack_item_detail.bind(item))
		slot.focus_entered.connect(_show_backpack_item_detail.bind(item))
		backpack_strip.add_child(slot)
	if not first_item.is_empty():
		_show_backpack_item_detail(first_item)


func _show_backpack_item_detail(item: Dictionary) -> void:
	if backpack_detail_label == null:
		return
	var presentation := RunUIViewModel.item_presentation(item)
	backpack_detail_label.text = String(presentation.get("detail_text", "尚未选择物品。"))
	backpack_detail_label.tooltip_text = backpack_detail_label.text


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
	var panel_style := Art10UISkinKitScript.style_box_from_asset_ref_with_insets(
		Art21UIPlacementContractScript.component_ref(
			&"shared.panel.modal.normal",
			&"ui.art19.panel.terminal_main",
			&"runtime_modal"
		),
		Art10UISkinKitScript.POPUP_CONTENT_INSETS,
		Art10UISkinKitScript.POPUP_SLICE_INSETS
	)
	if panel_style != null:
		panel_style.set_meta("runtime_modal_theme_key", theme_key)
		panel.add_theme_stylebox_override("panel", panel_style)
	else:
		Art10UISkinKitScript.apply_panel(panel, &"deep")
	panel.set_meta("runtime_modal_theme_key", theme_key)
	_style_modal_children(panel, theme_key)


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
	_apply_runtime_modal_button_style(button, tone)


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
	button.text = "%s %s" % [_key_label_for_action(action_id), _short_action_label(action_id, label)]
	# The parent hotbar owns width. A per-button 82 px minimum forced seven
	# children to overflow the UE-scaled 480 px strip at 1280x720.
	button.custom_minimum_size = Vector2(0, 28)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	button.mouse_entered.connect(_show_action_guidance.bind(action_id))
	button.mouse_exited.connect(_restore_action_guidance.bind(action_id))
	button.focus_entered.connect(_show_action_guidance.bind(action_id))
	button.focus_exited.connect(_restore_action_guidance.bind(action_id))
	button.add_theme_font_size_override("font_size", 13)
	var copy := Label.new()
	copy.name = "ActionCopy"
	copy.set_anchors_preset(Control.PRESET_FULL_RECT)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_font_size_override("font_size", 13)
	copy.add_theme_color_override("font_color", Color(0.98, 0.91, 0.70, 1.0))
	copy.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
	copy.add_theme_constant_override("outline_size", 2)
	button.add_child(copy)
	# Native Button text is the production rendering path. Keep ActionCopy as
	# a compatibility child for older theme variants, but avoid double copy.
	copy.visible = false
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
	# Slot size is assigned once by apply_layout().  Full-rect anchors plus the
	# explicit width/height offsets doubled the logical canvas and pushed simple
	# centered overlays (notably the tutorial) off the lower-right viewport.
	slot.set_anchors_preset(Control.PRESET_TOP_LEFT)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot)
	return slot


func _apply_actions(actions: Variant) -> void:
	action_guidance_data.clear()
	if not (actions is Array):
		_restore_default_action_guidance()
		_refresh_action_button_visibility()
		return
	var ordered_index := 0
	for action in actions:
		if not (action is Dictionary):
			continue
		var action_data: Dictionary = action
		var action_id := StringName(action_data.get("id", &""))
		if not action_buttons.has(action_id):
			continue
		var button: Button = action_buttons[action_id]
		var display_text := _action_button_text(action_id, String(action_data.get("label", "")))
		button.text = display_text
		var action_copy := button.get_node_or_null("ActionCopy") as Label
		if action_copy != null:
			action_copy.text = display_text
			action_copy.visible = false
		var enabled := bool(action_data.get("enabled", true))
		var is_primary := bool(action_data.get("is_primary", false)) and enabled
		action_guidance_data[action_id] = action_data.duplicate(true)
		button.disabled = not enabled
		button.set_meta("context_rank", int(action_data.get("context_rank", ordered_index)))
		button.set_meta("context_primary", is_primary)
		button.tooltip_text = _action_guidance_text(action_data)
		var tone := StringName(action_data.get("tone", &"secondary"))
		button.set_meta("context_tone", tone)
		var visual_tone := &"danger" if is_primary and tone == &"danger" else (&"primary" if is_primary else tone)
		_apply_action_button_style(button, visual_tone, enabled)
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		_apply_key_prompt_icon(button, action_id)
		action_bar.move_child(button, ordered_index)
		ordered_index += 1
	_refresh_action_button_visibility()
	if active_guidance_action != "":
		var active_button := action_buttons.get(active_guidance_action) as Button
		if active_button == null or active_button.disabled:
			active_guidance_action = &""
	_refresh_active_action_guidance()


func _refresh_action_button_visibility() -> void:
	var compact_mode := ui_scale_factor >= 1.49
	for action_id_variant in action_buttons.keys():
		var action_id := StringName(action_id_variant)
		var button := action_buttons.get(action_id) as Button
		if button == null:
			continue
		button.visible = not (compact_mode and button.disabled)
		button.text = _action_button_text(action_id, _short_action_label(action_id, button.text))


func _action_button_text(action_id: StringName, fallback: String) -> String:
	var key_label := _key_label_for_action(action_id)
	if action_id == &"combat" and key_label == "鼠标左键":
		key_label = "左键"
	return "%s %s" % [key_label, _short_action_label(action_id, fallback)]


func blocks_world_pointer(viewport_position: Vector2) -> bool:
	# These surfaces can overlap the room plate while remaining presentation
	# overlays. Treat their visible pixels as UI so a click cannot attack an
	# obscured target underneath.
	for control in [
		left_backdrop,
		status_card_art,
		bottom_backdrop,
		bottom_overlay_art,
		mine_risk_tag_art,
		encounter_backdrop,
		command_feedback_art,
		action_bar,
	]:
		if (
			control != null
			and is_instance_valid(control)
			and control.is_visible_in_tree()
			and control.get_global_rect().has_point(viewport_position)
		):
			return true
	return false


func _show_action_guidance(action_id: StringName) -> void:
	var action_data := _dict_variant(action_guidance_data.get(action_id, {}))
	if action_data.is_empty() or action_hint_label == null:
		return
	active_guidance_action = action_id
	action_hint_label.text = _action_guidance_text(action_data)
	action_hint_label.visible = false


func _restore_action_guidance(action_id: StringName) -> void:
	var button := action_buttons.get(action_id) as Button
	if button != null and (button.has_focus() or button.is_hovered()):
		return
	if active_guidance_action == action_id:
		active_guidance_action = &""
		_restore_default_action_guidance()


func _refresh_active_action_guidance() -> void:
	if active_guidance_action == &"" or not action_guidance_data.has(active_guidance_action):
		active_guidance_action = &""
		_restore_default_action_guidance()
		return
	_show_action_guidance(active_guidance_action)


func _restore_default_action_guidance() -> void:
	if action_hint_label == null:
		return
	action_hint_label.text = default_action_guidance
	action_hint_label.visible = false


func _action_guidance_text(action_data: Dictionary) -> String:
	var action_id := StringName(action_data.get("id", &""))
	var label := _short_action_label(action_id, String(action_data.get("label", "行动"))).strip_edges()
	var key_label := _key_label_for_action(action_id)
	var prefix := "%s %s" % [key_label, label] if not key_label.is_empty() else label
	var description := String(action_data.get("description", "")).strip_edges()
	var disabled_reason := String(action_data.get("disabled_reason", "")).strip_edges()
	var enabled := bool(action_data.get("enabled", true))
	var detail := description
	if not enabled and not disabled_reason.is_empty():
		if detail.is_empty() or detail == disabled_reason:
			detail = "暂不可用：%s" % disabled_reason
		else:
			detail = "%s；暂不可用：%s" % [detail, disabled_reason]
	if detail.is_empty():
		detail = "当前没有补充说明。"
	return Art10UISkinKitScript.sanitize_player_copy("%s：%s" % [prefix, detail]).strip_edges()


func _key_label_for_action(action_id: StringName) -> String:
	var input_action := _input_action_for_surface_action(action_id)
	if input_action == &"":
		return ""
	return SemanticActionHintScript.current_binding_label(input_action)


func _input_action_for_surface_action(action_id: StringName) -> StringName:
	match action_id:
		&"interact":
			return &"interact"
		&"inventory":
			return &"open_inventory"
		&"ground_loot":
			return &"open_ground_loot"
		&"map":
			return &"open_map"
		&"combat":
			return &"attack"
		&"extract":
			return &"request_extract"
		&"pause":
			return &"pause"
		_:
			return &""


func _default_action_hint_text() -> String:
	var parts: Array[String] = []
	for fixture in [
		{"action_id": &"interact", "label": "交互"},
		{"action_id": &"open_inventory", "label": "背包"},
		{"action_id": &"open_ground_loot", "label": "拾取"},
		{"action_id": &"open_map", "label": "地图"},
		{"action_id": &"attack", "label": "攻击"},
		{"action_id": &"pause", "label": "暂停"},
	]:
		var key_label := SemanticActionHintScript.current_binding_label(StringName(fixture["action_id"]))
		parts.append(
			"%s %s" % [key_label, String(fixture["label"])]
			if not key_label.is_empty()
			else String(fixture["label"])
		)
	return "  ".join(parts)


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
			return "攻击"
		&"extract":
			return "撤离"
		&"pause":
			return "暂停"
		_:
			return fallback


func _apply_encounter_section(section_variant: Variant) -> void:
	var section := _dict_variant(section_variant)
	encounter_title_label.text = _compact_line(String(section.get("title", "事件行动")), 10)
	encounter_body_label.text = _compact_line(String(section.get("body", "当前没有可处理的目标。")), 22)
	encounter_result_label.text = "结果  %s" % _compact_line(String(section.get("result_summary", "暂无结果。")), 18)
	_clear_encounter_option_buttons()
	# Event decisions have one player-facing route: approach the world marker,
	# open its focused modal, then submit through RunScene/CommandBus. Keeping
	# these options in the steady HUD duplicated that route (including "leave")
	# and allowed the strip to compete with the world-context card.
	if _encounter_uses_event_modal(section):
		encounter_backdrop.visible = false
		encounter_options_box.visible = false
		return
	var options := _array_variant(section.get("options", []))
	for option_variant in options:
		if not (option_variant is Dictionary):
			continue
		var option: Dictionary = option_variant
		var option_id := StringName(option.get("id", &""))
		if REDUNDANT_ENCOUNTER_OPTION_IDS.has(option_id):
			continue
		var button := Button.new()
		var disabled := bool(option.get("disabled", false))
		var requires_confirm := bool(option.get("requires_confirm", false))
		var title := _encounter_option_title(option_id, String(option.get("title", String(option_id))))
		button.name = "RunEncounterOption_%s" % String(option_id)
		button.text = "%s%s" % [_compact_line(title, 9), "  确认" if requires_confirm else ""]
		button.custom_minimum_size = Vector2(0, 28)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = disabled
		# The default project tooltip has no reliable backing panel and visually
		# floats over the room. Keep the full copy as data for a future detail
		# view, but make the in-run action a bounded, readable control.
		button.tooltip_text = ""
		button.set_meta(&"art24_detail_copy", _encounter_option_tooltip(option))
		button.add_theme_font_size_override("font_size", 13)
		Art10UISkinKitScript.apply_button(button, &"primary" if not disabled else &"secondary", 13, &"key")
		if not disabled:
			var payload := _dict_variant(option.get("command_payload", {}))
			button.pressed.connect(_on_encounter_option_pressed.bind(option_id, payload))
		encounter_options_box.add_child(button)
		encounter_option_buttons.append(button)
	encounter_options_box.columns = clampi(encounter_option_buttons.size(), 1, 3)
	encounter_backdrop.visible = not encounter_option_buttons.is_empty()
	encounter_options_box.visible = not encounter_option_buttons.is_empty()


func _encounter_uses_event_modal(section: Dictionary) -> bool:
	var encounter_type := StringName(section.get("encounter_type", &"none"))
	if encounter_type in EVENT_MODAL_ENCOUNTER_TYPES:
		return true
	for raw_tag in _array_variant(section.get("encounter_tags", [])):
		if StringName(raw_tag) == &"event_like":
			return true
	return false


func _encounter_option_title(option_id: StringName, fallback: String) -> String:
	match option_id:
		&"sell_best_item":
			return "出售背包物资"
		&"confirm_high_value_sale":
			return "出售贵重物"
		&"buy_treatment":
			return "购买治疗"
		&"buy_info":
			return "购买路线情报"
		&"bet_small":
			return "押注黑币"
		&"offer_hp":
			return "献祭生命"
		&"disarm":
			return "尝试解除机关"
		&"leave":
			return "离开当前遭遇"
	return fallback


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
		backpack_detail_label,
		backpack_capacity_label,
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
			label.add_theme_font_size_override(
				"font_size",
				Art10UISkinKitScript.scaled_font_size(
					Art10UISkinKitScript.font_size(&"hud_small"),
					ui_scale_factor
				)
			)
			label.clip_text = true
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for title_label in [scanner_title_label, room_title_label, encounter_title_label, right_title_label]:
		if title_label is Label:
			Art10UISkinKitScript.apply_composition_label(
				title_label,
				&"status",
				Art10UISkinKitScript.scaled_font_size(
					Art10UISkinKitScript.font_size(&"hud"),
					ui_scale_factor
				),
				Art10UISkinKitScript.color(&"accent")
			)
			title_label.clip_text = true
			title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if mine_risk_label is Label:
		Art10UISkinKitScript.apply_composition_label(
			mine_risk_label,
			&"status",
			Art10UISkinKitScript.scaled_font_size(16, ui_scale_factor),
			Color(0.91, 0.87, 0.78, 1.0)
		)
		mine_risk_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		mine_risk_label.clip_text = false
		mine_risk_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	if command_feedback_label is Label:
		command_feedback_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		command_feedback_label.clip_text = true
		command_feedback_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		command_feedback_label.size = Vector2(command_feedback_label.size.x, maxf(22.0, command_feedback_label.get_combined_minimum_size().y))
	if action_hint_label is Label:
		action_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		action_hint_label.clip_text = true
		action_hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		action_hint_label.size = Vector2(action_hint_label.size.x, maxf(22.0, action_hint_label.get_combined_minimum_size().y))
	if backpack_detail_label is Label:
		backpack_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		backpack_detail_label.max_lines_visible = 3
		backpack_detail_label.clip_text = true
	for left_label in [scanner_summary_label, scanner_legend_label, scanner_detail_label, resource_label]:
		if left_label is Label:
			left_label.clip_text = true
			left_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for action_id in action_buttons.keys():
		var action_button := action_buttons[action_id] as Button
		action_button.custom_minimum_size = Vector2(
			0.0,
			Art10UISkinKitScript.scaled_control_minimum(
				Vector2(0.0, 30.0),
				minf(ui_scale_factor, 1.25)
			).y
		)
		var tone := StringName(action_button.get_meta("context_tone", &"secondary"))
		var is_primary := bool(action_button.get_meta("context_primary", false)) and not action_button.disabled
		var visual_tone := &"danger" if is_primary and tone == &"danger" else (&"primary" if is_primary else tone)
		_apply_action_button_style(action_button, visual_tone, not action_button.disabled)
		action_button.focus_mode = Control.FOCUS_NONE if action_button.disabled else Control.FOCUS_ALL
		_apply_key_prompt_icon(action_button, StringName(action_id))
	for button in encounter_option_buttons:
		Art10UISkinKitScript.apply_transparent_button(
			button,
			&"primary" if button != null and not button.disabled else &"secondary",
			Art10UISkinKitScript.scaled_font_size(13, ui_scale_factor),
			&"key",
			0
		)
	_fit_encounter_option_geometry()


func _fit_encounter_option_geometry() -> void:
	if encounter_backdrop == null or encounter_options_box == null:
		return
	var panel_rect := encounter_option_base_rect
	if panel_rect.size.x <= 0.0 or panel_rect.size.y <= 0.0:
		return
	if encounter_option_buttons.is_empty():
		_set_rect(encounter_backdrop, panel_rect)
		_set_rect(
			encounter_options_box,
			Rect2(panel_rect.position + Vector2(5.0, 5.0), panel_rect.size - Vector2(10.0, 10.0))
		)
		return
	var columns := maxi(1, encounter_options_box.columns)
	var rows := ceili(float(encounter_option_buttons.size()) / float(columns))
	var row_height := 0.0
	for button in encounter_option_buttons:
		if button == null:
			continue
		row_height = maxf(
			row_height,
			maxf(button.custom_minimum_size.y, button.get_combined_minimum_size().y)
		)
	var vertical_separation := float(encounter_options_box.get_theme_constant("v_separation"))
	var required_height := 10.0 + float(rows) * row_height + float(maxi(0, rows - 1)) * vertical_separation
	if required_height > panel_rect.size.y:
		var preserved_bottom := panel_rect.end.y
		panel_rect.size.y = required_height
		panel_rect.position.y = preserved_bottom - required_height
	_set_rect(encounter_backdrop, panel_rect)
	_set_rect(
		encounter_options_box,
		Rect2(panel_rect.position + Vector2(5.0, 5.0), panel_rect.size - Vector2(10.0, 10.0))
	)


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


func _interior_band_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	# The authored rail already supplies the only complete frame. Interior
	# sections are quiet tonal bands so they cannot read as stacked plastic
	# panels or put another outline through their headings.
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	return style


func _apply_action_button_style(button: Button, tone: StringName, enabled: bool) -> void:
	Art10UISkinKitScript.apply_transparent_button(
		button,
		tone,
		Art10UISkinKitScript.scaled_font_size(13, ui_scale_factor),
		&"key",
		0,
		&"readable"
	)
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var normal_style := _art24_keycap_style("normal", tone)
	var pressed_style := _art24_keycap_style("pressed", tone)
	var disabled_style := _art24_keycap_style("disabled", tone)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", pressed_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	var tone_color := _tone_color(tone)
	var font_color := Color(0.98, 0.91, 0.70, 1.0)
	if tone == &"danger":
		font_color = Color(1.0, 0.72, 0.68, 1.0)
	elif tone == &"primary":
		font_color = Color(1.0, 0.90, 0.60, 1.0)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", tone_color.lightened(0.28))
	button.add_theme_color_override("font_pressed_color", tone_color.lightened(0.12))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.68, 0.56, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	button.add_theme_constant_override("outline_size", 2)
	button.modulate = Color(1, 1, 1, 1)
	var action_copy := button.get_node_or_null("ActionCopy") as Label
	if action_copy != null:
		action_copy.add_theme_color_override("font_color", Color(0.98, 0.91, 0.70, 1.0) if enabled else Color(0.64, 0.62, 0.54, 1.0))


func _art24_keycap_style(state: String, tone: StringName = &"secondary") -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.052, 0.054, 0.98)
	style.border_color = Color(0.48, 0.67, 0.54, 0.82)
	if tone == &"primary":
		style.bg_color = Color(0.075, 0.070, 0.035, 0.98)
		style.border_color = Color(0.94, 0.70, 0.27, 0.95)
	elif tone == &"danger":
		style.bg_color = Color(0.095, 0.030, 0.030, 0.98)
		style.border_color = Color(0.82, 0.28, 0.25, 0.95)
	elif tone == &"warning":
		style.bg_color = Color(0.090, 0.060, 0.025, 0.98)
		style.border_color = Color(0.92, 0.55, 0.20, 0.95)
	if state == "pressed":
		style.bg_color = style.bg_color.lightened(0.08)
		style.border_color = _tone_color(tone).lightened(0.16)
	elif state == "disabled":
		style.bg_color = Color(0.012, 0.028, 0.030, 0.96)
		style.border_color = Color(0.26, 0.34, 0.32, 0.78)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 6
	style.content_margin_top = 1
	style.content_margin_right = 6
	style.content_margin_bottom = 1
	return style


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


func _apply_runtime_modal_button_style(button: Button, tone: StringName) -> void:
	var visual_tone := &"danger" if tone == &"danger" else (&"primary" if tone == &"primary" else &"secondary")
	Art10UISkinKitScript.apply_button(
		button,
		visual_tone,
		Art10UISkinKitScript.scaled_font_size(13, ui_scale_factor),
		&"button",
		&"display"
	)
	var active_tone := &"danger" if visual_tone == &"danger" else &"primary"
	button.add_theme_stylebox_override("normal", Art10UISkinKitScript.registered_control_style(visual_tone))
	button.add_theme_stylebox_override("hover", Art10UISkinKitScript.registered_control_style(active_tone))
	button.add_theme_stylebox_override("pressed", Art10UISkinKitScript.registered_control_style(active_tone))
	button.add_theme_stylebox_override("disabled", Art10UISkinKitScript.registered_control_style(&"disabled"))
	button.add_theme_stylebox_override("focus", Art10UISkinKitScript.registered_control_style(&"focus"))
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var semantic_key := _runtime_modal_theme_key_for(button)
	if visual_tone == &"danger":
		semantic_key = &"ui.danger"
	var semantic_color := PresentationTheme.color_for_key(
		semantic_key,
		PresentationTheme.color_for_key(&"ui.accent")
	)
	if visual_tone != &"secondary":
		button.add_theme_color_override("font_color", semantic_color.lightened(0.12))
		button.add_theme_color_override("font_pressed_color", semantic_color)
	button.add_theme_color_override("font_hover_color", semantic_color.lightened(0.20))
	button.add_theme_color_override("font_focus_color", semantic_color.lightened(0.20))
	button.set_meta("runtime_modal_button_tone", visual_tone)


func _runtime_modal_theme_key_for(node: Node) -> StringName:
	var current := node
	while current != null:
		if current.has_meta("runtime_modal_theme_key"):
			return StringName(current.get_meta("runtime_modal_theme_key", &"ui.accent"))
		current = current.get_parent()
	return &"ui.accent"


func _style_modal_children(node: Node, theme_key: StringName) -> void:
	if node is Label:
		var label := node as Label
		var title_like := (
			String(label.name).to_lower().contains("title")
			or label.get_theme_font_size("font_size") >= 18
		)
		var label_color := PresentationTheme.color_for_key(
			theme_key,
			PresentationTheme.color_for_key(&"ui.accent")
		) if title_like else PresentationTheme.text_color()
		Art10UISkinKitScript.apply_composition_label(
			label,
			&"title" if title_like else &"body",
			label.get_theme_font_size("font_size"),
			label_color
		)
	elif node is Button:
		var button := node as Button
		_apply_runtime_modal_button_style(button, &"secondary")
	for child in node.get_children():
		_style_modal_children(child, theme_key)


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
	var copy := Art10UISkinKitScript.sanitize_player_copy(text).strip_edges()
	if copy in ["已确认", "已确认。", "操作已确认", "操作已确认。", "操作已完成", "操作已完成。", "待命"]:
		return ""
	return copy


func _player_action_hint(raw_hint: String, actions_variant: Variant) -> String:
	if actions_variant is Array:
		for raw_action in actions_variant as Array:
			if not (raw_action is Dictionary):
				continue
			var action := raw_action as Dictionary
			if not bool(action.get("enabled", false)):
				continue
			return Art10UISkinKitScript.sanitize_player_copy(_action_guidance_text(action)).strip_edges()
	return Art10UISkinKitScript.sanitize_player_copy(raw_hint).strip_edges()


func _threat_copy(model: Dictionary) -> String:
	return "威胁\n协议 %s | 压力 %s/100\n%s" % [
		model.get("protocol_level", "--"),
		model.get("pressure", "--"),
		_compact_line(String(model.get("danger_label", "--")), 12),
	]


func _resource_copy(model: Dictionary) -> String:
	return String(model.get("resource_summary", "生命 --/-- | 作业强度 -- | 待结算黑币 -- | 安全金币 --"))


func _resource_lines(text: String) -> String:
	var parts := text.split(" | ", false)
	if parts.size() >= 4:
		return "生命 %s    强度 %s\n黑币 %s    金币 %s" % [
			_compact_stat_token(_resource_field_value(parts[0])),
			_compact_stat_token(_resource_field_value(parts[1])),
			_compact_stat_token(_resource_field_value(parts[2])),
			_compact_stat_token(_resource_field_value(parts[3])),
		]
	if text.strip_edges() == "":
		return "生命 --/--    战力 --\n待结算 --    安全收益 --"
	return text.replace(" | ", "\n")


func _resource_field_value(field: String) -> String:
	var separator := field.find(" ")
	if separator < 0:
		return field.strip_edges()
	return field.substr(separator + 1).strip_edges()


func _compact_stat_token(token: String) -> String:
	if token.contains("/"):
		var ratio := token.split("/", false, 1)
		if ratio.size() == 2:
			return "%s/%s" % [_compact_stat_number(ratio[0]), _compact_stat_number(ratio[1])]
	return _compact_stat_number(token)


func _compact_stat_number(token: String) -> String:
	var normalized := token.strip_edges()
	if not normalized.is_valid_int():
		return normalized
	var value := normalized.to_int()
	var magnitude := absi(value)
	if magnitude < 10000:
		return str(value)
	var divisor := 100000000.0 if magnitude >= 100000000 else 10000.0
	var suffix := "亿" if magnitude >= 100000000 else "万"
	var compact := "%.1f" % (float(value) / divisor)
	if compact.ends_with(".0"):
		compact = compact.left(-2)
	return compact + suffix


func _apply_ue_readability_tokens(profile: Dictionary = {}) -> void:
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	for label in [scanner_legend_label, scanner_detail_label, right_body_label, event_label]:
		if label is Label:
			label.clip_text = false
			label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resource_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	resource_label.clip_text = true
	resource_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var body_size := Art10UISkinKitScript.scaled_font_size(
		13 if is_low else (16 if is_high else 14),
		ui_scale_factor
	)
	for label in [scanner_legend_label, scanner_detail_label, right_body_label]:
		label.add_theme_font_size_override("font_size", body_size)
		label.add_theme_constant_override(
			"line_spacing",
			maxi(2, int(round(float(2 if is_low else 3) * ui_scale_factor)))
		)
		label.add_theme_color_override("font_color", Color(0.91, 0.94, 0.88, 1.0))
	resource_label.add_theme_font_size_override(
		"font_size",
		Art10UISkinKitScript.scaled_font_size(13 if is_low else (15 if is_high else 13), ui_scale_factor)
	)
	resource_label.add_theme_constant_override("line_spacing", 1)
	resource_label.add_theme_color_override("font_color", Color(0.91, 0.94, 0.88, 1.0))
	mine_risk_label.add_theme_font_size_override(
		"font_size",
		Art10UISkinKitScript.scaled_font_size(15 if is_low else (18 if is_high else 16), ui_scale_factor)
	)
	mine_risk_label.add_theme_color_override("font_color", Color(0.91, 0.87, 0.78, 1.0))
	scanner_title_label.add_theme_font_size_override(
		"font_size",
		Art10UISkinKitScript.scaled_font_size(16 if is_low else (20 if is_high else 18), ui_scale_factor)
	)
	right_title_label.add_theme_font_size_override(
		"font_size",
		Art10UISkinKitScript.scaled_font_size(16 if is_low else (20 if is_high else 18), ui_scale_factor)
	)
	event_label.add_theme_font_size_override(
		"font_size",
		Art10UISkinKitScript.scaled_font_size(12 if is_low else 13, ui_scale_factor)
	)
	event_label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.82, 1.0))
	for button_value in action_buttons.values():
		var button := button_value as Button
		if button != null:
			button.add_theme_font_size_override(
				"font_size",
				Art10UISkinKitScript.scaled_font_size(13, ui_scale_factor)
			)


func _protocol_level_ref(level: int) -> Dictionary:
	var safe_level := clampi(level, 1, 5)
	var state := StringName("level_%d" % safe_level)
	return Art09ManifestAssetMappingScript.asset_ref(
		StringName("%s%d" % [PROTOCOL_LEVEL_ASSET_PREFIX, safe_level]),
		PROTOCOL_LEVEL_FALLBACK_ASSET,
		&"protocol_panel",
		state
	)


func _update_protocol_presentation(level_value: Variant, pressure_value: Variant) -> void:
	current_protocol_level = clampi(int(level_value), 1, 5)
	current_protocol_pressure = clampf(float(pressure_value), 0.0, PROTOCOL_PRESSURE_MAX)
	if protocol_level_plate != null:
		_apply_texture_ref(protocol_level_plate, _protocol_level_ref(current_protocol_level), 0.48)
	var pressure_color := _protocol_level_color(current_protocol_level)
	if protocol_pressure_fill != null:
		protocol_pressure_fill.color = pressure_color
	if right_title_label != null:
		right_title_label.add_theme_color_override("font_color", pressure_color)
	if protocol_pressure_track != null and protocol_pressure_fill != null:
		_set_rect(
			protocol_pressure_fill,
			Rect2(
				protocol_pressure_track.position,
				Vector2(protocol_pressure_track.size.x * current_protocol_pressure / PROTOCOL_PRESSURE_MAX, protocol_pressure_track.size.y)
			)
		)
	if protocol_glow_layer != null:
		var pressure_ratio := current_protocol_pressure / PROTOCOL_PRESSURE_MAX
		protocol_glow_layer.color = Color(pressure_color.r, pressure_color.g, pressure_color.b, 0.06 + pressure_ratio * 0.12)
		protocol_glow_layer.visible = true


func _protocol_level_color(level_value: Variant) -> Color:
	var level := clampi(int(level_value), 1, 5)
	return Color(PROTOCOL_LEVEL_COLORS.get(level, PROTOCOL_LEVEL_COLORS[5]))


func _apply_art24_frame(frame: NinePatchRect, texture_path: String, patch_margin: int) -> void:
	if frame == null:
		return
	var texture := load(texture_path) as Texture2D
	if texture == null:
		return
	frame.texture = texture
	frame.patch_margin_left = patch_margin
	frame.patch_margin_top = patch_margin
	frame.patch_margin_right = patch_margin
	frame.patch_margin_bottom = patch_margin
	frame.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	frame.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH


func _set_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
