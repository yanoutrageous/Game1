extends SceneTree

const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const DeployPrepLayoutContractScript := preload("res://scripts/ui/deploy_prep/deploy_prep_layout_contract.gd")
const DeployPrepModelScript := preload("res://scripts/ui/deploy_prep/deploy_prep_model.gd")
const DeployPrepShellScript := preload("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")

const RESOLUTIONS := [
	{"id": &"1280x720", "size": Vector2i(1280, 720)},
	{"id": &"1366x768", "size": Vector2i(1366, 768)},
	{"id": &"1600x900", "size": Vector2i(1600, 900)},
	{"id": &"1920x1080", "size": Vector2i(1920, 1080)},
]
const UI_SCALES := [1.0, 1.25, 1.5]
const LOGICAL_SIZE := Vector2i(1280, 720)
const WAIT_TIMEOUT_MS := 5000

var failures: Array[String] = []
var capture_paths: Array[String] = []
var output_directory := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_directory = _output_directory(OS.get_cmdline_user_args())
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = LOGICAL_SIZE
	root.content_scale_factor = 1.0
	root.transparent_bg = false
	for resolution in RESOLUTIONS:
		for ui_scale in UI_SCALES:
			await _check_case(resolution as Dictionary, ui_scale)
	if failures.is_empty():
		print(
			"I4_DEPLOY_INFORMATION_LAYOUT=PASS matrix=4x3 ordinary=310,12,310 map=198,424 "
			+ "summary=dynamic_scroll detail=scroll gold=contextual focus=reachable "
			+ "screenshots=%d" % capture_paths.size()
		)
		quit(0)
		return
	for failure in failures:
		printerr("I4_DEPLOY_INFORMATION_LAYOUT=FAIL:%s" % failure)
	quit(1)


func _check_case(resolution: Dictionary, ui_scale: float) -> void:
	var resolution_id := StringName(resolution.get("id", &"unknown"))
	var physical_size: Vector2i = resolution.get("size", LOGICAL_SIZE)
	var case_id := "%s-ui%d" % [String(resolution_id), int(round(ui_scale * 100.0))]
	root.size = physical_size
	Art10UISkinKitScript.set_runtime_ui_scale_factor(ui_scale)
	var canvas := Control.new()
	canvas.name = "I4DeployMatrix_%s" % case_id
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	var shell := DeployPrepShellScript.new() as Control
	shell.name = "DeployPrepShell"
	canvas.add_child(shell)
	shell.build()
	shell.set_ui_scale_factor(ui_scale)
	shell.apply_snapshot(_snapshot())
	shell.show_tab(DeployTabModelScript.TAB_WAREHOUSE)
	var ready := await _wait_until(
		func() -> bool:
			return (
				shell.is_inside_tree()
				and shell.get("card_views") is Array
				and not (shell.get("card_views") as Array).is_empty()
				and _visible_summary_count(shell) >= 6
			),
		"%s warehouse and summary ready" % case_id
	)
	if ready:
		_check_ordinary_split(shell, case_id)
		_check_warehouse_batch_geometry(shell, case_id)
		_check_card_contract(shell, case_id)
		await _check_summary_contract(shell, case_id)
		await _check_detail_scroll(shell, case_id)
		await _check_focus_path(shell, case_id)
		await _check_filter_overflow(shell, case_id)
		await _check_contextual_gold_and_map(shell, case_id)
		_check_text_safety(shell, case_id)
		# Capture only after the same visible control geometry/alpha fingerprint
		# survives three consecutive render submissions. This is a measured
		# stability condition, not a fixed-frame delay.
		await _wait_for_stable_layout(shell, "%s capture layout" % case_id)
		await _capture_case(case_id, physical_size)
	canvas.queue_free()
	await canvas.tree_exited


