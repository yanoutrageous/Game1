extends SceneTree

const SkinKit := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const PlacementContract := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const GroundLootPanelScript := preload("res://scripts/ui/ground_loot/ground_loot_panel.gd")
const SettingsPanelScript := preload("res://scripts/ui/settings/settings_panel.gd")
const WorldContextPopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")
const ResultPanelScene := preload("res://scenes/ui/result/result_panel.tscn")

const DISPLAY_FONT_PATH := "res://assets/fonts/FusionPixel.otf"
const READABLE_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Regular.otf"
const LICENSE_PATH := "res://assets/licenses/FusionPixel-OFL.txt"
const MANIFEST_PATH := "res://data/assets/asset_manifest.csv"
const FUSION_SHA256 := "c20a65db093dad1a7b5947311d5294bfb9f72f1dd3141c19314e10ae457302e2"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_composition_descriptors()
	_check_font_bindings()
	_check_texture_safe_zones()
	_check_asset_governance()
	_check_shared_ui_consumers()
	await _check_live_dynamic_ui()
	_finish()


func _check_composition_descriptors() -> void:
	var expected_roles := {
		&"title": &"readable",
		&"body": &"readable",
		&"button": &"readable",
		&"status": &"readable",
	}
	for role in expected_roles:
		var descriptor: Dictionary = SkinKit.composition_descriptor(role)
		_check(StringName(descriptor.get("font_role", &"")) == expected_roles[role], "font role drifted for %s" % role)
		_check(int(descriptor.get("max_lines", 0)) > 0, "line contract missing for %s" % role)
		_check(int(descriptor.get("panel_safe_margin", 0)) >= 12, "panel safe margin missing for %s" % role)
		_check(descriptor.get("label_safe_padding") is Vector2, "label safe padding missing for %s" % role)
	_check(SkinKit.font_role_for_token(&"page_title") == &"readable", "page title token is not readable")
	_check(SkinKit.font_role_for_token(&"button") == &"readable", "button token is not readable")
	_check(SkinKit.font_role_for_token(&"body") == &"readable", "body token is not readable")
	_check(SkinKit.font_role_for_token(&"numeric") == &"display", "numeric token is not display")


func _check_font_bindings() -> void:
	var display_font := SkinKit.pixel_font()
	var readable_font := SkinKit.readable_font()
	_check_player_font(display_font, "display accessor")
	_check_player_font(readable_font, "readable accessor")
	_check(display_font != readable_font, "font role accessors were not separated")
	_check(_font_base_path(display_font) == DISPLAY_FONT_PATH, "display accessor is not FusionPixel")
	_check(_font_base_path(readable_font) == READABLE_FONT_PATH, "readable accessor is not Noto CJK")

	var shared_theme := SkinKit.player_ui_theme()
	_check(shared_theme != null, "player UI theme is missing")
	if shared_theme != null:
		_check_player_font(shared_theme.default_font, "theme default")
		_check_player_font(shared_theme.get_font(&"font", &"TooltipLabel"), "native tooltip theme")
		_check_player_font(shared_theme.get_font(&"font", &"PopupMenu"), "popup menu theme")
		_check(_font_base_path(shared_theme.default_font) == READABLE_FONT_PATH, "theme default is not readable")
		_check(_font_base_path(shared_theme.get_font(&"font", &"Button")) == READABLE_FONT_PATH, "theme buttons are not readable role")
		_check(_font_base_path(shared_theme.get_font(&"font", &"TooltipLabel")) == READABLE_FONT_PATH, "theme tooltip is not readable role")

	var title := Label.new()
	SkinKit.apply_composition_label(title, &"title")
	_check_player_font(title.get_theme_font("font"), "title")
	_check(_font_base_path(title.get_theme_font("font")) == READABLE_FONT_PATH, "title did not use readable role")
	_check(title.get_meta("ui_composition_role", &"") == &"title", "title composition metadata missing")

	var body := Label.new()
	SkinKit.apply_label(body)
	_check_player_font(body.get_theme_font("font"), "generic/body label")
	_check(_font_base_path(body.get_theme_font("font")) == READABLE_FONT_PATH, "body did not use readable role")

	var token_body := Label.new()
	SkinKit.apply_label_token(token_body, &"body")
	_check_player_font(token_body.get_theme_font("font"), "body token")

	var button := Button.new()
	SkinKit.apply_button_token(button, &"secondary", &"button")
	_check_player_font(button.get_theme_font("font"), "button")
	_check(_font_base_path(button.get_theme_font("font")) == READABLE_FONT_PATH, "button did not use readable role")
	_check(button.get_meta("ui_composition_role", &"") == &"button", "button composition metadata missing")

	var long_button := Button.new()
	SkinKit.apply_button(long_button, &"secondary", 14, &"button", &"readable")
	_check_player_font(long_button.get_theme_font("font"), "long-form button")

	title.free()
	body.free()
	token_body.free()
	button.free()
	long_button.free()


