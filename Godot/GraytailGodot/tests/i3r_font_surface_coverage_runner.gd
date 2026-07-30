extends SceneTree

const SkinKit := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const InteractableScript := preload("res://scripts/gameplay/interaction/g41_interactable.gd")

const DISPLAY_FONT_PATH := "res://assets/fonts/FusionPixel.otf"
const FALLBACK_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Regular.otf"

var failures: Array[String] = []
var checked_text_controls := 0
var checked_visible_controls := 0
var checked_tooltip_sources := 0
var checked_settings_popups := 0
var checked_surfaces: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var expected_theme := SkinKit.player_ui_theme()
	_require(expected_theme != null, "shared player UI theme is unavailable")
	_check_font(SkinKit.player_ui_font(), "shared player UI font")
	_check_font(
		expected_theme.get_font(&"normal_font", &"RichTextLabel") if expected_theme != null else null,
		"shared RichTextLabel normal font"
	)
	_check_font(
		expected_theme.get_font(&"font", &"TooltipLabel") if expected_theme != null else null,
		"shared native TooltipLabel font"
	)

	# Load the production scene only after autoloads have entered the tree.
	# RunScene legitimately resolves the SettingsManager autoload identifier.
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	_require(main_scene != null, "production main scene is unavailable")
	if main_scene == null:
		_finish()
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	for _index in range(4):
		await process_frame

	var run_scene := main.get_node_or_null("RunScene")
	if run_scene == null:
		_fail_and_finish("production RunScene is missing")
		return
	await _materialize_dynamic_surfaces(run_scene)

	var ui_root := run_scene.get("ui_root") as Control
	var app_shell := run_scene.get("ui_shell") as Control
	var run_surface := run_scene.get("run_surface") as Control
	var room_runtime_view := run_scene.get("room_runtime_view") as Node
	_require(ui_root != null, "production UI root is missing")
	_require(app_shell != null, "production AppShell is missing")
	_require(run_surface != null, "production RunSurface is missing")
	_require(room_runtime_view != null, "production room runtime view is missing")

	if ui_root != null:
		_check_surface_theme(ui_root, "ui_root", expected_theme)
		_check_text_control_tree(ui_root, "production_ui")
		_check_visible_nonempty_text_controls(ui_root, "production_ui_visible")
		_require(checked_visible_controls > 0, "production UI visible-text font scan found no controls")

	for entry in [
		["main", run_scene.get("main_menu_panel") as Control],
		["deploy", run_scene.get("deploy_shell_panel") as Control],
		["long_term", run_scene.get("long_term_shell_panel") as Control],
		["settings", app_shell.get("settings_panel") as Control if app_shell != null else null],
		["runtime_settings", run_scene.get("runtime_settings_panel") as Control],
		["run", run_surface],
		["inventory", run_scene.get("inventory_panel") as Control],
		["map", run_scene.get("map_overlay_panel") as Control],
		["result", run_scene.get("result_panel") as Control],
		["tutorial", run_scene.get("tutorial_popup_panel") as Control],
		["loot_result", run_scene.get("loot_panel") as Control],
		[
			"world_popup",
			room_runtime_view.get("context_popup") as Control if room_runtime_view != null else null,
		],
	]:
		var surface_name := String(entry[0])
		var surface := entry[1] as Control
		_require(surface != null, "%s production surface is missing" % surface_name)
		if surface != null:
			_check_surface_theme(surface, surface_name, expected_theme)

	_check_settings_popups(
		app_shell,
		run_scene.get("runtime_settings_panel") as Control,
		expected_theme
	)
	await _check_world_layer_fonts(room_runtime_view)

	main.free()
	await process_frame
	await process_frame
	_finish()


