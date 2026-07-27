extends SceneTree

const ItemCatalog := preload("res://scripts/core/content/m3_item_catalog.gd")
const ItemRarityDescriptor := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const DeployPrepModel := preload("res://scripts/ui/deploy_prep/deploy_prep_model.gd")
const DeployPrepCardView := preload("res://scripts/ui/deploy_prep/deploy_prep_card_view.gd")
const LootResultPanel := preload("res://scripts/ui/loot_result/loot_result_panel.gd")
const WorldContextPopup := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")

var failures: Array[String] = []
var pickup_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_descriptor_domain()
	_check_aliases()
	_check_formal_catalog()
	await _check_deploy_consumers()
	await _check_loot_result_consumer()
	await _check_world_popup_consumer()
	_finish()


func _check_descriptor_domain() -> void:
	var expected := [
		[&"tier_1", "普通", "T1", 1],
		[&"tier_2", "优良", "T2", 2],
		[&"tier_3", "稀有", "T3", 3],
		[&"tier_4", "珍贵", "T4", 4],
		[&"tier_5", "传奇", "T5", 5],
		[&"tier_6", "秘藏", "T6", 6],
	]
	var colors: Dictionary = {}
	var borders: Dictionary = {}
	for row in expected:
		var descriptor: Dictionary = ItemRarityDescriptor.describe(row[0])
		_check(StringName(descriptor.get("normalized_key", &"")) == row[0], "normalized key drifted for %s" % row[0])
		_check(String(descriptor.get("label", "")) == row[1], "label drifted for %s" % row[0])
		_check(String(descriptor.get("badge", "")) == row[2], "non-color badge drifted for %s" % row[0])
		_check(int(descriptor.get("tier", 0)) == row[3], "numeric tier drifted for %s" % row[0])
		_check(String(descriptor.get("display_text", "")).contains(row[1]) and String(descriptor.get("display_text", "")).contains(row[2]), "display text lacks badge + label for %s" % row[0])
		_check(bool(descriptor.get("known", false)) and not bool(descriptor.get("locked", true)), "formal tier is not known/unlocked: %s" % row[0])
		_check(not descriptor.has("ordinary_drop_allowed"), "presentation descriptor exposed drop policy for %s" % row[0])
		_check(descriptor.get("color") is Color, "descriptor color missing for %s" % row[0])
		_check(String(descriptor.get("border_token", "")).begins_with("rarity.border."), "border token missing for %s" % row[0])
		_check(String(descriptor.get("shape_token", "")).begins_with("rarity.shape."), "shape token missing for %s" % row[0])
		colors[descriptor.get("color")] = true
		borders[descriptor.get("border_token")] = true
	_check(colors.size() == 6, "T1-T6 colors are not individually stable")
	_check(borders.size() == 6, "T1-T6 border tokens are not individually stable")

	var unique: Dictionary = ItemRarityDescriptor.describe(&"unique")
	_check(StringName(unique.get("normalized_key", &"")) == &"unique", "unique was not normalized")
	_check(bool(unique.get("known", false)) and bool(unique.get("locked", false)), "unique is not an explicit locked concept")
	_check(not unique.has("ordinary_drop_allowed"), "unique descriptor exposed drop policy")
	_check(String(unique.get("display_text", "")).contains("唯一") and String(unique.get("display_text", "")).contains("锁定") and String(unique.get("display_text", "")).contains("◆"), "unique lacks label, lock state, or non-color badge")

	var unknown: Dictionary = ItemRarityDescriptor.describe(&"not_a_rarity")
	_check(StringName(unknown.get("normalized_key", &"")) == &"unknown", "unknown input did not fail closed")
	_check(not bool(unknown.get("known", true)) and not unknown.has("ordinary_drop_allowed"), "unknown input exposed content policy")
	_check(String(unknown.get("display_text", "")) == "[?] 未鉴定", "unknown player text drifted")