func _check_texture_safe_zones() -> void:
	_check(SkinKit.safe_content_margin(8, 18) == 18, "safe margin did not protect the texture slice")
	_check(SkinKit.safe_content_margin(24, 12) == 24, "safe margin discarded larger authored padding")

	var direct_texture := load("res://assets/art24/ui/modal_frame.png") as Texture2D
	_check_texture_style(SkinKit.style_box_from_texture(direct_texture, 24, 46), "direct_modal_frame")
	_check_texture_style(SkinKit.panel_style(&"surface"), "shared_panel")
	_check_texture_style(SkinKit.button_style(&"secondary"), "shared_button")
	_check_texture_style(
		PlacementContract.style_box_for_visual_key(&"art21r2.modal.title_plate", &"ui.art19.panel.terminal_main", 8, 34),
		"placement_title_plate"
	)
	_check_texture_style(
		PlacementContract.style_box_for_visual_key(&"art21r2.modal.button.secondary", &"ui.art19.button.dark", 8, 18),
		"placement_button"
	)


func _check_texture_style(style: StyleBox, label: String) -> void:
	if not (style is StyleBoxTexture):
		failures.append("%s did not resolve to shared texture art" % label)
		return
	var textured := style as StyleBoxTexture
	var texture_margins := [
		textured.texture_margin_left,
		textured.texture_margin_top,
		textured.texture_margin_right,
		textured.texture_margin_bottom,
	]
	var content_margins := [
		textured.content_margin_left,
		textured.content_margin_top,
		textured.content_margin_right,
		textured.content_margin_bottom,
	]
	var decoupled := bool(textured.get_meta("ui_content_insets_decoupled_from_slice", false))
	for index in range(4):
		if decoupled:
			_check(
				float(content_margins[index]) >= 12.0,
				"%s authored content safe inset %d is too small: %s" % [label, index, content_margins[index]]
			)
		else:
			_check(
				float(content_margins[index]) >= float(texture_margins[index]),
				"%s content margin %d intrudes into texture margin: %s < %s" % [label, index, content_margins[index], texture_margins[index]]
			)


