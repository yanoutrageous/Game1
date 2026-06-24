extends RefCounted
class_name RunSurfaceModel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const PresentationTheme := preload("res://scripts/presentation/presentation_theme.gd")


static func build(snapshot: Dictionary, minimap_view_model: MiniMapViewModel, layout_profile: Dictionary, last_command_result: Dictionary) -> Dictionary:
	var position: Vector2i = snapshot.get("position", snapshot.get("player_pos", Vector2i.ZERO))
	var room_type := StringName(snapshot.get("current_room", &"Unknown"))
	var adjacent_mines := int(snapshot.get("adjacent_mines", 0))
	var event_state: Dictionary = _dict_from(snapshot, "event_state")
	var search_data: Dictionary = _dict_from(snapshot, "search_state_data")
	var reward: Dictionary = _dict_from(snapshot, "last_reward")
	var run_map_snapshot: Dictionary = _dict_from(snapshot, "run_map_snapshot")
	var run_flow_snapshot: Dictionary = _dict_from(snapshot, "run_flow_snapshot")
	var current_room_detail: Dictionary = _dict_from(snapshot, "current_room_detail")
	var return_eligibility: Dictionary = _dict_from(snapshot, "return_eligibility")
	var encounter_section := _encounter_section(snapshot)
	var last_message := String(snapshot.get("last_message", ""))
	var command_feedback := RunUIViewModel.command_result_text(last_command_result)
	if command_feedback == "":
		command_feedback = _player_message(last_message)
	var action_data := _action_buttons(snapshot, search_data, event_state, room_type)

	return {
		"room_title": _room_label(room_type),
		"room_type": room_type,
		"room_position": position,
		"room_coordinate": "(%d,%d)" % [position.x, position.y],
		"room_summary": _room_summary(snapshot, room_type, adjacent_mines),
		"current_objective": _objective_for_room(room_type, search_data, event_state),
		"protocol_level": snapshot.get("protocol_level", 5),
		"pressure": snapshot.get("pressure", 0),
		"danger_label": _danger_label(room_type, adjacent_mines),
		"danger_theme_key": PresentationTheme.risk_key(adjacent_mines, room_type),
		"event_summary": _event_summary(event_state),
		"search_summary": _search_summary(search_data, String(snapshot.get("search_state", "blocked"))),
		"reward_summary": RunUIViewModel.reward_text(reward, last_message),
		"backpack_summary": _backpack_summary(snapshot),
		"resource_summary": _resource_summary(snapshot),
		"command_feedback": command_feedback,
		"encounter_section": encounter_section,
		"scanner_summary": _scanner_summary(minimap_view_model, position),
		"scanner_legend_lines": _scanner_legend_lines(minimap_view_model),
		"scanner_detail": _scanner_detail(minimap_view_model, run_map_snapshot),
		"scanner_markers": _scanner_markers(minimap_view_model),
		"status_lines": _status_lines(snapshot, room_type, adjacent_mines, search_data, current_room_detail, return_eligibility, run_flow_snapshot),
		"map_domain_summary": _map_domain_summary(run_map_snapshot),
		"run_flow_summary": _run_flow_summary(run_flow_snapshot),
		"room_state_detail": _room_state_detail(current_room_detail),
		"return_eligibility_summary": _return_eligibility_summary(return_eligibility),
		"settlement_trigger_summary": _settlement_trigger_summary(run_flow_snapshot),
		"event_panel_summary": event_modal_text(event_state),
		"loot_panel_summary": loot_modal_text(reward, last_message),
		"extract_summary": extract_modal_text(snapshot),
		"action_hint": _action_hint(action_data),
		"action_buttons": action_data,
		"layout_profile": layout_profile.duplicate(true),
	}


