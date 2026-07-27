extends Control
class_name TutorialPopupPanel

const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const PresentationThemeScript := preload("res://scripts/presentation/presentation_theme.gd")

signal confirmed

var popup: Dictionary = {}
var layout_profile: Dictionary = {}
var ui_scale_factor := 1.0
var _last_popup_id: StringName = &""
var _presentation_occluded := false


func apply_popup(next_popup: Dictionary) -> void:
	var next_id := StringName(next_popup.get("id", &""))
	var popup_changed := next_id != _last_popup_id
	popup = next_popup.duplicate(true)
	_last_popup_id = next_id
	_refresh(popup_changed)


func set_presentation_occluded(occluded: bool) -> void:
	if _presentation_occluded == occluded:
		return
	_presentation_occluded = occluded
	_refresh(false)


func apply_layout_profile(next_profile: Dictionary) -> void:
	layout_profile = next_profile.duplicate(true)
	if layout_profile.has("ui_scale_factor"):
		ui_scale_factor = clampf(float(layout_profile.get("ui_scale_factor", 1.0)), 1.0, 1.5)
	else:
		layout_profile["ui_scale_factor"] = ui_scale_factor
	_refresh(false)


func set_ui_scale_factor(value: float) -> void:
	ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value)
	set_meta("runtime_ui_scale_factor", ui_scale_factor)
	layout_profile["ui_scale_factor"] = ui_scale_factor
	_refresh(false)


func layout_snapshot() -> Dictionary:
	var panel := get_node_or_null("Panel") as Panel
	var message := get_node_or_null("Panel/Content/Message") as RichTextLabel
	var button := get_node_or_null("Panel/Content/ConfirmButton") as Button
	var blocking := bool(popup.get("blocking", false))
	var profile := _resolved_layout_profile()
	return {
		"visible": visible,
		"blocking": blocking,
		"presentation_occluded": _presentation_occluded,
		"ui_scale_factor": ui_scale_factor,
		"panel_rect": panel.get_global_rect() if panel != null else Rect2(),
		"message_rect": message.get_global_rect() if message != null else Rect2(),
		"message_content_height": message.get_content_height() if message != null else 0.0,
		"message_scroll_active": message.scroll_active if message != null else false,
		"button_rect": button.get_global_rect() if button != null and button.visible else Rect2(),
		"button_text": button.text if button != null else "",
		"button_tooltip": button.tooltip_text if button != null else "",
		"geometry": UILayerContractScript.run_tutorial_geometry(profile, blocking),
	}


func _ready() -> void:
	ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	Art10UISkinKitScript.apply_player_ui_theme(self)
	var panel := get_node_or_null("Panel") as Panel
	if panel != null:
		var panel_style := Art10UISkinKitScript.style_box_from_asset_ref(
			Art21UIPlacementContractScript.panel_ref(&"modal"),
			18,
			20
		)
		if panel_style != null:
			panel.add_theme_stylebox_override("panel", panel_style)
	var button := get_node_or_null("Panel/Content/ConfirmButton") as Button
	if button != null:
		Art10UISkinKitScript.apply_button(button, &"primary")
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(func() -> void: confirmed.emit())
	_refresh(true)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not bool(popup.get("blocking", false)):
		return
	var confirm_action := StringName(popup.get("confirm_action", &"ui_accept"))
	if event.is_action_pressed(String(confirm_action)):
		confirmed.emit()
		get_viewport().set_input_as_handled()


