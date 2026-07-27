extends RefCounted
class_name DeployPrepLayoutContract

const LOGICAL_SIZE := Vector2(1280, 720)

const NAV_MAIN := Rect2(38, 36, 176, 46)
const NAV_LONG_TERM := Rect2(38, 126, 176, 46)
const NAV_CHAIN_TOP := Rect2(178, 0, 24, 38)
const NAV_CHAIN_MIDDLE := Rect2(50, 80, 24, 48)

const CHARACTER_SHADOW := Rect2(26, 606, 210, 28)
const CHARACTER := Rect2(34, 392, 190, 216)
const APPEARANCE_BUTTON := Rect2(24, 646, 104, 40)
const CHARACTER_BUTTON := Rect2(136, 646, 104, 40)

const PARCHMENT := Rect2(254, 14, 688, 692)
const PRIMARY_TABS := Rect2(286, 48, 624, 44)
const SPLIT_WORKSPACE := Rect2(282, 104, 632, 554)
const SELECTION_PANE := Rect2(282, 104, 248, 554)
const FILTER_SCROLL := Rect2(286, 104, 240, 38)
const FILTER_SCROLL_WITH_NAV := Rect2(307, 104, 198, 38)
const FILTER_PREVIOUS := Rect2(282, 106, 22, 32)
const FILTER_NEXT := Rect2(508, 106, 22, 32)
const CARD_SCROLL := Rect2(286, 150, 240, 500)
const WAREHOUSE_CARD_SCROLL := Rect2(286, 194, 240, 456)
const WAREHOUSE_BATCH_ENTRY := Rect2(286, 150, 240, 36)
const WAREHOUSE_BATCH_SELECT_ALL := Rect2(286, 150, 116, 36)
const WAREHOUSE_BATCH_CLEAR := Rect2(410, 150, 116, 36)
const RESULT_HINT := Rect2(292, 606, 228, 34)
const DETAIL_PANE := Rect2(542, 104, 372, 554)
const DETAIL_HEADING := Rect2(550, 108, 178, 36)
const DETAIL_GOLD_PANEL := Rect2(738, 108, 168, 36)
const DETAIL_GOLD_ICON := Rect2(746, 114, 24, 24)
const DETAIL_GOLD_VALUE := Rect2(776, 108, 122, 36)
const DETAIL_HEADER := Rect2(550, 150, 356, 116)
const DETAIL_ART_FRAME := Rect2(562, 158, 78, 96)
const DETAIL_ART := Rect2(568, 164, 66, 84)
const DETAIL_TITLE := Rect2(650, 158, 244, 44)
const DETAIL_BADGE := Rect2(650, 204, 244, 50)
const DETAIL_BODY_PANEL := Rect2(550, 274, 356, 252)
const DETAIL_DESCRIPTION := Rect2(562, 286, 332, 66)
const DETAIL_FACT_RECTS := [
	Rect2(562, 356, 332, 34),
	Rect2(562, 394, 332, 34),
	Rect2(562, 432, 332, 34),
	Rect2(562, 470, 332, 50),
]
const DETAIL_FEEDBACK := Rect2(550, 530, 356, 28)
const DETAIL_PRIMARY_ACTION := Rect2(550, 566, 222, 40)
const DETAIL_SECONDARY_ACTION := Rect2(780, 566, 126, 40)
const COLLAPSE_HANDLE := Rect2(520, 670, 156, 32)
const COLLAPSED_OFFSET := Vector2(0, -706)

# The map tab keeps scale, difficulty and detail inside the existing center
# parchment. These rects deliberately do not introduce another route or page.
const MAP_SPLIT_VIEW := Rect2(282, 104, 632, 554)
const MAP_SCALE_COLUMN := Rect2(282, 104, 198, 554)
const MAP_SCALE_TITLE := Rect2(298, 118, 166, 28)
const MAP_SCALE_CAPTION := Rect2(298, 148, 166, 34)
const MAP_SCALE_BUTTON_RECTS := [
	Rect2(298, 190, 166, 70),
	Rect2(298, 268, 166, 70),
	Rect2(298, 346, 166, 70),
	Rect2(298, 424, 166, 70),
]
const MAP_SCALE_STATUS := Rect2(298, 504, 166, 134)