func _materialize_dynamic_surfaces(run_scene: Node) -> void:
	var item := {
		"instance_id": "i3r_font_probe_item",
		"item_id": "i3r_font_probe_item",
		"display_name": "像素字体校验物资",
		"rarity": &"tier_3",
		"weight": 2,
		"quantity": 1,
		"short_description": "动态物品、悬浮详情与操作按钮必须沿用统一像素字体。",
		"base_value": 16,
		"can_consume": true,
	}
	var inventory := run_scene.get("inventory_panel") as Control
	if inventory != null:
		inventory.call("apply_snapshot", {
			"inventory_items": [item],
			"equipped_items": [],
			"backpack_used": 2,
			"backpack_capacity": 10,
			"black_coin": 3,
			"gold_coin": 8,
		})
	var ground_loot := run_scene.get("ground_loot_panel") as Control
	if ground_loot != null:
		ground_loot.call("apply_snapshot", {
			"room_floor_items": [item],
			"inventory_items": [],
			"equipped_items": [],
			"backpack_used": 0,
			"backpack_capacity": 10,
			"backpack_remaining": 10,
		})
	var result := run_scene.get("result_panel") as Control
	if result != null:
		result.call("show_summary", {
			"outcome": "Extracted",
			"persistence_state": &"committed",
			"normal_exit_allowed": true,
			"settlement": {
				"outcome": "success",
				"warehouse_items": [item],
				"room_floor_lost_items": [],
				"cleared_consumables": [],
				"black_coin_converted": 3,
				"safe_yield_retained": 8,
				"gold_coin_gained": 11,
			},
		})
	var room_runtime_view := run_scene.get("room_runtime_view") as Node
	if room_runtime_view != null:
		var popup := room_runtime_view.get("context_popup") as Control
		if popup != null:
			popup.call("apply_context", {
				"interaction_kind": &"ground_loot",
				"world_pos": Vector2(640, 360),
				"player_world_pos": Vector2(620, 360),
				"room_bounds": Rect2(300, 0, 980, 720),
				"gameplay_focus_rect": Rect2(300, 0, 980, 560),
				"reserved_rects": [],
				"items": [item],
				"inventory_items": [],
				"backpack_remaining": 10,
			})
	var tutorial := run_scene.get("tutorial_popup_panel") as Control
	if tutorial != null:
		tutorial.call("apply_popup", {
			"id": &"i3r_font_probe",
			"title": "教程提示",
			"message": "像素字体必须覆盖教程标题、富文本正文、确认按钮和按钮悬浮说明。",
			"blocking": true,
			"confirm_text": "继续",
			"confirm_action": &"ui_accept",
			"confirm_action_hint": {"display_label": "Enter / A"},
		})
	await process_frame
	await process_frame


func _check_surface_theme(surface: Control, surface_name: String, expected_theme: Theme) -> void:
	checked_surfaces.append(surface_name)
	_require(
		surface.theme == expected_theme,
		"%s does not own the shared player UI theme" % surface_name
	)


func _check_text_control_tree(node: Node, scope: String) -> void:
	if node is RichTextLabel:
		var rich_text := node as RichTextLabel
		_check_font(rich_text.get_theme_font(&"normal_font"), "%s/%s normal" % [scope, rich_text.name])
		_check_font(rich_text.get_theme_font(&"bold_font"), "%s/%s bold" % [scope, rich_text.name])
		checked_text_controls += 1
	elif node is Label:
		_check_font((node as Label).get_theme_font(&"font"), "%s/%s" % [scope, node.name])
		checked_text_controls += 1
	elif node is Button:
		_check_font((node as Button).get_theme_font(&"font"), "%s/%s" % [scope, node.name])
		checked_text_controls += 1
	elif node is LineEdit:
		_check_font((node as LineEdit).get_theme_font(&"font"), "%s/%s" % [scope, node.name])
		checked_text_controls += 1
	elif node is TextEdit:
		_check_font((node as TextEdit).get_theme_font(&"font"), "%s/%s" % [scope, node.name])
		checked_text_controls += 1
	elif node is ItemList:
		_check_font((node as ItemList).get_theme_font(&"font"), "%s/%s" % [scope, node.name])
		checked_text_controls += 1
	elif node is Tree:
		_check_font((node as Tree).get_theme_font(&"font"), "%s/%s" % [scope, node.name])
		checked_text_controls += 1
	elif node is TabBar:
		_check_font((node as TabBar).get_theme_font(&"font"), "%s/%s" % [scope, node.name])
		checked_text_controls += 1
	if node is Control and not (node as Control).tooltip_text.is_empty():
		_check_font((node as Control).get_theme_font(&"font"), "%s/%s tooltip source" % [scope, node.name])
		checked_tooltip_sources += 1
	for child in node.get_children():
		_check_text_control_tree(child, scope)


func _check_visible_nonempty_text_controls(node: Node, scope: String) -> void:
	if node is PopupMenu:
		var popup := node as PopupMenu
		if popup.visible and _popup_has_nonempty_item(popup):
			_check_font(popup.get_theme_font(&"font"), "%s/%s PopupMenu" % [scope, popup.name])
			checked_visible_controls += 1
	elif node is OptionButton:
		var option := node as OptionButton
		if option.is_visible_in_tree() and (not option.text.strip_edges().is_empty() or option.item_count > 0):
			_check_font(option.get_theme_font(&"font"), "%s/%s OptionButton" % [scope, option.name])
			checked_visible_controls += 1
	elif node is RichTextLabel:
		var rich_text := node as RichTextLabel
		if rich_text.is_visible_in_tree() and not rich_text.text.strip_edges().is_empty():
			_check_font(rich_text.get_theme_font(&"normal_font"), "%s/%s RichTextLabel normal" % [scope, rich_text.name])
			_check_font(rich_text.get_theme_font(&"bold_font"), "%s/%s RichTextLabel bold" % [scope, rich_text.name])
			checked_visible_controls += 1
	elif node is Label:
		var label := node as Label
		if label.is_visible_in_tree() and not label.text.strip_edges().is_empty():
			_check_font(label.get_theme_font(&"font"), "%s/%s Label" % [scope, label.name])
			checked_visible_controls += 1
	elif node is Button:
		var button := node as Button
		if button.is_visible_in_tree() and not button.text.strip_edges().is_empty():
			_check_font(button.get_theme_font(&"font"), "%s/%s Button" % [scope, button.name])
			checked_visible_controls += 1
	for child in node.get_children(true):
		_check_visible_nonempty_text_controls(child, scope)


