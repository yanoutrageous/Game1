extends RefCounted
class_name MainMenuLayoutContract

## Pure semantic layout contract for the main-menu scene. Runtime nodes may
## consume this data, but the contract itself never reads or mutates scene
## state. All authored values live on the 1280x720 logical canvas.

const LOGICAL_SIZE := Vector2(1280, 720)
const SUPPORTED_VIEWPORTS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
const ENTRY_IDS := [&"deploy", &"long_term", &"settings", &"exit_game"]
const CHARACTER_SIZE := Vector2(190, 216)
const FOCUSED_OFFSET := Vector2(-4, 0)

const CHARACTER_ANCHORS := {
	&"character_home": Vector2(286, 408),
	&"character_cave": Vector2(230, 408),
	&"character_company": Vector2(706, 408),
}

const ENTRY_ANCHORS := {
	&"deploy": Vector2(790, 181),
	&"long_term": Vector2(865, 329),
	&"settings": Vector2(887, 434),
	&"exit_game": Vector2(897, 528),
}

# Every component is local to its entry anchor. A state offset is applied once
# to the anchor, so board, rendered text, hit target and focus response cannot
# drift apart when focus changes.
const ENTRY_COMPONENT_LOCAL_RECTS := {
	&"deploy": {
		&"board": Rect2(0, 0, 370, 146),
		&"text": Rect2(60, 34, 256, 70),
		&"hit": Rect2(-14, -13, 395, 171),
		&"focus": Rect2(-6, -6, 382, 158),
	},
	&"long_term": {
		&"board": Rect2(0, 0, 249, 96),
		&"text": Rect2(34, 20, 181, 56),
		&"hit": Rect2(-13, -11, 274, 119),
		&"focus": Rect2(-4, -4, 257, 104),
	},
	&"settings": {
		&"board": Rect2(0, 0, 221, 84),
		&"text": Rect2(28, 14, 165, 54),
		&"hit": Rect2(-12, -10, 245, 105),
		&"focus": Rect2(-4, -4, 229, 92),
	},
	&"exit_game": {
		&"board": Rect2(0, 0, 211, 75),
		&"text": Rect2(22, 11, 167, 52),
		&"hit": Rect2(-13, -10, 236, 96),
		&"focus": Rect2(-4, -4, 219, 83),
	},
}

const NOTICE_ANCHOR := Vector2(54, 348)
const NOTICE_COMPONENT_LOCAL_RECTS := {
	&"panel": Rect2(0, 0, 220, 250),
	&"heading": Rect2(18, 30, 146, 34),
	&"title": Rect2(30, 80, 136, 30),
	&"description": Rect2(30, 115, 136, 100),
}

const ENTRY_TEXT_RULES := {
	&"deploy": {"preferred_font_size": 38, "min_font_size": 18, "max_lines": 2, "line_height_ratio": 1.12},
	&"long_term": {"preferred_font_size": 30, "min_font_size": 18, "max_lines": 2, "line_height_ratio": 1.12},
	&"settings": {"preferred_font_size": 28, "min_font_size": 18, "max_lines": 2, "line_height_ratio": 1.12},
	&"exit_game": {"preferred_font_size": 27, "min_font_size": 18, "max_lines": 2, "line_height_ratio": 1.12},
}

const NOTICE_TITLE_RULE := {
	"preferred_font_size": 20,
	"min_font_size": 15,
	"max_lines": 1,
	"line_height_ratio": 1.15,
}
const NOTICE_DESCRIPTION_RULE := {
	"preferred_font_size": 14,
	"min_font_size": 12,
	"max_lines": 7,
	"line_height_ratio": 1.15,
}


static func scale(viewport_size: Vector2i) -> float:
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return 1.0
	return minf(float(viewport_size.x) / LOGICAL_SIZE.x, float(viewport_size.y) / LOGICAL_SIZE.y)


static func content_origin(viewport_size: Vector2i) -> Vector2:
	var uniform_scale := scale(viewport_size)
	return ((Vector2(viewport_size) - LOGICAL_SIZE * uniform_scale) * 0.5).round()


static func logical_anchor(anchor_id: StringName, active_focus: StringName = &"") -> Vector2:
	if CHARACTER_ANCHORS.has(anchor_id):
		return CHARACTER_ANCHORS[anchor_id] as Vector2
	if not ENTRY_ANCHORS.has(anchor_id):
		return Vector2.ZERO
	var value := ENTRY_ANCHORS[anchor_id] as Vector2
	if active_focus == anchor_id:
		value += FOCUSED_OFFSET
	return value


static func anchor(anchor_id: StringName, viewport_size: Vector2i = Vector2i(1280, 720), active_focus: StringName = &"") -> Vector2:
	return (content_origin(viewport_size) + logical_anchor(anchor_id, active_focus) * scale(viewport_size)).round()