func _refresh(reset_scroll: bool = false) -> void:
	var blocking := bool(popup.get("blocking", false))
	visible = not popup.is_empty() and (blocking or not _presentation_occluded)
	if not visible or not is_inside_tree():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_inside_tree():
			var focus_owner := get_viewport().gui_get_focus_owner()
			if focus_owner != null and (focus_owner == self or is_ancestor_of(focus_owner)):
				get_viewport().gui_release_focus()
		return
	var title := get_node_or_null("Panel/Content/Title") as Label
	var message := get_node_or_null("Panel/Content/Message") as RichTextLabel
	var button := get_node_or_null("Panel/Content/ConfirmButton") as Button
	var panel := get_node_or_null("Panel") as Panel
	var content := get_node_or_null("Panel/Content") as Control
	var profile := _resolved_layout_profile()
	var geometry := UILayerContractScript.run_tutorial_geometry(profile, blocking)

	mouse_filter = Control.MOUSE_FILTER_STOP if blocking else Control.MOUSE_FILTER_IGNORE
	UILayerContractScript.apply_layer(self, &"modal" if blocking else &"overlay", 4)
	if panel != null:
		# Non-blocking guidance does not own keyboard focus, but its visible
		# card still stops pointer clicks from reaching an obscured world target.
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_rect(panel, geometry.get("panel_rect", Rect2(304, 12, 260, 520)))
	if content != null and panel != null:
		var content_inset := 20.0 + 4.0 * ((ui_scale_factor - 1.0) / 0.5)
		_set_rect(
			content,
			Rect2(
				Vector2(content_inset, content_inset),
				Vector2(
					maxf(1.0, panel.size.x - content_inset * 2.0),
					maxf(1.0, panel.size.y - content_inset * 2.0)
				)
			)
		)

	if title != null:
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.add_theme_color_override("font_color", PresentationThemeScript.color_for_key(&"ui.accent"))
		title.add_theme_font_size_override(
			"font_size",
			Art10UISkinKitScript.scaled_font_size(
				Art10UISkinKitScript.font_size(&"section_title"),
				ui_scale_factor
			)
		)
		title.text = String(popup.get("title", "教程：%s" % String(popup.get("id", ""))))
	if message != null:
		message.mouse_filter = Control.MOUSE_FILTER_STOP if blocking else Control.MOUSE_FILTER_IGNORE
		message.add_theme_color_override("default_color", PresentationThemeScript.text_color())
		var body_font := Art10UISkinKitScript.player_ui_font()
		if body_font is Font:
			message.add_theme_font_override("normal_font", body_font as Font)
			message.add_theme_font_override("bold_font", body_font as Font)
		message.add_theme_font_override("italics_font", body_font as Font)
		var body_size := Art10UISkinKitScript.scaled_font_size(
			Art10UISkinKitScript.font_size(&"body"),
			ui_scale_factor
		)
		message.add_theme_font_size_override("normal_font_size", body_size)
		message.add_theme_font_size_override("bold_font_size", body_size)
		message.add_theme_font_size_override("italics_font_size", body_size)
		message.add_theme_constant_override("line_separation", maxi(2, int(round(3.0 * ui_scale_factor))))
		message.text = String(popup.get("message", ""))
		message.scroll_active = true
		message.scroll_following = false
		if reset_scroll:
			call_deferred("_reset_message_scroll", _last_popup_id)
	if button != null:
		button.visible = true
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		Art10UISkinKitScript.apply_button(button, &"primary" if blocking else &"secondary")
		button.focus_mode = Control.FOCUS_ALL if blocking else Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0.0, round(40.0 * minf(ui_scale_factor, 1.25)))
		button.add_theme_font_size_override(
			"font_size",
			Art10UISkinKitScript.scaled_font_size(
				Art10UISkinKitScript.font_size(&"body"),
				ui_scale_factor
			)
		)
		if blocking:
			var confirm_hint := popup.get("confirm_action_hint", {}) as Dictionary
			var compact_hint := SemanticActionHintScript.compact_label_from_descriptor(
				confirm_hint,
				SemanticActionHintScript.current_device()
			)
			var full_hint := str(confirm_hint.get("display_label", ""))
			var confirm_text := str(popup.get("confirm_text", "继续"))
			if ui_scale_factor >= 1.4:
				if confirm_text == "开始作业":
					confirm_text = "开始"
				elif confirm_text == "我知道了":
					confirm_text = "知道了"
			button.text = "%s · %s" % [confirm_text, compact_hint] if not compact_hint.is_empty() else confirm_text
			button.tooltip_text = "确认操作：%s" % full_hint if not full_hint.is_empty() else confirm_text
		else:
			button.text = "点击关闭"
			button.tooltip_text = "关闭当前教程提示"
		if blocking and reset_scroll:
			call_deferred("_grab_confirm_focus_if_valid", _last_popup_id)
	if content != null:
		var gap := 8.0 + 4.0 * ((ui_scale_factor - 1.0) / 0.5)
		var title_height := maxf(
			30.0,
			title.get_combined_minimum_size().y if title != null else 30.0
		)
		var button_height := 0.0
		if button != null and button.visible:
			button_height = maxf(
				40.0 * minf(ui_scale_factor, 1.25),
				button.get_combined_minimum_size().y
			)
		if title != null:
			_set_rect(title, Rect2(0.0, 0.0, content.size.x, title_height))
		if message != null:
			var message_top := title_height + gap
			var message_bottom := content.size.y - (
				button_height + gap
				if button != null and button.visible
				else 0.0
			)
			_set_rect(
				message,
				Rect2(
					0.0,
					message_top,
					content.size.x,
					maxf(80.0, message_bottom - message_top)
				)
			)
		if button != null and button.visible:
			_set_rect(
				button,
				Rect2(
					0.0,
					content.size.y - button_height,
					content.size.x,
					button_height
				)
			)


func _resolved_layout_profile() -> Dictionary:
	var profile := layout_profile.duplicate(true)
	if profile.is_empty():
		var viewport_size := get_viewport_rect().size
		profile = UILayoutProfileScript.profile_for_size(viewport_size)
		profile["actual_viewport_size"] = Vector2i(int(round(viewport_size.x)), int(round(viewport_size.y)))
	profile["ui_scale_factor"] = ui_scale_factor
	return profile


func _reset_message_scroll(expected_popup_id: StringName) -> void:
	if expected_popup_id != _last_popup_id:
		return
	var message := get_node_or_null("Panel/Content/Message") as RichTextLabel
	if message != null:
		message.scroll_to_line(0)


func _grab_confirm_focus_if_valid(expected_popup_id: StringName) -> void:
	if (
		expected_popup_id != _last_popup_id
		or not visible
		or not bool(popup.get("blocking", false))
	):
		return
	var button := get_node_or_null("Panel/Content/ConfirmButton") as Button
	if (
		button != null
		and button.visible
		and not button.disabled
		and button.focus_mode != Control.FOCUS_NONE
	):
		button.grab_focus()


func blocks_world_pointer(viewport_position: Vector2) -> bool:
	if not visible:
		return false
	var panel := get_node_or_null("Panel") as Control
	return panel != null and panel.is_visible_in_tree() and panel.get_global_rect().has_point(viewport_position)


func _set_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
