extends RefCounted
class_name DeployPrepModel

const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")


static func build(snapshot: Dictionary = {}) -> Dictionary:
	var run_active := bool(snapshot.get("run_active", snapshot.get("has_active_run", false)))
	var meta_summary: Dictionary = snapshot.get("meta_progress_summary", {})
	var config := DeployConfigScript.with_active_run_preview(DeployConfigScript.default_config(1, meta_summary), run_active)
	var active_run_config: Dictionary = snapshot.get("run_start_config", {})
	if run_active and not active_run_config.is_empty():
		config = DeployConfigScript.with_active_run_config(config, active_run_config)
	var active_tab := DeployTabModelScript.DEFAULT_TAB
	var selected_filter := DeployTabModelScript.default_filter_for(active_tab)
	var selected_card := DeployTabModelScript.default_card_for(active_tab)
	return _build_model(config, run_active, active_tab, selected_filter, selected_card, false, "")


static func refresh_from_snapshot(model: Dictionary, snapshot: Dictionary = {}) -> Dictionary:
	if model.is_empty():
		return build(snapshot)
	var run_active := bool(snapshot.get("run_active", snapshot.get("has_active_run", false)))
	var config := DeployConfigScript.refresh_from_meta(_config_from(model), snapshot.get("meta_progress_summary", {}), run_active)
	var active_run_config: Dictionary = snapshot.get("run_start_config", {})
	if run_active and not active_run_config.is_empty():
		config = DeployConfigScript.with_active_run_config(config, active_run_config)
	return _build_model(
		config,
		run_active,
		StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB)),
		StringName(model.get("selected_filter", DeployTabModelScript.FILTER_ALL)),
		StringName(model.get("selected_card", &"")),
		false,
		str(model.get("action_message", ""))
	)


static func model_with_tab(model: Dictionary, tab_id: StringName) -> Dictionary:
	var config := _config_from(model)
	var run_active := _has_active_run(config)
	var selected_filter := DeployTabModelScript.default_filter_for(tab_id)
	var selected_card := DeployTabModelScript.default_card_for(tab_id)
	return _build_model(config, run_active, tab_id, selected_filter, selected_card, false, "")


static func model_with_filter(model: Dictionary, filter_id: StringName) -> Dictionary:
	var config := _config_from(model)
	var run_active := _has_active_run(config)
	var active_tab := StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var cards := DeployTabModelScript.filter_cards(active_tab, filter_id)
	var selected_card := &""
	if not cards.is_empty():
		selected_card = StringName((cards[0] as Dictionary).get("id", &""))
	return _build_model(config, run_active, active_tab, filter_id, selected_card, false, "")


static func model_with_card(model: Dictionary, card_id: StringName) -> Dictionary:
	var config := _config_from(model)
	var run_active := _has_active_run(config)
	var active_tab := StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var selected_filter := StringName(model.get("selected_filter", DeployTabModelScript.default_filter_for(active_tab)))
	return _build_model(config, run_active, active_tab, selected_filter, card_id, false, "")


static func model_with_action_message(model: Dictionary, message: String, confirm_visible: bool = false) -> Dictionary:
	var result := model.duplicate(true)
	result["action_message"] = message
	result["abandon_confirm_visible"] = confirm_visible
	return result


static func model_with_config(model: Dictionary, config: Dictionary, selected_card: StringName, message: String = "") -> Dictionary:
	var run_active := _has_active_run(config)
	var active_tab := StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var selected_filter := StringName(model.get("selected_filter", DeployTabModelScript.default_filter_for(active_tab)))
	return _build_model(config, run_active, active_tab, selected_filter, selected_card, false, message)