func _check_aliases() -> void:
	var aliases := {
		&"tier_1": ["tier_1", "tier1", "T1", "common", "COMMON", "普通", 1],
		&"tier_2": ["tier_2", "tier2", "T2", "uncommon", "UNCOMMON", "good", "GOOD", "优良", 2],
		&"tier_3": ["tier_3", "tier3", "T3", "rare", "RARE", "稀有", 3],
		&"tier_4": ["tier_4", "tier4", "T4", "epic", "EPIC", "珍贵", 4],
		&"tier_5": ["tier_5", "tier5", "T5", "legendary", "LEGENDARY", "传奇", 5],
		&"tier_6": ["tier_6", "tier6", "T6", "mythic", "MYTHIC", "秘藏", "神话", 6],
		&"unique": ["unique", "唯一"],
	}
	for expected_key in aliases:
		for alias in aliases[expected_key]:
			_check(ItemRarityDescriptor.normalize(alias) == expected_key, "alias %s did not normalize to %s" % [alias, expected_key])
	for unauthorized_alias in ["unique_locked", "locked_unique", "locked-unique"]:
		_check(ItemRarityDescriptor.normalize(unauthorized_alias) == &"unknown", "unauthorized unique alias remained accepted: %s" % unauthorized_alias)


func _check_formal_catalog() -> void:
	var items: Array[Dictionary] = ItemCatalog.all_items()
	var before := items.duplicate(true)
	var counts := {
		&"tier_1": 0,
		&"tier_2": 0,
		&"tier_3": 0,
		&"tier_4": 0,
		&"tier_5": 0,
		&"tier_6": 0,
	}
	_check(items.size() == 43, "formal item count drifted from 43")
	for item in items:
		var descriptor: Dictionary = ItemRarityDescriptor.describe_item(item)
		var key := StringName(descriptor.get("normalized_key", &"unknown"))
		_check(counts.has(key), "formal item has an unmapped rarity: %s=%s" % [item.get("item_id", ""), item.get("rarity", "")])
		if counts.has(key):
			counts[key] = int(counts[key]) + 1
		_check(not bool(descriptor.get("locked", false)), "formal item was projected as a locked rarity: %s" % item.get("item_id", ""))
		_check(not descriptor.has("ordinary_drop_allowed"), "descriptor overrode content policy for %s" % item.get("item_id", ""))
		_check(not String(descriptor.get("display_text", "")).contains("tier_"), "formal item leaked a raw rarity key: %s" % item.get("item_id", ""))
	_check(items == before, "presentation descriptor mutated the formal item catalog")
	var expected_counts := {
		&"tier_1": 7,
		&"tier_2": 10,
		&"tier_3": 12,
		&"tier_4": 6,
		&"tier_5": 4,
		&"tier_6": 4,
	}
	_check(counts == expected_counts, "formal rarity distribution drifted: %s" % counts)
	var unique_items: Array[Dictionary] = ItemCatalog.unique_concept_items()
	_check(unique_items.size() == 1, "locked unique concept fixture drifted")
	if not unique_items.is_empty():
		var unique_descriptor: Dictionary = ItemRarityDescriptor.describe_item(unique_items[0])
		_check(bool(unique_descriptor.get("locked", false)) and not unique_descriptor.has("ordinary_drop_allowed"), "catalog unique concept descriptor exposed content policy")
		_check(not bool(unique_items[0].get("ordinary_drop_allowed", true)), "catalog unique concept authority no longer blocks ordinary drops")


