extends SceneTree

const ItemCatalog := preload("res://scripts/core/content/m3_item_catalog.gd")
const RunAssetLedgerScript := preload("res://scripts/core/run/run_asset_ledger.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const RunRuleServiceScript := preload("res://scripts/core/run/run_rule_service.gd")
const ItemRarityDescriptorScript := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_catalog_to_ledger_to_view()
	_check_legacy_aliases()
	_check_carry_in_settlement_round_trip()
	_check_unique_gate_uses_normalized_rarity()
	_check_presentation_does_not_own_content_policy()
	_check_combat_flee_rarity_candidates()
	_finish()


func _check_catalog_to_ledger_to_view() -> void:
	var ledger = RunAssetLedgerScript.new()
	ledger.setup({"selected_equipment_items": [], "selected_consumable_items": []})
	var source_items: Array[Dictionary] = ItemCatalog.all_items()
	var source_copy := source_items.duplicate(true)
	var counts := {}
	for source in source_items:
		var instance: Dictionary = ledger.create_item_instance(source, RunAssetLedgerScript.LOCATION_INVENTORY)
		var expected := ItemRarityDescriptorScript.normalize(source.get("rarity", &"unknown"))
		var actual := StringName(instance.get("rarity", &""))
		_check(actual == expected, "ledger changed %s rarity %s -> %s" % [source.get("item_id", ""), expected, actual])
		var descriptor: Dictionary = ItemRarityDescriptorScript.describe_item(instance)
		_check(descriptor.get("normalized_key") == expected, "view descriptor drifted after ledger for %s" % source.get("item_id", ""))
		_check(not String(descriptor.get("display_text", "")).contains("tier_"), "raw rarity leaked after ledger for %s" % source.get("item_id", ""))
		counts[actual] = int(counts.get(actual, 0)) + 1
	_check(source_items == source_copy, "ledger/view round trip mutated the formal catalog")
	_check(counts == {&"tier_1": 7, &"tier_2": 10, &"tier_3": 12, &"tier_4": 6, &"tier_5": 4, &"tier_6": 4}, "ledger rarity distribution drifted: %s" % counts)


func _check_legacy_aliases() -> void:
	var aliases := {
		&"tier_1": [&"tier_1", &"common"],
		&"tier_2": [&"tier_2", &"uncommon", &"good"],
		&"tier_3": [&"tier_3", &"rare"],
		&"tier_4": [&"tier_4", &"epic"],
		&"tier_5": [&"tier_5", &"legendary"],
		&"tier_6": [&"tier_6", &"mythic"],
		&"unique": [&"unique"],
	}
	var ledger = RunAssetLedgerScript.new()
	ledger.setup({"selected_equipment_items": [], "selected_consumable_items": []})
	for expected in aliases:
		for alias in aliases[expected]:
			var instance: Dictionary = ledger.create_item_instance(_fixture_item(alias), RunAssetLedgerScript.LOCATION_INVENTORY)
			_check(StringName(instance.get("rarity", &"")) == expected, "ledger alias %s did not converge to %s" % [alias, expected])
	var unknown: Dictionary = ledger.create_item_instance(_fixture_item(&"unexpected_rarity"), RunAssetLedgerScript.LOCATION_INVENTORY)
	_check(StringName(unknown.get("rarity", &"")) == &"tier_1", "unknown rarity no longer uses the compatible T1 fallback")


func _check_carry_in_settlement_round_trip() -> void:
	var tier_2 := _first_catalog_item(&"tier_2", true)
	var tier_6 := _first_catalog_item(&"tier_6", true)
	_check(not tier_2.is_empty() and not tier_6.is_empty(), "catalog lacks non-consumable T2/T6 carry fixtures")
	if tier_2.is_empty() or tier_6.is_empty():
		return
	tier_2["instance_id"] = "i2_roundtrip_t2"
	tier_6["instance_id"] = "i2_roundtrip_t6"
	var ledger = RunAssetLedgerScript.new()
	ledger.setup({"selected_equipment_items": [tier_2, tier_6], "selected_consumable_items": []})
	var settlement: Dictionary = ledger.settle_success()
	var warehouse: Array = settlement.get("warehouse_items", [])
	_check(_rarity_for_instance(warehouse, "i2_roundtrip_t2") == &"tier_2", "T2 carry-in degraded during success settlement")
	_check(_rarity_for_instance(warehouse, "i2_roundtrip_t6") == &"tier_6", "T6 carry-in degraded during success settlement")
	var adapter = MetaProgressAdapterScript.new()
	for raw_item in warehouse:
		if not (raw_item is Dictionary):
			continue
		var item: Dictionary = raw_item
		var minimal: Dictionary = adapter.call("_minimal_item_record", item)
		_check(StringName(minimal.get("rarity", &"")) == StringName(item.get("rarity", &"")), "meta minimal record degraded %s" % item.get("instance_id", ""))


func _check_unique_gate_uses_normalized_rarity() -> void:
	var legacy_unique := _fixture_item(&"unique")
	legacy_unique.erase("is_unique")
	legacy_unique["unique_drop_allowed"] = false
	var ledger = RunAssetLedgerScript.new()
	ledger.setup({"selected_equipment_items": [], "selected_consumable_items": []})
	var result: Dictionary = ledger.add_reward_items([legacy_unique], RunAssetLedgerScript.LOCATION_ROOM_FLOOR, Vector2i.ZERO, "i2_roundtrip")
	_check((result.get("ground_items", []) as Array).is_empty(), "legacy rarity=unique bypassed the ordinary reward gate")
	_check((result.get("blocked_reasons", []) as Array).has("unique_not_allowed_in_ordinary_drop"), "unique rejection reason drifted")


func _check_presentation_does_not_own_content_policy() -> void:
	for value in [&"tier_1", &"tier_6", &"unique", &"unknown"]:
		var descriptor: Dictionary = ItemRarityDescriptorScript.describe(value)
		for forbidden in ["ordinary_drop_allowed", "pickup_allowed", "can_sell", "can_store"]:
			_check(not descriptor.has(forbidden), "presentation descriptor exposed domain field %s for %s" % [forbidden, value])
	var receipt := _item_by_id(ItemCatalog.all_items(), "sp_trader_receipt")
	_check(not receipt.is_empty() and not bool(receipt.get("ordinary_drop_allowed", true)), "formal virtual receipt policy fixture drifted")
	_check(not ItemRarityDescriptorScript.describe_item(receipt).has("ordinary_drop_allowed"), "descriptor overrode virtual receipt drop policy")


func _check_combat_flee_rarity_candidates() -> void:
	var context = RunContextScript.new()
	context.start_tutorial_run()
	context.seed_value = 0
	context.asset_ledger.backpack_capacity = 64
	var flee_pos := Vector2i.ZERO
	var ids_by_tier := {}
	for tier_index in range(1, 7):
		var tier := StringName("tier_%d" % tier_index)
		var instance_id := _instance_id_with_successful_flee_roll(tier, context.seed_value, flee_pos)
		var item := _fixture_item(tier)
		item["instance_id"] = instance_id
		var add_result: Dictionary = context.asset_ledger.add_reward_items(
			[item],
			RunAssetLedgerScript.LOCATION_INVENTORY,
			flee_pos,
			"i2_flee_rarity_contract"
		)
		_check((add_result.get("inventory_items", []) as Array).size() == 1, "flee fixture %s did not enter inventory" % tier)
		ids_by_tier[tier] = instance_id

	var stored_items: Array[Dictionary] = context.asset_ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_INVENTORY)
	_check(stored_items.size() == 6, "flee rarity fixture inventory drifted before rule execution")
	for item in stored_items:
		var stored_tier := StringName(item.get("rarity", &""))
		_check(stored_tier in [&"tier_1", &"tier_2", &"tier_3", &"tier_4", &"tier_5", &"tier_6"], "ledger stored a non-canonical flee rarity: %s" % stored_tier)

	var result: Dictionary = RunRuleServiceScript.apply_combat_flee(context, flee_pos)
	_check(bool(result.get("ok", false)), "combat flee rarity contract was rejected")
	var dropped: Array = result.get("dropped_instance_ids", [])
	var tier_1_id := String(ids_by_tier.get(&"tier_1", ""))
	_check(dropped.size() == 1 and dropped.has(tier_1_id), "combat flee candidates were not limited to canonical T1: %s" % dropped)
	for tier_index in range(2, 7):
		var tier := StringName("tier_%d" % tier_index)
		var instance_id := String(ids_by_tier.get(tier, ""))
		_check(not dropped.has(instance_id), "%s entered combat-flee loss candidates after ledger normalization" % tier)
		_check(_location_for_instance(context.asset_ledger, instance_id) == RunAssetLedgerScript.LOCATION_INVENTORY, "%s moved despite being excluded from combat-flee candidates" % tier)
	_check(_location_for_instance(context.asset_ledger, tier_1_id) == RunAssetLedgerScript.LOCATION_ROOM_FLOOR, "canonical T1 did not execute its deterministic flee-loss effect")