static func character_anchor_for_focus(active_focus: StringName) -> StringName:
	match active_focus:
		&"deploy":
			return &"character_cave"
		&"long_term":
			return &"character_company"
		_:
			return &"character_home"


static func logical_rect(element_id: StringName, active_focus: StringName = &"") -> Rect2:
	var element := String(element_id)
	if element.begins_with("character."):
		var character_anchor_id := StringName("character_" + element.trim_prefix("character."))
		if CHARACTER_ANCHORS.has(character_anchor_id):
			return Rect2(logical_anchor(character_anchor_id), CHARACTER_SIZE)
		return Rect2()
	if element.begins_with("entry."):
		var parts := element.split(".")
		if parts.size() != 3:
			return Rect2()
		var entry_id := StringName(parts[1])
		var component_id := StringName(parts[2])
		if not ENTRY_COMPONENT_LOCAL_RECTS.has(entry_id):
			return Rect2()
		var component_rects := ENTRY_COMPONENT_LOCAL_RECTS[entry_id] as Dictionary
		if not component_rects.has(component_id):
			return Rect2()
		var local_rect := component_rects[component_id] as Rect2
		return Rect2(logical_anchor(entry_id, active_focus) + local_rect.position, local_rect.size)
	if element.begins_with("notice."):
		var component_id := StringName(element.trim_prefix("notice."))
		if NOTICE_COMPONENT_LOCAL_RECTS.has(component_id):
			var local_rect := NOTICE_COMPONENT_LOCAL_RECTS[component_id] as Rect2
			return Rect2(NOTICE_ANCHOR + local_rect.position, local_rect.size)
	return Rect2()


static func rect(element_id: StringName, viewport_size: Vector2i = Vector2i(1280, 720), active_focus: StringName = &"") -> Rect2:
	var source := logical_rect(element_id, active_focus)
	if source.size == Vector2.ZERO:
		return Rect2()
	var uniform_scale := scale(viewport_size)
	var origin := content_origin(viewport_size)
	var snapped_position := (origin + source.position * uniform_scale).round()
	var snapped_end := (origin + source.end * uniform_scale).round()
	return Rect2(snapped_position, snapped_end - snapped_position)


static func entry_text_profile(entry_id: StringName) -> Dictionary:
	if not ENTRY_TEXT_RULES.has(entry_id):
		return {}
	return (ENTRY_TEXT_RULES[entry_id] as Dictionary).duplicate(true)


static func text_fit(text: String, logical_bounds: Rect2, rule: Dictionary) -> Dictionary:
	var preferred_font_size := maxi(1, int(rule.get("preferred_font_size", 18)))
	var min_font_size := clampi(int(rule.get("min_font_size", preferred_font_size)), 1, preferred_font_size)
	var max_lines := maxi(1, int(rule.get("max_lines", 1)))
	var line_height_ratio := maxf(1.0, float(rule.get("line_height_ratio", 1.12)))
	var padding_value: Variant = rule.get("padding", Vector2.ZERO)
	var padding := padding_value as Vector2 if padding_value is Vector2 else Vector2.ZERO
	var available_width := maxf(0.0, logical_bounds.size.x - padding.x * 2.0)
	var available_height := maxf(0.0, logical_bounds.size.y - padding.y * 2.0)
	for font_size in range(preferred_font_size, min_font_size - 1, -1):
		var lines := _wrap_text(text, available_width, font_size)
		var metrics := _line_metrics(lines, font_size, line_height_ratio)
		if lines.size() <= max_lines and float(metrics.get("width", INF)) <= available_width + 0.01 and float(metrics.get("height", INF)) <= available_height + 0.01:
			return {
				"fits": true,
				"truncated": false,
				"font_size": font_size,
				"min_font_size": min_font_size,
				"max_lines": max_lines,
				"line_height": float(font_size) * line_height_ratio,
				"lines": lines,
				"display_text": "\n".join(lines),
				"measured_width": metrics.get("width", 0.0),
				"measured_height": metrics.get("height", 0.0),
				"available_width": available_width,
				"available_height": available_height,
			}
	var fallback_lines := _wrap_text(text, available_width, min_font_size)
	var fallback_metrics := _line_metrics(fallback_lines, min_font_size, line_height_ratio)
	return {
		"fits": false,
		"truncated": true,
		"font_size": min_font_size,
		"min_font_size": min_font_size,
		"max_lines": max_lines,
		"line_height": float(min_font_size) * line_height_ratio,
		"lines": fallback_lines,
		"display_text": "\n".join(fallback_lines),
		"measured_width": fallback_metrics.get("width", 0.0),
		"measured_height": fallback_metrics.get("height", 0.0),
		"available_width": available_width,
		"available_height": available_height,
	}


