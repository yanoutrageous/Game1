extends SceneTree

const SkinKit := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const RunUIViewModelScript := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const DeployPrepModelScript := preload("res://scripts/ui/deploy_prep/deploy_prep_model.gd")

const DISPLAY_FONT_PATH := "res://assets/fonts/FusionPixel.otf"
const READABLE_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Regular.otf"
const PASS_MARKER := "I4_FONT_ROLE_RASTER=PASS"
const FAIL_MARKER := "I4_FONT_ROLE_RASTER=FAIL"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var display := SkinKit.pixel_font() as FontVariation
	var readable := SkinKit.readable_font() as FontVariation
	_expect(display != null and readable != null and display != readable, "display and readable roles still share one font object")
	if display != null:
		_expect(_base_path(display) == DISPLAY_FONT_PATH, "display role is not FusionPixel")
		_expect(_fallback_paths(display).has(READABLE_FONT_PATH), "display role lost explicit CJK fallback")
		var display_file := display.base_font as FontFile
		_expect(display_file != null and display_file.antialiasing == TextServer.FONT_ANTIALIASING_NONE, "pixel display font is antialiased")
		_expect(display_file != null and display_file.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED, "pixel display font uses subpixel positioning")
	if readable != null:
		_expect(_base_path(readable) == DISPLAY_FONT_PATH, "readable role is not FusionPixel")
		_expect(_fallback_paths(readable).has(READABLE_FONT_PATH), "readable role lost explicit Noto glyph fallback")
		var readable_file := readable.base_font as FontFile
		_expect(readable_file != null and readable_file.antialiasing == TextServer.FONT_ANTIALIASING_NONE, "readable FusionPixel font is antialiased")
		_expect(readable_file != null and readable_file.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED, "readable FusionPixel font uses subpixel positioning")

	var theme := SkinKit.player_ui_theme()
	_expect(_base_path(theme.default_font as FontVariation) == DISPLAY_FONT_PATH, "theme default is not FusionPixel")
	for theme_type in [&"Label", &"TooltipLabel", &"PopupMenu", &"LineEdit"]:
		_expect(_base_path(theme.get_font(&"font", theme_type) as FontVariation) == DISPLAY_FONT_PATH, "%s is not FusionPixel" % theme_type)
	for theme_type in [&"Button", &"MenuButton", &"TabBar"]:
		_expect(_base_path(theme.get_font(&"font", theme_type) as FontVariation) == DISPLAY_FONT_PATH, "%s is not FusionPixel" % theme_type)
	_expect(_base_path(theme.get_font(&"normal_font", &"RichTextLabel") as FontVariation) == DISPLAY_FONT_PATH, "rich body text is not FusionPixel")

	var title := Label.new()
	var body := Label.new()
	var numeric := Label.new()
	var short_button := Button.new()
	SkinKit.apply_composition_label(title, &"title")
	SkinKit.apply_composition_label(body, &"body")
	SkinKit.apply_label_token(numeric, &"numeric")
	SkinKit.apply_button_token(short_button, &"secondary", &"button")
	_expect(_base_path(title.get_theme_font("font") as FontVariation) == DISPLAY_FONT_PATH, "localized title is not FusionPixel")
	_expect(_base_path(body.get_theme_font("font") as FontVariation) == DISPLAY_FONT_PATH, "body composition is not FusionPixel")
	_expect(_base_path(short_button.get_theme_font("font") as FontVariation) == DISPLAY_FONT_PATH, "localized button is not FusionPixel")
	_expect(_base_path(numeric.get_theme_font("font") as FontVariation) == DISPLAY_FONT_PATH, "numeric token lost the intentional pixel role")
	_expect(title.get_meta("ui_font_token", &"") == &"page_title", "title has no semantic font token")
	_expect(body.get_meta("ui_font_token", &"") == &"body", "body has no semantic font token")

	for scale in [1.0, 1.25, 1.5]:
		SkinKit.set_runtime_ui_scale_factor(scale)
		for token in [&"page_title", &"button", &"body", &"body_small", &"hud"]:
			var scaled_size := SkinKit.scaled_font_size(SkinKit.font_size(token), scale)
			_expect(scaled_size == int(round(float(scaled_size))), "%s at %.2f did not land on an integer raster size" % [token, scale])
	SkinKit.set_runtime_ui_scale_factor(1.0)

	var host := Control.new()
	host.size = Vector2(1280, 720)
	root.add_child(host)
	var inventory := InventoryPanelScript.new()
	host.add_child(inventory)
	inventory.apply_snapshot({
		"inventory_items": [_item("ration_b"), _item("ration_a")],
		"equipped_items": [],
		"backpack_used": 2,
		"backpack_capacity": 10,
	})
	inventory.show_panel()
	await _wait_until(
		func() -> bool: return inventory.find_child("InventoryUseButton", true, false) != null,
		"inventory role surfaces"
	)
	var inventory_title := inventory.get("title_label") as Label
	var inventory_summary := inventory.get("summary_label") as Label
	_expect(_base_path(inventory_title.get_theme_font("font") as FontVariation) == DISPLAY_FONT_PATH, "inventory title is not FusionPixel")
	_expect(_base_path(inventory_summary.get_theme_font("font") as FontVariation) == DISPLAY_FONT_PATH, "inventory summary is not FusionPixel")
	var use_button := inventory.find_child("InventoryUseButton", true, false) as Button
	_expect(use_button != null and use_button.get_meta("ui_control_size_class", &"") == &"compact", "compact item action did not use the compact nine-slice contract")
	if use_button != null:
		var style := use_button.get_theme_stylebox("normal") as StyleBoxTexture
		var available_width := use_button.custom_minimum_size.x - style.content_margin_left - style.content_margin_right
		var measured_width := use_button.get_theme_font("font").get_string_size(use_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, use_button.get_theme_font_size("font_size")).x
		_expect(available_width >= measured_width, "compact button frame overlaps its text safe area")

	var compact_profile := SkinKit.control_inset_profile(&"compact")
	var large_profile := SkinKit.control_inset_profile(&"large")
	_expect(compact_profile.get("content") != large_profile.get("content"), "compact and large controls still share one content inset")
	_expect(
		float((compact_profile.get("content") as Vector4).x) < float((large_profile.get("content") as Vector4).x),
		"compact control did not reclaim text-safe width"
	)

	var item_presentation := RunUIViewModelScript.item_presentation(_item("rarity_probe"))
	_expect(not str(item_presentation.get("detail_text", "")).contains("[T"), "player item detail still exposes engineering T-codes")
	var deploy_model := DeployPrepModelScript.build({
		"meta_progress_summary": {
			"gold": 100,
			"warehouse_items": [_item("warehouse_probe")],
		},
	})
	_expect(not JSON.stringify(deploy_model).contains("[T"), "Deploy player projection still exposes engineering T-codes")

	title.free()
	body.free()
	numeric.free()
	short_button.free()
	host.queue_free()
	await host.tree_exited
	_finish()


func _item(instance_id: String) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": "con_ration",
		"display_name": "压缩饼",
		"item_type": &"consumable",
		"main_type": &"consumable",
		"rarity": &"tier_1",
		"weight": 1,
		"base_value": 12,
		"can_sell": true,
		"can_store": true,
		"can_consume": true,
		"effect_kind": "heal",
		"effect_amount": 20,
	}


func _base_path(font: FontVariation) -> String:
	return "" if font == null or font.base_font == null else font.base_font.resource_path


func _fallback_paths(font: FontVariation) -> Array[String]:
	var result: Array[String] = []
	if font == null:
		return result
	for fallback in font.fallbacks:
		result.append(fallback.resource_path)
	return result


func _wait_until(predicate: Callable, label: String, max_polls: int = 120) -> void:
	for _poll_index in range(max_polls):
		if bool(predicate.call()):
			return
		await process_frame
	failures.append("timed out waiting for semantic state: %s" % label)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s primary=FusionPixel fallback=Noto aa=pixel sizes=integer frame_safe=compact,large rarity=natural" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("%s count=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
