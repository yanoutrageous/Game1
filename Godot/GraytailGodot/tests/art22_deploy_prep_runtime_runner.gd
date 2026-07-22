extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")

var failures: Array[String] = []
var route_intents: Array[Dictionary] = []
var start_intents: Array[Dictionary] = []
var meta_actions: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)

	var shell_script := load("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
	_check(shell_script != null, "DeployPrepShell could not be loaded")
	if shell_script == null:
		_finish()
		return
	var shell := shell_script.new() as Control
	shell.name = "Art22RuntimeDeployPrep"
	shell.size = Vector2(1280, 720)
	canvas.add_child(shell)
	shell.connect("navigation_intent_requested", _on_route_intent)
	shell.connect("deploy_start_intent_requested", _on_start_intent)
	shell.connect("meta_action_requested", _on_meta_action)
	shell.call("build")
	await _frames(12)

	_check_shell_frame(shell)
	_check_player_tabs(shell)
	_check_map_same_page_contract(shell)
	await _check_map_selection_contract(shell)
	_check_motion_contract(shell)
	_check_collapse_contract(shell)

	var representative := _representative_snapshot(false)
	shell.call("apply_snapshot", representative)
	await _frames(5)
	await _check_non_map_split_and_explicit_actions(shell)
	_check_summary_contract(shell)
	_check_focus_neighbors(shell)
	_check_reduced_motion(shell)
	await _check_run_actions_and_escape(shell, representative)
	_check_appearance_route(shell)
	await _check_result_settlement_surface(canvas)

	_finish()


func _check_shell_frame(shell: Control) -> void:
	_check(shell.size == Vector2(1280, 720), "DeployPrep does not fill the design canvas")
	for root_name in [
		"BackgroundRoot", "DecorationRoot", "CharacterRoot", "MainContentRoot",
		"SideStatusRoot", "PrimaryActionRoot", "FloatingInfoRoot", "OverlayRoot", "ModalRoot"
	]:
		_check(shell.get_node_or_null(root_name) != null, "Missing layer root: " + root_name)
	_check_texture_size(shell, "BackgroundRoot/DeployPrepSceneCleanPlate", Vector2(1280, 720))
	_check_texture_size(shell, "MainContentRoot/DeployParchmentGroup/DeployParchment", Vector2(688, 692))
	_check_texture_size(shell, "SideStatusRoot/DeploySummaryBoard", Vector2(252, 494))
	_check(shell.get_node_or_null("CharacterRoot/DeployCharacter") is TextureRect, "Environment-integrated character is missing")
	_check(shell.get_node_or_null("PrimaryActionRoot/DeployNavMain") is Button, "Main-menu plaque is missing")
	_check(shell.get_node_or_null("PrimaryActionRoot/DeployNavLongTerm") is Button, "Long-term plaque is missing")
	_check(shell.get_node_or_null("MainContentRoot/DeployCollapseHandle") is Button, "Parchment collapse handle is missing")


func _check_player_tabs(shell: Control) -> void:
	var expected := {
		&"map": "地图",
		&"warehouse": "仓库",
		&"claim": "申领",
		&"objective": "本局委托",
		&"loadout": "携带清单",
	}
	var buttons := shell.get("tab_buttons") as Dictionary
	_check(buttons.size() == expected.size(), "Primary tab count must remain five")
	for tab_id in expected:
		var button := buttons.get(tab_id) as Button
		_check(button != null, "Missing player-facing tab: " + String(tab_id))
		if button != null:
			_check(button.text == str(expected[tab_id]), "Wrong player-facing tab label for %s: %s" % [String(tab_id), button.text])
	_check(not ((shell.get("primary_tab_button_group") as ButtonGroup).allow_unpress), "Primary tabs can be visually unselected")


func _check_map_same_page_contract(shell: Control) -> void:
	_check(StringName((shell.get("current_model") as Dictionary).get("active_tab", &"")) == &"map", "Deploy must open on its map tab")
	_check((shell.get("filter_buttons") as Dictionary).is_empty(), "Map regressed to the old secondary-filter hierarchy")
	_check((shell.get("card_views") as Array).is_empty(), "Map regressed to generic route cards")
	var map_view := shell.get("map_split_view") as Control
	_check(map_view != null and map_view.visible, "Single-page map split view is missing")
	if map_view == null:
		return
	_check(shell.get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployMapSplitView") == map_view, "Map split escaped the existing Deploy parchment")
	var projection := (shell.get("current_model") as Dictionary).get("map_projection", {}) as Dictionary
	_check(StringName(projection.get("page_id", &"")) == &"deploy_prep", "Map projection introduced another page")
	_check(StringName(projection.get("route_page_id", &"")) == &"deploy_prep", "Map projection introduced a region route")
	_check(StringName(projection.get("tab_id", &"")) == &"map", "Map projection is outside the Deploy map tab")
	_check(StringName(projection.get("fallback_policy", &"")) == &"fail_closed", "Map projection no longer fails closed")
	var scale_options := projection.get("scale_options", []) as Array
	_check(scale_options.size() == 3, "Map split must expose exactly three scales")
	var expected_ids := {
		&"7x7": ["classic_7x7_simple", "classic_7x7_normal"],
		&"10x10": ["classic_10x10_easy", "classic_10x10_standard", "classic_10x10_hard"],
		&"13x13": ["classic_13x13_normal", "classic_13x13_hard", "classic_13x13_hell"],
	}
	var all_ids: Array[String] = []
	for raw_scale in scale_options:
		var scale := raw_scale as Dictionary
		var scale_id := StringName(scale.get("scale_id", &""))
		_check(expected_ids.has(scale_id), "Unexpected map scale: " + String(scale_id))
		var actual_ids: Array[String] = []
		for raw_map in scale.get("maps", []) as Array:
			var map_data := raw_map as Dictionary
			var map_id := str(map_data.get("map_config_id", ""))
			actual_ids.append(map_id)
			all_ids.append(map_id)
			_check(not M7ContentCatalogScript.map_definition_exact(map_id).is_empty(), "Map split projected a non-exact id: " + map_id)
		if expected_ids.has(scale_id):
			_check(actual_ids == expected_ids[scale_id], "Difficulty ids drifted for %s: %s" % [String(scale_id), actual_ids])
	_check(all_ids.size() == 8, "Map split must cover all eight exact map ids")
	var snapshot := map_view.call("projection_snapshot") as Dictionary
	_check(int(snapshot.get("scale_count", 0)) == 3, "Map view did not build three scale controls")
	_check(int(snapshot.get("difficulty_count", 0)) == 2, "Default 7x7 scale must expose two difficulties")
	var scale_buttons := map_view.get("scale_buttons") as Dictionary
	_check(_sorted_key_strings(scale_buttons) == ["10x10", "13x13", "7x7"], "Map scale controls are not exactly 7x7/10x10/13x13")
	var gold_label := shell.get("detail_gold_label") as Label
	var gold_panel := shell.get("detail_gold_panel") as Control
	_check(gold_label != null and gold_label.visible and gold_label.text.begins_with("—") and gold_label.text.ends_with("金币"), "Missing wallet value must display — 金币")
	_check(gold_panel != null and gold_panel.visible and gold_panel.position.x >= 700.0 and gold_panel.position.y <= 120.0, "Gold is not resident at the upper-right of Deploy content")


func _check_map_selection_contract(shell: Control) -> void:
	var map_view := shell.get("map_split_view") as Control
	if map_view == null:
		return
	var config_before := _config(shell)
	var route_count_before := route_intents.size()
	var scale_buttons := map_view.get("scale_buttons") as Dictionary
	var scale_10 := scale_buttons.get(&"10x10") as Button
	_check(scale_10 != null, "10x10 scale control is missing")
	if scale_10 == null:
		return
	scale_10.emit_signal("pressed")
	await _frames(2)
	_check(_config(shell) == config_before, "Scale preview mutated DeployConfig")
	_check(route_intents.size() == route_count_before, "Scale preview left the single Deploy page")
	var projection_snapshot := map_view.call("projection_snapshot") as Dictionary
	_check(StringName(projection_snapshot.get("selected_scale_id", &"")) == &"10x10", "10x10 scale preview was not retained")
	_check(int(projection_snapshot.get("difficulty_count", 0)) == 3, "10x10 scale must expose three difficulties")
	var difficulties := map_view.get("difficulty_buttons") as Dictionary
	_check(_sorted_key_strings(difficulties) == ["classic_10x10_easy", "classic_10x10_hard", "classic_10x10_standard"], "10x10 difficulty controls lost exact ids")
	var standard := difficulties.get(&"classic_10x10_standard") as Button
	_check(standard != null, "Exact classic_10x10_standard control is missing")
	if standard == null:
		return
	standard.emit_signal("pressed")
	await _frames(2)
	_check(_config(shell) == config_before, "Difficulty preview mutated DeployConfig before confirmation")
	_check(StringName(map_view.call("get_preview_map_id")) == &"classic_10x10_standard", "Difficulty preview substituted another map id")
	var select_action := map_view.get("select_action_button") as Button
	_check(select_action != null and not select_action.disabled, "Unlocked exact map cannot be explicitly adopted")
	if select_action != null and not select_action.disabled:
		select_action.emit_signal("pressed")
		await _frames(3)
		_check(str(_config(shell).get("map_config_id", "")) == "classic_10x10_standard", "Explicit map action did not commit the exact id")
		_check(route_intents.size() == route_count_before, "Explicit map action created a second route page")
	for scale_id in [&"7x7", &"10x10", &"13x13"]:
		var scale_button := (map_view.get("scale_buttons") as Dictionary).get(scale_id) as Button
		_check(scale_button != null, "Scale button disappeared after exact selection: " + String(scale_id))
		if scale_button == null:
			continue
		scale_button.emit_signal("pressed")
		await _frames(1)
		var count := (map_view.get("difficulty_buttons") as Dictionary).size()
		var expected_count := 2 if scale_id == &"7x7" else 3
		_check(count == expected_count, "Difficulty count mismatch for %s: %d" % [String(scale_id), count])


func _check_non_map_split_and_explicit_actions(shell: Control) -> void:
	shell.call("show_tab", &"warehouse")
	await _frames(4)
	var selection_pane := shell.get_node_or_null("MainContentRoot/DeployParchmentGroup/DeploySelectionPane") as Control
	var detail_pane := shell.get("detail_panel") as Control
	var card_scroll := shell.get("card_scroll") as Control
	_check(selection_pane != null and selection_pane.visible, "Warehouse left selection pane is missing")
	_check(detail_pane != null and detail_pane.visible, "Warehouse right detail pane is missing")
	_check(card_scroll != null and card_scroll.visible and detail_pane != null and card_scroll.position.x < detail_pane.position.x, "Non-map content is not a left-selection/right-detail split")
	var filter_scroll := shell.get("filter_scroll") as ScrollContainer
	var filter_previous := shell.get("filter_previous_button") as Button
	var filter_next := shell.get("filter_next_button") as Button
	if filter_scroll != null:
		filter_scroll.position = Vector2(307, 104)
		filter_scroll.size = Vector2(198, 38)
		shell.call("_update_filter_navigation")
		_check(filter_scroll.position == Vector2(286, 104) and filter_scroll.size == Vector2(240, 38), "Filter navigation did not recover its full-width viewport after a prior overflow state")
		_check(filter_previous != null and not filter_previous.visible and filter_next != null and not filter_next.visible, "Filter arrows remained visible for a full-width filter set that fits")
		var filter_buttons := shell.get("filter_buttons") as Dictionary
		if not filter_buttons.is_empty():
			var wide_filter := filter_buttons.values()[0] as Button
			wide_filter.custom_minimum_size.x = 300
			await _frames(2)
			shell.call("_update_filter_navigation")
			var bar := filter_scroll.get_h_scroll_bar()
			var final_scroll := maxi(0, int(bar.max_value - bar.page)) if bar != null else 0
			_check(filter_scroll.size == Vector2(198, 38) and filter_next != null and filter_next.visible, "Overflowing filters did not reserve non-overlapping navigation controls")
			filter_scroll.scroll_horizontal = final_scroll
			await process_frame
			_check(filter_scroll.scroll_horizontal == final_scroll and filter_next != null and filter_next.disabled, "Overflow navigation clamps away the end of the filter row")
			shell.call("_rebuild_filters")
			await _frames(2)
	var card_views := shell.get("card_views") as Array
	_check(card_views.size() >= 2, "Representative warehouse does not expose selectable rows")
	for raw_view in card_views:
		var view := raw_view as Control
		_check(view != null and is_equal_approx(view.size.y, 76.0), "Selection row height must remain 76")
		if view != null:
			var title := view.get_node_or_null("CardTitle") as Label
			var summary := view.get_node_or_null("CardSummary") as Label
			_check(title != null and title.clip_text, "Selection row title is not bounded")
			_check(summary != null and summary.clip_text and summary.autowrap_mode == TextServer.AUTOWRAP_OFF, "Selection row summary is not a compact single line")

	var target := _find_card_view(shell, &"m3r_i2_eq_sleeve")
	_check(target != null, "Representative warehouse row is missing")
	if target != null:
		var config_before := _config(shell)
		var meta_before := meta_actions.size()
		(target.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
		_check(_config(shell) == config_before, "Selecting a warehouse row mutated DeployConfig")
		_check(meta_actions.size() == meta_before, "Selecting a warehouse row emitted a meta action")
		_check(StringName((shell.get("current_model") as Dictionary).get("selected_card", &"")) == &"m3r_i2_eq_sleeve", "Warehouse selection did not update the right detail")
		var detail := (shell.get("current_model") as Dictionary).get("detail_projection", {}) as Dictionary
		_check(str(detail.get("instance_id", "")) == "i2_eq_sleeve", "Right detail does not describe the selected warehouse instance")
		var action_button := shell.get("detail_primary_action_button") as Button
		_check(action_button != null and action_button.visible and not action_button.disabled, "Warehouse detail lacks an explicit attendance action")
		if action_button != null and not action_button.disabled:
			action_button.emit_signal("pressed")
			await _frames(3)
			_check((_config(shell).get("selected_equipment_ids", []) as Array).has("i2_eq_sleeve"), "Explicit warehouse action did not update attendance")
			_check(meta_actions.size() == meta_before, "Local attendance action incorrectly emitted a meta action")
			var refreshed_target := _find_card_view(shell, &"m3r_i2_eq_sleeve")
			var refreshed_data := refreshed_target.get("card_data") as Dictionary if refreshed_target != null else {}
			_check(bool(refreshed_data.get("selected", false)) and int(refreshed_data.get("deployed_count", 0)) == 1, "Warehouse left row did not rebuild after adding attendance")
			var remove_button := shell.get("detail_primary_action_button") as Button
			_check(remove_button != null and remove_button.text == "移出出勤", "Warehouse detail did not switch to the true removal action")
			if remove_button != null and not remove_button.disabled:
				remove_button.emit_signal("pressed")
				await _frames(3)
				var removed_target := _find_card_view(shell, &"m3r_i2_eq_sleeve")
				var removed_data := removed_target.get("card_data") as Dictionary if removed_target != null else {}
				_check(not bool(removed_data.get("selected", true)) and int(removed_data.get("deployed_count", -1)) == 0, "Warehouse left row did not rebuild after removing attendance")

	var ration_a := _find_card_view(shell, &"m3r_i2_con_ration_a")
	_check(ration_a != null, "First duplicate consumable row is missing")
	if ration_a != null:
		(ration_a.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
		var carry_button := shell.get("detail_primary_action_button") as Button
		_check(carry_button != null and carry_button.text == "加入携带" and not carry_button.disabled, "First duplicate consumable lacks an explicit carry action")
		if carry_button != null and not carry_button.disabled:
			carry_button.emit_signal("pressed")
			await _frames(3)
	var selected_consumable_ids := _config(shell).get("selected_consumable_ids", []) as Array
	_check(selected_consumable_ids.has("i2_con_ration_a") and not selected_consumable_ids.has("i2_con_ration_b"), "Selecting one duplicate consumable did not preserve exact instance identity")
	var ration_row_a := _find_selection_row(shell, &"m3r_i2_con_ration_a")
	var ration_row_b := _find_selection_row(shell, &"m3r_i2_con_ration_b")
	_check(bool(ration_row_a.get("selected", false)), "Selected duplicate consumable is not shown as selected")
	_check(not bool(ration_row_b.get("selected", true)), "Unselected duplicate consumable inherited the selected state by item_id")
	var ration_b_actions := ration_row_b.get("actions", []) as Array
	_check(not ration_b_actions.is_empty() and str((ration_b_actions[0] as Dictionary).get("label", "")) == "加入携带", "Unselected duplicate consumable exposes an action opposite to its true state")
	if not ration_b_actions.is_empty():
		_check(str(((ration_b_actions[0] as Dictionary).get("payload", {}) as Dictionary).get("instance_id", "")) == "i2_con_ration_b", "Duplicate consumable action lost exact instance identity")

	var collectible := _find_card_view(shell, &"m3r_i2_collectible")
	_check(collectible != null, "Sellable collectible row is missing")
	if collectible != null:
		(collectible.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
		var sell_button := shell.get("detail_primary_action_button") as Button
		var meta_before_sell := meta_actions.size()
		_check(sell_button != null and sell_button.text == "出售", "Collectible did not begin with an explicit sell action")
		if sell_button != null and not sell_button.disabled:
			sell_button.emit_signal("pressed")
			await _frames(3)
		_check(meta_actions.size() == meta_before_sell, "First sell click bypassed confirmation")
		sell_button = shell.get("detail_primary_action_button") as Button
		_check(sell_button != null and sell_button.text == "确认出售", "Pending single-item sale is not visibly confirmed")
		var other_row := _find_card_view(shell, &"m3r_i2_eq_goggles")
		if other_row != null:
			(other_row.call("focus_button") as Button).emit_signal("pressed")
			await _frames(2)
			collectible = _find_card_view(shell, &"m3r_i2_collectible")
			(collectible.call("focus_button") as Button).emit_signal("pressed")
			await _frames(2)
			sell_button = shell.get("detail_primary_action_button") as Button
			_check(sell_button != null and sell_button.text == "出售", "Sell confirmation survived leaving and returning to the target row")
			if sell_button != null and not sell_button.disabled:
				sell_button.emit_signal("pressed")
				await _frames(2)
			_check(meta_actions.size() == meta_before_sell, "Returning to a prior sell target allowed one-click submission")
			sell_button = shell.get("detail_primary_action_button") as Button
			_check(sell_button != null and sell_button.text == "确认出售", "Second visible sell confirmation was not retained")
			if sell_button != null and not sell_button.disabled:
				sell_button.emit_signal("pressed")
				await _frames(2)
			_check(meta_actions.size() == meta_before_sell + 1, "Visible sell confirmation did not emit exactly one meta action")
			if meta_actions.size() == meta_before_sell + 1:
				var sale_action := meta_actions.back() as Dictionary
				_check(StringName(sale_action.get("action", &"")) == &"sell_collectible", "Sell confirmation emitted the wrong domain action")
				_check(str(sale_action.get("instance_id", "")) == "i2_collectible", "Sell confirmation lost exact collectible instance identity")

	shell.call("show_tab", &"claim")
	await _frames(4)
	var emergency_row := _find_card_view(shell, &"claim_emergency_ration")
	_check(emergency_row != null, "Emergency claim row is missing")
	if emergency_row != null:
		(emergency_row.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
		var claim_button := shell.get("detail_primary_action_button") as Button
		if claim_button != null and not claim_button.disabled:
			claim_button.emit_signal("pressed")
			await _frames(3)
		var refreshed_claim := _find_card_view(shell, &"claim_emergency_ration")
		var claim_data := refreshed_claim.get("card_data") as Dictionary if refreshed_claim != null else {}
		_check(bool(claim_data.get("claimed", false)) and StringName(claim_data.get("state", &"")) == &"selected", "Claim left row did not rebuild after receiving the emergency ration")
		claim_button = shell.get("detail_primary_action_button") as Button
		if claim_button != null and not claim_button.disabled:
			claim_button.emit_signal("pressed")
			await _frames(3)
	var purchase_row := _find_card_view(shell, &"m7_shop_con_ration")
	_check(purchase_row != null, "Representative purchase row is missing")
	if purchase_row != null:
		var config_before_purchase := _config(shell)
		var meta_before_purchase := meta_actions.size()
		(purchase_row.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
		_check(_config(shell) == config_before_purchase, "Selecting a claim row mutated DeployConfig")
		_check(meta_actions.size() == meta_before_purchase, "Selecting a claim row emitted a purchase")
		var purchase_button := shell.get("detail_primary_action_button") as Button
		_check(purchase_button != null and purchase_button.visible and not purchase_button.disabled, "Claim detail lacks an explicit purchase action")
		if purchase_button != null and not purchase_button.disabled:
			purchase_button.emit_signal("pressed")
			await _frames(2)
			_check(meta_actions.size() == meta_before_purchase + 1, "Explicit purchase did not emit exactly one meta action")
			if meta_actions.size() == meta_before_purchase + 1:
				var purchase_action := meta_actions.back() as Dictionary
				_check(StringName(purchase_action.get("action", &"")) == &"purchase", "Explicit claim action emitted the wrong domain action")
				_check(str(purchase_action.get("item_id", "")) == "con_ration", "Explicit purchase lost the exact catalog item id")
				var purchase_carry_ids := purchase_action.get("selected_consumable_ids", []) as Array
				_check(purchase_carry_ids.has("i2_con_ration_a") and not purchase_carry_ids.has("i2_con_ration_b"), "Purchase action attached the wrong exact carried instances")

	shell.call("show_tab", &"objective")
	await _frames(3)
	var objective_rows := (shell.get("current_model") as Dictionary).get("selection_rows", []) as Array
	var previous_objective_id := StringName((shell.get("current_model") as Dictionary).get("selected_card", &""))
	var next_objective_id := &""
	for raw_objective in objective_rows:
		var objective := raw_objective as Dictionary
		if not bool(objective.get("selected", false)):
			next_objective_id = StringName(objective.get("id", &""))
			break
	_check(not next_objective_id.is_empty(), "Objective tab lacks an alternate commission")
	if not next_objective_id.is_empty():
		var next_objective := _find_card_view(shell, next_objective_id)
		(next_objective.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
		var objective_button := shell.get("detail_primary_action_button") as Button
		if objective_button != null and not objective_button.disabled:
			objective_button.emit_signal("pressed")
			await _frames(3)
		var selected_objective_row := _find_selection_row(shell, next_objective_id)
		var prior_objective_row := _find_selection_row(shell, previous_objective_id)
		_check(bool(selected_objective_row.get("selected", false)), "Objective left row did not rebuild to the newly selected commission")
		_check(prior_objective_row.is_empty() or not bool(prior_objective_row.get("selected", true)), "Previous objective row retained a stale selected state")

	shell.call("show_tab", &"loadout")
	await _frames(3)
	var expected_art_filters := {
		&"loadout_map": &"loadout_intent",
		&"loadout_objective": &"loadout_permission_interface",
		&"loadout_capacity": &"loadout_bag",
	}
	for raw_row in (shell.get("current_model") as Dictionary).get("selection_rows", []) as Array:
		var row := raw_row as Dictionary
		var row_id := StringName(row.get("id", &""))
		if expected_art_filters.has(row_id):
			_check(StringName(row.get("art_filter_id", &"")) == expected_art_filters[row_id], "Synthetic loadout row has the wrong semantic artwork: " + String(row_id))


func _check_summary_contract(shell: Control) -> void:
	var summary_buttons := shell.get("summary_buttons") as Dictionary
	_check(_sorted_key_strings(summary_buttons) == ["config", "effect", "objective", "overview"], "Summary pages must be overview/config/effect/objective")
	var summary_projection := (shell.get("current_model") as Dictionary).get("summary_projection", {}) as Dictionary
	_check(_string_name_array(summary_projection.get("page_ids", [])) == [&"overview", &"config", &"effect", &"objective"], "Summary projection page order drifted")
	var forbidden := ["当前选择", "路线 / 难度", "运行状态", "风险"]
	for page_id in [&"overview", &"config", &"effect", &"objective"]:
		shell.call("_show_summary_page", page_id)
		var joined := ""
		for raw_label in shell.get("summary_row_labels") as Array:
			var label := raw_label as Label
			if label != null:
				joined += label.text + "\n"
		var message := shell.get("summary_message_label") as Label
		if message != null:
			joined += message.text
		_check(not joined.strip_edges().is_empty(), "Summary page is empty: " + String(page_id))
		for phrase in forbidden:
			_check(not joined.contains(phrase), "Summary page %s contains forbidden copy: %s" % [String(page_id), phrase])
		var button := summary_buttons.get(page_id) as Button
		_check(button != null and button.button_pressed, "Summary page lacks selected feedback: " + String(page_id))


func _check_focus_neighbors(shell: Control) -> void:
	var tabs := shell.get("tab_buttons") as Dictionary
	for raw_button in tabs.values():
		var button := raw_button as Button
		_check(button != null and not button.focus_neighbor_left.is_empty(), "Tab lacks left focus neighbor")
		_check(button != null and not button.focus_neighbor_right.is_empty(), "Tab lacks right focus neighbor")
	shell.call("show_tab", &"warehouse")
	var card_views := shell.get("card_views") as Array
	if card_views.size() >= 2:
		var first := card_views[0].call("focus_button") as Button
		_check(not first.focus_neighbor_top.is_empty(), "Selection row lacks top focus neighbor")
		_check(not first.focus_neighbor_bottom.is_empty(), "Selection row lacks bottom focus neighbor")
		_check(not first.focus_neighbor_right.is_empty(), "Selection row cannot reach right detail actions")
	shell.call("show_tab", &"map")
	var map_view := shell.get("map_split_view") as Control
	if map_view != null:
		var map_focus := map_view.call("focus_buttons") as Array
		_check(map_focus.size() >= 5, "Map split does not expose keyboard/controller focus targets")
		if not map_focus.is_empty():
			var first_map_button := map_focus[0] as Button
			_check(not first_map_button.focus_neighbor_right.is_empty(), "Map scale focus cannot reach difficulty choices")


func _check_reduced_motion(shell: Control) -> void:
	shell.call("set_reduced_motion_enabled", true)
	_check(bool(shell.call("is_reduced_motion_enabled")), "Deploy reduced-motion flag did not apply")
	var map_view := shell.get("map_split_view") as Control
	_check(map_view != null and bool(map_view.call("is_reduced_motion_enabled")), "Map split did not inherit reduced motion")
	for raw_particles in shell.get("ambient_particles") as Array:
		var particles := raw_particles as CPUParticles2D
		_check(particles != null and not particles.emitting, "Reduced motion left ambient particles active")
	shell.call("_process", 0.8)
	var summary_root := shell.get_node_or_null("SideStatusRoot") as Control
	_check(summary_root != null and summary_root.position == Vector2.ZERO, "Reduced motion left hanging-board sway active")
	shell.call("set_reduced_motion_enabled", false)
	_check(not bool(shell.call("is_reduced_motion_enabled")), "Deploy could not leave reduced-motion mode")


func _check_run_actions_and_escape(shell: Control, representative: Dictionary) -> void:
	shell.call("show_tab", &"map")
	var start_button := shell.get("primary_action_button") as Button
	_check(start_button != null and start_button.text == "确认出发", "No-run primary action is not confirm deploy")
	if start_button != null:
		start_button.emit_signal("pressed")
		await process_frame
	_check(start_intents.size() == 1, "Confirm deploy did not emit exactly one run intent")
	if start_intents.size() == 1:
		var intent := start_intents[0]
		var payload := intent.get("payload", {}) as Dictionary
		_check(StringName(intent.get("target", &"")) == &"run", "Deploy intent target is not run")
		_check(bool(payload.get("uses_existing_route", false)), "Deploy intent no longer uses the existing playable route")
		_check(not bool(payload.get("preview_only", true)), "Deploy intent regressed to preview-only")

	var active_snapshot := representative.duplicate(true)
	active_snapshot["run_active"] = true
	active_snapshot["run_start_config"] = (shell.get("current_model") as Dictionary).get("run_start_config", {})
	shell.call("apply_snapshot", active_snapshot)
	await _frames(4)
	var config_before := _config(shell)
	var map_view := shell.get("map_split_view") as Control
	var map_projection := (shell.get("current_model") as Dictionary).get("map_projection", {}) as Dictionary
	_check(bool(config_before.get("active_run_locked", false)), "Active run did not lock DeployConfig")
	_check(bool(map_projection.get("active_run_locked", false)), "Active run lock did not reach map projection")
	_check(map_view != null and bool((map_view.call("projection_snapshot") as Dictionary).get("active_run_locked", false)), "Active run lock did not reach map split view")
	if map_view != null:
		var select_action := map_view.get("select_action_button") as Button
		_check(select_action != null and select_action.disabled, "Active run still allows map mutation")
	shell.call("show_tab", &"warehouse")
	await _frames(3)
	var actions := ((shell.get("current_model") as Dictionary).get("detail_projection", {}) as Dictionary).get("actions", []) as Array
	for raw_action in actions:
		_check(not bool((raw_action as Dictionary).get("enabled", true)), "Active run still enables a warehouse mutation")
	var meta_before := meta_actions.size()
	shell.call("_on_detail_action_pressed", 0)
	_check(_config(shell) == config_before, "Blocked active-run detail action mutated config")
	_check(meta_actions.size() == meta_before, "Blocked active-run detail action emitted a meta action")

	start_button = shell.get("primary_action_button") as Button
	var cancel_button := shell.get("cancel_action_button") as Button
	_check(start_button != null and start_button.text == "继续探索", "Active-run primary action is not continue")
	_check(cancel_button != null and cancel_button.visible, "Active run does not expose cancel current exploration")
	if start_button != null:
		start_button.emit_signal("pressed")
		await process_frame
	_check(start_intents.size() == 2, "Continue did not emit one additional run intent")
	if start_intents.size() == 2:
		_check(bool((start_intents[1].get("payload", {}) as Dictionary).get("continue_active_run", false)), "Continue intent lacks active-run authority marker")

	var route_before_modal_escape := route_intents.size()
	shell.call("set_reduced_motion_enabled", true)
	if cancel_button != null:
		cancel_button.emit_signal("pressed")
		await _frames(2)
	var modal := shell.get("modal_layer") as Control
	_check(modal != null and modal.visible, "Cancel action did not open the strong-confirm boundary")
	_check(modal != null and modal.modulate == Color.WHITE, "Reduced-motion modal did not open directly at its stable visual state")
	var modal_stack = shell.get("modal_focus_stack")
	_check(modal_stack != null and int(modal_stack.call("depth")) == 1, "Deploy abandon modal is not registered in the shared focus lifecycle")
	var modal_confirm := shell.get("modal_confirm_button") as Button
	var modal_cancel := shell.get("modal_cancel_button") as Button
	var focus_owner := root.gui_get_focus_owner() as Control
	_check(focus_owner != null and modal != null and modal.is_ancestor_of(focus_owner), "Deploy abandon modal did not capture focus")
	for modal_button in [modal_confirm, modal_cancel]:
		if modal_button == null:
			continue
		for neighbor_path in [modal_button.focus_neighbor_top, modal_button.focus_neighbor_bottom, modal_button.focus_neighbor_left, modal_button.focus_neighbor_right, modal_button.focus_next, modal_button.focus_previous]:
			var neighbor := modal_button.get_node_or_null(neighbor_path) as Control
			_check(neighbor != null and modal != null and modal.is_ancestor_of(neighbor), "Modal focus navigation can escape to the obscured Deploy page")
	var routes_before_echo := route_intents.size()
	shell.call("_unhandled_input", _cancel_echo_event())
	await process_frame
	_check(modal != null and modal.visible and route_intents.size() == routes_before_echo, "Repeated ESC closed the modal or routed through it")
	shell.call("_unhandled_input", _cancel_event())
	await _frames(2)
	_check(modal != null and not modal.visible, "ESC did not close the active confirmation first")
	_check(modal_stack != null and int(modal_stack.call("depth")) == 0, "Closing the Deploy modal left a stale focus-stack entry")
	_check(route_intents.size() == route_before_modal_escape, "ESC escaped the page while a modal was open")
	shell.call("set_reduced_motion_enabled", false)

	if cancel_button != null:
		cancel_button.emit_signal("pressed")
		await _frames(2)
	var confirm := shell.get("modal_confirm_button") as Button
	_check(confirm != null and not confirm.disabled, "Real abandon settlement is not confirmable")
	if confirm != null:
		confirm.emit_signal("pressed")
		await _frames(2)
	_check(start_intents.size() == 3, "Confirmed abandon did not emit one additional run intent")
	if start_intents.size() == 3:
		_check(bool((start_intents[2].get("payload", {}) as Dictionary).get("abandon_active_run", false)), "Confirmed abandon intent lacks runtime authority marker")

	var route_before_page_escape := route_intents.size()
	shell.call("_unhandled_input", _cancel_event())
	await process_frame
	_check(route_intents.size() == route_before_page_escape + 1, "ESC outside a modal did not request the main menu")
	if route_intents.size() == route_before_page_escape + 1:
		_check(StringName(route_intents.back().get("target", &"")) == &"main_menu", "ESC routes to the wrong page")


func _check_appearance_route(shell: Control) -> void:
	var before := route_intents.size()
	var appearance := shell.get_node("PrimaryActionRoot/DeployAppearanceButton") as Button
	appearance.emit_signal("pressed")
	_check(route_intents.size() == before + 1, "Appearance hook did not emit one navigation intent")
	if route_intents.size() == before + 1:
		var payload := route_intents.back().get("payload", {}) as Dictionary
		_check(StringName(payload.get("module_id", &"")) == &"collection_appearance", "Appearance hook routes to the wrong long-term module")


func _check_result_settlement_surface(canvas: Control) -> void:
	var result_scene := load("res://scenes/ui/result/result_panel.tscn") as PackedScene
	_check(result_scene != null, "ResultPanel scene could not be loaded")
	if result_scene == null:
		return
	var result_panel = result_scene.instantiate()
	canvas.add_child(result_panel)
	await _frames(2)
	result_panel.show_summary({
		"outcome": "Failed",
		"settlement": {
			"outcome": &"failure",
			"requires_salvage_selection": true,
			"finalized": false,
			"salvage_capacity": 4,
			"settlement_pool": [{"instance_id": "art22_i2_candidate", "display_name": "I2 Candidate", "weight": 1}],
		},
	})
	await _frames(2)
	_check(result_panel.requires_salvage_confirmation(), "Failure result does not expose manual salvage selection")
	var result_actions := result_panel.get_node_or_null("ResultActions") as HBoxContainer
	_check(result_actions != null and not result_actions.visible, "Failure result allows leaving before salvage confirmation")
	result_panel.show_summary({"outcome": "Failed", "settlement": {"outcome": &"failure", "requires_salvage_selection": false, "finalized": true}})
	await _frames(2)
	_check(not result_panel.requires_salvage_confirmation(), "Failure selector remains after settlement confirmation")
	_check(result_actions != null and result_actions.visible, "Final result does not restore navigation actions")
	result_panel.queue_free()
	await _frames(2)


func _check_collapse_contract(shell: Control) -> void:
	var parchment := shell.get("parchment_group") as Control
	shell.call("set_parchment_collapsed", true, false)
	_check(parchment != null and parchment.position == Vector2(0, -706), "Collapsed parchment did not fully clear the environment")
	_check((shell.get_node("BackgroundRoot/DeployPrepSceneCleanPlate") as CanvasItem).visible, "Collapse hides the exploration background")
	shell.call("set_parchment_collapsed", false, false)
	_check(parchment != null and parchment.position == Vector2.ZERO, "Parchment did not restore to its layout contract")


func _check_motion_contract(shell: Control) -> void:
	var frames := shell.get("character_frames") as Array
	_check(frames.size() == 8, "Character motion must load eight source frames")
	var unique_paths := {}
	for frame in frames:
		if frame is Texture2D:
			var texture := frame as Texture2D
			var identity := texture.resource_path if not texture.resource_path.is_empty() else texture.resource_name
			unique_paths[identity] = true
	_check(unique_paths.size() == 8, "Character motion frames are not resource-distinct")
	_check((shell.get("ambient_animations") as Array).size() == 8, "Expected eight ambient frame animations")
	_check((shell.get("ambient_particles") as Array).size() == 2, "Expected two ambient particle fields")
	var observed_frames := {}
	var observed_sway := false
	var character := shell.get("character_texture") as TextureRect
	for _index in range(48):
		shell.call("_process", 0.36)
		if character != null and character.texture != null:
			var identity := character.texture.resource_path if not character.texture.resource_path.is_empty() else character.texture.resource_name
			observed_frames[identity] = true
		var summary_root := shell.get_node_or_null("SideStatusRoot") as Control
		if summary_root != null and summary_root.position != Vector2.ZERO:
			observed_sway = true
	_check(observed_frames.size() == 8, "Character cadence did not expose all eight distinct frames")
	_check(observed_sway, "Hanging summary board did not produce subtle sway")


func _representative_snapshot(run_active: bool) -> Dictionary:
	var equipment_a := M7ContentCatalogScript.item_definition("eq_goggles")
	equipment_a["instance_id"] = "i2_eq_goggles"
	var equipment_b := M7ContentCatalogScript.item_definition("eq_insulated_sleeve")
	equipment_b["instance_id"] = "i2_eq_sleeve"
	var consumable_a := M7ContentCatalogScript.item_definition("con_ration")
	consumable_a["instance_id"] = "i2_con_ration_a"
	var consumable_b := M7ContentCatalogScript.item_definition("con_ration")
	consumable_b["instance_id"] = "i2_con_ration_b"
	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "i2_collectible"
	var unlocked: Array[String] = []
	for definition in M7ContentCatalogScript.map_definitions():
		unlocked.append(str(definition.get("id", "")))
	return {
		"run_active": run_active,
		"meta_progress_summary": {
			"profile_id": "i2_runtime",
			"profile_level": 5,
			"profile_exp": 500,
			"permit_level": 2,
			"protocol_difficulty": 5,
			"gold": 500,
			"unlocked_map_ids": unlocked,
			"warehouse_items": [equipment_a, equipment_b, consumable_a, consumable_b, collectible],
			"warehouse_items_count": 5,
			"completed_research_ids": [],
			"talent_flags": [],
		},
	}


func _find_card_view(shell: Control, card_id: StringName) -> Control:
	for raw_view in shell.get("card_views") as Array:
		var view := raw_view as Control
		if view != null and StringName(view.get("card_id")) == card_id:
			return view
	return null


func _find_selection_row(shell: Control, card_id: StringName) -> Dictionary:
	for raw_row in (shell.get("current_model") as Dictionary).get("selection_rows", []) as Array:
		var row := raw_row as Dictionary
		if StringName(row.get("id", &"")) == card_id:
			return row
	return {}


func _config(shell: Control) -> Dictionary:
	return ((shell.get("current_model") as Dictionary).get("config", {}) as Dictionary).duplicate(true)


func _sorted_key_strings(dictionary: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in dictionary.keys():
		result.append(String(key))
	result.sort()
	return result


func _string_name_array(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for entry in value as Array:
			result.append(StringName(entry))
	return result


func _cancel_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	return event


func _cancel_echo_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	event.echo = true
	return event


func _on_route_intent(intent: Dictionary) -> void:
	route_intents.append(intent.duplicate(true))


func _on_start_intent(intent: Dictionary) -> void:
	start_intents.append(intent.duplicate(true))


func _on_meta_action(action: Dictionary) -> void:
	meta_actions.append(action.duplicate(true))


func _check_texture_size(parent: Node, path: String, expected: Vector2) -> void:
	var node := parent.get_node_or_null(path) as TextureRect
	if node == null or node.texture == null:
		failures.append("Texture is absent: " + path)
		return
	_check(node.texture.get_size() == expected, "Texture size mismatch for %s: %s" % [path, node.texture.get_size()])


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("ART22_DEPLOY_PREP_RUNTIME=PASS tabs=5 map_page=single map_scales=3 map_difficulties=2,3,3 exact_maps=8 split=selection_detail explicit_actions=local,meta summary=overview,config,effect,objective card_height=76 active_run=locked input=focus,escape,reduced_motion")
		quit(0)
		return
	for failure in failures:
		push_error("ART22 runtime failure: " + failure)
	print("ART22_DEPLOY_PREP_RUNTIME=FAIL count=%d" % failures.size())
	quit(1)
