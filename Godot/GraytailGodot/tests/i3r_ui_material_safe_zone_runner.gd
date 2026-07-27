extends SceneTree

const SkinKit := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const PresentationTheme := preload("res://scripts/presentation/presentation_theme.gd")
const PlacementContract := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const AppShellScript := preload("res://scripts/ui/app_shell/app_shell.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const GroundLootPanelScript := preload("res://scripts/ui/ground_loot/ground_loot_panel.gd")
const ResultPanelScene := preload("res://scenes/ui/result/result_panel.tscn")
const RunSurfaceScript := preload("res://scripts/ui/run_surface/run_surface.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const MainMenuLayoutContractScript := preload("res://scripts/ui/main_menu/main_menu_layout_contract.gd")
const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")

const PHYSICAL_SIZE := Vector2i(1280, 720)
const PHYSICAL_SIZES := [Vector2i(1280, 720), Vector2i(1920, 1080)]
const UI_SCALES := [1.0, 1.25, 1.5]
const MAIN_MENU_ENTRY_IDS := [&"deploy", &"long_term", &"settings", &"exit_game"]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	RuntimeInputProfileScript.install()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_factor = 1.0
	for physical_size in PHYSICAL_SIZES:
		root.size = physical_size
		await _frames(2)
		for ui_scale in UI_SCALES:
			await _check_scale(ui_scale, physical_size)
	await _check_inventory_1280()
	await _check_result_1280()
	await _check_action_dock_150()
	_check_shared_theme_materials()
	await _check_runtime_modal_materials()
	_finish()


func _check_shared_theme_materials() -> void:
	var theme := SkinKit.player_ui_theme()
	for theme_type in [&"Button", &"OptionButton", &"CheckButton"]:
		for state in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			_check(
				theme.get_stylebox(state, theme_type) is StyleBoxTexture,
				"%s/%s is not registered texture art" % [theme_type, state]
			)
	for state in [&"panel", &"hover"]:
		_check(
			theme.get_stylebox(state, &"PopupMenu") is StyleBoxTexture,
			"PopupMenu/%s is not registered texture art" % state
		)
	for state in [&"slider", &"grabber_area", &"grabber_area_highlight"]:
		_check(
			theme.get_stylebox(state, &"HSlider") is StyleBoxTexture,
			"HSlider/%s is not registered texture art" % state
		)
	var option_style := theme.get_stylebox(&"normal", &"OptionButton")
	if option_style is StyleBoxTexture:
		_check(
			(option_style as StyleBoxTexture).content_margin_left >= 22.0
			and (option_style as StyleBoxTexture).content_margin_right >= 22.0,
			"OptionButton text safe insets do not clear the authored corners"
		)
	_check(theme.get_icon(&"arrow", &"OptionButton") != null, "OptionButton has no pixel-art arrow")
	_check(theme.get_icon(&"checked", &"CheckButton") != null, "CheckButton has no pixel-art checked state")
	_check(theme.get_icon(&"unchecked", &"CheckButton") != null, "CheckButton has no pixel-art unchecked state")
	_check(theme.get_icon(&"grabber", &"HSlider") != null, "HSlider has no pixel-art grabber")


func _check_runtime_modal_materials() -> void:
	var surface := RunSurfaceScript.new() as Control
	var panel := PanelContainer.new()
	panel.name = "MaterialSafeZoneRuntimeModal"
	panel.position = Vector2(80, 64)
	panel.size = Vector2(450, 360)
	var content := VBoxContainer.new()
	content.name = "RuntimeModalContent"
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	var title := Label.new()
	title.name = "RuntimeModalTitle"
	title.text = "事件抉择"
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)
	var body := Label.new()
	body.name = "RuntimeModalBody"
	body.text = "选择本次探索的处理方式。"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(250, 78)
	content.add_child(body)
	var action := Button.new()
	action.name = "RuntimeModalAction"
	action.text = "确认处理"
	action.custom_minimum_size = Vector2(110, 34)
	content.add_child(action)
	root.add_child(panel)
	surface.call("apply_legacy_modal_style", panel, &"mini.event")
	await _frames(3)

	var panel_style := panel.get_theme_stylebox(&"panel")
	_check(panel_style is StyleBoxTexture, "production runtime modal retained a flat plastic frame")
	if panel_style is StyleBoxTexture:
		var textured := panel_style as StyleBoxTexture
		var expected_texture := PlacementContract.texture_for_visual_key(
			&"shared.panel.modal.normal",
			&"ui.art19.panel.terminal_main"
		)
		_check(textured.texture == expected_texture, "runtime modal bypassed shared.panel.modal.normal")
		_check(
			textured.content_margin_left >= SkinKit.POPUP_CONTENT_INSETS.x
			and textured.content_margin_top >= SkinKit.POPUP_CONTENT_INSETS.y
			and textured.content_margin_right >= SkinKit.POPUP_CONTENT_INSETS.z
			and textured.content_margin_bottom >= SkinKit.POPUP_CONTENT_INSETS.w,
			"runtime modal content insets do not clear the authored frame"
		)
		_check(
			bool(textured.get_meta("ui_content_insets_decoupled_from_slice", false)),
			"runtime modal did not use the shared decoupled safe-inset helper"
		)
		_check(
			StringName(textured.get_meta("runtime_modal_theme_key", &"")) == &"mini.event",
			"runtime modal texture lost its event semantic key"
		)
	var expected_event_color := PresentationTheme.color_for_key(&"mini.event")
	_check(
		title.get_theme_color(&"font_color").is_equal_approx(expected_event_color),
		"event modal title lost its event semantic color"
	)
	_check(
		title.get_theme_font(&"font") == SkinKit.player_ui_font()
		and body.get_theme_font(&"font") == SkinKit.player_ui_font(),
		"runtime modal copy does not use the shared player pixel font stack"
	)
	for state in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		_check(
			action.get_theme_stylebox(state) is StyleBoxTexture,
			"runtime modal button/%s is not shared texture art" % state
		)
	surface.call("apply_legacy_button_style", action, &"primary")
	_check(
		action.get_theme_color(&"font_color").is_equal_approx(expected_event_color.lightened(0.12)),
		"runtime event action lost its event semantic color"
	)
	surface.call("apply_legacy_button_style", action, &"danger")
	var danger_style := action.get_theme_stylebox(&"normal") as StyleBoxTexture
	var expected_danger := SkinKit.registered_control_style(&"danger") as StyleBoxTexture
	_check(
		danger_style != null
		and expected_danger != null
		and danger_style.texture == expected_danger.texture,
		"runtime destructive action lost the registered danger material"
	)
	_check(
		StringName(action.get_meta("runtime_modal_button_tone", &"")) == &"danger",
		"runtime destructive action lost its danger semantic key"
	)

	var safe_rect := Rect2(
		panel.get_global_rect().position + Vector2(
			SkinKit.POPUP_CONTENT_INSETS.x,
			SkinKit.POPUP_CONTENT_INSETS.y
		),
		panel.size - Vector2(
			SkinKit.POPUP_CONTENT_INSETS.x + SkinKit.POPUP_CONTENT_INSETS.z,
			SkinKit.POPUP_CONTENT_INSETS.y + SkinKit.POPUP_CONTENT_INSETS.w
		)
	)
	_check(
		_contains_rect(safe_rect, content.get_global_rect()),
		"runtime modal content overlaps its authored frame: content=%s safe=%s"
		% [content.get_global_rect(), safe_rect]
	)
	_check(
		panel.get_combined_minimum_size().x <= panel.size.x + 0.01
		and panel.get_combined_minimum_size().y <= panel.size.y + 0.01,
		"runtime modal safe insets overflow its production frame"
	)
	panel.queue_free()
	surface.free()
	await _frames(3)


func _check_scale(ui_scale: float, physical_size: Vector2i) -> void:
	_check(is_equal_approx(root.content_scale_factor, 1.0), "UI scale mutated the production canvas scale")
	var shell := AppShellScript.new() as Control
	shell.name = "MaterialSafeZoneAppShell"
	shell.size = root.get_visible_rect().size
	root.add_child(shell)
	shell.call("build")
	_check(bool(shell.call("set_ui_scale_factor", ui_scale)), "production shell rejected UI scale")
	_check(
		is_equal_approx(float(shell.call("get_ui_scale_factor")), ui_scale),
		"production shell did not report requested UI scale"
	)
	await _frames(3)
	var viewport_rect := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	_check_main_menu_scale(shell, viewport_rect, ui_scale)
	var opened := bool(shell.call("show_settings"))
	_check(opened, "settings did not open at %d%%" % int(round(ui_scale * 100.0)))
	await _frames(4)
	shell.call("_layout_settings_overlay")
	await _frames(2)
	var modal_art := shell.get("settings_modal_art") as TextureRect
	var settings := shell.get("settings_panel") as PanelContainer
	var settings_close := shell.get("settings_close_button") as Button
	_check(modal_art != null, "settings modal art missing at %d%%" % int(round(ui_scale * 100.0)))
	_check(settings != null, "settings panel missing at %d%%" % int(round(ui_scale * 100.0)))
	if modal_art != null:
		_check(
			_contains_rect(viewport_rect, modal_art.get_global_rect()),
			"settings modal exceeds logical viewport at %d%%: viewport=%s modal=%s"
			% [int(round(ui_scale * 100.0)), viewport_rect, modal_art.get_global_rect()]
		)
	if settings != null:
		var minimum := settings.get_combined_minimum_size()
		_check(
			minimum.x <= settings.size.x + 0.01 and minimum.y <= settings.size.y + 0.01,
			"settings minimum exceeds assigned safe area at %d%%: minimum=%s assigned=%s"
			% [int(round(ui_scale * 100.0)), minimum, settings.size]
		)
		if modal_art != null:
			_check(
				_contains_rect(modal_art.get_global_rect().grow(-12.0), settings.get_global_rect()),
				"settings content enters the modal border at %d%%: modal=%s settings=%s"
				% [int(round(ui_scale * 100.0)), modal_art.get_global_rect(), settings.get_global_rect()]
			)
			var settings_title := settings.get_node_or_null("SettingsFields/SettingsTitle") as Label
			_check(
				settings_title != null
				and settings_title.autowrap_mode == TextServer.AUTOWRAP_OFF
				and settings_title.max_lines_visible == 1
				and settings_title.get_global_rect().position.y >= modal_art.get_global_rect().position.y + 44.0,
				"settings title overlaps the authored top frame at %d%%: modal=%s title=%s"
				% [
					int(round(ui_scale * 100.0)),
					modal_art.get_global_rect(),
					settings_title.get_global_rect() if settings_title != null else Rect2(),
				]
			)
		_check_visible_controls_inside(settings, settings.get_global_rect(), ui_scale)
		var option := settings.get("window_mode_option") as OptionButton
		var slider := settings.get("master_volume_slider") as HSlider
		var toggle := settings.get("reduce_motion_check") as CheckButton
		_check(option != null and option.get_theme_stylebox(&"normal") is StyleBoxTexture, "live OptionButton lost texture art")
		_check(slider != null and slider.get_theme_stylebox(&"slider") is StyleBoxTexture, "live HSlider lost texture art")
		_check(toggle != null and toggle.get_theme_stylebox(&"normal") is StyleBoxTexture, "live CheckButton lost texture art")
		if option != null:
			_check(
				option.get_theme_font_size("font_size") == SkinKit.scaled_font_size(SkinKit.font_size(&"body"), ui_scale),
				"live OptionButton did not use production UI-scale typography at %d%%"
				% int(round(ui_scale * 100.0))
			)
	if settings_close != null and modal_art != null:
		_check(
			_contains_rect(modal_art.get_global_rect().grow(-12.0), settings_close.get_global_rect()),
			"settings close button enters the modal border at %d%%: %s"
			% [int(round(ui_scale * 100.0)), settings_close.get_global_rect()]
		)
		_check(settings_close.get_theme_stylebox(&"normal") is StyleBoxTexture, "settings close lost texture art")
		_check(
			settings_close.get_theme_font_size("font_size") == SkinKit.scaled_font_size(SkinKit.font_size(&"button"), ui_scale),
			"settings close did not use production UI-scale control metrics at %d%%"
			% int(round(ui_scale * 100.0))
		)
	else:
		_check(false, "settings production close button is missing at %d%%" % int(round(ui_scale * 100.0)))
	print(
		"I3R_UI_MATERIAL_SCALE physical=%s scale=%d logical=%s modal=%s settings=%s minimum=%s"
		% [
			physical_size,
			int(round(ui_scale * 100.0)),
			viewport_rect.size,
			modal_art.get_global_rect() if modal_art != null else Rect2(),
			settings.get_global_rect() if settings != null else Rect2(),
			settings.get_combined_minimum_size() if settings != null else Vector2.ZERO,
		]
	)
	shell.queue_free()
	await _frames(3)


func _check_main_menu_scale(shell: Control, viewport_rect: Rect2, ui_scale: float) -> void:
	var main_menu := shell.get("main_menu_shell") as Control
	_check(main_menu != null, "production main menu is missing")
	if main_menu == null:
		return
	var clean_plate := main_menu.get_node_or_null("BackgroundRoot/MainMenuSceneCleanPlate") as Control
	_check(clean_plate != null, "main-menu clean plate is missing")
	if clean_plate != null:
		_check(
			_contains_rect(viewport_rect, clean_plate.get_global_rect()),
			"main-menu background is cropped at %d%%: viewport=%s background=%s"
			% [int(round(ui_scale * 100.0)), viewport_rect, clean_plate.get_global_rect()]
		)
		_check(
			clean_plate.size == Vector2(1280, 720),
			"UI scale resized the scene background at %d%%: %s"
			% [int(round(ui_scale * 100.0)), clean_plate.size]
		)
	var notice_body := main_menu.get_node_or_null("SideStatusRoot/MainMenuNoticeText") as Label
	_check(notice_body != null, "main-menu notice body is missing")
	if notice_body != null:
		var notice_minimum := notice_body.get_combined_minimum_size()
		var model: Dictionary = main_menu.get("current_model")
		var notice: Dictionary = model.get("notice", {})
		var source_notice := String(notice.get("body", ""))
		_check(
			notice_minimum.x <= notice_body.size.x + 0.01
			and notice_minimum.y <= notice_body.size.y + 0.01,
			"main-menu notice text overlaps its frame at %d%%: minimum=%s assigned=%s"
			% [int(round(ui_scale * 100.0)), notice_minimum, notice_body.size]
		)
		_check(
			notice_body.text.replace("\n", "") == source_notice.replace("\n", ""),
			"main-menu notice scaling changed or removed player information"
		)
		_check(
			notice_body.text.split("\n").size() <= 5,
			"main-menu notice exceeds its five-line density budget at %d%%"
			% int(round(ui_scale * 100.0))
		)
		_check(
			notice_body.get_theme_constant("line_spacing") == 0,
			"main-menu notice retained unsafe extra line spacing"
		)
	for entry_id in MAIN_MENU_ENTRY_IDS:
		var button := main_menu.get_node_or_null(
			"PrimaryActionRoot/MainMenuEntry_%s" % String(entry_id)
		) as Button
		var label := main_menu.get_node_or_null(
			"PrimaryActionRoot/MainMenuBoardLabel_%s" % String(entry_id)
		) as Label
		_check(button != null, "main-menu entry button missing: %s" % String(entry_id))
		_check(label != null, "main-menu entry label missing: %s" % String(entry_id))
		if button != null:
			_check(
				_contains_rect(viewport_rect, button.get_global_rect()),
				"main-menu entry leaves the safe area at %d%%: %s=%s"
				% [int(round(ui_scale * 100.0)), String(entry_id), button.get_global_rect()]
			)
		if label != null:
			var expected_fit := MainMenuLayoutContractScript.fit_entry_text(entry_id, label.text, ui_scale)
			var expected_font_size := int(expected_fit.get("font_size", 0))
			var text_rule := MainMenuLayoutContractScript.entry_text_profile(entry_id)
			var padding: Vector2 = text_rule.get("padding", Vector2.ZERO)
			var label_minimum := label.get_combined_minimum_size()
			var label_safe_size := label.size - padding * 2.0
			_check(
				label.get_theme_font_size("font_size") == expected_font_size,
				"main-menu label did not apply UI scale at %d%%: %s actual=%d expected=%d"
				% [
					int(round(ui_scale * 100.0)),
					String(entry_id),
					label.get_theme_font_size("font_size"),
					expected_font_size,
				]
			)
			_check(
				label_minimum.x <= label_safe_size.x + 0.01
				and label_minimum.y <= label_safe_size.y + 0.01,
				"main-menu entry text enters its art border at %d%%: %s minimum=%s safe=%s"
				% [
					int(round(ui_scale * 100.0)),
					String(entry_id),
					label_minimum,
					label_safe_size,
				]
			)


func _check_inventory_1280() -> void:
	root.content_scale_factor = 1.0
	root.size = PHYSICAL_SIZE
	await _frames(2)
	var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(&"1280x720")
	profile["actual_viewport_size"] = PHYSICAL_SIZE
	var inventory := InventoryPanelScript.new() as PanelContainer
	root.add_child(inventory)
	inventory.call("apply_layout_profile", profile)
	inventory.call("apply_snapshot", {
		"inventory_items": [],
		"equipped_items": [],
		"backpack_used": 0,
		"backpack_capacity": 10,
		"run_black_coin": 0,
		"gold_coin": 0,
	})
	inventory.show()
	await _frames(4)
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(PHYSICAL_SIZE))
	var panel_rect := inventory.get_global_rect()
	var minimum := inventory.get_combined_minimum_size()
	_check(_contains_rect(viewport_rect, panel_rect), "inventory outer frame exceeds 1280x720 viewport: %s" % panel_rect)
	_check(panel_rect.end.y <= 648.01, "inventory outer frame enters the 72px hotbar reserve: %s" % panel_rect)
	_check(
		minimum.x <= inventory.size.x + 0.01 and minimum.y <= inventory.size.y + 0.01,
		"inventory real content minimum exceeds authored drawer: minimum=%s assigned=%s" % [minimum, inventory.size]
	)
	_check_visible_controls_inside(inventory, panel_rect, 1.0)
	_check(inventory.get_theme_stylebox(&"panel") is StyleBoxTexture, "inventory outer frame lost texture art")
	var opaque_backing := inventory.get("opaque_content_backing") as ColorRect
	_check(
		opaque_backing != null and opaque_backing.color.a >= 0.98,
		"inventory has no near-opaque content backing"
	)
	var footer_geometry := UILayerContractScript.run_footer_geometry(profile)
	var footer_safe_top := float(footer_geometry.get("mine_risk_top", 540.0)) - 12.0
	_check(
		panel_rect.end.y <= footer_safe_top + 0.01,
		"inventory enters the mine-risk/footer safe band: panel=%s safe_top=%s" % [panel_rect, footer_safe_top]
	)
	_check(inventory.find_child("InventoryCommandResultPanel", true, false) == null, "inventory retained the redundant nested result frame")
	var result_label := inventory.get("last_result_label") as Label
	_check(result_label != null and not result_label.visible, "empty inventory command result still occupies a framed row")
	print("I3R_UI_MATERIAL_INVENTORY viewport=%s panel=%s minimum=%s" % [viewport_rect.size, panel_rect, minimum])
	inventory.queue_free()
	await _frames(3)

	var ground_loot := GroundLootPanelScript.new() as PanelContainer
	root.add_child(ground_loot)
	ground_loot.call("apply_layout_profile", profile)
	ground_loot.call("apply_snapshot", {
		"room_floor_items": [],
		"backpack_used": 0,
		"backpack_capacity": 10,
		"backpack_remaining": 10,
	})
	ground_loot.show()
	await _frames(4)
	var ground_rect := ground_loot.get_global_rect()
	var ground_minimum := ground_loot.get_combined_minimum_size()
	_check(_contains_rect(viewport_rect, ground_rect), "ground-loot outer frame exceeds 1280x720 viewport: %s" % ground_rect)
	_check(ground_rect.end.y <= 648.01, "ground-loot outer frame enters the 72px hotbar reserve: %s" % ground_rect)
	_check(
		ground_minimum.x <= ground_loot.size.x + 0.01 and ground_minimum.y <= ground_loot.size.y + 0.01,
		"ground-loot real content minimum exceeds authored drawer: minimum=%s assigned=%s" % [ground_minimum, ground_loot.size]
	)
	_check_visible_controls_inside(ground_loot, ground_rect, 1.0)
	_check(ground_loot.find_child("GroundLootCommandResultPanel", true, false) == null, "ground-loot retained the redundant nested result frame")
	var ground_result := ground_loot.get("last_result_label") as Label
	_check(ground_result != null and not ground_result.visible, "empty ground-loot command result still occupies a framed row")
	print("I3R_UI_MATERIAL_GROUND_LOOT viewport=%s panel=%s minimum=%s" % [viewport_rect.size, ground_rect, ground_minimum])
	ground_loot.queue_free()
	await _frames(3)


