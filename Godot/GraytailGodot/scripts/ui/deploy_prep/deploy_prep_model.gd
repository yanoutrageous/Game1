extends RefCounted
class_name DeployPrepModel

const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployMapProjectionScript := preload("res://scripts/ui/deploy_prep/deploy_map_projection.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")

const EMERGENCY_CLAIM_ID := &"m6_emergency_ration"
const EMERGENCY_CLAIM_CARD_ID := &"claim_emergency_ration"
const MAX_CARRIED_CONSUMABLES := 3


static func build(snapshot: Dictionary = {}) -> Dictionary:
	var run_active := bool(snapshot.get("run_active", snapshot.get("has_active_run", false)))
	var meta_summary := _dictionary_from(snapshot.get("meta_progress_summary", {}))
	var config := DeployConfigScript.with_active_run_preview(DeployConfigScript.default_config(1, meta_summary), run_active)
	var active_run_config := _dictionary_from(snapshot.get("run_start_config", {}))
	if run_active and not active_run_config.is_empty():
		config = DeployConfigScript.with_active_run_config(config, active_run_config)
	var active_tab := DeployTabModelScript.DEFAULT_TAB
	return _build_model(
		config,
		run_active,
		active_tab,
		DeployTabModelScript.default_filter_for(active_tab),
		&"",
		false,
		""
	)


static func refresh_from_snapshot(model: Dictionary, snapshot: Dictionary = {}) -> Dictionary:
	if model.is_empty():
		return build(snapshot)
	var run_active := bool(snapshot.get("run_active", snapshot.get("has_active_run", false)))
	var config := DeployConfigScript.refresh_from_meta(
		_config_from(model),
		_dictionary_from(snapshot.get("meta_progress_summary", {})),
		run_active
	)
	var active_run_config := _dictionary_from(snapshot.get("run_start_config", {}))
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
	var tab := DeployTabModelScript.find_tab(tab_id)
	var normalized_tab := StringName(tab.get("id", DeployTabModelScript.DEFAULT_TAB))
	var config := _without_sell_confirmation(_config_from(model))
	return _build_model(
		config,
		_has_active_run(config),
		normalized_tab,
		DeployTabModelScript.default_filter_for(normalized_tab),
		&"",
		false,
		""
	)


static func model_with_filter(model: Dictionary, filter_id: StringName) -> Dictionary:
	var config := _without_sell_confirmation(_config_from(model))
	var active_tab := StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var normalized_filter := DeployTabModelScript.normalize_filter_for(active_tab, filter_id)
	return _build_model(config, _has_active_run(config), active_tab, normalized_filter, &"", false, "")


static func model_with_card(model: Dictionary, card_id: StringName) -> Dictionary:
	# Row selection is deliberately read-only. Domain mutations belong to an
	# explicit detail action and must not be inferred from selecting a row.
	var config := _without_sell_confirmation(_config_from(model))
	var active_tab := StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var selected_filter := StringName(model.get("selected_filter", DeployTabModelScript.FILTER_ALL))
	return _build_model(config, _has_active_run(config), active_tab, selected_filter, card_id, false, "")


static func model_with_action_message(model: Dictionary, message: String, confirm_visible: bool = false) -> Dictionary:
	var result := model.duplicate(true)
	result["action_message"] = message
	result["abandon_confirm_visible"] = confirm_visible
	return result