static func _encounter_section(snapshot: Dictionary) -> Dictionary:
	var view_model: Dictionary = _dict_from(snapshot, "encounter_view_model")
	var result_summary: Dictionary = _dict_from(snapshot, "encounter_result_summary")
	if result_summary.is_empty():
		result_summary = _dict_variant(view_model.get("result_summary", {}))
	var state: Dictionary = _dict_variant(view_model.get("state", {}))
	var encounter_type := StringName(view_model.get("encounter_type", state.get("encounter_type", &"none")))
	var state_id := StringName(state.get("state", &"unavailable"))
	var title := _encounter_title(String(state.get("title", "遭遇槽")))
	var description := _encounter_description(String(state.get("description", "当前遭遇无公开信息。")))
	var monster_summary := _dict_variant(view_model.get("monster_summary", {}))
	var options := _encounter_options(_array_variant(view_model.get("options", [])))
	var body_lines: Array[String] = [
		"类型：%s | 状态：%s" % [_encounter_type_label(encounter_type), _encounter_state_label(state_id)],
		description,
	]
	if not monster_summary.is_empty():
		body_lines.append(_monster_summary_text(monster_summary))
	if options.is_empty():
		body_lines.append(_encounter_empty_options_text(encounter_type, state_id))
	return {
		"title": title,
		"body": _join_lines(body_lines),
		"options": options,
		"result_summary": _encounter_result_text(result_summary),
	}


static func _encounter_options(raw_options: Array) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for option_variant in raw_options:
		if not (option_variant is Dictionary):
			continue
		var option: Dictionary = option_variant
		var option_id := StringName(option.get("id", &""))
		var command_payload := _dict_variant(option.get("command_payload", {}))
		var command_name := StringName(option.get("command_name", &"select_encounter_option"))
		var disabled := bool(option.get("disabled", false))
		var disabled_reason := String(option.get("disabled_reason", ""))
		if command_name != &"select_encounter_option":
			disabled = true
			disabled_reason = "unsupported_command:%s" % String(command_name)
		elif not command_payload.has("option_id"):
			disabled = true
			disabled_reason = "missing_option_payload"
		var requires_confirm := bool(option.get("requires_confirm", false))
		var summary_lines: Array[String] = [
			"花费：%s" % _dict_summary(_dict_variant(option.get("cost", {})), "无"),
			"预期：%s" % _dict_summary(_dict_variant(option.get("expected_reward", {})), "待定"),
			"风险：%s" % _dict_summary(_dict_variant(option.get("risk", {})), "低"),
		]
		if requires_confirm:
			summary_lines.append("标记：需确认")
		if disabled:
			summary_lines.append("禁用：%s" % _reason_label(disabled_reason))
		options.append({
			"id": option_id,
			"title": _option_title(String(option.get("title", option_id))),
			"summary": _join_lines(summary_lines),
			"disabled": disabled,
			"disabled_reason": _reason_label(disabled_reason),
			"requires_confirm": requires_confirm,
			"command_payload": command_payload.duplicate(true),
		})
	return options


static func _encounter_result_text(result_summary: Dictionary) -> String:
	if result_summary.is_empty():
		return "最近结果：暂无遭遇结果。"
	var encounter_type := StringName(result_summary.get("encounter_type", &"none"))
	var option_id := StringName(result_summary.get("option_id", &""))
	if encounter_type == &"none" and option_id == &"":
		return "最近结果：暂无遭遇结果。"
	var ok := bool(result_summary.get("ok", false))
	var lines: Array[String] = [
		"最近结果：%s | 类型：%s" % ["成功" if ok else "未完成", _encounter_type_label(encounter_type)],
	]
	if option_id != &"":
		lines.append("选项：%s" % String(option_id))
	var blocked_reason := String(result_summary.get("blocked_reason", ""))
	if blocked_reason != "":
		lines.append("阻止原因：%s" % _reason_label(blocked_reason))
	var effect_summary := _dict_variant(result_summary.get("effect_summary", {}))
	if not effect_summary.is_empty():
		lines.append("影响：%s" % _effect_summary(effect_summary))
	var messages := _array_variant(result_summary.get("messages", []))
	if not messages.is_empty():
		lines.append("记录：%s" % String(messages[0]))
	return _join_lines(lines)


