extends SceneTree

const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployPrepModelScript := preload("res://scripts/ui/deploy_prep/deploy_prep_model.gd")
const DeployPrepShellScript := preload("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")

var failures: Array[String] = []
var emitted_actions: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_projection_and_draft()
	await _test_player_controls()
	if failures.is_empty():
		print("I4_DEPLOY_QUANTITY_UI=PASS card=two_line context=single quantity=minus_value_plus carry=exact purchase=draft sale=batch")
		quit(0)
		return
	for failure in failures:
		printerr("I4_DEPLOY_QUANTITY_UI=FAIL:%s" % failure)
	quit(1)


func _test_projection_and_draft() -> void:
	var model := DeployPrepModelScript.build(_snapshot())
	model = DeployPrepModelScript.model_with_tab(model, DeployTabModelScript.TAB_WAREHOUSE)
	var ration := _row_by_item(model, "con_ration")
	_expect(not ration.is_empty(), "grouped ration row is missing")
	_expect((ration.get("instance_ids", []) as Array) == ["ration_a", "ration_b"], "compatible ration instances did not aggregate deterministically")
	_expect(int(ration.get("owned_count", 0)) == 2 and int(ration.get("deployed_count", -1)) == 0, "carry projection count is wrong")
	_expect(StringName(ration.get("quantity_mode", &"")) == &"carry", "warehouse carry card uses the wrong quantity meaning")
	_expect(not str(ration.get("summary", "")).contains("T1"), "player card still exposes a T code")
	var config: Dictionary = model.get("config", {})
	var first := DeployConfigScript.adjust_warehouse_stack_quantity(config, ration.get("instance_ids", []), 1)
	var first_config: Dictionary = first.get("config", {})
	var second := DeployConfigScript.adjust_warehouse_stack_quantity(first_config, ration.get("instance_ids", []), 1)
	var second_config: Dictionary = second.get("config", {})
	_expect(second_config.get("selected_consumable_ids", []) == ["ration_a", "ration_b"], "carry plus did not select stable exact instances")
	var removed := DeployConfigScript.adjust_warehouse_stack_quantity(second_config, ration.get("instance_ids", []), -1)
	_expect((removed.get("config", {}) as Dictionary).get("selected_consumable_ids", []) == ["ration_a"], "carry minus did not remove exactly one deterministic instance")

	model = DeployPrepModelScript.model_with_tab(model, DeployTabModelScript.TAB_CLAIM)
	var purchase_config: Dictionary = model.get("config", {})
	for _index in range(2):
		purchase_config = (DeployConfigScript.adjust_purchase_quantity(purchase_config, "con_ration", 1).get("config", {}) as Dictionary)
	model = DeployPrepModelScript.model_with_config(model, purchase_config, &"m7_shop_con_ration")
	var purchase := _row_by_id(model, &"m7_shop_con_ration")
	_expect(StringName(purchase.get("quantity_mode", &"")) == &"purchase", "shop card uses the wrong quantity meaning")
	_expect(int(purchase.get("purchase_quantity", 0)) == 3, "purchase stepper draft did not persist")
	_expect(int(purchase.get("total_price", 0)) == 36, "purchase draft total is wrong")
	var action_result := DeployConfigScript.apply_card_action(purchase_config, DeployTabModelScript.TAB_CLAIM, &"m7_shop_con_ration")
	_expect(int((action_result.get("meta_action", {}) as Dictionary).get("quantity", 0)) == 3, "purchase confirmation lost its quantity")