static func model_with_config(model: Dictionary, config: Dictionary, selected_card: StringName, message: String = "") -> Dictionary:
	var active_tab := StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var selected_filter := StringName(model.get("selected_filter", DeployTabModelScript.FILTER_ALL))
	return _build_model(config, _has_active_run(config), active_tab, selected_filter, selected_card, false, message)


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
	active_tab = StringName(tab.get("id", DeployTabModelScript.DEFAULT_TAB))
	selected_filter = DeployTabModelScript.normalize_filter_for(active_tab, selected_filter)
	var map_projection := DeployMapProjectionScript.project(config)
	var rows := _dynamic_rows_for_tab(config, active_tab, selected_filter, map_projection)
	var selected_row := _find_visible_card(rows, selected_card)
	if selected_row.is_empty() and not rows.is_empty():
		selected_row = _dictionary_from(rows[0])
		selected_card = StringName(selected_row.get("id", &""))
	elif selected_row.is_empty():
		selected_card = &""
	var wallet_projection := _wallet_projection(config)
	var detail_projection := _detail_projection(active_tab, selected_row)
	var summary_projection := _summary_projection(config, map_projection)
	var preview_lines := _legacy_preview_lines(summary_projection)
	var tab_data := tab.duplicate(true)
	tab_data["item_count"] = rows.size()
	tab_data["empty_state"] = _empty_state_for(active_tab) if rows.is_empty() else ""
	return {
		"title": "出发探索",
		"subtitle": "地图、物资、委托与携带清单",
		"boundary": "本页读取真实地图、仓库、基地申领和本局委托；选择行只查看详情，明确操作才提交变更。",
		"tabs": DeployTabModelScript.build_tabs(),
		"active_tab": active_tab,
		"selected_filter": selected_filter,
		"selected_card": selected_card,
		"active_tab_data": tab_data,
		"wallet_projection": wallet_projection,
		"map_projection": map_projection,
		"selection_rows": rows.duplicate(true),
		"detail_projection": detail_projection,
		"summary_projection": summary_projection,
		# ART22 compatibility while the view migrates to the explicit projections.
		"visible_cards": rows.duplicate(true),
		"selected_card_detail": selected_row.duplicate(true),
		"config": config,
		"run_start_config": DeployConfigScript.build_run_start_config(config),
		"local_draft_preview": _local_draft_preview(config),
		"run_flow_route_preview": _run_flow_route_preview(config, run_active),
		"asset_domain_preview": {
			"deploy_asset_view_preview": _dictionary_from(config.get("deploy_asset_view_preview", {})),
			"warehouse_view_snapshot": _dictionary_from(config.get("warehouse_view_snapshot", {})),
			"warehouse_view_content_snapshot": _dictionary_from(config.get("warehouse_view_content_snapshot", {})),
			"long_term_asset_interface_preview": _dictionary_from(config.get("long_term_asset_interface_preview", {})),
			"objective_preview": _dictionary_from(config.get("objective_preview", {})),
			"config_validity_preview": _dictionary_from(config.get("config_validity_preview", {})),
			"action_intent_boundaries": _dictionary_from(config.get("action_intent_boundaries", {})),
			"read_only": true,
			"display_only": false,
			"preview": false,
		},
		"preview_lines": preview_lines,
		"abandon_confirm_visible": confirm_visible,
		"action_message": action_message,
		"actions": _actions(run_active),
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func _wallet_projection(config: Dictionary) -> Dictionary:
	var meta := _dictionary_from(config.get("meta_progress_summary", {}))
	var available := meta.has("gold")
	var gold_value: Variant = int(meta.get("gold", 0)) if available else null
	var display := str(gold_value) if available else "—"
	return {
		"currency": &"gold",
		"currency_id": &"gold_coin",
		"label": "金币",
		"gold": gold_value,
		"amount": gold_value,
		"display": display,
		"display_text": "金币 %s" % display,
		"available": available,
		"read_only": true,
	}


static func _dynamic_rows_for_tab(config: Dictionary, active_tab: StringName, selected_filter: StringName, map_projection: Dictionary) -> Array:
	match active_tab:
		DeployTabModelScript.TAB_MAP:
			return _map_rows(config, selected_filter, map_projection)
		DeployTabModelScript.TAB_WAREHOUSE:
			return _warehouse_rows(config, selected_filter)
		DeployTabModelScript.TAB_CLAIM:
			return _claim_rows(config, selected_filter)
		DeployTabModelScript.TAB_OBJECTIVE:
			return _objective_rows(config)
		DeployTabModelScript.TAB_LOADOUT:
			return _loadout_rows(config, map_projection)
	return []


static func _map_rows(config: Dictionary, selected_filter: StringName, map_projection: Dictionary) -> Array:
	var result := []
	var selected_map_id := str(config.get("map_config_id", ""))
	for raw_scale in _array_from(map_projection.get("scale_options", [])):
		var scale := _dictionary_from(raw_scale)
		for raw_map in _array_from(scale.get("maps", [])):
			var map_data := _dictionary_from(raw_map)
			var unlocked := bool(map_data.get("unlocked", false))
			if selected_filter == DeployTabModelScript.FILTER_MAP_UNLOCKED and not unlocked:
				continue
			var map_id := str(map_data.get("map_config_id", ""))
			var selected := map_id == selected_map_id
			var domain_action := _dictionary_from(map_data.get("select_action", {}))
			var action_enabled := bool(domain_action.get("enabled", false)) and not selected
			var reason_code := StringName(domain_action.get("reason_code", &"map_locked"))
			if selected:
				reason_code = &"already_selected"
			var action := _action(
				&"select_map",
				"已选择" if selected else "选择地图",
				action_enabled,
				false,
				false,
				reason_code,
				{"map_config_id": map_id}
			)
			result.append({
				"id": StringName("m7_map_%s" % map_id),
				"filter_id": DeployTabModelScript.FILTER_MAP_UNLOCKED if unlocked else DeployTabModelScript.FILTER_ALL,
				"title": str(map_data.get("display_name", map_id)),
				"category": "地图",
				"state": "selected" if selected else ("ready" if unlocked else "locked"),
				"summary": "%s · %s · %s" % [str(map_data.get("scale_label", "")), str(map_data.get("difficulty_label", "")), "已解锁" if unlocked else "未解锁"],
				"detail": str(map_data.get("role", "")),
				"map_config_id": map_id,
				"scale_id": StringName(map_data.get("scale_id", &"")),
				"scale_label": str(map_data.get("scale_label", "")),
				"difficulty": StringName(map_data.get("difficulty", &"")),
				"difficulty_label": str(map_data.get("difficulty_label", "")),
				"unlocked": unlocked,
				"selected": selected,
				"mine_count": int(map_data.get("mine_count", 0)),
				"content_room_count": int(map_data.get("content_room_count", 0)),
				"facts": [
					_fact("规模", str(map_data.get("scale_label", "—"))),
					_fact("难度", str(map_data.get("difficulty_label", "—"))),
					_fact("定位", str(map_data.get("role", "—"))),
					_fact("状态", "已解锁" if unlocked else "未解锁", &"positive" if unlocked else &"muted"),
				],
				"actions": [action],
				"select_action": action.duplicate(true),
				"map_projection": map_data,
				"preview": false,
				"display_only": false,
				"read_only": true,
			})
	return result


static func _warehouse_rows(config: Dictionary, selected_filter: StringName) -> Array:
	var warehouse := _dictionary_from(config.get("warehouse_lite", {}))
	var groups := _dictionary_from(warehouse.get("groups", {}))
	var selected_ids := _selected_instance_ids(config)
	var all_items := _all_warehouse_items(warehouse)
	var result := []
	var definitions := [
		{"key": &"equipment", "label": "装备", "filter": DeployTabModelScript.FILTER_WAREHOUSE_EQUIPMENT},
		{"key": &"consumable", "label": "消耗品", "filter": DeployTabModelScript.FILTER_WAREHOUSE_CONSUMABLE},
		{"key": &"collectible", "label": "藏品", "filter": DeployTabModelScript.FILTER_WAREHOUSE_COLLECTIBLE},
		{"key": &"special", "label": "特殊物", "filter": DeployTabModelScript.FILTER_WAREHOUSE_SPECIAL},
	]
	for raw_definition in definitions:
		var definition := raw_definition as Dictionary
		var filter_id := StringName(definition.get("filter", DeployTabModelScript.FILTER_ALL))
		if selected_filter != DeployTabModelScript.FILTER_ALL and selected_filter != filter_id:
			continue
		for raw_item in _group_items(groups, StringName(definition.get("key", &""))):
			var item := _dictionary_from(raw_item)
			if not item.is_empty():
				result.append(_warehouse_item_row(config, item, str(definition.get("label", "物品")), filter_id, selected_ids, all_items))
	return result


static func _warehouse_item_row(
	config: Dictionary,
	item: Dictionary,
	group_label: String,
	filter_id: StringName,
	selected_ids: Dictionary,
	all_items: Array
) -> Dictionary:
	var instance_id := str(item.get("instance_id", ""))
	var item_id := str(item.get("item_id", instance_id))
	if instance_id.is_empty():
		instance_id = item_id
	var selected := selected_ids.has(instance_id)
	var item_type := StringName(item.get("item_type", &"special"))
	var owned_count := _count_item_id(all_items, item_id)
	var deployed_count := _count_selected_item(config, item_id)
	var rarity := StringName(item.get("rarity", &"tier_1"))
	var active_locked := bool(config.get("active_run_locked", false))
	var actions := []
	if bool(item.get("can_equip", false)) or bool(item.get("can_consume", false)):
		var toggle_id := &"toggle_attendance" if bool(item.get("can_equip", false)) else &"toggle_carry"
		var toggle_label := "移出出勤" if selected else ("设为出勤" if bool(item.get("can_equip", false)) else "加入携带")
		actions.append(_action(toggle_id, toggle_label, not active_locked, false, false, &"active_run_locked" if active_locked else &"ok", {"instance_id": instance_id}))
	if bool(item.get("can_consume", false)):
		actions.append(_action(&"use", "局内使用", false, false, false, &"only_available_in_run", {"instance_id": instance_id}))
	if bool(item.get("can_sell", false)):
		var sell_enabled := not active_locked and not selected
		var sell_reason := &"ok"
		if active_locked:
			sell_reason = &"active_run_locked"
		elif selected:
			sell_reason = &"remove_from_attendance_first"
		var sell_pending := str(config.get("sell_confirm_pending_instance_id", "")) == instance_id
		var sell_label := "确认出售" if sell_pending and sell_enabled else "出售"
		actions.append(_action(&"sell", sell_label, sell_enabled, true, not sell_pending, sell_reason, {"instance_id": instance_id, "item_id": item_id}))
	return {
		"id": StringName("m3r_%s" % instance_id),
		"filter_id": filter_id,
		"title": str(item.get("display_name", item_id)),
		"category": group_label,
		"state": "selected" if selected else "owned",
		"summary": "%s · 拥有 %d · 出勤 %d" % [_rarity_label(rarity), owned_count, deployed_count],
		"detail": str(item.get("short_description", "")),
		"detail_kind": &"warehouse_item",
		"instance_id": instance_id,
		"item_id": item_id,
		"item_type": item_type,
		"rarity": rarity,
		"rarity_label": _rarity_label(rarity),
		"owned_count": owned_count,
		"deployed_count": deployed_count,
		"selected": selected,
		"weight": int(item.get("weight", 0)),
		"value": int(item.get("base_value", 0)),
		"description": str(item.get("short_description", "")),
		"source_label": str(item.get("source_label", item.get("source", "仓库"))),
		"facts": [
			_fact("品质", _rarity_label(rarity), _rarity_tone(rarity)),
			_fact("拥有 / 出勤", "%d / %d" % [owned_count, deployed_count]),
			_fact("重量", str(int(item.get("weight", 0)))),
			_fact("价值", "%d 金币" % int(item.get("base_value", 0))),
		],
		"actions": actions,
		"raw_item": item.duplicate(true),
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func _claim_rows(config: Dictionary, selected_filter: StringName) -> Array:
	var result := []
	var wallet := _wallet_projection(config)
	var active_locked := bool(config.get("active_run_locked", false))
	var claimed := _array_from(config.get("enabled_claims", [])).has(EMERGENCY_CLAIM_ID)
	if selected_filter in [DeployTabModelScript.FILTER_ALL, DeployTabModelScript.FILTER_CLAIM_RECEIVE]:
		var ration := M7ContentCatalogScript.item_definition("con_ration")
		var slot_available := _array_from(config.get("selected_consumable_items", [])).size() < MAX_CARRIED_CONSUMABLES
		var claim_enabled := not active_locked and (claimed or slot_available)
		var claim_reason := &"ok"
		if active_locked:
			claim_reason = &"active_run_locked"
		elif not claimed and not slot_available:
			claim_reason = &"supply_slots_full"
		var claim_action := _action(&"toggle_claim", "移出携带" if claimed else "领取并携带", claim_enabled, false, false, claim_reason, {"claim_id": EMERGENCY_CLAIM_ID})
		result.append({
			"id": EMERGENCY_CLAIM_CARD_ID,
			"filter_id": DeployTabModelScript.FILTER_CLAIM_RECEIVE,
			"title": "应急压缩饼",
			"category": "本局领取",
			"state": "selected" if claimed else "ready",
			"summary": "免费 · 每局 1 份 · %s" % ("已携带" if claimed else "可领取"),
			"detail": str(ration.get("short_description", "恢复少量生命。")),
			"detail_kind": &"claim",
			"item_id": "con_ration",
			"price": 0,
			"balance": wallet.get("gold", null),
			"balance_display": str(wallet.get("display", "—")),
			"unlocked": true,
			"unlock_text": "每局可领取一次",
			"claimed": claimed,
			"facts": [
				_fact("价格", "免费", &"positive"),
				_fact("余额", str(wallet.get("display", "—"))),
				_fact("解锁", "每局可领取一次"),
				_fact("终局", "清空，不进入仓库"),
			],
			"actions": [claim_action],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	if selected_filter == DeployTabModelScript.FILTER_CLAIM_RECEIVE:
		return result
	var meta := _dictionary_from(config.get("meta_progress_summary", {}))
	var shop_catalog := _array_from(meta.get("shop_catalog", M7ContentCatalogScript.shop_definitions()))
	for raw_shop in shop_catalog:
		var shop := _dictionary_from(raw_shop)
		var unlocked := bool(shop.get("unlocked", M7ContentCatalogScript.is_shop_unlocked(shop, meta)))
		if selected_filter == DeployTabModelScript.FILTER_CLAIM_PURCHASE and not unlocked:
			continue
		if selected_filter == DeployTabModelScript.FILTER_CLAIM_LOCKED and unlocked:
			continue
		var item_id := str(shop.get("item_id", ""))
		var item := M7ContentCatalogScript.item_definition(item_id)
		var price := int(shop.get("price", 0))
		var affordable := bool(wallet.get("available", false)) and int(wallet.get("gold", 0)) >= price
		var purchase_enabled := unlocked and affordable and not active_locked
		var reason_code := &"ok"
		if active_locked:
			reason_code = &"active_run_locked"
		elif not unlocked:
			reason_code = &"claim_locked"
		elif not bool(wallet.get("available", false)):
			reason_code = &"balance_unavailable"
		elif not affordable:
			reason_code = &"insufficient_gold"
		var unlock_text := _claim_unlock_text(shop, unlocked)
		var action := _action(&"purchase", "购买", purchase_enabled, false, false, reason_code, {"item_id": item_id, "price": price})
		result.append({
			"id": StringName("m7_shop_%s" % item_id),
			"filter_id": DeployTabModelScript.FILTER_CLAIM_PURCHASE if unlocked else DeployTabModelScript.FILTER_CLAIM_LOCKED,
			"title": str(shop.get("display_name", item.get("display_name", item_id))),
			"category": "基地申领",
			"state": "ready" if purchase_enabled else ("unaffordable" if unlocked else "locked"),
			"summary": "%d 金币 · 余额 %s · %s" % [price, str(wallet.get("display", "—")), "已解锁" if unlocked else "未解锁"],
			"detail": str(item.get("short_description", "购买后进入长期仓库。")),
			"detail_kind": &"claim",
			"item_id": item_id,
			"price": price,
			"balance": wallet.get("gold", null),
			"balance_display": str(wallet.get("display", "—")),
			"unlocked": unlocked,
			"affordable": affordable,
			"unlock_text": unlock_text,
			"facts": [
				_fact("价格", "%d 金币" % price),
				_fact("余额", str(wallet.get("display", "—")), &"positive" if affordable else &"warning"),
				_fact("解锁", unlock_text, &"positive" if unlocked else &"muted"),
				_fact("发放", "购买后进入仓库"),
			],
			"actions": [action],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	return result


static func _objective_rows(config: Dictionary) -> Array:
	var result := []
	var selected_id := str(config.get("selected_objective_id", ""))
	var active_locked := bool(config.get("active_run_locked", false))
	for raw_candidate in _array_from(config.get("commission_candidates", [])):
		var candidate := _dictionary_from(raw_candidate)
		var commission_id := str(candidate.get("id", ""))
		var selected := commission_id == selected_id
		var reward := _dictionary_from(candidate.get("reward", {}))
		var action := _action(
			&"select_objective",
			"已选择" if selected else "选择委托",
			not selected and not active_locked,
			false,
			false,
			&"already_selected" if selected else (&"active_run_locked" if active_locked else &"ok"),
			{"commission_id": commission_id}
		)
		result.append({
			"id": StringName("m7_commission_%s" % commission_id),
			"filter_id": DeployTabModelScript.FILTER_ALL,
			"title": str(candidate.get("display_name", commission_id)),
			"category": "本局委托",
			"state": "selected" if selected else "ready",
			"summary": "%s · %s" % [str(candidate.get("description", "")), _reward_text(reward)],
			"detail": str(candidate.get("description", "")),
			"detail_kind": &"objective",
			"commission_id": commission_id,
			"condition": str(candidate.get("description", "")),
			"metric": StringName(candidate.get("metric", &"")),
			"target": int(candidate.get("target", 0)),
			"reward": reward,
			"reward_text": _reward_text(reward),
			"selected": selected,
			"facts": [
				_fact("完成条件", str(candidate.get("description", "—"))),
				_fact("奖励", _reward_text(reward), &"positive"),
				_fact("结算", "达成条件并成功撤离"),
			],
			"actions": [action],
			"preview": false,
			"display_only": false,
			"read_only": true,
		})
	return result


static func _loadout_rows(config: Dictionary, map_projection: Dictionary) -> Array:
	var result := []
	var selected_map := _dictionary_from(map_projection.get("selected_detail", {}))
	var map_name := str(config.get("map_display_name", selected_map.get("display_name", "未选择地图")))
	var scale_label := str(selected_map.get("scale_label", "—"))
	var difficulty_label := str(config.get("difficulty_label", selected_map.get("difficulty_label", "—")))
	result.append({
		"id": &"loadout_map",
		"filter_id": DeployTabModelScript.FILTER_ALL,
		"art_filter_id": &"loadout_intent",
		"title": map_name,
		"category": "地图",
		"state": "selected",
		"summary": "已用于本次出发",
		"detail": str(selected_map.get("role", "")),
		"detail_kind": &"loadout_map",
		"facts": [_fact("规模", scale_label), _fact("难度", difficulty_label)],
		"actions": [_action(&"open_map", "修改地图", not bool(config.get("active_run_locked", false)), false, false, &"active_run_locked" if bool(config.get("active_run_locked", false)) else &"ok")],
		"preview": false,
		"display_only": false,
		"read_only": true,
	})
	var commission := _selected_commission(config)
	var objective_name := str(config.get("selected_objective_label", commission.get("display_name", "未选择委托")))
	result.append({
		"id": &"loadout_objective",
		"filter_id": DeployTabModelScript.FILTER_ALL,
		"art_filter_id": &"loadout_permission_interface",
		"title": objective_name,
		"category": "本局委托",
		"state": "selected",
		"summary": str(commission.get("description", config.get("selected_objective_summary", ""))),
		"detail": _reward_text(_dictionary_from(commission.get("reward", {}))),
		"detail_kind": &"loadout_objective",
		"facts": [
			_fact("完成条件", str(commission.get("description", "—"))),
			_fact("奖励", _reward_text(_dictionary_from(commission.get("reward", {}))), &"positive"),
		],
		"actions": [_action(&"open_objective", "修改委托", not bool(config.get("active_run_locked", false)), false, false, &"active_run_locked" if bool(config.get("active_run_locked", false)) else &"ok")],
		"preview": false,
		"display_only": false,
		"read_only": true,
	})
	var active_locked := bool(config.get("active_run_locked", false))
	for raw_item in _array_from(config.get("selected_equipment_items", [])):
		result.append(_loadout_item_row(_dictionary_from(raw_item), "装备", &"loadout_equipment", active_locked))
	for raw_item in _array_from(config.get("selected_consumable_items", [])):
		result.append(_loadout_item_row(_dictionary_from(raw_item), "补给", &"loadout_consumable", active_locked))
	var used := int(config.get("bag_used", 0))
	var limit := int(config.get("bag_limit", config.get("backpack_capacity", 10)))
	result.append({
		"id": &"loadout_capacity",
		"filter_id": DeployTabModelScript.FILTER_ALL,
		"art_filter_id": &"loadout_bag",
		"title": "携带容量",
		"category": "容量",
		"state": "ready" if used <= limit else "over_limit",
		"summary": "%d / %d" % [used, limit],
		"detail": "装备不占背包；携入补给按重量计入容量。",
		"detail_kind": &"loadout_capacity",
		"used": used,
		"limit": limit,
		"facts": [
			_fact("已用", str(used)),
			_fact("上限", str(limit)),
			_fact("剩余", str(maxi(0, limit - used)), &"positive" if used <= limit else &"warning"),
		],
		"actions": [],
		"preview": false,
		"display_only": false,
		"read_only": true,
	})
	return result


static func _loadout_item_row(item: Dictionary, category: String, prefix: StringName, active_locked: bool) -> Dictionary:
	var instance_id := str(item.get("instance_id", item.get("item_id", "item")))
	var rarity := StringName(item.get("rarity", &"tier_1"))
	return {
		"id": StringName("%s:%s" % [String(prefix), instance_id]),
		"filter_id": DeployTabModelScript.FILTER_ALL,
		"title": str(item.get("display_name", item.get("item_id", "物品"))),
		"category": category,
		"state": "selected",
		"summary": "%s · 重量 %d" % [_rarity_label(rarity), int(item.get("weight", 0))],
		"detail": str(item.get("short_description", "")),
		"detail_kind": &"loadout_item",
		"item_id": str(item.get("item_id", "")),
		"instance_id": instance_id,
		"rarity": rarity,
		"rarity_label": _rarity_label(rarity),
		"weight": int(item.get("weight", 0)),
		"facts": [
			_fact("类型", category),
			_fact("品质", _rarity_label(rarity), _rarity_tone(rarity)),
			_fact("重量", str(int(item.get("weight", 0)))),
		],
		"actions": [_action(&"remove_from_loadout", "移出携带", not active_locked, false, false, &"active_run_locked" if active_locked else &"ok", {"instance_id": instance_id})],
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func _detail_projection(active_tab: StringName, selected_row: Dictionary) -> Dictionary:
	if selected_row.is_empty():
		return {
			"kind": active_tab,
			"empty": true,
			"title": _empty_state_for(active_tab),
			"description": "",
			"facts": [],
			"actions": [],
			"read_only": true,
		}
	var result := {
		"kind": StringName(selected_row.get("detail_kind", active_tab)),
		"empty": false,
		"id": StringName(selected_row.get("id", &"")),
		"title": str(selected_row.get("title", "")),
		"subtitle": str(selected_row.get("summary", "")),
		"description": str(selected_row.get("description", selected_row.get("detail", ""))),
		"state": str(selected_row.get("state", "")),
		"facts": _array_from(selected_row.get("facts", [])),
		"actions": _array_from(selected_row.get("actions", [])),
		"read_only": true,
	}
	for key in [
		"map_config_id", "scale_id", "scale_label", "difficulty", "difficulty_label", "unlocked",
		"instance_id", "item_id", "item_type", "rarity", "rarity_label", "owned_count", "deployed_count", "weight", "value",
		"price", "balance", "balance_display", "affordable", "unlock_text", "claimed",
		"commission_id", "condition", "metric", "target", "reward", "reward_text", "used", "limit"
	]:
		if selected_row.has(key):
			result[key] = selected_row[key]
	return result


static func _summary_projection(config: Dictionary, map_projection: Dictionary) -> Dictionary:
	var selected_map := _dictionary_from(map_projection.get("selected_detail", {}))
	var map_name := str(config.get("map_display_name", selected_map.get("display_name", "未选择地图")))
	var scale_label := str(selected_map.get("scale_label", "—"))
	var difficulty_label := str(config.get("difficulty_label", selected_map.get("difficulty_label", "—")))
	var commission := _selected_commission(config)
	var objective_name := str(config.get("selected_objective_label", commission.get("display_name", "未选择委托")))
	var condition := str(commission.get("description", config.get("selected_objective_summary", "—")))
	var reward_text := _reward_text(_dictionary_from(commission.get("reward", {})))
	var equipment := _array_from(config.get("selected_equipment_items", []))
	var consumables := _array_from(config.get("selected_consumable_items", []))
	var equipment_names := _item_names(equipment, "未携带装备")
	var consumable_names := _item_names(consumables, "未携带补给")
	var used := int(config.get("bag_used", 0))
	var limit := int(config.get("bag_limit", config.get("backpack_capacity", 10)))
	var map_summary := _map_summary_text(map_name, scale_label, difficulty_label)
	var overview := [
		map_summary,
		"委托：%s" % objective_name,
		"携带：%s；%s" % [equipment_names, consumable_names],
		"容量：%d / %d" % [used, limit],
	]
	var config_lines := [
		"地图：%s" % map_summary,
		"委托：%s" % objective_name,
		"装备：%s" % equipment_names,
		"补给：%s" % consumable_names,
		"容量：%d / %d" % [used, limit],
	]
	var effect_lines := _effect_summary_lines(config, equipment, consumables)
	var objective_lines := [
		"委托：%s" % objective_name,
		"条件：%s" % condition,
		"奖励：%s" % reward_text,
	]
	var pages := {
		"overview": overview,
		"config": config_lines,
		"effect": effect_lines,
		"objective": objective_lines,
	}
	return {
		"page_ids": [&"overview", &"config", &"effect", &"objective"],
		"active_page": &"overview",
		"pages": pages,
		"overview": overview.duplicate(true),
		"config": config_lines.duplicate(true),
		"effect": effect_lines.duplicate(true),
		"objective": objective_lines.duplicate(true),
		"read_only": true,
	}


static func _map_summary_text(map_name: String, scale_label: String, difficulty_label: String) -> String:
	var parts := PackedStringArray([map_name])
	if not scale_label.is_empty() and scale_label != "—" and map_name.find(scale_label) < 0:
		parts.append(scale_label)
	if not difficulty_label.is_empty() and difficulty_label != "—" and map_name.find(difficulty_label) < 0:
		parts.append(difficulty_label)
	return " · ".join(parts)


static func _legacy_preview_lines(summary_projection: Dictionary) -> Dictionary:
	var pages := _dictionary_from(summary_projection.get("pages", {}))
	var objective := _array_from(pages.get("objective", []))
	return {
		"summary": _array_from(pages.get("overview", [])),
		"config": _array_from(pages.get("config", [])),
		"effect": _array_from(pages.get("effect", [])),
		"objective": objective,
		# Legacy shell alias only; risk is not a summary page in the I2 model.
		"risk": objective.duplicate(true),
	}


static func _effect_summary_lines(config: Dictionary, equipment: Array, consumables: Array) -> Array:
	var result := []
	for raw_effect in _array_from(config.get("equipment_effects", [])):
		var effect := _dictionary_from(raw_effect)
		result.append("%s：%s" % [str(effect.get("display_name", effect.get("item_id", "装备"))), _effect_text(str(effect.get("effect_kind", "")), int(effect.get("effect_amount", 0)))])
	for raw_item in consumables:
		var item := _dictionary_from(raw_item)
		result.append("%s：%s" % [str(item.get("display_name", item.get("item_id", "补给"))), str(item.get("short_description", "局内使用"))])
	if result.is_empty():
		result.append("本局无额外装备或补给效果")
	result.append("背包容量 %d；失败抢救容量 %d" % [int(config.get("bag_limit", 10)), int(config.get("failure_salvage_capacity", 4))])
	return result


static func _local_draft_preview(config: Dictionary) -> Dictionary:
	return {
		"map": {
			"summary": str(config.get("selected_map_summary", "")),
			"map_mode": str(config.get("map_mode_label", "常规扫雷")),
			"difficulty": str(config.get("difficulty_label", "普通")),
			"region": str(config.get("region_label", "")),
		},
		"warehouse": _dictionary_from(config.get("warehouse_attendance_preview", {})),
		"claim": _dictionary_from(config.get("claim_preview", {})),
		"objective": _dictionary_from(config.get("objective_preview", {})),
		"loadout": _dictionary_from(config.get("loadout_preview", {})),
		"backpack_capacity": _dictionary_from(config.get("backpack_capacity_preview", {})),
		"validity": _dictionary_from(config.get("config_validity_preview", {})),
		"permission_interface": _dictionary_from(config.get("permission_interface_preview", {})),
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
		"continue": {"disabled": not run_active, "disabled_reason": &"" if run_active else &"no_active_run"},
		"abandon": {"disabled": not run_active, "disabled_reason": &"" if run_active else &"no_active_run", "strong_confirm_required": run_active},
		"read_only": true,
		"display_only": false,
		"preview": false,
		"no_persistence": true,
	}


static func _actions(run_active: bool) -> Dictionary:
	return {
		"start": {
			"label": "确认出发",
			"disabled": run_active,
			"run_intent": {"target_route": &"run", "route_mode": &"standard_run", "entry_id": &"deploy_prep_start_bridge", "deploy_config_bridge": true, "uses_existing_route": true},
		},
		"continue": {"label": "继续探索", "disabled": not run_active, "has_active_run": run_active, "disabled_reason": &"" if run_active else &"no_active_run"},
		"abandon": {"label": "放弃探索", "disabled": not run_active, "requires_confirm": run_active, "disabled_reason": &"" if run_active else &"no_active_run", "confirm_copy": "放弃会失去黑色资源和全部物品；直接获得的金币保留。"},
	}


static func _action(
	id: StringName,
	label: String,
	enabled: bool,
	destructive: bool,
	requires_confirm: bool,
	reason_code: StringName,
	payload: Dictionary = {}
) -> Dictionary:
	return {
		"id": id,
		"action": id,
		"label": label,
		"enabled": enabled,
		"destructive": destructive,
		"requires_confirm": requires_confirm,
		"reason_code": reason_code,
		"payload": payload.duplicate(true),
	}


static func _fact(label: String, value: String, tone: StringName = &"normal") -> Dictionary:
	return {"label": label, "value": value, "tone": tone}


static func _find_visible_card(rows: Array, selected_card: StringName) -> Dictionary:
	for raw_row in rows:
		var row := _dictionary_from(raw_row)
		if StringName(row.get("id", &"")) == selected_card:
			return row
	return {}


static func _selected_instance_ids(config: Dictionary) -> Dictionary:
	var result := {}
	for raw_item in _array_from(config.get("selected_equipment_items", [])) + _array_from(config.get("selected_consumable_items", [])):
		var item := _dictionary_from(raw_item)
		var instance_id := str(item.get("instance_id", ""))
		var item_id := str(item.get("item_id", ""))
		if instance_id != "":
			result[instance_id] = true
		elif item_id != "":
			result[item_id] = true
	return result


static func _without_sell_confirmation(config: Dictionary) -> Dictionary:
	if not config.has("sell_confirm_pending_instance_id"):
		return config
	var result := config.duplicate(true)
	result.erase("sell_confirm_pending_instance_id")
	return result


static func _all_warehouse_items(warehouse: Dictionary) -> Array:
	var result := []
	var groups := _dictionary_from(warehouse.get("groups", {}))
	for group_id in [&"equipment", &"consumable", &"collectible", &"special"]:
		result.append_array(_group_items(groups, group_id))
	return result


static func _count_item_id(items: Array, item_id: String) -> int:
	var count := 0
	for raw_item in items:
		if str(_dictionary_from(raw_item).get("item_id", "")) == item_id:
			count += 1
	return count


static func _count_selected_item(config: Dictionary, item_id: String) -> int:
	return _count_item_id(_array_from(config.get("selected_equipment_items", [])) + _array_from(config.get("selected_consumable_items", [])), item_id)


static func _group_items(groups: Dictionary, key: StringName) -> Array:
	if groups.has(key):
		return _array_from(groups.get(key, []))
	var text_key := str(key)
	if groups.has(text_key):
		return _array_from(groups.get(text_key, []))
	return []


static func _selected_commission(config: Dictionary) -> Dictionary:
	var selected_id := str(config.get("selected_objective_id", ""))
	for raw_candidate in _array_from(config.get("commission_candidates", [])):
		var candidate := _dictionary_from(raw_candidate)
		if str(candidate.get("id", "")) == selected_id:
			return candidate
	return {}


static func _claim_unlock_text(shop: Dictionary, unlocked: bool) -> String:
	if unlocked:
		return "已解锁"
	match str(shop.get("unlock_kind", "default")):
		"research":
			return "需完成研究：%s" % str(shop.get("unlock_value", ""))
		"profile":
			return "档案等级达到 %s" % str(shop.get("unlock_value", ""))
	return "尚未解锁"


static func _rarity_label(rarity: StringName) -> String:
	match rarity:
		&"tier_1": return "普通"
		&"tier_2": return "优良"
		&"tier_3": return "稀有"
		&"tier_4": return "珍贵"
		&"unique": return "唯一"
	return "未知"


static func _rarity_tone(rarity: StringName) -> StringName:
	match rarity:
		&"tier_2": return &"uncommon"
		&"tier_3": return &"rare"
		&"tier_4": return &"epic"
		&"unique": return &"unique"
	return &"common"


static func _reward_text(reward: Dictionary) -> String:
	var parts := []
	if int(reward.get("gold", 0)) > 0:
		parts.append("金币 %d" % int(reward.get("gold", 0)))
	if int(reward.get("exp", 0)) > 0:
		parts.append("经验 %d" % int(reward.get("exp", 0)))
	var items := _array_from(reward.get("items", []))
	if not items.is_empty():
		parts.append("物品 %s" % ", ".join(PackedStringArray(items)))
	return "无" if parts.is_empty() else " · ".join(PackedStringArray(parts))


static func _item_names(items: Array, empty_text: String) -> String:
	var names := PackedStringArray()
	for raw_item in items:
		var item := _dictionary_from(raw_item)
		names.append(str(item.get("display_name", item.get("item_id", "物品"))))
	return empty_text if names.is_empty() else "、".join(names)


static func _effect_text(kind: String, amount: int) -> String:
	match kind:
		"backpack_capacity": return "背包容量 +%d" % amount
		"salvage_capacity": return "失败抢救容量 +%d" % amount
		"mine_damage_reduce": return "触雷伤害降低 %d" % amount
		"protocol_pressure_reduce": return "协议压力增量降低 %d" % amount
		"search_reward": return "搜索收益判定 +%d" % amount
		"scan_hint": return "扫描提示 +%d" % amount
	return "%s %+d" % [kind, amount]


static func _empty_state_for(tab_id: StringName) -> String:
	match tab_id:
		DeployTabModelScript.TAB_WAREHOUSE: return "仓库暂无物品"
		DeployTabModelScript.TAB_CLAIM: return "暂无可申领物资"
		DeployTabModelScript.TAB_OBJECTIVE: return "暂无可接委托"
		DeployTabModelScript.TAB_LOADOUT: return "携带清单为空"
	return "暂无可用地图"


static func _array_from(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []


static func _dictionary_from(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


static func _config_from(model: Dictionary) -> Dictionary:
	var raw: Variant = model.get("config", {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else DeployConfigScript.default_config()


static func _has_active_run(config: Dictionary) -> bool:
	var active_run := _dictionary_from(config.get("active_run_preview", {}))
	return bool(active_run.get("has_active_run", false))