func _check_deploy_consumers() -> void:
	var tier_5 := ItemCatalog.collectible_items()[16].duplicate(true)
	tier_5["instance_id"] = "i2_rarity_t5"
	var tier_6 := ItemCatalog.collectible_items()[20].duplicate(true)
	tier_6["instance_id"] = "i2_rarity_t6"
	var model: Dictionary = DeployPrepModel.build({
		"run_active": false,
		"meta_progress_summary": {
			"gold": 100,
			"warehouse_items": [tier_5, tier_6],
			"warehouse_items_count": 2,
		},
	})
	model = DeployPrepModel.model_with_tab(model, &"warehouse")
	var rows: Array = model.get("selection_rows", [])
	for item in [tier_5, tier_6]:
		var row := _row_for_item(rows, String(item.get("item_id", "")))
		var descriptor: Dictionary = ItemRarityDescriptor.describe_item(item)
		_check(not row.is_empty(), "Deploy warehouse omitted %s" % item.get("item_id", ""))
		if row.is_empty():
			continue
		_check(StringName(row.get("rarity", &"")) == descriptor.get("normalized_key"), "Deploy did not normalize %s" % item.get("item_id", ""))
		_check(String(row.get("rarity_display_text", "")) == descriptor.get("display_text"), "Deploy display text drifted for %s" % item.get("item_id", ""))
		_check(String(row.get("summary", "")).contains(String(descriptor.get("badge", ""))) and String(row.get("summary", "")).contains(String(descriptor.get("label", ""))), "Deploy summary lacks badge + label for %s" % item.get("item_id", ""))
		var collectible_level := int(item.get("collectible_level", 0))
		_check(collectible_level > 0 and int(row.get("collectible_level", 0)) == collectible_level, "Deploy did not project the authoritative collectible level for %s" % item.get("item_id", ""))
		_check(String(row.get("summary", "")).contains("收藏 Lv.%d" % collectible_level), "Deploy summary omitted the collectible level for %s" % item.get("item_id", ""))
		_check(not String(row.get("summary", "")).contains("tier_"), "Deploy summary leaked raw rarity for %s" % item.get("item_id", ""))
		_check(row.get("rarity_border_token") == descriptor.get("border_token"), "Deploy border token drifted for %s" % item.get("item_id", ""))

	var tier_6_row := _row_for_item(rows, String(tier_6.get("item_id", "")))
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	var card: DeployPrepCardView = DeployPrepCardView.new()
	canvas.add_child(card)
	card.setup(tier_6_row, &"warehouse", true)
	await process_frame
	var chip := card.get_node_or_null("CardModeChipLabel") as Label
	var category_chip := card.get_node_or_null("CardCategoryChipLabel") as Label
	var edge := card.get_node_or_null("CardRarityEdge") as ColorRect
	var tier_6_descriptor: Dictionary = ItemRarityDescriptor.describe(&"tier_6")
	var tier_6_collectible_level := int(tier_6.get("collectible_level", 0))
	_check(chip != null and chip.text.contains("T6") and chip.text.contains("秘藏"), "Deploy card did not render the T6 non-color badge + label")
	_check(category_chip != null and category_chip.text == "藏品 Lv.%d" % tier_6_collectible_level, "Deploy card did not render the authoritative collectible level")
	_check(edge != null and edge.color == tier_6_descriptor.get("color"), "Deploy card did not consume the shared T6 color")
	_check(edge != null and edge.get_meta("rarity_border_token", &"") == tier_6_descriptor.get("border_token"), "Deploy card did not consume the shared T6 border token")
	canvas.queue_free()
	await _frames(2)


func _check_loot_result_consumer() -> void:
	var tier_6 := ItemCatalog.collectible_items()[20].duplicate(true)
	tier_6["instance_id"] = "i2_result_t6"
	var panel: LootResultPanel = LootResultPanel.new()
	root.add_child(panel)
	panel.build()
	panel.show_result("搜索完成", {"items": [tier_6]}, "")
	await _frames(2)
	var meta := panel.find_child("LootResultRarityMeta", true, false) as Label
	var edge := panel.find_child("LootResultRarityEdge", true, false) as ColorRect
	var card := panel.find_child("LootResultItemCard", true, false) as PanelContainer
	var descriptor: Dictionary = ItemRarityDescriptor.describe_item(tier_6)
	var collectible_level := int(tier_6.get("collectible_level", 0))
	_check(meta != null and meta.text.contains("[T6] 秘藏"), "Loot result downgraded or omitted T6")
	_check(collectible_level > 0 and meta != null and meta.text.contains("收藏等级 %d" % collectible_level), "Loot result omitted the authoritative collectible level")
	_check(meta != null and not meta.text.contains("tier_6"), "Loot result leaked raw tier_6")
	_check(edge != null and edge.color == descriptor.get("color"), "Loot result did not consume the shared T6 color")
	_check(edge != null and edge.get_meta("rarity_border_token", &"") == descriptor.get("border_token"), "Loot result did not consume the shared T6 border token")
	var card_style := card.get_theme_stylebox("panel") as StyleBoxTexture if card != null else null
	_check(card_style != null and card_style.texture != null and card_style.texture.resource_path.ends_with("item_row_normal.png"), "Loot result still turns high rarity into a full selected border")
	panel.queue_free()
	await _frames(2)


