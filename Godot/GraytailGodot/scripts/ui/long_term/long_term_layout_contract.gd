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
const CONTENT_TITLE := Rect2(250, 194, 440, 32)
const CONTENT_META := Rect2(700, 196, 190, 26)
const CONTENT_SUMMARY := Rect2(250, 230, 640, 46)
const CONTENT_LIST_HEADER := Rect2(224, 282, 294, 28)
const CONTENT_DETAIL_HEADER := Rect2(544, 282, 388, 28)
const CONTENT_CARDS := Rect2(224, 316, 294, 304)
const CONTENT_RECORD_TITLE := Rect2(544, 316, 274, 34)
const CONTENT_RECORD_STATE := Rect2(820, 318, 112, 28)
const CONTENT_RECORD_BODY := Rect2(544, 354, 388, 84)
const CONTENT_RECORD_FACTS := Rect2(544, 446, 388, 132)
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
const PROFILE_ROLE := Rect2(1036, 312, 210, 30)
const PROFILE_LEVEL := Rect2(1036, 344, 210, 42)
const PROFILE_EXP_LABEL := Rect2(1038, 394, 76, 28)
const PROFILE_EXP_VALUE := Rect2(1110, 394, 132, 28)
const PROFILE_STAT_ORIGIN := Vector2(1038, 438)
const PROFILE_STAT_SIZE := Vector2(206, 34)
const PROFILE_STAT_GAP := 9.0
const PROFILE_APPEARANCE := Rect2(1036, 646, 210, 48)


static func furniture_rect(_module_id: StringName) -> Rect2:
	return FURNITURE_DEFAULT


static func module_button_rect(index: int) -> Rect2:
	return Rect2(
		MODULE_BUTTON_ORIGIN + Vector2(index * (MODULE_BUTTON_SIZE.x + MODULE_BUTTON_GAP), 0),
		MODULE_BUTTON_SIZE
	)