func _instance_id_with_successful_flee_roll(tier: StringName, seed_value: int, pos: Vector2i) -> String:
	for suffix in range(10000):
		var instance_id := "i2_flee_%s_%d" % [String(tier), suffix]
		var roll := absi(seed_value * 31 + pos.x * 73856093 + pos.y * 19349663 + instance_id.hash()) % 100
		if roll < 25:
			return instance_id
	_check(false, "could not construct deterministic flee-roll fixture for %s" % tier)
	return "i2_flee_fixture_missing_%s" % tier


func _location_for_instance(ledger: Variant, instance_id: String) -> StringName:
	var item: Dictionary = ledger.item_instances.get(instance_id, {})
	return StringName(item.get("location_state", &"missing"))


func _fixture_item(rarity: StringName) -> Dictionary:
	return {
		"item_id": "i2_alias_%s" % rarity,
		"display_name": "品质往返夹具",
		"item_type": &"collectible",
		"rarity": rarity,
		"weight": 1,
		"base_value": 1,
		"can_store": true,
		"can_sell": true,
	}


func _first_catalog_item(rarity: StringName, non_consumable: bool) -> Dictionary:
	for item in ItemCatalog.all_items():
		if StringName(item.get("rarity", &"")) != rarity:
			continue
		if non_consumable and bool(item.get("can_consume", false)):
			continue
		return item.duplicate(true)
	return {}


func _item_by_id(items: Array[Dictionary], item_id: String) -> Dictionary:
	for item in items:
		if String(item.get("item_id", "")) == item_id:
			return item.duplicate(true)
	return {}


func _rarity_for_instance(items: Array, instance_id: String) -> StringName:
	for raw_item in items:
		if raw_item is Dictionary and String((raw_item as Dictionary).get("instance_id", "")) == instance_id:
			return StringName((raw_item as Dictionary).get("rarity", &""))
	return &""


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I2_ITEM_RARITY_AUTHORITY_ROUNDTRIP=PASS formal_items=43 canonical=tier_1..tier_6 aliases=good,uncommon settlement=preserved unique_gate=normalized presentation=read_only flee_candidates=t1_only")
		quit(0)
		return
	for failure in failures:
		push_error("I2 rarity authority round-trip failure: " + failure)
	print("I2_ITEM_RARITY_AUTHORITY_ROUNDTRIP=FAIL failures=%d" % failures.size())
	quit(1)
