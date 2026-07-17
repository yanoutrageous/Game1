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
const FILTER_SCROLL := Rect2(286, 104, 624, 38)
const FILTER_PREVIOUS := Rect2(260, 106, 22, 32)
const FILTER_NEXT := Rect2(914, 106, 22, 32)
const CARD_SCROLL := Rect2(282, 158, 632, 500)
const RESULT_HINT := Rect2(420, 610, 356, 34)
const COLLAPSE_HANDLE := Rect2(520, 666, 156, 40)
const COLLAPSED_OFFSET := Vector2(0, -706)

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
const CARD_HEIGHT := 112.0
const CARD_GAP := 8


static func rect(key: StringName) -> Rect2:
	match key:
		&"nav_main": return NAV_MAIN
		&"nav_long_term": return NAV_LONG_TERM
		&"character": return CHARACTER
		&"appearance_button": return APPEARANCE_BUTTON
		&"character_button": return CHARACTER_BUTTON
		&"parchment": return PARCHMENT
		&"primary_tabs": return PRIMARY_TABS
		&"filter_scroll": return FILTER_SCROLL
		&"card_scroll": return CARD_SCROLL
		&"collapse_handle": return COLLAPSE_HANDLE
		&"summary_board": return SUMMARY_BOARD
		&"summary_tabs": return SUMMARY_TABS
		&"summary_body": return SUMMARY_BODY
		&"primary_action": return PRIMARY_ACTION
		&"cancel_action": return CANCEL_ACTION
		&"modal_board": return MODAL_BOARD
		_: return Rect2()