static func _build_model(
	config: Dictionary,
	run_active: bool,
	active_tab: StringName,
	selected_filter: StringName,
	selected_card: StringName,
	confirm_visible: bool,
	action_message: String
) -> Dictionary:
	var tab := DeployTabModelScript.find_tab(active_tab)
	var cards := DeployTabModelScript.filter_cards(active_tab, selected_filter)
	if cards.is_empty() and selected_filter != DeployTabModelScript.FILTER_ALL:
		cards = DeployTabModelScript.filter_cards(active_tab, DeployTabModelScript.FILTER_ALL)
	var dynamic_cards := _dynamic_cards_for_tab(config, active_tab, selected_filter)
	if not dynamic_cards.is_empty():
		cards = dynamic_cards
		if _find_visible_card(cards, selected_card).is_empty():
			selected_card = StringName((cards[0] as Dictionary).get("id", &""))
	var selected_detail := _find_visible_card(cards, selected_card)
	if selected_detail.is_empty():
		selected_detail = DeployTabModelScript.find_card(active_tab, selected_card)
	if selected_detail.is_empty() and not cards.is_empty():
		selected_detail = (cards[0] as Dictionary).duplicate(true)
		selected_card = StringName(selected_detail.get("id", &""))
	var preview := DeployConfigScript.build_preview_lines(config)
	return {
		"title": "出发探索",
		"subtitle": "整备、路线、背包和出勤确认",
		"boundary": "本页使用真实仓库、地图解锁、委托与基地商店生成本局出勤配置；抽奖仍保持封存。",
		"tabs": DeployTabModelScript.build_tabs(),
		"active_tab": active_tab,
		"selected_filter": selected_filter,
		"selected_card": selected_card,
		"active_tab_data": tab,
		"visible_cards": cards,
		"selected_card_detail": selected_detail,
		"config": config,
		"run_start_config": DeployConfigScript.build_run_start_config(config),
		"local_draft_preview": _local_draft_preview(config),
		"run_flow_route_preview": _run_flow_route_preview(config, run_active),
		"asset_domain_preview": {
			"deploy_asset_view_preview": (config.get("deploy_asset_view_preview", {}) as Dictionary).duplicate(true),
			"warehouse_view_snapshot": (config.get("warehouse_view_snapshot", {}) as Dictionary).duplicate(true),
			"warehouse_view_content_snapshot": (config.get("warehouse_view_content_snapshot", {}) as Dictionary).duplicate(true),
			"long_term_asset_interface_preview": (config.get("long_term_asset_interface_preview", {}) as Dictionary).duplicate(true),
			"objective_preview": (config.get("objective_preview", {}) as Dictionary).duplicate(true),
			"config_validity_preview": (config.get("config_validity_preview", {}) as Dictionary).duplicate(true),
			"action_intent_boundaries": (config.get("action_intent_boundaries", {}) as Dictionary).duplicate(true),
			"summary": "M7 读取真实仓库实例并保留玩家的地图、委托与出勤选择，直至本局开始。",
			"read_only": true,
			"display_only": false,
			"preview": false,
		},
		"preview_lines": preview,
		"abandon_confirm_visible": confirm_visible,
		"action_message": action_message,
		"actions": _actions(run_active),
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func _local_draft_preview(config: Dictionary) -> Dictionary:
	return {
		"map": {
			"summary": str(config.get("selected_map_summary", "")),
			"map_mode": str(config.get("map_mode_label", "甯歌鎵浄")),
			"difficulty": str(config.get("difficulty_label", "Normal")),
			"region": str(config.get("region_label", "鐏板熬澶栧洿")),
		},
		"warehouse": (config.get("warehouse_attendance_preview", {}) as Dictionary).duplicate(true),
		"claim": (config.get("claim_preview", {}) as Dictionary).duplicate(true),
		"objective": (config.get("objective_preview", {}) as Dictionary).duplicate(true),
		"loadout": (config.get("loadout_preview", {}) as Dictionary).duplicate(true),
		"backpack_capacity": (config.get("backpack_capacity_preview", {}) as Dictionary).duplicate(true),
		"validity": (config.get("config_validity_preview", {}) as Dictionary).duplicate(true),
		"permission_interface": (config.get("permission_interface_preview", {}) as Dictionary).duplicate(true),
		"linkage_note": "Map, warehouse, objective placeholders, and deploy config share the same M3R minimal config. This page does not directly write warehouse or objective progress.",
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func _run_flow_route_preview(config: Dictionary, run_active: bool) -> Dictionary:
	return {
		"schema_kind": &"RunIntent",
		"start_bridge": {
			"target_route": &"run",
			"route_mode": &"standard_run",
			"entry_id": &"deploy_prep_start_bridge",
			"deploy_config_bridge": true,
			"uses_existing_route": true,
			"does_not_create_run_bootstrapper": true,
			"config_ref": str(DeployConfigScript.build_run_start_config(config).get("config_id", "")),
		},
		"continue": {
			"disabled": not run_active,
			"disabled_reason": &"" if run_active else &"no_active_run",
			"preview": false,
		},
		"abandon": {
			"disabled": not run_active,
			"disabled_reason": &"" if run_active else &"no_active_run",
			"strong_confirm_required": run_active,
			"preview": false,
		},
		"read_only": true,
		"display_only": false,
		"preview": false,
		"no_persistence": true,
	}


static func _actions(run_active: bool) -> Dictionary:
	return {
		"start": {
			"label": "Start run",
			"tooltip": "Use M3R warehouse loadout and route into the existing standard_10x10 playable run; full deploy bootstrap remains future work.",
			"disabled": run_active,
			"run_intent": {
				"target_route": &"run",
				"route_mode": &"standard_run",
				"entry_id": &"deploy_prep_start_bridge",
				"deploy_config_bridge": true,
				"uses_existing_route": true,
			},
			"preview": false,
			"display_only": false,
			"read_only": false,
		},
		"continue": {
			"label": "Continue run",
			"tooltip": "Return to the active in-process exploration without creating another run.",
			"disabled": not run_active,
			"has_active_run": run_active,
			"disabled_reason": &"" if run_active else &"no_active_run",
			"preview": false,
			"display_only": false,
			"read_only": false,
		},
		"abandon": {
			"label": "Abandon run",
			"tooltip": "Abandon the active run after strong confirmation and resolve the zero-salvage branch.",
			"disabled": not run_active,
			"requires_confirm": run_active,
			"disabled_reason": &"" if run_active else &"no_active_run",
			"confirm_copy": "Black resources and all items are lost; direct gold is retained.",
			"preview": false,
			"display_only": false,
			"read_only": false,
		},
	}


static func _dynamic_cards_for_tab(config: Dictionary, active_tab: StringName, selected_filter: StringName) -> Array:
	match active_tab:
		DeployTabModelScript.TAB_MAP:
			return _m7_map_cards(config, selected_filter)
		DeployTabModelScript.TAB_WAREHOUSE:
			return _warehouse_cards(config, selected_filter)
		DeployTabModelScript.TAB_CLAIM:
			return _m7_claim_cards(config, selected_filter)
		DeployTabModelScript.TAB_OBJECTIVE:
			return _m7_objective_cards(config, selected_filter)
		DeployTabModelScript.TAB_LOADOUT:
			return _loadout_cards(config, selected_filter)
	return []


static func _m7_map_cards(config: Dictionary, selected_filter: StringName) -> Array:
	if selected_filter in [DeployTabModelScript.FILTER_MAP_HONEYCOMB, DeployTabModelScript.FILTER_MAP_SPECIAL]:
		return []
	var cards := []
	var unlocked: Array = config.get("unlocked_map_ids", [])
	var selected_map_id := str(config.get("map_config_id", "classic_7x7_simple"))
	for definition in M7ContentCatalogScript.map_definitions():
		var map_id := str(definition.get("id", ""))
		var is_unlocked := unlocked.has(map_id)
		if selected_filter == DeployTabModelScript.FILTER_MAP_UNLOCKED and not is_unlocked:
			continue
		if selected_filter == DeployTabModelScript.FILTER_MAP_RECOMMENDED and map_id != selected_map_id:
			continue
		cards.append({
			"id": "m7_map_%s" % map_id,
			"title": str(definition.get("display_name", map_id)),
			"category": "地图",
			"state": "selected" if map_id == selected_map_id else ("ready" if is_unlocked else "locked"),
			"summary": "%s；雷房%d，内容房各%d，撤离点%d。" % [
				str(definition.get("role", "")).replace(" / ", "/"),
				int(definition.get("mine_count", 0)),
				int(definition.get("content_room_count", 0)),
				int(definition.get("visible_exit_count", 0)) + int(definition.get("hidden_exit_count", 0)),
			],
			"detail": "已解锁并可真实进入。" if is_unlocked else "需要通过地图成功、研究或成就解锁。",
			"filter_id": DeployTabModelScript.FILTER_MAP_CLASSIC,
		})
	return cards


static func _m7_claim_cards(config: Dictionary, selected_filter: StringName) -> Array:
	var cards := []
	if selected_filter in [DeployTabModelScript.FILTER_ALL, DeployTabModelScript.FILTER_CLAIM_RECEIVE]:
		cards.append(DeployTabModelScript.find_card(DeployTabModelScript.TAB_CLAIM, &"claim_emergency_ration"))
	var meta := _dictionary_from(config.get("meta_progress_summary", {}))
	for raw_shop in _array_from(meta.get("shop_catalog", M7ContentCatalogScript.shop_definitions())):
		var shop := _dictionary_from(raw_shop)
		var unlocked := bool(shop.get("unlocked", M7ContentCatalogScript.is_shop_unlocked(shop, meta)))
		if selected_filter == DeployTabModelScript.FILTER_CLAIM_PURCHASE and not unlocked:
			continue
		if selected_filter == DeployTabModelScript.FILTER_CLAIM_LOCKED and unlocked:
			continue
		if not (selected_filter in [DeployTabModelScript.FILTER_ALL, DeployTabModelScript.FILTER_CLAIM_PURCHASE, DeployTabModelScript.FILTER_CLAIM_LOCKED, DeployTabModelScript.FILTER_CLAIM_RECOMMENDED]):
			continue
		var item_id := str(shop.get("item_id", ""))
		cards.append({
			"id": "m7_shop_%s" % item_id,
			"title": str(shop.get("display_name", item_id)),
			"category": "申领",
			"state": "ready" if unlocked else "locked",
			"summary": "价格 %d 金币；购买后生成真实仓库实例。" % int(shop.get("price", 0)),
			"detail": "金币充足时可购买。" if unlocked else "研究或资历条件尚未满足。",
			"filter_id": DeployTabModelScript.FILTER_CLAIM_PURCHASE if unlocked else DeployTabModelScript.FILTER_CLAIM_LOCKED,
		})
	return cards


static func _m7_objective_cards(config: Dictionary, selected_filter: StringName) -> Array:
	if selected_filter in [DeployTabModelScript.FILTER_OBJECTIVE_LOCKED, DeployTabModelScript.FILTER_OBJECTIVE_REWARD]:
		return []
	var cards := []
	var selected_id := str(config.get("selected_objective_id", ""))
	for raw_candidate in _array_from(config.get("commission_candidates", [])):
		var candidate := _dictionary_from(raw_candidate)
		var commission_id := str(candidate.get("id", ""))
		cards.append({
			"id": "m7_commission_%s" % commission_id,
			"title": str(candidate.get("display_name", commission_id)),
			"category": "目标",
			"state": "selected" if selected_id == commission_id else "ready",
			"summary": str(candidate.get("description", "")),
			"detail": "成功撤离且达成条件后自动发放委托奖励。",
			"filter_id": DeployTabModelScript.FILTER_OBJECTIVE_COMMISSION,
		})
	return cards


static func _warehouse_cards(config: Dictionary, selected_filter: StringName) -> Array:
	var warehouse := _dictionary_from(config.get("warehouse_lite", {}))
	var selected_ids := _selected_instance_ids(config)
	var cards := []
	var groups := [
		{
			"key": &"equipment",
			"label": "Equipment",
			"filter_id": DeployTabModelScript.FILTER_WAREHOUSE_EQUIPMENT,
		},
		{
			"key": &"consumable",
			"label": "Consumable",
			"filter_id": DeployTabModelScript.FILTER_WAREHOUSE_CONSUMABLE,
		},
		{
			"key": &"collectible",
			"label": "Collectible",
			"filter_id": DeployTabModelScript.FILTER_WAREHOUSE_COLLECTIBLE,
		},
		{
			"key": &"special",
			"label": "Special",
			"filter_id": DeployTabModelScript.FILTER_WAREHOUSE_SPECIAL,
		},
	]
	var group_data := _dictionary_from(warehouse.get("groups", {}))
	for group in groups:
		var group_dict := group as Dictionary
		var filter_id := StringName(group_dict.get("filter_id", DeployTabModelScript.FILTER_ALL))
		if selected_filter != DeployTabModelScript.FILTER_ALL and selected_filter != filter_id:
			continue
		for raw_item in _group_items(group_data, StringName(group_dict.get("key", &""))):
			var item := _dictionary_from(raw_item)
			if item.is_empty():
				continue
			cards.append(_warehouse_item_card(item, str(group_dict.get("label", "Item")), filter_id, selected_ids))
	if selected_filter == DeployTabModelScript.FILTER_ALL or selected_filter == DeployTabModelScript.FILTER_WAREHOUSE_STATUS:
		cards.append(_warehouse_status_card(warehouse))
	return cards


static func _loadout_cards(config: Dictionary, selected_filter: StringName) -> Array:
	var cards := []
	var equipment := _array_from(config.get("selected_equipment_items", []))
	var consumables := _array_from(config.get("selected_consumable_items", []))
	var effects := _array_from(config.get("equipment_effects", []))
	var capacity := {
		"used": int(config.get("bag_used", 0)),
		"limit": int(config.get("bag_limit", config.get("backpack_capacity", 10))),
		"failure_salvage_capacity": int(config.get("failure_salvage_capacity", 4)),
	}
	if selected_filter == DeployTabModelScript.FILTER_ALL or selected_filter == DeployTabModelScript.FILTER_LOADOUT_EQUIPMENT:
		cards.append({
			"id": &"m3r_loadout_equipment",
			"filter_id": DeployTabModelScript.FILTER_LOADOUT_EQUIPMENT,
			"title": "Selected equipment",
			"category": "Loadout",
			"state": "minimal_real",
			"summary": "%d equipment item(s) will enter the next run as equipped/runtime passive context." % equipment.size(),
			"detail": "These items are read from MetaProgress warehouse_items and passed through RunStartConfig; they are not picked up and activated inside the same run.",
			"lines": _item_lines(equipment) + _effect_lines(effects),
			"link_preview": ["Warehouse Lite", "RunStartConfig"],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	if selected_filter == DeployTabModelScript.FILTER_ALL or selected_filter == DeployTabModelScript.FILTER_LOADOUT_CONSUMABLE:
		cards.append({
			"id": &"m3r_loadout_consumables",
			"filter_id": DeployTabModelScript.FILTER_LOADOUT_CONSUMABLE,
			"title": "Carried consumables",
			"category": "Loadout",
			"state": "minimal_real",
			"summary": "%d consumable item(s) will enter the next run backpack." % consumables.size(),
			"detail": "Carry-in and in-run consumables are cleared when the run ends, even when unused.",
			"lines": _item_lines(consumables),
			"link_preview": ["Warehouse Lite", "Backpack"],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	if selected_filter == DeployTabModelScript.FILTER_ALL or selected_filter == DeployTabModelScript.FILTER_LOADOUT_BAG:
		cards.append({
			"id": &"m3r_loadout_capacity",
			"filter_id": DeployTabModelScript.FILTER_LOADOUT_BAG,
			"title": "Carry capacity",
			"category": "Loadout",
			"state": "valid" if int(capacity.get("used", 0)) <= int(capacity.get("limit", 0)) else "over_limit",
			"summary": "Carry weight %d / %d; failure salvage capacity %d." % [int(capacity.get("used", 0)), int(capacity.get("limit", 0)), int(capacity.get("failure_salvage_capacity", 4))],
			"detail": "Capacity is derived from profile hooks, selected equipment effects, and selected consumable weight.",
			"lines": [
				"bag_used=%d" % int(capacity.get("used", 0)),
				"bag_limit=%d" % int(capacity.get("limit", 0)),
				"failure_salvage_capacity=%d" % int(capacity.get("failure_salvage_capacity", 4)),
			],
			"link_preview": ["RunStartConfig", "Settlement salvage"],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	if selected_filter == DeployTabModelScript.FILTER_ALL or selected_filter == DeployTabModelScript.FILTER_LOADOUT_PERMISSION:
		var profile := _dictionary_from(config.get("profile_fields", {}))
		cards.append({
			"id": &"m3r_profile_permission_protocol",
			"filter_id": DeployTabModelScript.FILTER_LOADOUT_PERMISSION,
			"title": "Profile / permit / protocol hooks",
			"category": "Loadout",
			"state": "minimal_real",
			"summary": "Profile level %d, permit level %d, protocol difficulty %d." % [int(config.get("profile_level", 1)), int(config.get("permit_level", 1)), int(config.get("protocol_difficulty", 5))],
			"detail": "M3R exposes minimal fields and talent hooks without implementing a complete profile, permit, or protocol difficulty table.",
			"lines": [
				"profile_exp=%d" % int(config.get("profile_exp", 0)),
				"talent_hooks=%d" % _array_from(config.get("talent_interface", [])).size(),
				"active_talent_effects=%d" % _array_from(config.get("active_talent_effects", [])).size(),
				"mine_dmg_reduce=%d" % int(config.get("mine_dmg_reduce", profile.get("mine_dmg_reduce", 0))),
			],
			"link_preview": ["角色档案", "当局摘要"],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	if selected_filter == DeployTabModelScript.FILTER_ALL or selected_filter == DeployTabModelScript.FILTER_LOADOUT_INTENT:
		cards.append({
			"id": &"m3r_start_intent",
			"filter_id": DeployTabModelScript.FILTER_LOADOUT_INTENT,
			"title": "开始常规探索",
			"category": "出勤",
			"state": "ready",
			"summary": "使用当前整备进入常规路线。",
			"detail": "确认当前地图、委托、装备与补给后进入真实探索；终局按成功、失败或放弃结算。",
			"lines": [
				"路线：常规探索",
				"模式：标准房间",
				"装备：%d 件" % equipment.size(),
				"补给：%d 件" % consumables.size(),
			],
			"link_preview": ["出发路线", "操作入口"],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	return cards


static func _warehouse_item_card(item: Dictionary, group_label: String, filter_id: StringName, selected_ids: Dictionary) -> Dictionary:
	var instance_id := str(item.get("instance_id", item.get("item_id", "")))
	var item_id := str(item.get("item_id", instance_id))
	var selected := selected_ids.has(instance_id) or selected_ids.has(item_id)
	return {
		"id": StringName("m3r_%s" % instance_id),
		"filter_id": filter_id,
		"title": str(item.get("display_name", item_id)),
		"category": group_label,
		"state": "selected" if selected else "owned",
		"summary": "%s | weight %d | value %d | source %s" % [str(item.get("item_type", group_label)), int(item.get("weight", 0)), int(item.get("base_value", 0)), str(item.get("source_label", item.get("source", "warehouse")))],
		"detail": "%s%s" % [str(item.get("short_description", "")), "；藏品需连续点击两次确认单件出售。" if str(item.get("item_type", "")) == "collectible" and bool(item.get("can_sell", false)) else ""],
		"lines": [
			"item_id=%s" % item_id,
			"instance_id=%s" % instance_id,
			"can_equip=%s" % str(bool(item.get("can_equip", false))),
			"can_consume=%s" % str(bool(item.get("can_consume", false))),
			"can_carry=%s" % str(bool(item.get("can_carry", false))),
			"can_sell=%s" % str(bool(item.get("can_sell", false))),
			"collectible_level=%d" % int(item.get("collectible_level", 0)),
		],
		"link_preview": ["Loadout candidate" if bool(item.get("can_carry", false)) else "Warehouse record"],
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func _warehouse_status_card(warehouse: Dictionary) -> Dictionary:
	var counts := _dictionary_from(warehouse.get("group_counts", {}))
	return {
		"id": &"m3r_warehouse_status",
		"filter_id": DeployTabModelScript.FILTER_WAREHOUSE_STATUS,
		"title": "Warehouse Lite status",
		"category": "Warehouse",
		"state": "minimal_real",
		"summary": "%d real warehouse item(s) are available from MetaProgress." % int(warehouse.get("item_count", 0)),
		"detail": "读取真实仓库实例；装备与补给可加入出勤，可出售藏品需连续点击两次确认。",
		"lines": [
			"equipment=%d" % int(counts.get("equipment", 0)),
			"consumable=%d" % int(counts.get("consumable", 0)),
			"collectible=%d" % int(counts.get("collectible", 0)),
			"special=%d" % int(counts.get("special", 0)),
		],
		"link_preview": ["LongTerm Codex Lite", "DeployPrep Loadout"],
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func _find_visible_card(cards: Array, selected_card: StringName) -> Dictionary:
	for raw_card in cards:
		if raw_card is Dictionary:
			var card := raw_card as Dictionary
			if StringName(card.get("id", &"")) == selected_card:
				return card.duplicate(true)
	return {}


static func _selected_instance_ids(config: Dictionary) -> Dictionary:
	var result := {}
	for raw_item in _array_from(config.get("selected_equipment_items", [])) + _array_from(config.get("selected_consumable_items", [])):
		var item := _dictionary_from(raw_item)
		var instance_id := str(item.get("instance_id", ""))
		var item_id := str(item.get("item_id", ""))
		if instance_id != "":
			result[instance_id] = true
		if item_id != "":
			result[item_id] = true
	return result


static func _group_items(groups: Dictionary, key: StringName) -> Array:
	if groups.has(key):
		return _array_from(groups.get(key, []))
	var text_key := str(key)
	if groups.has(text_key):
		return _array_from(groups.get(text_key, []))
	return []


static func _item_lines(items: Array) -> Array:
	var lines := []
	if items.is_empty():
		return ["none"]
	for raw_item in items:
		var item := _dictionary_from(raw_item)
		lines.append("%s | weight %d | %s" % [str(item.get("display_name", item.get("item_id", "item"))), int(item.get("weight", 0)), str(item.get("effect_kind", ""))])
	return lines


static func _effect_lines(effects: Array) -> Array:
	var lines := []
	for raw_effect in effects:
		var effect := _dictionary_from(raw_effect)
		lines.append("effect %s %+d from %s" % [str(effect.get("effect_kind", "")), int(effect.get("effect_amount", 0)), str(effect.get("display_name", effect.get("item_id", "")))])
	return lines


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _config_from(model: Dictionary) -> Dictionary:
	var raw: Variant = model.get("config", {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return DeployConfigScript.default_config()


static func _has_active_run(config: Dictionary) -> bool:
	var active_run: Variant = config.get("active_run_preview", {})
	if active_run is Dictionary:
		return bool((active_run as Dictionary).get("has_active_run", false))
	return false