func _check_world_popup_consumer() -> void:
	var tier_6 := ItemCatalog.collectible_items()[20].duplicate(true)
	tier_6["instance_id"] = "i2_world_t6"
	var popup: G41WorldContextPopup = WorldContextPopup.new()
	root.add_child(popup)
	await process_frame
	popup.apply_context(_ground_context(tier_6))
	await _frames(2)
	var info := popup.find_child("ContextItemInfo", true, false) as Button
	var marker := popup.find_child("WorldContextItemRarityMarker", true, false) as ColorRect
	var descriptor: Dictionary = ItemRarityDescriptor.describe_item(tier_6)
	var collectible_level := int(tier_6.get("collectible_level", 0))
	_check(info != null and info.text.contains("[T6] 秘藏"), "World popup downgraded or omitted T6")
	_check(collectible_level > 0 and info != null and info.text.contains("收藏等级 %d" % collectible_level), "World popup omitted the authoritative collectible level")
	_check(info != null and not info.text.contains("tier_6"), "World popup leaked raw tier_6")
	_check(info != null and info.get_meta("rarity_border_token", &"") == descriptor.get("border_token"), "World popup did not consume the shared T6 border token")
	_check(marker != null and marker.color == descriptor.get("color"), "World popup independent rarity marker color drifted")
	_check(marker != null and marker.mouse_filter == Control.MOUSE_FILTER_IGNORE, "World popup rarity marker intercepted item input")
	var normal_style := info.get_theme_stylebox("normal") as StyleBoxFlat if info != null else null
	_check(normal_style != null and not normal_style.border_color.is_equal_approx(Color(descriptor.get("color"))), "World popup still paints the full item border with rarity color")
	popup.show_command_result({"ok": true, "accepted": true, "message": "Picked up floor item: raw_internal_item_id", "reason": "操作完成"})
	var status := popup.find_child("ContextStatus", true, false) as Label
	_check(status != null and not status.visible and status.text.is_empty(), "World popup retained redundant success command copy")
	popup.show_command_result({"ok": false, "accepted": false, "reason_code": "blocked_capacity", "message": "Raw English failure"})
	_check(status != null and status.visible and status.text == "背包容量不足。", "World popup did not map failure through player-facing reason authority")
	_check(status == null or (not status.text.contains("Raw English") and not status.text.contains("操作完成")), "World popup leaked raw command copy")

	pickup_count = 0
	popup.pickup_requested.connect(func(_instance_id: String) -> void: pickup_count += 1)
	var unique := ItemCatalog.unique_concept_items()[0].duplicate(true)
	unique["instance_id"] = "i2_world_unique_locked"
	popup.apply_context(_ground_context(unique))
	await _frames(2)
	info = popup.find_child("ContextItemInfo", true, false) as Button
	var unique_action := popup.find_child("ContextPickupButton", true, false) as Button
	_check(info != null and info.text.contains("◆") and info.text.contains("唯一") and info.text.contains("锁定"), "World popup did not present unique as a locked concept")
	_check(unique_action != null and not unique_action.disabled, "rarity descriptor overrode explicit action authority")
	_check(popup.activate_primary(), "explicitly allowed action was blocked by rarity presentation")
	_check(pickup_count == 1, "explicit unique fixture action did not emit exactly once")
	var blocked_unique := unique.duplicate(true)
	blocked_unique["pickup_allowed"] = false
	blocked_unique["pickup_blocked_reason"] = "内容规则不允许拾取。"
	popup.apply_context(_ground_context(blocked_unique))
	await _frames(2)
	var blocked_action := popup.find_child("ContextBlockedButton", true, false) as Button
	_check(blocked_action != null and blocked_action.disabled, "explicit action projection was ignored")
	_check(not popup.activate_primary(), "explicit blocked action was accepted")
	_check(pickup_count == 1, "viewing/focusing blocked item emitted a pickup request")
	popup.queue_free()
	await _frames(2)


func _ground_context(item: Dictionary) -> Dictionary:
	return {
		"interaction_kind": &"ground_loot",
		"world_pos": Vector2(640, 360),
		"room_bounds": Rect2(240, 60, 800, 600),
		"items": [item],
		"inventory_items": [],
		"backpack_remaining": 10,
	}


func _row_for_item(rows: Array, item_id: String) -> Dictionary:
	for raw_row in rows:
		if raw_row is Dictionary and String((raw_row as Dictionary).get("item_id", "")) == item_id:
			return (raw_row as Dictionary).duplicate(true)
	return {}


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("I2_ITEM_RARITY_PRESENTATION=PASS formal_items=43 tiers=6 aliases=common,uncommon,rare,epic,legendary,mythic consumers=deploy,result,world unique=locked collectible_level=deploy,result,world rarity_marker=independent")
		quit(0)
		return
	for failure in failures:
		push_error("I2 item rarity presentation failure: " + failure)
	print("I2_ITEM_RARITY_PRESENTATION=FAIL failures=%d" % failures.size())
	quit(1)
