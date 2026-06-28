extends RefCounted
class_name DeployPrepModel

const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")


static func build(snapshot: Dictionary = {}) -> Dictionary:
	var run_active := bool(snapshot.get("run_active", snapshot.get("has_active_run", false)))
	var meta_summary: Dictionary = snapshot.get("meta_progress_summary", {})
	var config := DeployConfigScript.with_active_run_preview(DeployConfigScript.default_config(1, meta_summary), run_active)
	var active_tab := DeployTabModelScript.DEFAULT_TAB
	var selected_filter := DeployTabModelScript.default_filter_for(active_tab)
	var selected_card := DeployTabModelScript.default_card_for(active_tab)
	return _build_model(config, run_active, active_tab, selected_filter, selected_card, false, "")


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
	var selected_detail := _find_visible_card(cards, selected_card)
	if selected_detail.is_empty():
		selected_detail = DeployTabModelScript.find_card(active_tab, selected_card)
	if selected_detail.is_empty() and not cards.is_empty():
		selected_detail = (cards[0] as Dictionary).duplicate(true)
		selected_card = StringName(selected_detail.get("id", &""))
	var preview := DeployConfigScript.build_preview_lines(config)
	return {
		"title": "Deploy Prep",
		"subtitle": "M3R / Warehouse Lite / Codex Lite / minimal real loadout",
		"boundary": "M3R reads MetaProgress warehouse_items, derives Warehouse Lite / loadout / Codex Lite, and passes equipment plus consumables into the existing standard_10x10 start path. It does not implement complete warehouse economy, rewards, objectives, or full RunBootstrapper.",
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
			"summary": "M3R consumes real warehouse_items for minimal loadout; asset contracts remain read-only and do not write assets here.",
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
			"disabled_reason": &"" if run_active else &"no_active_run_persistence",
			"preview": true,
		},
		"abandon": {
			"disabled": true,
			"disabled_reason": &"settlement_runtime_not_connected",
			"strong_confirm_required": run_active,
			"preview": true,
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
			"label": "Continue preview",
			"tooltip": "Continue remains a read-only active-run status placeholder; active run persistence is future work.",
			"disabled": not run_active,
			"has_active_run": run_active,
			"disabled_reason": &"" if run_active else &"no_active_run_persistence",
			"preview": true,
			"display_only": true,
			"read_only": true,
		},
		"abandon": {
			"label": "Abandon preview",
			"tooltip": "Abandon remains confirm/display-only in M3R.",
			"disabled": not run_active,
			"requires_confirm": run_active,
			"disabled_reason": &"settlement_runtime_not_connected",
			"confirm_copy": "Confirm preview: abandon settlement is not implemented in M3R.",
			"preview": true,
			"display_only": true,
			"read_only": true,
		},
	}


static func _dynamic_cards_for_tab(config: Dictionary, active_tab: StringName, selected_filter: StringName) -> Array:
	match active_tab:
		DeployTabModelScript.TAB_WAREHOUSE:
			return _warehouse_cards(config, selected_filter)
		DeployTabModelScript.TAB_LOADOUT:
			return _loadout_cards(config, selected_filter)
	return []


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
		"failure_salvage_capacity": int(config.get("failure_salvage_capacity", 1)),
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
			"detail": "Unused carry-in consumables return on success and become failure salvage candidates under the M3 settlement rule.",
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
			"summary": "Carry weight %d / %d; failure salvage capacity %d." % [int(capacity.get("used", 0)), int(capacity.get("limit", 0)), int(capacity.get("failure_salvage_capacity", 1))],
			"detail": "Capacity is derived from profile hooks, selected equipment effects, and selected consumable weight.",
			"lines": [
				"bag_used=%d" % int(capacity.get("used", 0)),
				"bag_limit=%d" % int(capacity.get("limit", 0)),
				"failure_salvage_capacity=%d" % int(capacity.get("failure_salvage_capacity", 1)),
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
			"link_preview": ["Profile interface", "Run snapshot"],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	if selected_filter == DeployTabModelScript.FILTER_ALL or selected_filter == DeployTabModelScript.FILTER_LOADOUT_INTENT:
		cards.append({
			"id": &"m3r_start_intent",
			"filter_id": DeployTabModelScript.FILTER_LOADOUT_INTENT,
			"title": "Start standard_10x10",
			"category": "Loadout",
			"state": "ready",
			"summary": "Start passes the current M3R RunStartConfig to the existing standard_10x10 route.",
			"detail": "This is the minimal real route bridge; it does not create a full deploy bootstrapper or complete loadout economy.",
			"lines": [
				"target_route=run",
				"route_mode=standard_run",
				"selected_equipment=%d" % equipment.size(),
				"selected_consumables=%d" % consumables.size(),
			],
			"link_preview": ["RunSceneRouteController", "CommandBus"],
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
		"detail": str(item.get("short_description", "")),
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
		"detail": "This page reads warehouse_items and derives carry-in candidates; it does not implement sell pricing or a complete warehouse economy.",
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