func _check_ordinary_split(shell: Control, case_id: String) -> void:
	var selection := shell.get_node_or_null(
		"MainContentRoot/DeployParchmentGroup/DeploySelectionPane"
	) as Control
	var detail := shell.get("detail_panel") as Control
	_expect(selection != null and detail != null, "%s ordinary panes missing" % case_id)
	if selection == null or detail == null:
		return
	_expect(_rect_matches(selection, DeployPrepLayoutContractScript.SELECTION_PANE), "%s selection pane drifted: %s" % [case_id, selection.get_rect()])
	_expect(_rect_matches(detail, DeployPrepLayoutContractScript.DETAIL_PANE), "%s detail pane drifted: %s" % [case_id, detail.get_rect()])
	_expect(is_equal_approx(selection.size.x, 310.0), "%s selection width=%s" % [case_id, selection.size.x])
	_expect(is_equal_approx(detail.size.x, 310.0), "%s detail width=%s" % [case_id, detail.size.x])
	var selection_end_x := selection.position.x + selection.size.x
	_expect(is_equal_approx(detail.position.x - selection_end_x, 12.0), "%s ordinary gap=%s" % [case_id, detail.position.x - selection_end_x])


func _check_warehouse_batch_geometry(shell: Control, case_id: String) -> void:
	var entry := shell.get("warehouse_batch_entry_button") as Button
	var scroll := shell.get("card_scroll") as ScrollContainer
	_expect(entry != null and scroll != null, "%s warehouse batch geometry missing" % case_id)
	if entry == null or scroll == null:
		return
	_expect(
		_rect_matches(entry, DeployPrepLayoutContractScript.WAREHOUSE_BATCH_ENTRY),
		"%s warehouse batch entry escaped its logical rect: %s" % [case_id, entry.get_rect()]
	)
	var visible_gap := scroll.position.y - entry.get_rect().end.y
	_expect(
		visible_gap >= 8.0,
		"%s warehouse batch entry overlaps the first card viewport: gap=%s" % [case_id, visible_gap]
	)


func _check_card_contract(shell: Control, case_id: String) -> void:
	var card := _card_by_item(shell, "con_ration")
	_expect(card != null, "%s ration quantity card missing" % case_id)
	if card == null:
		return
	var title := card.get_node_or_null("CardTitle") as Label
	var summary := card.get_node_or_null("CardSummary") as Label
	var minus := card.get_node_or_null("CardQuantityMinus") as Button
	var value := card.get_node_or_null("CardQuantityValue") as Label
	var plus := card.get_node_or_null("CardQuantityPlus") as Button
	var edge := card.get_node_or_null("CardRarityEdge") as ColorRect
	_expect(title != null and summary != null, "%s quantity card lost its two text lines" % case_id)
	_expect(card.get_node_or_null("CardCategoryChip") == null and card.get_node_or_null("CardModeChip") == null, "%s quantity card restored a third chip layer" % case_id)
	_expect(minus != null and value != null and plus != null, "%s quantity stepper incomplete" % case_id)
	_expect(edge != null and edge.visible, "%s rarity lacks its non-text edge channel" % case_id)
	if title != null:
		_expect(not _contains_t_code(title.text), "%s title exposed a T code: %s" % [case_id, title.text])
	if summary != null:
		_expect(not _contains_t_code(summary.text), "%s summary exposed a T code: %s" % [case_id, summary.text])
	if value != null:
		_expect(value.tooltip_text == "已携带 / 持有", "%s carry quantity meaning is ambiguous" % case_id)
	for label in [title, summary, value]:
		if label != null and label.has_meta("deploy_text_fit"):
			var fit := label.get_meta("deploy_text_fit", {}) as Dictionary
			_expect(bool(fit.get("fits", false)), "%s %s text escaped its safe bounds" % [case_id, label.name])