static func _encounter_empty_options_text(encounter_type: StringName, state_id: StringName) -> String:
	if state_id == &"reserved":
		return "当前遭遇为后续阶段预留，暂无可执行选项。"
	if state_id == &"completed":
		return "当前遭遇已处理完成。"
	match encounter_type:
		&"combat", &"combat_basic", &"monster_basic":
			return "战斗遭遇当前没有可执行攻击选项；可能已清理或命令被阻止。"
		&"extract", &"exit_beacon":
			return "撤离仍走既有撤离按钮和确认路径。"
		_:
			return "当前遭遇无可用选项。"


static func _encounter_type_label(encounter_type: StringName) -> String:
	match encounter_type:
		&"search_basic":
			return "搜索"
		&"chest_basic":
			return "物资箱"
		&"event":
			return "事件"
		&"combat":
			return "战斗"
		&"combat_basic":
			return "基础战斗"
		&"monster_basic":
			return "怪物遭遇"
		&"extract", &"exit_beacon":
			return "撤离"
		&"lottery":
			return "抽奖预留"
		&"none":
			return "无"
		_:
			return String(encounter_type)


static func _encounter_state_label(state_id: StringName) -> String:
	match state_id:
		&"available":
			return "可处理"
		&"completed":
			return "已完成"
		&"reserved":
			return "预留"
		&"unavailable":
			return "不可用"
		_:
			return String(state_id)


static func _option_title(raw_title: String) -> String:
	match raw_title:
		"Search room":
			return "搜索房间"
		"Open chest":
			return "开启物资箱"
		"Basic attack":
			return "基础攻击"
		"Attack monster":
			return "基础攻击"
		"Close":
			return "关闭遭遇"
		_:
			return raw_title


static func _dict_summary(data: Dictionary, fallback: String) -> String:
	if data.is_empty():
		return fallback
	var parts: Array[String] = []
	for key_variant in data.keys():
		var key := String(key_variant)
		parts.append("%s=%s" % [_field_label(key), _value_label(data[key_variant])])
	return _join_parts(parts, "，")


static func _effect_summary(effect_summary: Dictionary) -> String:
	var parts: Array[String] = []
	var fields := {
		"black_coin_delta": "黑币",
		"gold_coin_delta": "金币",
		"item_delta": "物品",
		"backpack_delta": "背包",
		"hp_delta": "生命",
		"pressure_delta": "压力",
	}
	for key_variant in fields.keys():
		var key := String(key_variant)
		var value := int(effect_summary.get(key, 0))
		if value != 0:
			var sign := "+" if value > 0 else ""
			parts.append("%s%s%s" % [String(fields[key_variant]), sign, value])
	var room_state_delta := _dict_variant(effect_summary.get("room_state_delta", {}))
	if not room_state_delta.is_empty():
		parts.append("房间：%s" % _dict_summary(room_state_delta, "无"))
	var encounter_state_delta := _dict_variant(effect_summary.get("encounter_state_delta", {}))
	if not encounter_state_delta.is_empty():
		parts.append("遭遇：%s" % _dict_summary(encounter_state_delta, "无"))
	if parts.is_empty():
		return "无直接数值变化"
	return _join_parts(parts, "，")


static func _field_label(key: String) -> String:
	match key:
		"black_coin":
			return "黑币"
		"gold_coin":
			return "金币"
		"items":
			return "物品"
		"status_effects":
			return "状态"
		"adjacent_danger":
			return "周围危险"
		"enemy_power":
			return "敌方战斗力"
		"player_power":
			return "我方战斗力"
		"base_power":
			return "基础战斗力"
		"current_power":
			return "当前战斗力"
		"power_gain":
			return "力量成长"
		"blocked_if_defeated":
			return "失败无奖励"
		"cleared":
			return "已清理"
		"fought":
			return "已交战"
		"player_win":
			return "玩家胜利"
		"codex_ref":
			return "图鉴接口"
		"black_coin_loss":
			return "黑币损失"
		"hp_loss":
			return "生命损失"
		"pressure":
			return "压力"
		"hp":
			return "生命"
		_:
			return key