func _popup_has_nonempty_item(popup: PopupMenu) -> bool:
	for index in range(popup.item_count):
		if not popup.get_item_text(index).strip_edges().is_empty():
			return true
	return false


func _check_settings_popups(
	app_shell: Control,
	runtime_settings: Control,
	expected_theme: Theme
) -> void:
	var app_settings := app_shell.get("settings_panel") as Control if app_shell != null else null
	for entry in [
		["settings", app_settings],
		["runtime_settings", runtime_settings],
	]:
		var scope := String(entry[0])
		var settings := entry[1] as Control
		_require(settings != null, "%s panel is missing" % scope)
		if settings == null:
			continue
		for property_name in [
			"window_mode_option",
			"resolution_option",
			"vsync_option",
			"frame_limit_option",
		]:
			var option := settings.get(property_name) as OptionButton
			_require(option != null, "%s %s is missing" % [scope, property_name])
			if option == null:
				continue
			var popup := option.get_popup()
			_require(
				popup != null and popup.theme == expected_theme,
				"%s %s PopupMenu bypasses the shared player UI theme" % [scope, property_name]
			)
			if popup != null:
				_check_font(popup.get_theme_font(&"font"), "%s %s PopupMenu" % [scope, property_name])
				checked_settings_popups += 1
	_require(
		checked_settings_popups == 8,
		"settings PopupMenu coverage expected 8, checked %d" % checked_settings_popups
	)


func _check_world_layer_fonts(room_runtime_view: Node) -> void:
	if room_runtime_view != null:
		var door_prompt := room_runtime_view.get_node_or_null("DoorPrompt") as Label
		_require(door_prompt != null, "world DoorPrompt is missing")
		if door_prompt != null:
			_check_font(door_prompt.get_theme_font(&"font"), "world DoorPrompt")
			checked_text_controls += 1
	var interactable := InteractableScript.new()
	root.add_child(interactable)
	await process_frame
	var interaction_prompt := interactable.get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	_require(interaction_prompt != null, "world InteractionPrompt is missing")
	if interaction_prompt != null:
		_check_font(interaction_prompt.get_theme_font(&"font"), "world InteractionPrompt")
		checked_text_controls += 1
	interactable.free()
	await process_frame


func _check_font(font: Font, consumer: String) -> void:
	if not (font is FontVariation):
		failures.append("%s did not resolve the shared font stack: %s" % [consumer, font])
		return
	var variation := font as FontVariation
	var base_path := variation.base_font.resource_path if variation.base_font != null else ""
	_require(
		base_path == DISPLAY_FONT_PATH,
		"%s primary font is not FusionPixel: %s" % [
			consumer,
			base_path,
		]
	)
	var fallback_paths: Array[String] = []
	for fallback in variation.fallbacks:
		fallback_paths.append(fallback.resource_path)
	_require(
		fallback_paths.has(FALLBACK_FONT_PATH),
		"%s lost the Noto glyph fallback %s: %s" % [consumer, FALLBACK_FONT_PATH, fallback_paths]
	)


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fail_and_finish(message: String) -> void:
	failures.append(message)
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print(
			"I3R_FONT_SURFACE_COVERAGE=PASS controls=%d visible_controls=%d tooltips=%d settings_popups=%d surfaces=%s primary=FusionPixel fallback=Noto"
			% [
				checked_text_controls,
				checked_visible_controls,
				checked_tooltip_sources,
				checked_settings_popups,
				checked_surfaces,
			]
		)
		quit(0)
		return
	for failure in failures:
		push_error("I3R font surface coverage: " + failure)
	print(
		"I3R_FONT_SURFACE_COVERAGE=FAIL failures=%d controls=%d visible_controls=%d tooltips=%d settings_popups=%d surfaces=%s"
		% [
			failures.size(),
			checked_text_controls,
			checked_visible_controls,
			checked_tooltip_sources,
			checked_settings_popups,
			checked_surfaces,
		]
	)
	quit(1)