static func fit_entry_text(entry_id: StringName, text: String) -> Dictionary:
	return text_fit(text, logical_rect(StringName("entry.%s.text" % String(entry_id))), entry_text_profile(entry_id))


static func fit_notice(title: String, description: String) -> Dictionary:
	return {
		"title": text_fit(title, logical_rect(&"notice.title"), NOTICE_TITLE_RULE),
		"description": text_fit(description, logical_rect(&"notice.description"), NOTICE_DESCRIPTION_RULE),
	}


static func profile(viewport_size: Vector2i, active_focus: StringName = &"") -> Dictionary:
	var entry_profiles: Dictionary = {}
	for entry_id in ENTRY_IDS:
		entry_profiles[entry_id] = {
			"anchor": anchor(entry_id, viewport_size, active_focus),
			"board_rect": rect(StringName("entry.%s.board" % String(entry_id)), viewport_size, active_focus),
			"text_rect": rect(StringName("entry.%s.text" % String(entry_id)), viewport_size, active_focus),
			"hit_rect": rect(StringName("entry.%s.hit" % String(entry_id)), viewport_size, active_focus),
			"focus_rect": rect(StringName("entry.%s.focus" % String(entry_id)), viewport_size, active_focus),
			"text_rule": entry_text_profile(entry_id),
		}
	var character_rects: Dictionary = {}
	for character_id in CHARACTER_ANCHORS:
		var suffix := String(character_id).trim_prefix("character_")
		character_rects[character_id] = rect(StringName("character." + suffix), viewport_size)
	return {
		"logical_size": LOGICAL_SIZE,
		"viewport_size": viewport_size,
		"scale": scale(viewport_size),
		"content_origin": content_origin(viewport_size),
		"is_supported_16_9": SUPPORTED_VIEWPORTS.has(viewport_size),
		"focus_entry": active_focus,
		"entries": entry_profiles,
		"character_rects": character_rects,
		"active_character_anchor": character_anchor_for_focus(active_focus),
		"notice": {
			"panel_rect": rect(&"notice.panel", viewport_size),
			"heading_rect": rect(&"notice.heading", viewport_size),
			"title_rect": rect(&"notice.title", viewport_size),
			"description_rect": rect(&"notice.description", viewport_size),
			"single_item": true,
			"title_rule": NOTICE_TITLE_RULE.duplicate(true),
			"description_rule": NOTICE_DESCRIPTION_RULE.duplicate(true),
		},
	}


static func _wrap_text(text: String, max_width: float, font_size: int) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	var current_width := 0.0
	for index in range(text.length()):
		var character := text.substr(index, 1)
		if character == "\r":
			continue
		if character == "\n":
			lines.append(current.strip_edges(false, true))
			current = ""
			current_width = 0.0
			continue
		var advance := _glyph_advance(text.unicode_at(index)) * float(font_size)
		if not current.is_empty() and current_width + advance > max_width + 0.01:
			var break_index := current.rfind(" ")
			if break_index >= 0:
				var completed := current.substr(0, break_index).strip_edges(false, true)
				if not completed.is_empty():
					lines.append(completed)
				current = current.substr(break_index + 1).strip_edges(true, false)
				current_width = _measure_line(current, font_size)
				if not character.strip_edges().is_empty():
					current += character
					current_width += advance
				continue
			lines.append(current.strip_edges(false, true))
			current = ""
			current_width = 0.0
		if current.is_empty() and character == " ":
			continue
		current += character
		current_width += advance
	if not current.is_empty() or lines.is_empty():
		lines.append(current.strip_edges(false, true))
	return lines


static func _line_metrics(lines: Array[String], font_size: int, line_height_ratio: float) -> Dictionary:
	var width := 0.0
	for line in lines:
		width = maxf(width, _measure_line(line, font_size))
	return {
		"width": width,
		"height": float(lines.size()) * float(font_size) * line_height_ratio,
	}


static func _measure_line(text: String, font_size: int) -> float:
	var width := 0.0
	for index in range(text.length()):
		width += _glyph_advance(text.unicode_at(index)) * float(font_size)
	return width


static func _glyph_advance(codepoint: int) -> float:
	if codepoint == 0x20 or codepoint == 0x09:
		return 0.33
	if (codepoint >= 0x2E80 and codepoint <= 0x9FFF) or (codepoint >= 0xAC00 and codepoint <= 0xD7AF) or (codepoint >= 0xF900 and codepoint <= 0xFAFF):
		return 1.0
	if codepoint >= 0x41 and codepoint <= 0x5A:
		return 0.64
	if codepoint >= 0x61 and codepoint <= 0x7A:
		return 0.56
	if codepoint >= 0x30 and codepoint <= 0x39:
		return 0.56
	if codepoint < 0x80:
		return 0.38
	return 0.62