func _check_result_1280() -> void:
	var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(&"1280x720")
	profile["actual_viewport_size"] = PHYSICAL_SIZE
	var result_panel := ResultPanelScene.instantiate() as Control
	root.add_child(result_panel)
	await _frames(2)
	result_panel.call("apply_layout_profile", profile)
	result_panel.show()
	await _frames(3)
	var backing := result_panel.get("result_modal_backing") as ColorRect
	var modal_art := result_panel.get("result_modal_art") as Control
	var actions := result_panel.get_node_or_null("ResultActions") as Control
	_check(backing != null and backing.color.a >= 0.98, "result has no near-opaque modal backing")
	_check(modal_art != null and modal_art.get_global_rect().end.y <= 660.01, "result modal enters the bottom safe band")
	_check(actions != null and actions.get_global_rect().end.y <= 640.01, "result actions enter the bottom action-dock band")
	if backing != null and modal_art != null:
		_check(
			_contains_rect(modal_art.get_global_rect().grow(-10.0), backing.get_global_rect()),
			"result opaque backing escapes its authored frame"
		)
	result_panel.queue_free()
	await _frames(3)


func _check_action_dock_150() -> void:
	var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(&"1280x720")
	profile["actual_viewport_size"] = PHYSICAL_SIZE
	profile["ui_scale_factor"] = 1.5
	var surface := RunSurfaceScript.new() as Control
	root.add_child(surface)
	surface.set_ui_scale_factor(1.5)
	surface.apply_layout_profile(profile)
	surface.apply_surface_model({
		"layout_profile": profile,
		"resource_summary": "生命 10000/10000 | 作业强度 5 | 待结算黑币 0 | 安全金币 0",
		"backpack_used": 0,
		"backpack_capacity": 10,
		"mine_risk": {"count": 0},
		"action_buttons": [
			{"id": &"interact", "label": "搜索", "enabled": false},
			{"id": &"inventory", "label": "背包", "enabled": true},
			{"id": &"ground_loot", "label": "拾取", "enabled": false},
			{"id": &"map", "label": "地图", "enabled": true},
			{"id": &"combat", "label": "攻击", "enabled": true, "is_primary": true},
			{"id": &"extract", "label": "撤离", "enabled": false},
			{"id": &"pause", "label": "暂停", "enabled": true},
		],
		"encounter_section": {
			"encounter_type": &"rule_modifier",
			"title": "规则终端",
			"body": "选择本次规则处理方式。",
			"options": [
				{"id": &"sell_best_item", "title": "出售物资"},
				{"id": &"confirm_high_value_sale", "title": "确认出售"},
				{"id": &"buy_treatment", "title": "购买治疗"},
				{"id": &"buy_info", "title": "购买情报"},
				{"id": &"leave", "title": "离开旅商"},
			],
		},
	})
	await _frames(4)
	var buttons: Dictionary = surface.get("action_buttons")
	var action_bar := surface.get("action_bar") as Control
	_check(action_bar != null, "UI150 action dock is missing")
	for hidden_id in [&"interact", &"ground_loot", &"extract"]:
		var hidden_button := buttons.get(hidden_id) as Button
		_check(hidden_button != null and not hidden_button.visible, "UI150 retained unavailable action %s" % hidden_id)
	var combat_button := buttons.get(&"combat") as Button
	_check(
		combat_button != null and combat_button.visible and combat_button.text == "左键 攻击",
		"UI150 combat copy is not compact: %s" % (combat_button.text if combat_button != null else "<missing>")
	)
	var scanner_legend := surface.get("scanner_legend_label") as Label
	var capacity_label := surface.get("backpack_capacity_label") as Label
	var scanner_mask := surface.get("scanner_text_mask") as Control
	var encounter_panel := surface.get("encounter_backdrop") as Control
	var encounter_buttons: Array = surface.get("encounter_option_buttons")
	_check(scanner_legend != null and scanner_legend.text.contains("1万/1万"), "UI150 long HP was not compacted")
	_check(scanner_legend != null and scanner_legend.get_line_count() <= 2, "UI150 resource summary wrapped beyond its two-line contract")
	_check(
		scanner_legend != null and scanner_legend.get_combined_minimum_size().y <= scanner_legend.size.y + 0.01,
		"UI150 resource summary overflows its assigned stats rectangle"
	)
	_check(
		capacity_label != null and scanner_mask != null and _contains_rect(scanner_mask.get_global_rect(), capacity_label.get_global_rect()),
		"UI150 burden label escapes the left-rail visible rectangle"
	)
	_check(
		capacity_label != null and capacity_label.get_combined_minimum_size().y <= capacity_label.size.y + 0.01,
		"UI150 burden label is vertically clipped"
	)
	if scanner_legend != null and capacity_label != null and scanner_mask != null:
		print(
			"I3R_UI150_LEFT_RAIL stats=%s stats_min=%s lines=%d burden=%s burden_min=%s visible=%s"
			% [
				scanner_legend.get_global_rect(),
				scanner_legend.get_combined_minimum_size(),
				scanner_legend.get_line_count(),
				capacity_label.get_global_rect(),
				capacity_label.get_combined_minimum_size(),
				scanner_mask.get_global_rect(),
			]
		)
	if action_bar != null:
		for visible_id in [&"inventory", &"map", &"combat", &"pause"]:
			var button := buttons.get(visible_id) as Button
			_check(
				button != null and button.visible and _contains_rect(action_bar.get_global_rect(), button.get_global_rect()),
				"UI150 action %s escapes its dock" % visible_id
			)
	_check(encounter_panel != null and encounter_buttons.size() == 5, "UI150 five-option encounter surface is incomplete")
	if encounter_panel != null:
		for raw_button in encounter_buttons:
			var encounter_button := raw_button as Button
			_check(
				encounter_button != null and _contains_rect(encounter_panel.get_global_rect(), encounter_button.get_global_rect()),
				"UI150 encounter option escapes its dynamically fitted panel"
			)
		if action_bar != null:
			_check(
				not encounter_panel.get_global_rect().intersects(action_bar.get_global_rect()),
				"UI150 encounter panel overlaps the action dock"
			)
	surface.queue_free()
	await _frames(3)