static func _encounter_title(raw_title: String) -> String:
	match raw_title:
		"Search encounter":
			return "搜索遭遇"
		"Reward encounter":
			return "物资遭遇"
		"Combat encounter":
			return "战斗遭遇"
		"Monster combat encounter":
			return "怪物遭遇"
		"Extraction encounter":
			return "撤离遭遇"
		"No encounter":
			return "无遭遇"
		_:
			if raw_title.begins_with("Event encounter: "):
				return "事件遭遇：%s" % raw_title.substr("Event encounter: ".length())
			return raw_title


static func _encounter_description(raw_description: String) -> String:
	match raw_description:
		"No active run.":
			return "当前没有运行中的探索。"
		"This encounter has already been resolved.":
			return "当前遭遇已处理完成。"
		"Search the room through the existing search command path.":
			return "通过现有搜索命令处理当前房间。"
		"Open the reward container through the existing search command path.":
			return "通过现有搜索命令开启物资箱。"
		"Choose an event option. Resolution stays in existing event rules.":
			return "选择事件选项；结算仍由现有事件规则处理。"
		"Combat is reserved for a later combat encounter stage.":
			return "战斗遭遇预留到后续战斗阶段。"
		"Resolve the monster through the existing deterministic combat command path.":
			return "通过现有确定性战斗命令处理当前怪物遭遇。"
		"Extraction remains on existing request/confirm extract commands.":
			return "撤离仍走现有请求/确认撤离命令。"
		_:
			if raw_description.begins_with("No active encounter option for "):
				return "当前类型暂无可执行遭遇选项。"
			return raw_description


static func _value_label(value: Variant) -> String:
	if value is StringName:
		return String(value)
	if value is String:
		match String(value):
			"possible":
				return "可能获得"
			"roll_dependent":
				return "掷骰决定"
			"power_dependent":
				return "力量决定"
			"sell_best_inventory_item":
				return "出售背包最高价值物品"
			"none":
				return "无"
			"future_codex_monster_basic":
				return "后续图鉴接口预留"
			_:
				return String(value)
	if value is bool:
		return "是" if bool(value) else "否"
	return String(value)


static func _reason_label(reason: String) -> String:
	match reason:
		"":
			return "无"
		"searched":
			return "该房间已搜索"
		"not_chest":
			return "当前不是物资箱房间"
		"not_search_room":
			return "当前不是可搜索房间"
		"not_ready":
			return "遭遇尚未准备"
		"no_inventory_item":
			return "背包没有可用物品"
		"not_enough_black_coin":
			return "黑币不足"
		"not_enough_hp":
			return "生命不足"
		"event_option_unavailable":
			return "事件选项暂不可用"
		"monster_cleared":
			return "当前怪物已清理"
		"missing_option_payload":
			return "缺少公开 option payload"
		_:
			return reason


static func _action_buttons(snapshot: Dictionary, search_data: Dictionary, event_state: Dictionary, room_type: StringName) -> Array[Dictionary]:
	var run_active := bool(snapshot.get("run_active", false))
	var phase := StringName(snapshot.get("phase", &"idle"))
	var has_event := not event_state.is_empty()
	var can_search := bool(search_data.get("can_search", false))
	var floor_count := int(snapshot.get("room_floor_item_count", 0))
	return [
		_action(&"interact", "搜索 / 交互", run_active and (can_search or has_event or room_type == &"Exit"), _interact_hint(room_type, search_data, has_event)),
		_action(&"inventory", "背包", run_active, "查看背包和装备摘要。"),
		_action(&"ground_loot", "地面物品", run_active and floor_count > 0, "查看当前房间地面物品。"),
		_action(&"map", "区域扫描", run_active, "打开大地图扫描视图。"),
		_action(&"combat", "清理威胁", run_active and room_type == &"Monster", "当前房间存在可清理威胁时可用。"),
		_action(&"extract", "撤离", run_active and (room_type == &"Exit" or phase == &"confirm_extract"), "在撤离点请求或确认撤离。"),
		_action(&"pause", "暂停", run_active, "打开暂停和设置入口。"),
	]


