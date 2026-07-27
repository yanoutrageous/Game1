extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")

var failures: Array[String] = []
var page_change_count := 0
var last_page: StringName = &""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	_check(main_scene != null, "main.tscn could not be loaded")
	if main_scene == null:
		_finish()
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await _frames(12)

	var run_scene := main.get_node_or_null("RunScene")
	_check(run_scene != null, "main.tscn does not contain the real RunScene host")
	if run_scene == null:
		_finish()
		return

	var app_shell := run_scene.get("ui_shell") as Control
	_check(app_shell != null, "RunScene did not build AppShell")
	_check(app_shell != null and app_shell.name == "AppShell", "RunScene is not using the AppShell presentation host")
	if app_shell == null:
		_finish()
		return
	app_shell.connect("page_changed", _on_page_changed)

	var main_menu := app_shell.get_node_or_null("MainMenuShell") as Control
	var deploy_page := app_shell.get_node_or_null("DeployPrepShell") as Control
	_check(main_menu != null and main_menu.visible, "Actual startup route is not the main menu")
	_check(deploy_page != null, "Actual AppShell is missing DeployPrepShell")
	if main_menu == null or deploy_page == null:
		_finish()
		return

	var deploy_button := main_menu.get_node_or_null("PrimaryActionRoot/MainMenuEntry_deploy") as Button
	_check(deploy_button != null, "Main-menu exploration entry is missing")
	if deploy_button == null:
		_finish()
		return

	deploy_button.emit_signal("pressed")
	var playing: Dictionary = app_shell.call("get_navigation_transition_snapshot")
	_check(StringName(playing.get("state", &"")) == &"playing", "Deploy route did not enter coordinator PLAYING")
	_check(StringName(playing.get("profile_id", &"")) == &"enter_cave", "Deploy route did not use enter_cave")
	_check(StringName(run_scene.get("screen_state")) == &"main_menu", "Deploy route changed screen before presentation completion")
	_check(not deploy_page.visible and page_change_count == 0, "Deploy route committed before presentation completion")
	main_menu.call("_process", 1.2)
	await _frames(8)

	_check(StringName(run_scene.get("screen_state")) == &"deploy_shell", "Main-menu exploration entry did not reach deploy_shell")
	_check(deploy_page.visible, "DeployPrepShell is hidden after the actual main-menu route")
	_check(not main_menu.visible, "MainMenuShell remained visible over DeployPrepShell")
	var settled: Dictionary = app_shell.call("get_navigation_transition_snapshot")
	var last_result := settled.get("last_result", {}) as Dictionary
	_check(StringName(settled.get("state", &"")) == &"idle", "Deploy coordinator did not settle IDLE")
	_check(StringName(last_result.get("outcome", &"")) == &"committed" and int(last_result.get("commit_count", 0)) == 1, "Deploy route did not commit exactly once")
	_check(page_change_count == 1 and last_page == &"deploy_prep", "Deploy route emitted duplicate or false page changes")

	_check(deploy_page.get_node_or_null("BackgroundRoot/DeployPrepSceneCleanPlate") is TextureRect, "Actual deploy route is missing the ART22 clean plate")
	_check(deploy_page.get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployParchment") is TextureRect, "Actual deploy route is missing the ART22 parchment")
	_check(deploy_page.get_node_or_null("SideStatusRoot/DeploySummaryBoard") is TextureRect, "Actual deploy route is missing the ART22 hanging summary")
	_check(deploy_page.get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployMapSplitView") is Control, "Actual deploy route is missing the same-page map split")
	_check((deploy_page.get("filter_buttons") as Dictionary).is_empty(), "Actual map route regressed to region/filter staging")
	_check((deploy_page.get("card_views") as Array).is_empty(), "Actual map route regressed to generic map cards")
	_check_player_tab_labels(deploy_page)

	var model := deploy_page.get("current_model") as Dictionary
	var projection := model.get("map_projection", {}) as Dictionary
	_check(StringName(model.get("active_tab", &"")) == &"map", "Actual Deploy route does not land on the map tab")
	_check(StringName(projection.get("page_id", &"")) == &"deploy_prep" and StringName(projection.get("route_page_id", &"")) == &"deploy_prep", "Actual map route introduced an intermediate page")
	var scale_options := projection.get("scale_options", []) as Array
	var scale_ids: Array[StringName] = []
	for raw_scale in scale_options:
		scale_ids.append(StringName((raw_scale as Dictionary).get("scale_id", &"")))
	_check(
		scale_ids == [&"5x5", &"7x7", &"10x10", &"13x13"],
		"Actual Deploy route does not expose the tutorial map plus all three standard map scales"
	)
	var map_view := deploy_page.get("map_split_view") as Control
	_check(map_view != null and int((map_view.call("projection_snapshot") as Dictionary).get("difficulty_count", 0)) == 2, "Actual default scale does not expose its two difficulties")
	if map_view != null:
		var scale_13 := (map_view.get("scale_buttons") as Dictionary).get(&"13x13") as Button
		_check(scale_13 != null, "Actual route is missing the 13x13 scale")
		if scale_13 != null:
			scale_13.emit_signal("pressed")
			await _frames(2)
			_check((map_view.get("difficulty_buttons") as Dictionary).size() == 3, "Actual 13x13 scale does not expose three difficulties")
			_check(page_change_count == 1 and StringName(run_scene.get("screen_state")) == &"deploy_shell", "Map scale preview navigated away from the single Deploy page")

	_check_meta_transaction_production_chain(run_scene, app_shell, deploy_page)

	main.queue_free()
	await _frames(4)
	_finish()


func _check_player_tab_labels(deploy_page: Control) -> void:
	var expected := {
		&"map": "地图",
		&"warehouse": "仓库",
		&"claim": "申领",
		&"objective": "本局委托",
		&"loadout": "携带清单",
	}
	var buttons := deploy_page.get("tab_buttons") as Dictionary
	_check(buttons.size() == 5, "Actual deploy route does not expose five primary tabs")
	for tab_id in expected:
		var button := buttons.get(tab_id) as Button
		_check(button != null and button.text == str(expected[tab_id]), "Actual deploy route has the wrong player tab label: " + String(tab_id))


func _check_meta_transaction_production_chain(run_scene: Node, app_shell: Control, deploy_page: Control) -> void:
	var adapter = run_scene.get("meta_progress_adapter")
	var controller = run_scene.get("runtime_controller")
	_check(adapter != null and controller != null, "Production meta transaction authority is missing")
	if adapter == null or controller == null:
		return
	adapter.set_active_profile_path("user://tests/art22_deploy_main_route_transactions.json", "art22_deploy_main_route_transactions")
	adapter.clear()
	adapter.data["gold"] = 500
	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "art22_route_collectible"
	adapter.data["warehouse_items"].append(collectible)
	_check(adapter.save(), "Production transaction seed save failed")
	controller.bind_meta_progress_adapter(adapter)
	app_shell.call("apply_snapshot", run_scene.call("_shell_snapshot"))
	var draft_before := _draft_signature((deploy_page.get("current_model") as Dictionary).get("config", {}))
	var purchase_before: Dictionary = adapter.get_summary()
	var purchase_revision_before := int((app_shell.call("get_meta_result_delivery_snapshot") as Dictionary).get("current_snapshot_revision", -1))
	deploy_page.call("_submit_explicit_card_action", &"claim", &"m7_shop_con_ration", &"m7_shop_con_ration")
	var purchase_state := deploy_page.call("get_meta_transaction_snapshot") as Dictionary
	var purchase_result := purchase_state.get("last_result", {}) as Dictionary
	var purchase_after: Dictionary = adapter.get_summary()
	var purchase_delivery_snapshot := app_shell.call("get_meta_result_delivery_snapshot") as Dictionary
	var purchase_delivery := purchase_delivery_snapshot.get("last_delivery", {}) as Dictionary
	var purchase_price := int(M7ContentCatalogScript.shop_definition("con_ration").get("price", -1))
	_check(not bool(purchase_state.get("pending", true)), "Production purchase remained pending after synchronous result")
	_check(bool(purchase_result.get("ok", false)) and StringName(purchase_result.get("status", &"")) == &"purchased", "Production purchase result was not routed back to Deploy")
	_check(StringName(purchase_result.get("source_page", &"")) == &"deploy_prep" and str(purchase_result.get("request_id", "")).begins_with("deploy:"), "Production purchase lost source/request correlation")
	_check(int(purchase_after.get("gold", -1)) == int(purchase_before.get("gold", 0)) - purchase_price, "Production purchase did not apply the exact catalog price")
	_check(_instance_ids(purchase_after.get("warehouse_items", [])).size() == _instance_ids(purchase_before.get("warehouse_items", [])).size() + 1, "Production purchase did not add exactly one instance")
	_check(_draft_signature((deploy_page.get("current_model") as Dictionary).get("config", {})) == draft_before, "Production purchase refresh lost the Deploy draft")
	_check(str((deploy_page.get("current_model") as Dictionary).get("action_message", "")).contains("购买成功"), "Production snapshot refresh overwrote the purchase feedback")
	_check(bool(purchase_delivery.get("accepted", false)) and str(purchase_delivery.get("request_id", "")) == str(purchase_result.get("request_id", "")), "Production purchase delivery trace lost the matching result")
	_check(int(purchase_delivery_snapshot.get("current_snapshot_revision", -1)) == purchase_revision_before + 1, "Production purchase did not refresh one authoritative snapshot")
	_check(int(purchase_delivery.get("snapshot_revision", -1)) == int(purchase_delivery_snapshot.get("current_snapshot_revision", -2)) and int(purchase_delivery.get("page_snapshot_revision", -1)) == int(purchase_delivery_snapshot.get("current_snapshot_revision", -2)), "Production purchase result was delivered before its authoritative snapshot")

	var sale_before: Dictionary = adapter.get_summary()
	var sale_revision_before := int((app_shell.call("get_meta_result_delivery_snapshot") as Dictionary).get("current_snapshot_revision", -1))
	deploy_page.call("_submit_explicit_card_action", &"warehouse", &"m3r_art22_route_collectible", &"m3r_art22_route_collectible")
	deploy_page.call("_submit_explicit_card_action", &"warehouse", &"m3r_art22_route_collectible", &"m3r_art22_route_collectible")
	var sale_state := deploy_page.call("get_meta_transaction_snapshot") as Dictionary
	var sale_result := sale_state.get("last_result", {}) as Dictionary
	var sale_after: Dictionary = adapter.get_summary()
	var sale_delivery_snapshot := app_shell.call("get_meta_result_delivery_snapshot") as Dictionary
	var sale_delivery := sale_delivery_snapshot.get("last_delivery", {}) as Dictionary
	var sale_value := int(collectible.get("base_value", -1))
	_check(not bool(sale_state.get("pending", true)), "Production sale remained pending after synchronous result")
	_check(bool(sale_result.get("ok", false)) and StringName(sale_result.get("status", &"")) == &"sold", "Production sale result was not routed back to Deploy")
	_check(StringName(sale_result.get("source_page", &"")) == &"deploy_prep" and str(sale_result.get("target_id", "")) == "art22_route_collectible", "Production sale lost exact instance correlation")
	_check(int(sale_after.get("gold", -1)) == int(sale_before.get("gold", 0)) + sale_value, "Production sale did not apply the exact collectible value")
	_check(not _instance_ids(sale_after.get("warehouse_items", [])).has("art22_route_collectible"), "Production sale did not remove the exact instance")
	_check(_draft_signature((deploy_page.get("current_model") as Dictionary).get("config", {})) == draft_before, "Production sale refresh lost the Deploy draft")
	_check(str((deploy_page.get("current_model") as Dictionary).get("action_message", "")).contains("%d 金币" % sale_value), "Production snapshot refresh overwrote the authoritative sale feedback")
	_check(bool(sale_delivery.get("accepted", false)) and str(sale_delivery.get("request_id", "")) == str(sale_result.get("request_id", "")), "Production sale delivery trace lost the matching result")
	_check(int(sale_delivery_snapshot.get("current_snapshot_revision", -1)) == sale_revision_before + 1, "Production sale did not refresh one authoritative snapshot")
	_check(int(sale_delivery.get("snapshot_revision", -1)) == int(sale_delivery_snapshot.get("current_snapshot_revision", -2)) and int(sale_delivery.get("page_snapshot_revision", -1)) == int(sale_delivery_snapshot.get("current_snapshot_revision", -2)), "Production sale result was delivered before its authoritative snapshot")
	adapter.clear()


func _draft_signature(config: Dictionary) -> Dictionary:
	return {
		"map_config_id": str(config.get("map_config_id", "")),
		"selected_objective_id": str(config.get("selected_objective_id", "")),
		"selected_equipment_ids": _sorted_strings(config.get("selected_equipment_ids", [])),
		"selected_consumable_ids": _sorted_strings(config.get("selected_consumable_ids", [])),
	}


func _instance_ids(raw_items: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_items is Array:
		for raw_item in raw_items as Array:
			if raw_item is Dictionary:
				result.append(str((raw_item as Dictionary).get("instance_id", "")))
	result.sort()
	return result


func _sorted_strings(raw_values: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_values is Array:
		for raw_value in raw_values as Array:
			result.append(str(raw_value))
	result.sort()
	return result


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _on_page_changed(page_id: StringName, _payload: Dictionary) -> void:
	page_change_count += 1
	last_page = page_id


func _finish() -> void:
	if failures.is_empty():
		print("ART22_DEPLOY_PREP_MAIN_ROUTE=PASS host=main.tscn route=main_menu_to_deploy commit=once map_page=single scales=4 tutorial=same_page meta=purchase,sell")
		quit(0)
		return
	for failure in failures:
		push_error("ART22 main-route failure: " + failure)
	print("ART22_DEPLOY_PREP_MAIN_ROUTE=FAIL count=%d" % failures.size())
	quit(1)