func _check_visible_controls_inside(node: Node, safe_rect: Rect2, ui_scale: float) -> void:
	if node is ScrollContainer and (node as ScrollContainer).clip_contents:
		return
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if control.visible:
				var rect := control.get_global_rect()
				_check(
					_contains_rect(safe_rect, rect),
					"settings control escapes safe area at %d%%: %s=%s safe=%s"
					% [int(round(ui_scale * 100.0)), control.name, rect, safe_rect]
				)
			_check_visible_controls_inside(child, safe_rect, ui_scale)


func _contains_rect(container: Rect2, child: Rect2) -> bool:
	return (
		child.position.x >= container.position.x - 0.01
		and child.position.y >= container.position.y - 0.01
		and child.end.x <= container.end.x + 0.01
		and child.end.y <= container.end.y + 0.01
	)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	root.content_scale_factor = 1.0
	SkinKit.set_runtime_ui_scale_factor(1.0)
	if failures.is_empty():
		print("I3R_UI_MATERIAL_SAFE_ZONE=PASS resolutions=1280x720,1920x1080 scales=100,125,150 controls=option,popup,slider,check,button")
		quit(0)
		return
	for failure in failures:
		push_error("I3R UI material safe zone: " + failure)
	print("I3R_UI_MATERIAL_SAFE_ZONE=FAIL failures=%d" % failures.size())
	quit(1)
