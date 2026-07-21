extends SceneTree

const LayoutContractScript := preload("res://scripts/ui/main_menu/main_menu_layout_contract.gd")

const VIEWPORTS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
const EXPECTED_SCALES := [1.0, 1.25, 1.5]
const ENTRY_IDS := [&"deploy", &"long_term", &"settings", &"exit_game"]
const COMPONENT_IDS := [&"board", &"text", &"hit", &"focus"]
const TEXT_CASES := [
	{
		"id": &"current_zh",
		"entries": {
			&"deploy": "出发探索",
			&"long_term": "长期系统",
			&"settings": "设置",
			&"exit_game": "退出游戏",
		},
		"notice_title": "基地公告",
		"notice_description": "今日回收区域已开放，整备完成后即可出发。",
	},
	{
		"id": &"cjk_8",
		"entries": {
			&"deploy": "出发探索整备行动",
			&"long_term": "长期成长档案系统",
			&"settings": "画面声音辅助设置",
			&"exit_game": "安全返回桌面确认",
		},
		"notice_title": "基地运营重要公告",
		"notice_description": "今日探索委托与回收档案已经更新，完成出勤整备后即可查看本次行动目标和可带回物资。",
	},
	{
		"id": &"latin_16",
		"entries": {
			&"deploy": "ExploreAdventure",
			&"long_term": "LongTermProgress",
			&"settings": "GraphicsSettings",
			&"exit_game": "ReturnToDesktopX",
		},
		"notice_title": "Station Bulletin",
		"notice_description": "Recovery assignments were updated today. Review the objective and carried supplies before leaving the station.",
	},
]

var failures: Array[String] = []
var case_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_text_fixtures()
	for viewport_index in range(VIEWPORTS.size()):
		var viewport: Vector2i = VIEWPORTS[viewport_index]
		var expected_scale: float = EXPECTED_SCALES[viewport_index]
		for text_case in TEXT_CASES:
			for focus_entry in ENTRY_IDS:
				case_count += 1
				_check_case(viewport, expected_scale, text_case as Dictionary, focus_entry)
	if case_count != 36:
		failures.append("case_count=%d_expected=36" % case_count)
	_finish()


func _check_text_fixtures() -> void:
	var cjk_entries := (TEXT_CASES[1] as Dictionary).get("entries", {}) as Dictionary
	var latin_entries := (TEXT_CASES[2] as Dictionary).get("entries", {}) as Dictionary
	for entry_id in ENTRY_IDS:
		var cjk_text := String(cjk_entries.get(entry_id, ""))
		var latin_text := String(latin_entries.get(entry_id, ""))
		_check(cjk_text.length() == 8, "fixture=%s_cjk_length=%d_expected=8" % [entry_id, cjk_text.length()])
		_check(latin_text.length() == 16 and latin_text.is_valid_identifier(), "fixture=%s_latin_length=%d_expected=16" % [entry_id, latin_text.length()])


func _check_case(viewport: Vector2i, expected_scale: float, text_case: Dictionary, focus_entry: StringName) -> void:
	var case_id := "%s/%s/%s" % [viewport, text_case.get("id", &""), focus_entry]
	var layout: Dictionary = LayoutContractScript.profile(viewport, focus_entry)
	_check(bool(layout.get("is_supported_16_9", false)), "%s unsupported_16_9" % case_id)
	_check(_near(float(layout.get("scale", 0.0)), expected_scale), "%s scale=%s_expected=%s" % [case_id, layout.get("scale", 0.0), expected_scale])
	_check((layout.get("content_origin", Vector2.ONE) as Vector2).distance_to(Vector2.ZERO) <= 1.0, "%s content_origin=%s" % [case_id, layout.get("content_origin", Vector2.ONE)])
	_check(StringName(layout.get("active_character_anchor", &"")) == _expected_character_anchor(focus_entry), "%s character_focus_anchor=%s" % [case_id, layout.get("active_character_anchor", &"")])
	_check_character_anchors(viewport, layout, case_id)
	var entry_profiles := layout.get("entries", {}) as Dictionary
	var labels := text_case.get("entries", {}) as Dictionary
	for entry_id in ENTRY_IDS:
		var entry_profile := entry_profiles.get(entry_id, {}) as Dictionary
		var shared_anchor := LayoutContractScript.anchor(entry_id, viewport, focus_entry)
		_check((entry_profile.get("anchor", Vector2.ONE) as Vector2).distance_to(shared_anchor) <= 1.0, "%s/%s profile_anchor_drift" % [case_id, entry_id])
		_check_entry_components(viewport, focus_entry, entry_id, shared_anchor, entry_profile, case_id)
		var fit: Dictionary = LayoutContractScript.fit_entry_text(entry_id, String(labels.get(entry_id, "")))
		_check(bool(fit.get("fits", false)) and not bool(fit.get("truncated", true)), "%s/%s entry_text_truncated" % [case_id, entry_id])
		_check(int(fit.get("font_size", 0)) >= 18, "%s/%s entry_font=%s_below_18" % [case_id, entry_id, fit.get("font_size", 0)])
		_check((fit.get("lines", []) as Array).size() <= 2, "%s/%s entry_lines=%d_above_2" % [case_id, entry_id, (fit.get("lines", []) as Array).size()])
		_check(float(fit.get("measured_width", INF)) <= float(fit.get("available_width", 0.0)) + 0.01, "%s/%s entry_width_clipped" % [case_id, entry_id])
		_check(float(fit.get("measured_height", INF)) <= float(fit.get("available_height", 0.0)) + 0.01, "%s/%s entry_height_clipped" % [case_id, entry_id])
	_check_notice(viewport, text_case, layout, case_id)