static func _action(action_id: StringName, label: String, enabled: bool, description: String) -> Dictionary:
	return {
		"id": action_id,
		"label": label,
		"enabled": enabled,
		"description": description,
		"disabled_reason": "" if enabled else description,
		"tone": _action_tone(action_id),
	}


static func _action_tone(action_id: StringName) -> StringName:
	match action_id:
		&"interact":
			return &"primary"
		&"combat":
			return &"danger"
		&"extract":
			return &"danger"
		&"ground_loot":
			return &"warning"
		_:
			return &"secondary"


static func event_modal_text(event_state: Dictionary) -> String:
	if event_state.is_empty():
		return "事件通道：暂无待处理事件。\n提示：事件判定仍由现有 run_scene / CommandBus 路径处理。"
	var event_type := String(event_state.get("event_type", event_state.get("type", "event")))
	var options: Array = _array_variant(event_state.get("options", []))
	var lines: Array[String] = []
	lines.append("事件通道：%s" % event_type)
	lines.append("状态：等待选择处理方式；完成后不会重复结算奖励。")
	lines.append("可选项：%s" % options.size())
	for option_variant in options:
		if not (option_variant is Dictionary):
			continue
		var option: Dictionary = option_variant
		var option_label := String(option.get("label", option.get("id", "option")))
		var enabled_text := "可执行" if bool(option.get("enabled", true)) else "暂不可用"
		lines.append("- %s [%s]" % [option_label, enabled_text])
	lines.append("边界：这里只展示事件表层，规则分支不在 UI 中判定。")
	return _join_lines(lines)


static func loot_modal_text(reward: Dictionary, last_message: String = "") -> String:
	var reward_text := RunUIViewModel.reward_text(reward, last_message)
	if reward_text == "":
		reward_text = "暂无新的回收记录。"
	return "回收记录\n%s\n\n提示：拾取、丢弃和容量检查仍通过现有背包/地面物品路径。" % reward_text