func _check_asset_governance() -> void:
	_check(FileAccess.file_exists(DISPLAY_FONT_PATH), "FusionPixel runtime font missing")
	_check(FileAccess.file_exists(LICENSE_PATH), "FusionPixel license evidence file missing")
	_check(FileAccess.get_sha256(DISPLAY_FONT_PATH).to_lower() == FUSION_SHA256, "FusionPixel hash drifted")
	var license_text := FileAccess.get_file_as_string(LICENSE_PATH)
	_check(license_text.contains("Copyright (c) 2022, TakWolf"), "FusionPixel copyright evidence missing")
	_check(license_text.contains("SIL OPEN FONT LICENSE Version 1.1"), "FusionPixel OFL text missing")
	_check(license_text.contains("https://github.com/TakWolf/fusion-pixel-font/blob/master/LICENSE-OFL"), "FusionPixel official upstream license URL missing")
	_check(license_text.contains("verified on 2026-07-24"), "FusionPixel official upstream verification date missing")
	_check(
		license_text.contains("does not") and license_text.contains("claim that embedded metadata alone proves"),
		"FusionPixel evidence note overclaims embedded metadata"
	)

	var row := _manifest_row(&"ui.font.fusion_pixel")
	_check(not row.is_empty(), "FusionPixel manifest row missing")
	_check(String(row.get("godot_path", "")) == DISPLAY_FONT_PATH, "FusionPixel manifest path drifted")
	_check(String(row.get("license_status", "")) == "verified_ofl_1_1", "FusionPixel manifest license is not verified OFL 1.1")
	_check(String(row.get("replacement_needed", "")).to_lower() == "false", "FusionPixel remains blocked from production")
	_check(String(row.get("source_status", "")) == "verified_upstream_ofl_with_font_identity", "FusionPixel evidence source status drifted")
	_check(String(row.get("note", "")).contains(LICENSE_PATH), "FusionPixel manifest lacks license path")
	_check(String(row.get("note", "")).contains("2026-07-24"), "FusionPixel manifest lacks official license verification date")
	_check(String(row.get("note", "")).contains("https://github.com/TakWolf/fusion-pixel-font/blob/master/LICENSE-OFL"), "FusionPixel manifest lacks official license URL")
	_check(String(row.get("note", "")).to_lower().contains(FUSION_SHA256), "FusionPixel manifest lacks verified hash")