func _check_character_anchors(viewport: Vector2i, layout: Dictionary, case_id: String) -> void:
	var character_rects := layout.get("character_rects", {}) as Dictionary
	for character_id in [&"character_home", &"character_cave", &"character_company"]:
		var rect_value := character_rects.get(character_id, Rect2()) as Rect2
		var expected_anchor := LayoutContractScript.anchor(character_id, viewport)
		_check(rect_value.position.distance_to(expected_anchor) <= 1.0, "%s/%s rect_anchor_drift=%s" % [case_id, character_id, rect_value.position - expected_anchor])


func _check_entry_components(viewport: Vector2i, focus_entry: StringName, entry_id: StringName, shared_anchor: Vector2, entry_profile: Dictionary, case_id: String) -> void:
	var base_rects: Dictionary = {}
	var focused_rects: Dictionary = {}
	for component_id in COMPONENT_IDS:
		var element_id := StringName("entry.%s.%s" % [String(entry_id), String(component_id)])
		var actual_rect := LayoutContractScript.rect(element_id, viewport, focus_entry)
		var profile_key := StringName(String(component_id) + "_rect")
		var profile_rect := entry_profile.get(profile_key, Rect2()) as Rect2
		_check(_rect_near(actual_rect, profile_rect), "%s/%s/%s profile_rect_drift" % [case_id, entry_id, component_id])
		var local_rect := ((LayoutContractScript.ENTRY_COMPONENT_LOCAL_RECTS[entry_id] as Dictionary)[component_id]) as Rect2
		var expected_local_offset := (local_rect.position * LayoutContractScript.scale(viewport)).round()
		_check((actual_rect.position - shared_anchor).distance_to(expected_local_offset) <= 1.0, "%s/%s/%s shared_anchor_offset=%s_expected=%s" % [case_id, entry_id, component_id, actual_rect.position - shared_anchor, expected_local_offset])
		base_rects[component_id] = LayoutContractScript.rect(element_id, viewport, &"")
		focused_rects[component_id] = actual_rect
	var expected_shift := (LayoutContractScript.FOCUSED_OFFSET * LayoutContractScript.scale(viewport)).round() if focus_entry == entry_id else Vector2.ZERO
	var observed_shift: Variant = null
	for component_id in COMPONENT_IDS:
		var shift := (focused_rects[component_id] as Rect2).position - (base_rects[component_id] as Rect2).position
		_check(shift.distance_to(expected_shift) <= 1.0, "%s/%s/%s focus_shift=%s_expected=%s" % [case_id, entry_id, component_id, shift, expected_shift])
		if observed_shift == null:
			observed_shift = shift
		else:
			_check(shift.distance_to(observed_shift as Vector2) <= 1.0, "%s/%s/%s focus_shared_offset_drift" % [case_id, entry_id, component_id])


func _check_notice(viewport: Vector2i, text_case: Dictionary, layout: Dictionary, case_id: String) -> void:
	var notice_profile := layout.get("notice", {}) as Dictionary
	_check(bool(notice_profile.get("single_item", false)), "%s notice_not_single_item" % case_id)
	var fit: Dictionary = LayoutContractScript.fit_notice(String(text_case.get("notice_title", "")), String(text_case.get("notice_description", "")))
	var title_fit := fit.get("title", {}) as Dictionary
	var description_fit := fit.get("description", {}) as Dictionary
	_check(bool(title_fit.get("fits", false)) and not bool(title_fit.get("truncated", true)), "%s notice_title_truncated" % case_id)
	_check((title_fit.get("lines", []) as Array).size() == 1, "%s notice_title_lines=%d_expected=1" % [case_id, (title_fit.get("lines", []) as Array).size()])
	_check(bool(description_fit.get("fits", false)) and not bool(description_fit.get("truncated", true)), "%s notice_description_truncated" % case_id)
	_check((description_fit.get("lines", []) as Array).size() >= 1 and (description_fit.get("lines", []) as Array).size() <= 7, "%s notice_description_lines=%d" % [case_id, (description_fit.get("lines", []) as Array).size()])
	_check(float(description_fit.get("measured_width", INF)) <= float(description_fit.get("available_width", 0.0)) + 0.01, "%s notice_description_width_clipped" % case_id)
	_check(float(description_fit.get("measured_height", INF)) <= float(description_fit.get("available_height", 0.0)) + 0.01, "%s notice_description_height_clipped" % case_id)
	for component_id in [&"panel", &"heading", &"title", &"description"]:
		var expected := LayoutContractScript.rect(StringName("notice." + String(component_id)), viewport)
		var actual := notice_profile.get(StringName(String(component_id) + "_rect"), Rect2()) as Rect2
		_check(_rect_near(actual, expected), "%s notice_%s_profile_rect_drift" % [case_id, component_id])


func _expected_character_anchor(focus_entry: StringName) -> StringName:
	if focus_entry == &"deploy":
		return &"character_cave"
	if focus_entry == &"long_term":
		return &"character_company"
	return &"character_home"


func _rect_near(left: Rect2, right: Rect2) -> bool:
	return left.position.distance_to(right.position) <= 1.0 and left.size.distance_to(right.size) <= 1.0


func _near(left: float, right: float) -> bool:
	return absf(left - right) <= 0.001


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I2_MAIN_MENU_ANCHOR_TEXT=PASS contract_cases=36 resolutions=3 text_profiles=3 focus_states=4 entry_lines_max=2 entry_font_min=18")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("I2_MAIN_MENU_ANCHOR_TEXT=FAIL failures=%d cases=%d" % [failures.size(), case_count])
	quit(2)
