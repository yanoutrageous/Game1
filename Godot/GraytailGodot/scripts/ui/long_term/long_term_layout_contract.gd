extends RefCounted
class_name LongTermLayoutContract

const LOGICAL_SIZE := Vector2(1280, 720)

const NAV_MAIN := Rect2(12, 28, 142, 50)
const NAV_CHAIN := Rect2(73, 77, 20, 70)
const NAV_DEPLOY := Rect2(12, 146, 142, 50)

const MODULE_RAIL := Rect2(170, 94, 820, 20)
const MODULE_BUTTON_ORIGIN := Vector2(184, 10)
const MODULE_BUTTON_SIZE := Vector2(126, 90)
const MODULE_BUTTON_GAP := 8.0

const MODULE_GROUP := Rect2(170, 112, 820, 580)
const FURNITURE_DEFAULT := Rect2(170, 144, 820, 536)
const SECONDARY_SCROLL := Rect2(194, 118, 772, 42)
const SECONDARY_ROW_MIN := Vector2(112, 36)
const CONTENT_PANEL := Rect2(194, 170, 772, 496)
const CONTENT_TITLE := Rect2(250, 186, 440, 32)
const CONTENT_META := Rect2(700, 188, 190, 26)
const CONTENT_SUMMARY := Rect2(250, 230, 640, 46)
const CONTENT_LIST_HEADER := Rect2(224, 278, 324, 28)
const CONTENT_DETAIL_HEADER := Rect2(566, 278, 366, 28)
const CONTENT_CARDS := Rect2(224, 310, 324, 324)
const CONTENT_RECORD_TITLE := Rect2(566, 310, 250, 34)
const CONTENT_RECORD_STATE := Rect2(818, 312, 114, 28)
const CONTENT_RECORD_BODY := Rect2(566, 348, 366, 92)
const CONTENT_RECORD_FACTS := Rect2(566, 446, 366, 140)
const CONTENT_ACTION := Rect2(732, 590, 200, 38)
# Compatibility constants for older callers. I2.4B replaces three-card paging
# with a single scrollable record list, so the corresponding controls stay hidden.
const CONTENT_PREVIOUS := Rect2(224, 590, 76, 28)
const CONTENT_NEXT := Rect2(306, 590, 76, 28)
const COLLAPSED_OFFSET := Vector2(0, 610)

const LEVER := Rect2(4, 612, 152, 100)
const LEVER_LABEL := Rect2(68, 672, 76, 22)

const PROFILE_FRAME := Rect2(1012, 8, 258, 704)
const PROFILE_HEADER := Rect2(1034, 26, 214, 40)
const PROFILE_CHARACTER := Rect2(1044, 82, 190, 216)
const PROFILE_ROLE := Rect2(1036, 324, 210, 24)
const PROFILE_LEVEL := Rect2(1036, 350, 210, 38)
const PROFILE_EXP_LABEL := Rect2(1038, 394, 76, 28)
const PROFILE_EXP_VALUE := Rect2(1110, 394, 132, 28)
const PROFILE_STAT_ORIGIN := Vector2(1038, 438)
const PROFILE_STAT_SIZE := Vector2(206, 34)
const PROFILE_STAT_GAP := 9.0
const PROFILE_APPEARANCE := Rect2(1036, 646, 210, 48)


static func fit_text(
	text: String,
	font: Font,
	bounds: Vector2,
	base_font_size: int,
	ui_scale_factor: float,
	multiline: bool,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	padding: Vector2 = Vector2(4, 2),
	max_font_size: int = -1
) -> Dictionary:
	var normalized_scale := clampf(ui_scale_factor, 1.0, 1.5)
	var minimum_size := maxi(1, base_font_size)
	var requested_size := maxi(minimum_size, int(round(float(minimum_size) * normalized_scale)))
	if max_font_size > 0:
		requested_size = mini(requested_size, maxi(minimum_size, max_font_size))
	var available := Vector2(
		maxf(1.0, bounds.x - padding.x * 2.0),
		maxf(1.0, bounds.y - padding.y * 2.0)
	)
	for candidate in range(requested_size, minimum_size - 1, -1):
		var measured := _measure_text(text, font, available.x, candidate, multiline, alignment)
		if measured.x <= available.x + 0.01 and measured.y <= available.y + 0.01:
			return {
				"fits": true,
				"font_size": candidate,
				"base_font_size": minimum_size,
				"requested_font_size": requested_size,
				"ui_scale_factor": normalized_scale,
				"measured_size": measured,
				"available_size": available,
			}
	var fallback_measured := _measure_text(text, font, available.x, minimum_size, multiline, alignment)
	return {
		"fits": fallback_measured.x <= available.x + 0.01 and fallback_measured.y <= available.y + 0.01,
		"font_size": minimum_size,
		"base_font_size": minimum_size,
		"requested_font_size": requested_size,
		"ui_scale_factor": normalized_scale,
		"measured_size": fallback_measured,
		"available_size": available,
	}


static func _measure_text(
	text: String,
	font: Font,
	available_width: float,
	font_size: int,
	multiline: bool,
	alignment: HorizontalAlignment
) -> Vector2:
	if font == null:
		var line_count := maxi(1, text.count("\n") + 1)
		return Vector2(
			mini(available_width, float(text.length()) * float(font_size)),
			float(line_count * font_size)
		)
	if multiline or text.contains("\n"):
		return font.get_multiline_string_size(
			text,
			alignment,
			available_width,
			font_size,
			-1,
			TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
		)
	return font.get_string_size(text, alignment, -1.0, font_size)


static func furniture_rect(_module_id: StringName) -> Rect2:
	return FURNITURE_DEFAULT


static func module_button_rect(index: int) -> Rect2:
	return Rect2(
		MODULE_BUTTON_ORIGIN + Vector2(index * (MODULE_BUTTON_SIZE.x + MODULE_BUTTON_GAP), 0),
		MODULE_BUTTON_SIZE
	)