func _check_summary_contract(shell: Control, case_id: String) -> void:
	var model := shell.get("current_model") as Dictionary
	var projection := model.get("summary_projection", {}) as Dictionary
	var pages := projection.get("pages", {}) as Dictionary
	var expected_prefixes := {
		&"overview": ["地图：", "委托：", "装备：", "补给：", "容量：", "出发"],
		&"config": ["装备：", "补给：", "合计：", "容量："],
		&"effect": ["协议：", "天赋：", "物品效果："],
		&"objective": ["委托：", "条件：", "奖励：", "进度：", "适用："],
	}
	for page_id in [&"overview", &"config", &"effect", &"objective"]:
		var expected_lines := pages.get(String(page_id), []) as Array
		var button := (shell.get("summary_buttons") as Dictionary).get(page_id) as Button
		_expect(button != null, "%s summary page button missing: %s" % [case_id, page_id])
		if button == null:
			continue
		button.emit_signal("pressed")
		var changed := await _wait_until(
			func() -> bool: return StringName(shell.get("active_summary_page")) == page_id,
			"%s summary page %s" % [case_id, page_id]
		)
		if not changed:
			continue
		var visible_text := _visible_summary_text(shell)
		_expect(visible_text.size() == expected_lines.size(), "%s/%s projected=%d visible=%d" % [case_id, page_id, expected_lines.size(), visible_text.size()])
		for prefix in expected_prefixes.get(page_id, []) as Array:
			_expect(_array_has_prefix(visible_text, str(prefix)), "%s/%s missing semantic row %s" % [case_id, page_id, prefix])
		for raw_label in shell.get("summary_row_labels") as Array:
			var row_label := raw_label as Label
			if row_label == null or not row_label.visible:
				continue
			var row_panel := row_label.get_meta("deploy_summary_row_panel") as Control
			if row_panel == null or not row_panel.visible:
				continue
			var left_inset := row_label.get_global_rect().position.x - row_panel.get_global_rect().position.x
			var right_inset := row_panel.get_global_rect().end.x - row_label.get_global_rect().end.x
			_expect(
				left_inset >= 8.0 and right_inset >= 8.0,
				"%s/%s summary row safe inset left=%s right=%s" % [case_id, page_id, left_inset, right_inset]
			)
	var overview_button := (shell.get("summary_buttons") as Dictionary).get(&"overview") as Button
	if overview_button != null:
		overview_button.emit_signal("pressed")
		await _wait_until(
			func() -> bool: return StringName(shell.get("active_summary_page")) == &"overview",
			"%s restore overview" % case_id
		)
	var scroll := shell.get("summary_scroll") as ScrollContainer
	_expect(scroll != null and scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s summary is not vertically scrollable" % case_id)
	if scroll != null:
		_expect(_visible_summary_count(shell) == 6, "%s overview does not expose all six decision rows" % case_id)
	await _check_summary_scroll_stress(shell, case_id, model)


func _check_summary_scroll_stress(shell: Control, case_id: String, original_model: Dictionary) -> void:
	var config := (original_model.get("config", {}) as Dictionary).duplicate(true)
	var equipment := [
		_item_fixture("eq_goggles", "%s_eq_1" % case_id),
		_item_fixture("eq_insulated_sleeve", "%s_eq_2" % case_id),
	]
	var consumables := [
		_item_fixture("con_ration", "%s_con_1" % case_id),
		_item_fixture("con_tape_roll", "%s_con_2" % case_id),
		_item_fixture("con_scan_pin", "%s_con_3" % case_id),
	]
	config["selected_equipment_items"] = equipment
	config["selected_consumable_items"] = consumables
	config["bag_used"] = 3
	var stress_model := DeployPrepModelScript.model_with_config(
		original_model,
		config,
		StringName(original_model.get("selected_card", &""))
	)
	shell.set("current_model", stress_model)
	shell.call("_refresh_all", false)
	shell.call("_show_summary_page", &"config")
	var scroll := shell.get("summary_scroll") as ScrollContainer
	var ready := await _wait_until(
		func() -> bool:
			return (
				StringName(shell.get("active_summary_page")) == &"config"
				and _visible_summary_count(shell) == 7
				and _scroll_has_range(scroll)
			),
		"%s summary stress range" % case_id
	)
	if ready and scroll != null:
		await _scroll_to_end(scroll, "%s summary stress" % case_id, false)
		await _wait_until(
			func() -> bool: return _summary_last_row_fully_visible(shell, scroll),
			"%s summary stress last row visibility" % case_id
		)
		var visible_labels := _visible_summary_labels(shell)
		var last_label: Label = visible_labels.back() if not visible_labels.is_empty() else null
		var last_panel: Control = (
			last_label.get_meta("deploy_summary_row_panel") as Control
			if last_label != null
			else null
		)
		_expect(
			last_panel != null
				and last_panel.get_global_rect().end.y <= scroll.get_global_rect().end.y + 0.5
				and last_panel.get_global_rect().position.y >= scroll.get_global_rect().position.y - 0.5,
			"%s summary stress last row is not fully reachable" % case_id
		)
	shell.set("current_model", original_model)
	shell.call("_refresh_all", false)
	shell.call("_show_summary_page", &"overview")
	if scroll != null:
		scroll.scroll_vertical = 0
	await _wait_until(
		func() -> bool:
			return (
				StringName(shell.get("active_summary_page")) == &"overview"
				and _visible_summary_count(shell) >= 6
				and (scroll == null or scroll.scroll_vertical == 0)
			),
		"%s summary overview restore" % case_id
	)


func _check_detail_scroll(shell: Control, case_id: String) -> void:
	var scroll := shell.get("detail_body_scroll") as ScrollContainer
	var description := shell.get("detail_description_label") as Label
	_expect(scroll != null and scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s detail is not vertically scrollable" % case_id)
	_expect(description != null and not description.clip_text and description.max_lines_visible == -1, "%s detail text is still clipped" % case_id)
	if scroll == null:
		return
	await _wait_until(
		func() -> bool: return _scroll_has_range(scroll),
		"%s detail scroll range" % case_id
	)
	await _scroll_to_end(scroll, "%s detail" % case_id)


func _check_focus_path(shell: Control, case_id: String) -> void:
	var card := _card_by_item(shell, "con_ration")
	var card_button := card.call("focus_button") as Button if card != null else null
	_expect(card_button != null and card_button.focus_mode == Control.FOCUS_ALL, "%s card cannot receive controller focus" % case_id)
	if card_button == null:
		return
	card_button.grab_focus()
	var focused := await _wait_until(
		func() -> bool: return root.gui_get_focus_owner() == card_button,
		"%s card focus" % case_id
	)
	if not focused:
		return
	_expect(not card_button.focus_neighbor_right.is_empty(), "%s card lacks a right focus route" % case_id)
	var event := InputEventAction.new()
	event.action = &"ui_right"
	event.pressed = true
	Input.parse_input_event(event)
	var moved := await _wait_until(
		func() -> bool:
			var owner := root.gui_get_focus_owner()
			return owner != null and owner != card_button and shell.is_ancestor_of(owner),
		"%s controller right focus" % case_id
	)
	event.pressed = false
	Input.parse_input_event(event)
	_expect(moved, "%s controller focus did not leave the card" % case_id)


func _check_filter_overflow(shell: Control, case_id: String) -> void:
	var scroll := shell.get("filter_scroll") as ScrollContainer
	var previous := shell.get("filter_previous_button") as Button
	var next := shell.get("filter_next_button") as Button
	var filters := shell.get("filter_buttons") as Dictionary
	var special := filters.get(DeployTabModelScript.FILTER_WAREHOUSE_SPECIAL) as Button
	_expect(
		scroll != null and previous != null and next != null and special != null,
		"%s filter overflow controls are incomplete" % case_id
	)
	if scroll == null or previous == null or next == null or special == null:
		return
	await _wait_until(
		func() -> bool:
			var bar := scroll.get_h_scroll_bar()
			return bar != null and scroll.size.x > 0.0 and special.size.x > 0.0,
		"%s filter geometry ready" % case_id
	)
	var bar := scroll.get_h_scroll_bar()
	var max_scroll := maxi(0, int(ceil(bar.max_value - bar.page))) if bar != null else 0
	if max_scroll == 0:
		_expect(not previous.visible and not next.visible, "%s filter arrows are visible without overflow" % case_id)
		return
	_expect(previous.visible and next.visible, "%s filter overflow has no visible navigation" % case_id)
	_expect(previous.disabled and not next.disabled, "%s filter overflow starts with incorrect arrow states" % case_id)
	next.emit_signal("pressed")
	var advanced := await _wait_until(
		func() -> bool: return scroll.scroll_horizontal > 0,
		"%s filter next scroll" % case_id
	)
	if not advanced:
		return
	special.grab_focus()
	var focused_and_visible := await _wait_until(
		func() -> bool:
			return (
				root.gui_get_focus_owner() == special
				and _rect_encloses(scroll.get_global_rect(), special.get_global_rect())
			),
		"%s hidden special filter focus reveal" % case_id
	)
	_expect(focused_and_visible, "%s hidden special filter is not focus-reachable" % case_id)
	scroll.scroll_horizontal = 0
	await _wait_until(
		func() -> bool: return scroll.scroll_horizontal == 0 and previous.disabled,
		"%s filter scroll restore" % case_id
	)


func _check_contextual_gold_and_map(shell: Control, case_id: String) -> void:
	var gold_panel := shell.get("detail_gold_panel") as Control
	shell.show_tab(DeployTabModelScript.TAB_LOADOUT)
	await _wait_until(
		func() -> bool: return StringName((shell.get("current_model") as Dictionary).get("active_tab", &"")) == DeployTabModelScript.TAB_LOADOUT,
		"%s loadout tab" % case_id
	)
	_expect(gold_panel != null and not gold_panel.visible, "%s gold leaked into non-transaction loadout" % case_id)
	shell.show_tab(DeployTabModelScript.TAB_CLAIM)
	await _wait_until(
		func() -> bool: return StringName((shell.get("current_model") as Dictionary).get("active_tab", &"")) == DeployTabModelScript.TAB_CLAIM,
		"%s claim tab" % case_id
	)
	_expect(gold_panel != null and gold_panel.visible, "%s purchase context omitted gold" % case_id)
	shell.show_tab(DeployTabModelScript.TAB_MAP)
	await _wait_until(
		func() -> bool:
			return (
				StringName((shell.get("current_model") as Dictionary).get("active_tab", &"")) == DeployTabModelScript.TAB_MAP
				and (shell.get("map_split_view") as Control).visible
			),
		"%s map tab" % case_id
	)
	_expect(gold_panel != null and not gold_panel.visible, "%s gold leaked into map context" % case_id)
	var map_view := shell.get("map_split_view") as Control
	var scale_column := map_view.get_node_or_null("MapScaleColumn") as Control if map_view != null else null
	var detail_column := map_view.get_node_or_null("MapDetailColumn") as Control if map_view != null else null
	_expect(scale_column != null and detail_column != null, "%s map columns missing" % case_id)
	if scale_column != null and detail_column != null:
		_expect(is_equal_approx(scale_column.size.x, 198.0), "%s map scale width=%s" % [case_id, scale_column.size.x])
		_expect(is_equal_approx(detail_column.size.x, 424.0), "%s map detail width=%s" % [case_id, detail_column.size.x])
	shell.show_tab(DeployTabModelScript.TAB_WAREHOUSE)
	await _wait_until(
		func() -> bool:
			return (
				StringName((shell.get("current_model") as Dictionary).get("active_tab", &"")) == DeployTabModelScript.TAB_WAREHOUSE
				and _card_by_item(shell, "con_ration") != null
			),
		"%s restore warehouse" % case_id
	)
	var restored_card := _card_by_item(shell, "con_ration")
	var card_scroll := shell.get("card_scroll") as ScrollContainer
	if card_scroll != null:
		await _wait_until(
			func() -> bool: return card_scroll.modulate.a >= 0.99,
			"%s restored warehouse fade" % case_id
		)
	_expect(
		restored_card != null
			and restored_card.is_visible_in_tree()
			and card_scroll != null
			and restored_card.get_global_rect().intersects(card_scroll.get_global_rect()),
		"%s restored warehouse card is outside the visible scroll viewport: card=%s scroll=%s offset=%s"
		% [
			case_id,
			Rect2() if restored_card == null else restored_card.get_global_rect(),
			Rect2() if card_scroll == null else card_scroll.get_global_rect(),
			-1 if card_scroll == null else card_scroll.scroll_vertical,
		]
	)


func _check_text_safety(shell: Control, case_id: String) -> void:
	for control in _control_descendants(shell):
		if not control.is_visible_in_tree():
			continue
		if control.has_meta("deploy_scroll_content") and bool(control.get_meta("deploy_scroll_content", false)):
			var scroll_label := control as Label
			_expect(scroll_label != null and not scroll_label.clip_text and scroll_label.max_lines_visible == -1, "%s scroll text clips at %s" % [case_id, control.get_path()])
			continue
		if not control.has_meta("deploy_text_fit"):
			continue
		var fit := control.get_meta("deploy_text_fit", {}) as Dictionary
		if bool(fit.get("fits", false)):
			continue
		var safely_trimmed := false
		if control is Label:
			var label := control as Label
			safely_trimmed = label.clip_text and label.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
		elif control is Button:
			safely_trimmed = (control as Button).clip_text
		_expect(safely_trimmed, "%s text overlaps its frame at %s" % [case_id, control.get_path()])


func _capture_case(case_id: String, expected_size: Vector2i) -> void:
	if output_directory.is_empty():
		return
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	_expect(image != null and not image.is_empty(), "%s screenshot is empty" % case_id)
	if image == null or image.is_empty():
		return
	var captured_size := image.get_size()
	_expect(
		absi(captured_size.x - expected_size.x) <= 1 and absi(captured_size.y - expected_size.y) <= 1,
		"%s screenshot=%s expected=%s (maximum one-pixel canvas rounding allowed)"
		% [case_id, captured_size, expected_size]
	)
	var path := output_directory.path_join("deploy_%s.png" % case_id)
	var error := image.save_png(path)
	_expect(error == OK, "%s screenshot save failed: %s" % [case_id, error_string(error)])
	if error == OK:
		capture_paths.append(path)


func _snapshot() -> Dictionary:
	var ration := M7ContentCatalogScript.item_definition("con_ration")
	ration["instance_id"] = "i4_layout_ration"
	ration["short_description"] = (
		"用于验证详情长文本滚动的生产夹具：进入探索前应能完整阅读用途、使用限制、"
		+ "携带规则、失败结算规则以及与背包容量的关系；任何 UI 比例下都不能被固定行数截断。"
	)
	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "i4_layout_collectible"
	var unlocked: Array[String] = []
	for definition in M7ContentCatalogScript.map_definitions():
		unlocked.append(str((definition as Dictionary).get("id", "")))
	return {
		"run_active": false,
		"meta_progress_summary": {
			"profile_id": "i4_layout",
			"profile_level": 9,
			"permit_level": 9,
			"protocol_difficulty": 5,
			"gold": 500,
			"tutorial_completed": true,
			"unlocked_map_ids": unlocked,
			"warehouse_items": [ration, collectible],
			"warehouse_items_count": 2,
			"completed_research_ids": [],
			"talent_flags": [],
		},
	}


func _card_by_item(shell: Control, item_id: String) -> Control:
	for raw_view in shell.get("card_views") as Array:
		var view := raw_view as Control
		if view != null and str((view.get("card_data") as Dictionary).get("item_id", "")) == item_id:
			return view
	return null


func _visible_summary_count(shell: Control) -> int:
	return _visible_summary_text(shell).size()


func _visible_summary_text(shell: Control) -> Array[String]:
	var result: Array[String] = []
	for label in _visible_summary_labels(shell):
		result.append(label.text)
	return result


func _visible_summary_labels(shell: Control) -> Array[Label]:
	var result: Array[Label] = []
	for raw_label in shell.get("summary_row_labels") as Array:
		var label := raw_label as Label
		var row_panel := (
			label.get_meta("deploy_summary_row_panel") as CanvasItem
			if label != null
			else null
		)
		if label != null and label.visible and row_panel != null and row_panel.visible:
			result.append(label)
	return result


func _item_fixture(item_id: String, instance_id: String) -> Dictionary:
	var item := M7ContentCatalogScript.item_definition(item_id)
	item["instance_id"] = instance_id
	return item


func _array_has_prefix(values: Array[String], prefix: String) -> bool:
	for value in values:
		if value.begins_with(prefix):
			return true
	return false


func _scroll_has_range(scroll: ScrollContainer) -> bool:
	if scroll == null:
		return false
	var bar := scroll.get_v_scroll_bar()
	return bar != null and bar.max_value > bar.page + 0.5


func _summary_last_row_fully_visible(shell: Control, scroll: ScrollContainer) -> bool:
	if shell == null or scroll == null:
		return false
	var visible_labels := _visible_summary_labels(shell)
	if visible_labels.is_empty():
		return false
	var last_label := visible_labels.back() as Label
	var last_panel := last_label.get_meta("deploy_summary_row_panel") as Control
	if last_panel == null:
		return false
	var row_rect := last_panel.get_global_rect()
	var scroll_rect := scroll.get_global_rect()
	return (
		row_rect.position.y >= scroll_rect.position.y - 0.5
		and row_rect.end.y <= scroll_rect.end.y + 0.5
	)


func _scroll_to_end(scroll: ScrollContainer, label: String, reset_after: bool = true) -> void:
	if not _scroll_has_range(scroll):
		_expect(false, "%s has no reachable scroll range" % label)
		return
	var bar := scroll.get_v_scroll_bar()
	scroll.scroll_vertical = int(ceil(bar.max_value - bar.page))
	await _wait_until(
		func() -> bool: return scroll.scroll_vertical > 0,
		"%s reaches content end" % label
	)
	_expect(scroll.scroll_vertical > 0, "%s did not move" % label)
	if reset_after:
		scroll.scroll_vertical = 0


func _rect_matches(control: Control, expected: Rect2) -> bool:
	return control.position.is_equal_approx(expected.position) and control.size.is_equal_approx(expected.size)


func _rect_encloses(outer: Rect2, inner: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x - 0.5
		and inner.position.y >= outer.position.y - 0.5
		and inner.end.x <= outer.end.x + 0.5
		and inner.end.y <= outer.end.y + 0.5
	)


func _contains_t_code(text: String) -> bool:
	for tier in range(1, 7):
		if text.contains("T%d" % tier):
			return true
	return false


func _control_descendants(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in node.get_children():
		if child is Control:
			result.append(child as Control)
		result.append_array(_control_descendants(child))
	return result


func _wait_for_stable_layout(
	shell: Control,
	label: String,
	required_submissions: int = 3,
	timeout_ms: int = WAIT_TIMEOUT_MS
) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	var previous_fingerprint := ""
	var stable_submissions := 0
	while Time.get_ticks_msec() <= deadline:
		await process_frame
		var fingerprint := _visible_layout_fingerprint(shell)
		if not fingerprint.is_empty() and fingerprint == previous_fingerprint:
			stable_submissions += 1
		else:
			previous_fingerprint = fingerprint
			stable_submissions = 1 if not fingerprint.is_empty() else 0
		if stable_submissions >= required_submissions:
			return true
	failures.append("timed out waiting for three stable render submissions: %s" % label)
	return false


func _visible_layout_fingerprint(shell: Control) -> String:
	if shell == null or not shell.is_inside_tree() or not shell.is_visible_in_tree():
		return ""
	var records: Array[String] = []
	for control in _control_descendants(shell):
		if not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		var text := ""
		if control is Label:
			text = (control as Label).text
		elif control is Button:
			text = (control as Button).text
		records.append(
			"%s|%.2f,%.2f,%.2f,%.2f|%.3f,%.3f|%s" % [
				String(shell.get_path_to(control)),
				rect.position.x,
				rect.position.y,
				rect.size.x,
				rect.size.y,
				control.modulate.a,
				control.self_modulate.a,
				text,
			]
		)
	records.sort()
	return "\n".join(records)


func _wait_until(predicate: Callable, label: String, timeout_ms: int = WAIT_TIMEOUT_MS) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await process_frame
	failures.append("timed out waiting for semantic state: %s" % label)
	return false


func _output_directory(arguments: PackedStringArray) -> String:
	for argument in arguments:
		if argument.begins_with("--output="):
			var requested := argument.trim_prefix("--output=").strip_edges()
			if requested.is_empty():
				return ""
			var absolute := ProjectSettings.globalize_path(requested)
			var error := DirAccess.make_dir_recursive_absolute(absolute)
			if error != OK:
				failures.append("could not create screenshot directory %s: %s" % [absolute, error_string(error)])
				return ""
			return absolute
	return ""


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