static func extract_modal_text(snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("撤离协议：等待最终确认")
	lines.append("待结算黑币：%s" % snapshot.get("black_coin", snapshot.get("pending_gold", 0)))
	lines.append("安全金币：%s" % snapshot.get("gold_coin", snapshot.get("safe_gold", 0)))
	lines.append("背包：%s/%s" % [snapshot.get("backpack_used", 0), snapshot.get("backpack_capacity", 0)])
	lines.append("当前房间地面遗留：%s" % snapshot.get("room_floor_item_count", 0))
	lines.append("确认后进入既有结算路径；取消会返回当前 run。")
	return _join_lines(lines)


static func _room_summary(snapshot: Dictionary, room_type: StringName, adjacent_mines: int) -> String:
	var lines: Array[String] = []
	lines.append("模式：%s | 阶段：%s" % [String(snapshot.get("mode", &"")), String(snapshot.get("phase", &""))])
	lines.append("房间：%s | 周边危险：%s" % [_room_label(room_type), adjacent_mines])
	lines.append("状态：%s | 地面物品：%s" % [String(snapshot.get("outcome", "Running")), snapshot.get("room_floor_item_count", 0)])
	return _join_lines(lines)


static func _objective_for_room(room_type: StringName, search_data: Dictionary, event_state: Dictionary) -> String:
	if not event_state.is_empty():
		return "处理当前事件选项，或关闭后继续探索。"
	if bool(search_data.get("can_search", false)):
		return "搜索当前房间，回收可用物资。"
	match room_type:
		&"Exit":
			return "撤离点已发现，确认带出资源。"
		&"Monster":
			return "清理威胁后继续推进。"
		&"Mine":
			return "雷险区域，谨慎穿越并观察扫描器。"
		&"Spawn":
			return "从出发点向未知区域推进。"
		_:
			return "继续移动、扫描和记录区域状态。"


static func _danger_label(room_type: StringName, adjacent_mines: int) -> String:
	if room_type == &"Mine":
		return "雷险确认"
	if room_type == &"Monster":
		return "威胁接触"
	if adjacent_mines >= 3:
		return "高危邻近"
	if adjacent_mines >= 1:
		return "风险邻近"
	return "暂稳"


static func _event_summary(event_state: Dictionary) -> String:
	if event_state.is_empty():
		return "事件：无待处理事件。"
	var event_type := String(event_state.get("event_type", event_state.get("type", "event")))
	var option_count := 0
	var options: Variant = event_state.get("options", [])
	if options is Array:
		option_count = (options as Array).size()
	return "事件：%s | 可选项：%s" % [event_type, option_count]


static func _search_summary(search_data: Dictionary, search_state: String) -> String:
	if search_data.is_empty():
		return "搜索：暂无公开搜索状态。"
	if bool(search_data.get("searched", false)):
		return "搜索：当前房间已搜索。"
	if bool(search_data.get("can_search", false)):
		return "搜索：可执行，原因 %s。" % String(search_data.get("reason", search_state))
	return "搜索：不可执行，原因 %s。" % String(search_data.get("reason", search_state))


static func _backpack_summary(snapshot: Dictionary) -> String:
	var inventory_items: Array = _array_from(snapshot, "inventory_items")
	var equipped_items: Array = _array_from(snapshot, "equipped_items")
	return "背包：%s/%s | 物品 %s | 装备 %s" % [
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		inventory_items.size(),
		equipped_items.size(),
	]


static func _resource_summary(snapshot: Dictionary) -> String:
	return "黑币 %s | 金币 %s | 零件 %s | HP %s/%s" % [
		snapshot.get("black_coin", 0),
		snapshot.get("gold_coin", 0),
		snapshot.get("parts", 0),
		snapshot.get("hp", 0),
		snapshot.get("max_hp", 0),
	]


static func _monster_summary_text(monster_summary: Dictionary) -> String:
	var display_name := String(monster_summary.get("display_name", "Anomaly"))
	var lines: Array[String] = [
		"目标：%s | 状态：%s" % [display_name, "已清理" if bool(monster_summary.get("cleared", false)) else "接触中"],
		"战力：我方 %s / 敌方 %s（基础 %s）" % [
			monster_summary.get("player_power", 0),
			monster_summary.get("current_power", monster_summary.get("enemy_power", 0)),
			monster_summary.get("base_power", 0),
		],
		"预期奖励：%s" % _dict_summary(_dict_variant(monster_summary.get("reward_preview", {})), "无"),
		"风险预估：%s" % _dict_summary(_dict_variant(monster_summary.get("risk_summary", {})), "低"),
	]
	var codex_ref := String(monster_summary.get("codex_ref", ""))
	if codex_ref != "":
		lines.append("图鉴：%s" % _value_label(codex_ref))
	return _join_lines(lines)


static func _status_lines(snapshot: Dictionary, room_type: StringName, adjacent_mines: int, search_data: Dictionary, room_detail: Dictionary = {}, return_eligibility: Dictionary = {}, run_flow_snapshot: Dictionary = {}) -> Array[String]:
	var lifecycle: Dictionary = _dict_variant(run_flow_snapshot.get("RunLifecycle", {}))
	var transition: Dictionary = _dict_variant(run_flow_snapshot.get("RoomTransition", {}))
	return [
		"协议：%s | 压力：%s/100" % [snapshot.get("protocol_level", 5), snapshot.get("pressure", 0)],
		"危险：%s | 周边雷险：%s" % [_danger_label(room_type, adjacent_mines), adjacent_mines],
		"房间状态：%s | 阶段：%s" % [String(snapshot.get("outcome", "Running")), String(snapshot.get("phase", &"running"))],
		"%s" % _search_summary(search_data, String(snapshot.get("search_state", "blocked"))),
		"RunLifecycle: %s / locked=%s" % [String(lifecycle.get("state", "initialized")), str(bool(lifecycle.get("locked", false)))],
		"RoomTransition: %s / %s" % [String(transition.get("entry_mode", "adjacent_or_return_preview")), String(transition.get("illegal_target_policy", "disabled_reason_only"))],
		"RoomState: %s / %s" % [String(room_detail.get("known_state", "unknown")), String(room_detail.get("visibility", "unknown"))],
		"fast_return: %s / %s" % [str(bool(return_eligibility.get("eligible", false))), String(return_eligibility.get("reason_code", "unknown"))],
	]


static func _scanner_legend_lines(minimap_view_model: MiniMapViewModel) -> Array[String]:
	if minimap_view_model == null:
		return ["P 当前 | ? 未知", "F 标记 | ! 危险", "E 事件 | $ 奖励 | X 撤离"]
	var flagged := 0
	var hidden := 0
	var danger := 0
	var event_count := 0
	var reward := 0
	var exit_count := 0
	for marker_variant in minimap_view_model.room_markers:
		if not (marker_variant is Dictionary):
			continue
		var marker: Dictionary = marker_variant
		var room_type := StringName(marker.get("room_type", &"Unknown"))
		if bool(marker.get("flagged", false)):
			flagged += 1
		if not bool(marker.get("revealed", false)) and StringName(marker.get("state", &"hidden")) == &"hidden":
			hidden += 1
		if room_type == &"Mine" or room_type == &"Monster" or int(marker.get("adjacent_mines", -1)) >= 3:
			danger += 1
		if room_type == &"Event":
			event_count += 1
		if room_type == &"Chest":
			reward += 1
		if room_type == &"Exit":
			exit_count += 1
	return [
		"P 当前 | ? 未知 %s | F 标记 %s" % [hidden, flagged],
		"! 危险 %s | E 事件 %s | $ 奖励 %s" % [danger, event_count, reward],
		"X 撤离 %s | 点击扫描器可打开大地图" % exit_count,
	]


static func _scanner_detail(minimap_view_model: MiniMapViewModel, run_map_snapshot: Dictionary = {}) -> String:
	if minimap_view_model == null:
		return "图例：等待 MiniMapViewModel；不会触发额外扫描或规则计算。"
	return "图例只反映已公开 MiniMap 数据；未知、标记、危险、事件、奖励、撤离均不改变地图规则。"


static func _action_hint(actions: Array[Dictionary]) -> String:
	for action in actions:
		if bool(action.get("enabled", true)):
			continue
		var reason := String(action.get("disabled_reason", ""))
		if reason != "":
			return "行动提示：%s 暂不可用：%s" % [String(action.get("label", "行动")), reason]
	return "行动提示：高亮按钮可执行；灰显按钮保留禁用原因，仍走既有命令路径。"


static func _scanner_summary(minimap_view_model: MiniMapViewModel, position: Vector2i) -> String:
	if minimap_view_model == null:
		return "扫描器：等待公开地图数据。"
	return "扫描器：%sx%s | 当前坐标 %s,%s | 已知格 %s" % [
		minimap_view_model.width,
		minimap_view_model.height,
		position.x,
		position.y,
		minimap_view_model.room_markers.size(),
	]


static func _scanner_markers(minimap_view_model: MiniMapViewModel) -> Array:
	if minimap_view_model == null:
		return []
	return minimap_view_model.room_markers.duplicate(true)


static func _map_domain_summary(run_map_snapshot: Dictionary) -> String:
	if run_map_snapshot.is_empty():
		return "RunMapSnapshot: unavailable"
	var run_map: Dictionary = _dict_variant(run_map_snapshot.get("RunMap", {}))
	var summary: Dictionary = _dict_variant(run_map_snapshot.get("map_summary_preview", {}))
	return "RunMapSnapshot: %sx%s | %s | display_only" % [
		run_map.get("width", 0),
		run_map.get("height", 0),
		String(summary.get("map_kind", "classic_rect_minesweeper")),
	]


static func _run_flow_summary(run_flow_snapshot: Dictionary) -> String:
	if run_flow_snapshot.is_empty():
		return "RunFlowSnapshot: unavailable"
	var lifecycle: Dictionary = _dict_variant(run_flow_snapshot.get("RunLifecycle", {}))
	var state: Dictionary = _dict_variant(run_flow_snapshot.get("RunState", {}))
	return "RunFlowSnapshot: %s | phase=%s | display_only" % [
		String(lifecycle.get("state", "initialized")),
		String(state.get("phase", "idle")),
	]


static func _room_state_detail(room_detail: Dictionary) -> String:
	if room_detail.is_empty():
		return "RoomState: unavailable"
	return "RoomState: %s / %s / %s" % [
		String(room_detail.get("room_type_key", "unknown")),
		String(room_detail.get("known_state", "unknown")),
		String(room_detail.get("visibility", "unknown")),
	]


static func _return_eligibility_summary(return_eligibility: Dictionary) -> String:
	if return_eligibility.is_empty():
		return "return_eligibility: unavailable"
	return "return_eligibility: %s / %s" % [
		str(bool(return_eligibility.get("eligible", false))),
		String(return_eligibility.get("reason_code", "unknown")),
	]


static func _settlement_trigger_summary(run_flow_snapshot: Dictionary) -> String:
	if run_flow_snapshot.is_empty():
		return "SettlementTriggerPreview: unavailable"
	var trigger: Dictionary = _dict_variant(run_flow_snapshot.get("SettlementTriggerPreview", {}))
	return "SettlementTriggerPreview: %s / writes_warehouse=%s" % [
		String(trigger.get("trigger_state", "not_ready")),
		str(bool(trigger.get("writes_warehouse", false))),
	]


static func _interact_hint(room_type: StringName, search_data: Dictionary, has_event: bool) -> String:
	if has_event:
		return "打开当前事件选项。"
	if bool(search_data.get("can_search", false)):
		return "搜索当前房间。"
	if room_type == &"Exit":
		return "请求撤离。"
	return "当前房间暂无可交互目标。"


static func _room_label(room_type: StringName) -> String:
	match room_type:
		&"Spawn":
			return "出发点"
		&"Normal":
			return "普通房间"
		&"Mine":
			return "雷险房间"
		&"Chest":
			return "物资箱"
		&"Event":
			return "事件房间"
		&"Monster":
			return "威胁房间"
		&"Exit":
			return "撤离点"
		_:
			return String(room_type)


static func _player_message(message: String) -> String:
	var text := message.strip_edges()
	if text == "":
		return "操作反馈：等待输入。"
	return "操作反馈：%s" % text


static func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


static func _array_variant(raw: Variant) -> Array:
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


static func _dict_from(source: Dictionary, key: String) -> Dictionary:
	var raw: Variant = source.get(key, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


static func _dict_variant(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


static func _join_parts(parts: Array[String], separator: String) -> String:
	var text := ""
	for index in range(parts.size()):
		if index > 0:
			text += separator
		text += parts[index]
	return text


static func _join_lines(lines: Array[String]) -> String:
	var text := ""
	for index in range(lines.size()):
		if index > 0:
			text += "\n"
		text += lines[index]
	return text