func _test_player_controls() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	var shell := DeployPrepShellScript.new() as Control
	shell.size = Vector2(1280, 720)
	canvas.add_child(shell)
	shell.meta_action_requested.connect(func(action: Dictionary) -> void:
		emitted_actions.append(action.duplicate(true))
	)
	shell.build()
	shell.apply_snapshot(_snapshot())
	shell.show_tab(DeployTabModelScript.TAB_WAREHOUSE)
	await _wait_until(
		func() -> bool: return _card_by_item(shell, "con_ration") != null,
		"warehouse card construction"
	)
	var ration_card := _card_by_item(shell, "con_ration")
	_expect(ration_card != null, "ration card was not constructed")
	if ration_card != null:
		_expect(ration_card.get_node_or_null("CardCategoryChip") == null, "quantity item card still renders a third chip layer")
		var plus := ration_card.get("quantity_plus_button") as Button
		_expect(plus != null and plus.visible and not plus.disabled, "carry card lacks an enabled plus control")
		if plus != null and not plus.disabled:
			plus.emit_signal("pressed")
		await _wait_until(
			func() -> bool:
				return (shell.call("get_selected_instance_ids") as Dictionary).get("selected_consumable_ids", []) == ["ration_a"],
			"first exact carry selection"
		)
		ration_card = _card_by_item(shell, "con_ration")
		plus = ration_card.get("quantity_plus_button") as Button
		if plus != null and not plus.disabled:
			plus.emit_signal("pressed")
		await _wait_until(
			func() -> bool:
				return (shell.call("get_selected_instance_ids") as Dictionary).get("selected_consumable_ids", []) == ["ration_a", "ration_b"],
			"second exact carry selection"
		)
		ration_card = _card_by_item(shell, "con_ration")
		var quantity_label := ration_card.get("quantity_value_label") as Label
		_expect(quantity_label != null and quantity_label.text == "2/2", "carry card does not show carried/owned")

	var batch_entry := shell.get("warehouse_batch_entry_button") as Button
	if batch_entry != null and not batch_entry.disabled:
		batch_entry.emit_signal("pressed")
	await _wait_until(
		func() -> bool: return bool((shell.call("get_warehouse_batch_snapshot") as Dictionary).get("active", false)),
		"batch sale activation"
	)
	var collectible_card := _card_by_item(shell, "col_01")
	_expect(collectible_card != null, "grouped collectible card is missing")
	if collectible_card != null:
		var plus_sale := collectible_card.get("quantity_plus_button") as Button
		for target_count in range(1, 3):
			if plus_sale != null and not plus_sale.disabled:
				plus_sale.emit_signal("pressed")
			await _wait_until(
				func() -> bool:
					return int(
						(shell.call("get_warehouse_batch_snapshot") as Dictionary).get(
							"selected_count",
							0
						)
					) == target_count,
				"batch sale selection count %d" % target_count
			)
			collectible_card = _card_by_item(shell, "col_01")
			plus_sale = collectible_card.get("quantity_plus_button") as Button
	await _wait_until(
		func() -> bool: return int((shell.call("get_warehouse_batch_snapshot") as Dictionary).get("selected_count", 0)) == 2,
		"batch sale quantity selection"
	)
	var batch := shell.call("get_warehouse_batch_snapshot") as Dictionary
	_expect(batch.get("selected_instance_ids", []) == ["sale_a", "sale_b"], "sale quantity lost exact instance identity")
	_expect(int(batch.get("total_value", 0)) == 22, "sale quantity total is wrong")
	canvas.queue_free()


func _snapshot() -> Dictionary:
	return {
		"run_active": false,
		"meta_progress_summary": {
			"gold": 100,
			"profile_level": 9,
			"permit_level": 9,
			"protocol_difficulty": 5,
			"unlocked_map_ids": ["classic_7x7_simple"],
			"warehouse_items": [
				_item("con_ration", "ration_b"),
				_item("con_ration", "ration_a"),
				_item("col_01", "sale_b"),
				_item("col_01", "sale_a"),
			],
		},
	}


func _item(item_id: String, instance_id: String) -> Dictionary:
	var item := M7ContentCatalogScript.item_definition(item_id)
	item["instance_id"] = instance_id
	if item_id == "col_01":
		item["base_value"] = 11
	return item


func _row_by_item(model: Dictionary, item_id: String) -> Dictionary:
	for raw_row in model.get("selection_rows", []) as Array:
		var row := raw_row as Dictionary
		if str(row.get("item_id", "")) == item_id:
			return row.duplicate(true)
	return {}


func _row_by_id(model: Dictionary, card_id: StringName) -> Dictionary:
	for raw_row in model.get("selection_rows", []) as Array:
		var row := raw_row as Dictionary
		if StringName(row.get("id", &"")) == card_id:
			return row.duplicate(true)
	return {}


func _card_by_item(shell: Control, item_id: String) -> Control:
	for raw_view in shell.get("card_views") as Array:
		var view := raw_view as Control
		if view != null and str((view.get("card_data") as Dictionary).get("item_id", "")) == item_id:
			return view
	return null


func _wait_until(predicate: Callable, label: String, timeout_ms: int = 5000) -> void:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return
		await process_frame
	failures.append("timed out waiting for semantic state: %s" % label)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