func _check_shared_ui_consumers() -> void:
	for path in [
		"res://scripts/ui/inventory/inventory_panel.gd",
		"res://scripts/ui/ground_loot/ground_loot_panel.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		_check(not source.contains("StyleBoxFlat.new()"), "%s still replaces image borders with local flat plastic styling" % path)
		_check(source.contains("texture_for_visual_key"), "%s does not consume shared framed art" % path)
		_check(source.contains("style_box_from_texture_with_insets"), "%s outer frame bypasses the size-specific safe-zone helper" % path)
		_check(source.contains("apply_composition_label"), "%s title bypasses the composition role contract" % path)

	for panel in [InventoryPanelScript.new(), GroundLootPanelScript.new()]:
		panel.build()
		var panel_label := String(panel.name)
		_check_texture_style(panel.get_theme_stylebox("panel"), panel_label + "_outer")
		var title := panel.find_child("*Title", true, false) as Label
		if title == null:
			failures.append("%s title is missing" % panel_label)
		else:
			_check_player_font(title.get_theme_font("font"), panel_label + " title")
		var title_plate := panel.find_child("*TitlePlate", true, false) as PanelContainer
		if title_plate == null:
			failures.append("%s title plate missing" % panel_label)
		else:
			_check_texture_style(title_plate.get_theme_stylebox("panel"), panel_label + "_title_plate")
		var minimum_size: Vector2 = panel.get_combined_minimum_size()
		_check(minimum_size.x <= panel.size.x + 0.01 and minimum_size.y <= panel.size.y + 0.01, "%s safe margins overflow its authored frame: minimum=%s frame=%s" % [panel_label, minimum_size, panel.size])
		panel.free()

	var long_term_source := FileAccess.get_file_as_string("res://scripts/ui/long_term/long_term_shell.gd")
	_check(long_term_source.contains('get_node_or_null("/root/ContentDB")'), "long-term display font checks the wrong runtime service")
	_check(not long_term_source.contains('get_node_or_null("/root/AssetCatalog")'), "long-term display font still depends on a nonexistent autoload")

	var map_overlay_source := FileAccess.get_file_as_string("res://scripts/ui/map_overlay/map_overlay_panel.gd")
	_check(map_overlay_source.contains("apply_composition_label(title, &\"title\""), "map overlay title bypasses the display-font role")
	_check(map_overlay_source.contains("apply_composition_label(detail, &\"body\""), "map overlay detail bypasses the readable-body role")


func _check_live_dynamic_ui() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var canvas := Control.new()
	canvas.name = "PlayerUIFontContractCanvas"
	canvas.size = Vector2(1280, 720)
	SkinKit.apply_player_ui_theme(canvas)
	root.add_child(canvas)

	var settings := SettingsPanelScript.new() as Control
	settings.position = Vector2(60, 40)
	canvas.add_child(settings)
	await process_frame
	settings.show()
	_check_text_control_tree(settings, "settings")
	var confirmation_label := settings.get("confirmation_label") as Label
	var status_label := settings.get("status_label") as Label
	_check_wrapping_label(confirmation_label, "settings confirmation")
	_check_wrapping_label(status_label, "settings status")
	var window_mode_option := settings.get("window_mode_option") as OptionButton
	if window_mode_option == null:
		failures.append("settings WindowMode OptionButton is missing")
	else:
		_check_player_font(window_mode_option.get_theme_font(&"font"), "settings OptionButton")
		var option_popup := window_mode_option.get_popup()
		_check(option_popup != null, "settings OptionButton popup is missing")
		if option_popup != null:
			_check(option_popup.theme == SkinKit.player_ui_theme(), "settings OptionButton popup does not own the shared theme")
			_check_player_font(option_popup.get_theme_font(&"font"), "settings OptionButton popup")

	var tooltip_panel := PopupPanel.new()
	tooltip_panel.name = "NativeTooltipPanelProbe"
	tooltip_panel.theme = SkinKit.player_ui_theme()
	tooltip_panel.theme_type_variation = &"TooltipPanel"
	canvas.add_child(tooltip_panel)
	var tooltip_label := Label.new()
	tooltip_label.name = "NativeTooltipLabelProbe"
	tooltip_label.theme_type_variation = &"TooltipLabel"
	tooltip_label.text = _long_chinese_text()
	tooltip_label.custom_minimum_size.x = 360.0
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.clip_text = false
	tooltip_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	tooltip_panel.add_child(tooltip_label)
	_check_player_font(tooltip_label.get_theme_font(&"font"), "native TooltipLabel")
	_check(
		tooltip_panel.get_theme_stylebox(&"panel") is StyleBoxTexture,
		"native TooltipPanel does not resolve the shared textured frame"
	)
	_check_wrapping_label(tooltip_label, "native tooltip")

	var item_panels: Array[Control] = []
	for panel_script in [InventoryPanelScript, GroundLootPanelScript]:
		var item_panel := panel_script.new() as Control
		canvas.add_child(item_panel)
		await process_frame
		item_panel.call("apply_snapshot", {})
		await process_frame
		var panel_name := String(item_panel.name)
		_check_text_control_tree(item_panel, panel_name)
		var item_tooltip := item_panel.get("tooltip_label") as Label
		_check_player_font(item_tooltip.get_theme_font(&"font") if item_tooltip != null else null, panel_name + " item hover")
		_check_wrapping_label(item_tooltip, panel_name + " item hover")
		var detail_scroll := item_panel.get("detail_scroll") as ScrollContainer
		_check(
			detail_scroll != null and detail_scroll.custom_minimum_size.y >= 112.0,
			"%s item hover viewport collapsed behind its frame" % panel_name
		)
		item_panels.append(item_panel)

	var world_popup := WorldContextPopupScript.new() as Control
	canvas.add_child(world_popup)
	await process_frame
	world_popup.show()
	var world_title := world_popup.get("title_label") as Label
	var world_hint := world_popup.get("hint_label") as Label
	var world_status := world_popup.get("status_label") as Label
	_check_player_font(world_title.get_theme_font(&"font") if world_title != null else null, "world hover title")
	_check_player_font(world_hint.get_theme_font(&"font") if world_hint != null else null, "world hover body")
	_check_player_font(world_status.get_theme_font(&"font") if world_status != null else null, "world hover status")
	if world_hint != null:
		world_hint.text = _long_chinese_text()
	_check_wrapping_label(world_hint, "world hover body")

	var result_panel := ResultPanelScene.instantiate() as Control
	result_panel.size = Vector2(1280, 720)
	canvas.add_child(result_panel)
	await process_frame
	result_panel.call("set_result_summary", "本次探索结算", _long_chinese_text())
	await process_frame
	_check_text_control_tree(result_panel, "result")
	var result_summary := result_panel.get_node_or_null("ResultSummary") as Label
	_check_wrapping_label(result_summary, "result summary")

	await process_frame
	settings.queue_free()
	world_popup.queue_free()
	result_panel.queue_free()
	for item_panel in item_panels:
		item_panel.queue_free()
	tooltip_panel.queue_free()
	canvas.queue_free()
	await process_frame


func _check_text_control_tree(node: Node, consumer_prefix: String) -> void:
	if node is Label:
		var label := node as Label
		_check_player_font(label.get_theme_font(&"font"), "%s/%s" % [consumer_prefix, label.name])
	elif node is Button:
		var button := node as Button
		_check_player_font(button.get_theme_font(&"font"), "%s/%s" % [consumer_prefix, button.name])
	for child in node.get_children():
		_check_text_control_tree(child, consumer_prefix)


func _check_wrapping_label(label: Label, consumer: String) -> void:
	if label == null:
		failures.append("%s label is missing" % consumer)
		return
	label.text = _long_chinese_text()
	_check(not label.clip_text, "%s clips long Chinese" % consumer)
	_check(label.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s does not wrap long Chinese" % consumer)
	_check(label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING, "%s trims long Chinese" % consumer)


func _long_chinese_text() -> String:
	return "这是一段用于验证像素字体、长中文自动换行与安全边距的完整说明；文字必须留在边框内容区内，不得被裁切，也不得覆盖按钮或相邻的美术素材。"


func _manifest_row(asset_id: StringName) -> Dictionary:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return {}
	var headers := file.get_csv_line()
	while file.get_position() < file.get_length():
		var values := file.get_csv_line()
		if values.is_empty() or (values.size() == 1 and String(values[0]).strip_edges() == ""):
			continue
		var row: Dictionary = {}
		for index in range(mini(headers.size(), values.size())):
			row[String(headers[index])] = String(values[index])
		if StringName(row.get("asset_id", "")) == asset_id:
			return row
	return {}


func _resource_path(resource: Resource) -> String:
	return "" if resource == null else resource.resource_path


func _check_player_font(font: Font, consumer: String) -> void:
	if not (font is FontVariation):
		_check(false, "%s did not resolve a registered role font stack: %s" % [consumer, font])
		return
	var variation := font as FontVariation
	var base_path := _resource_path(variation.base_font)
	_check(base_path in [DISPLAY_FONT_PATH, READABLE_FONT_PATH], "%s primary font=%s" % [consumer, base_path])
	var fallback_paths: Array[String] = []
	for fallback in variation.fallbacks:
		fallback_paths.append(_resource_path(fallback))
	var expected_fallback := READABLE_FONT_PATH if base_path == DISPLAY_FONT_PATH else DISPLAY_FONT_PATH
	_check(fallback_paths.has(expected_fallback), "%s lacks role fallback %s: %s" % [consumer, expected_fallback, fallback_paths])


func _font_base_path(font: Font) -> String:
	if not (font is FontVariation):
		return ""
	return _resource_path((font as FontVariation).base_font)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I3R_UI_COMPOSITION_CONTRACT=PASS fonts=FusionPixel,Noto roles=display,readable surfaces=settings,tooltip,item,world,option_popup,result texture_safe=5 license=upstream_ofl")
		quit(0)
		return
	for failure in failures:
		push_error("I3R UI composition contract: " + failure)
	print("I3R_UI_COMPOSITION_CONTRACT=FAIL failures=%d" % failures.size())
	quit(1)