const MAP_DETAIL_COLUMN := Rect2(490, 104, 424, 554)
const MAP_DETAIL_TITLE := Rect2(508, 118, 216, 30)
const MAP_DIFFICULTY_ROW := Rect2(508, 158, 388, 44)
const MAP_DETAIL_ART_FRAME := Rect2(508, 218, 168, 138)
const MAP_DETAIL_ART := Rect2(516, 226, 152, 122)
const MAP_DETAIL_NAME := Rect2(692, 218, 204, 34)
const MAP_DETAIL_ROLE := Rect2(692, 254, 204, 48)
const MAP_DETAIL_STATE := Rect2(692, 310, 204, 34)
const MAP_DETAIL_METRICS := Rect2(508, 372, 388, 150)
const MAP_DETAIL_DESCRIPTION := Rect2(508, 532, 244, 106)
const MAP_DETAIL_ACTION := Rect2(764, 548, 132, 74)
const MAP_EMPTY_STATE := Rect2(508, 218, 388, 404)

const MAP_DIFFICULTY_GAP := 8.0

const SUMMARY_CHAIN_LEFT := Rect2(1014, 0, 24, 58)
const SUMMARY_CHAIN_RIGHT := Rect2(1182, 0, 24, 58)
const SUMMARY_BOARD := Rect2(984, 54, 252, 494)
const SUMMARY_TABS := Rect2(1002, 100, 216, 34)
const SUMMARY_BODY := Rect2(1006, 150, 208, 336)
const SUMMARY_ROW_RECTS := [
	Rect2(998, 146, 224, 72),
	Rect2(998, 226, 224, 72),
	Rect2(998, 306, 224, 72),
	Rect2(998, 386, 224, 72),
]
const SUMMARY_MESSAGE_PANEL := Rect2(998, 470, 224, 54)
const SUMMARY_MESSAGE := Rect2(1008, 480, 204, 34)

const PRIMARY_ACTION := Rect2(984, 572, 252, 82)
const CANCEL_ACTION := Rect2(998, 662, 224, 44)

const MODAL_BOARD := Rect2(380, 220, 520, 268)
const MODAL_TITLE := Rect2(456, 258, 368, 42)
const MODAL_BODY := Rect2(456, 314, 368, 74)
const MODAL_CONFIRM := Rect2(462, 410, 156, 48)
const MODAL_CANCEL := Rect2(662, 410, 156, 48)

const TAB_WIDTH := 120.0
const TAB_GAP := 6
const FILTER_WIDTH := 104.0
const FILTER_GAP := 6
const CARD_HEIGHT := 76.0
const CARD_GAP := 8


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


static func map_difficulty_button_rect(index: int, option_count: int) -> Rect2:
	var count := maxi(1, option_count)
	var gap_width := MAP_DIFFICULTY_GAP * float(count - 1)
	var button_width := floorf((MAP_DIFFICULTY_ROW.size.x - gap_width) / float(count))
	var x := MAP_DIFFICULTY_ROW.position.x + float(index) * (button_width + MAP_DIFFICULTY_GAP)
	var width := MAP_DIFFICULTY_ROW.end.x - x if index == count - 1 else button_width
	return Rect2(Vector2(x, MAP_DIFFICULTY_ROW.position.y), Vector2(width, MAP_DIFFICULTY_ROW.size.y))


static func rect(key: StringName) -> Rect2:
	match key:
		&"nav_main": return NAV_MAIN
		&"nav_long_term": return NAV_LONG_TERM
		&"character": return CHARACTER
		&"appearance_button": return APPEARANCE_BUTTON
		&"character_button": return CHARACTER_BUTTON
		&"parchment": return PARCHMENT
		&"primary_tabs": return PRIMARY_TABS
		&"split_workspace": return SPLIT_WORKSPACE
		&"selection_pane": return SELECTION_PANE
		&"filter_scroll": return FILTER_SCROLL
		&"card_scroll": return CARD_SCROLL
		&"warehouse_card_scroll": return WAREHOUSE_CARD_SCROLL
		&"warehouse_batch_entry": return WAREHOUSE_BATCH_ENTRY
		&"detail_pane": return DETAIL_PANE
		&"detail_gold_panel": return DETAIL_GOLD_PANEL
		&"detail_header": return DETAIL_HEADER
		&"detail_body_panel": return DETAIL_BODY_PANEL
		&"map_split_view": return MAP_SPLIT_VIEW
		&"map_scale_column": return MAP_SCALE_COLUMN
		&"map_detail_column": return MAP_DETAIL_COLUMN
		&"map_difficulty_row": return MAP_DIFFICULTY_ROW
		&"map_detail_metrics": return MAP_DETAIL_METRICS
		&"map_empty_state": return MAP_EMPTY_STATE
		&"collapse_handle": return COLLAPSE_HANDLE
		&"summary_board": return SUMMARY_BOARD
		&"summary_tabs": return SUMMARY_TABS
		&"summary_body": return SUMMARY_BODY
		&"primary_action": return PRIMARY_ACTION
		&"cancel_action": return CANCEL_ACTION
		&"modal_board": return MODAL_BOARD
		_: return Rect2()
