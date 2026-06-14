extends RefCounted
class_name EncounterResolver

# Read-only encounter adapter for G15. It builds public display/command data
# from RunContext and delegates actual rule resolution to existing commands.


static func get_encounter_identity(context: RunContext, room_type: StringName, pos: Vector2i) -> Dictionary:
	var encounter_type: StringName = StringName(String(room_type).to_lower())
	var tags: Array = []
	match room_type:
		&"Event":
			encounter_type = EventService.get_event_type(context, pos)
			tags = [&"event_like", encounter_type]
		&"Chest":
			encounter_type = EncounterContract.TYPE_CHEST
			tags = [&"loot", &"container"]
		&"Monster":
			encounter_type = &"monster_basic"
			tags = [EncounterContract.TYPE_COMBAT, &"loot"]
		&"Exit":
			encounter_type = &"exit_beacon"
			tags = [&"settlement", EncounterContract.TYPE_EXTRACT]
		&"Mine":
			encounter_type = &"mine_trap"
			tags = [&"hazard"]
		&"Normal":
			encounter_type = EncounterContract.TYPE_SEARCH
			tags = [&"search", &"loot"]
		_:
			tags = [&"room"]
	return {
		"encounter_type": encounter_type,
		"encounter_tags": tags,
		"room_type": room_type,
		"position": pos,
	}


static func build_view_model(context: RunContext) -> Dictionary:
	if context == null:
		return EncounterContract.make_view_model(
			"",
			EncounterContract.TYPE_NONE,
			&"Unknown",
			Vector2i.ZERO,
			EncounterContract.make_state(EncounterContract.TYPE_NONE, EncounterContract.STATE_UNAVAILABLE, "No encounter", "No active run."),
			[]
		)
	var pos: Vector2i = context.get_current_pos()
	var room_type: StringName = context.current_room_type
	var identity: Dictionary = get_encounter_identity(context, room_type, pos)
	var encounter_type: StringName = StringName(identity.get("encounter_type", EncounterContract.TYPE_NONE))
	var tags: Array = identity.get("encounter_tags", [])
	var options: Array = _build_options(context, room_type, encounter_type, pos)
	var completed: bool = _is_completed(context, room_type, pos)
	var state_id: StringName = EncounterContract.STATE_COMPLETED if completed else EncounterContract.STATE_AVAILABLE
	if options.is_empty() and not completed:
		state_id = EncounterContract.STATE_RESERVED if room_type in [&"Monster", &"Exit"] else EncounterContract.STATE_UNAVAILABLE
	var state: Dictionary = EncounterContract.make_state(
		encounter_type,
		state_id,
		_title_for(room_type, encounter_type),
		_description_for(context, room_type, encounter_type, completed),
		completed,
		tags
	)
	return EncounterContract.make_view_model(
		"%s_%d_%d" % [String(encounter_type), pos.x, pos.y],
		encounter_type,
		room_type,
		pos,
		state,
		options,
		build_result_summary(context)
	)


static func build_result_summary(context: RunContext) -> Dictionary:
	if context == null or context.last_reward.is_empty():
		return EncounterContract.make_result(false, EncounterContract.TYPE_NONE)
	return EncounterContract.summarize_action_result(context.last_reward)


static func _build_options(context: RunContext, room_type: StringName, encounter_type: StringName, pos: Vector2i) -> Array:
	match room_type:
		&"Normal":
			return [_build_search_option(context, pos, false)]
		&"Chest":
			return [_build_search_option(context, pos, true)]
		&"Event":
			return _build_event_options(context, pos, encounter_type)
	return []


static func _build_search_option(context: RunContext, pos: Vector2i, is_chest: bool) -> Dictionary:
	var option_id: StringName = &"open_chest" if is_chest else &"search"
	var title: String = "Open chest" if is_chest else "Search room"
	var disabled_reason: String = _search_disabled_reason(context, pos, is_chest)
	var disabled: bool = disabled_reason != ""
	var expected_black_coin: int = 0
	if not disabled:
		expected_black_coin = RunRuleContent.default_search_black_coin(context, pos, context.current_adjacent_mines, is_chest)
	return EncounterContract.make_option(
		option_id,
		title,
		{},
		{"black_coin": expected_black_coin, "items": "possible"},
		{"adjacent_danger": context.current_adjacent_mines},
		true,
		is_chest,
		disabled,
		disabled_reason,
		&"select_encounter_option",
		{"option_id": option_id}
	)


static func _build_event_options(context: RunContext, pos: Vector2i, encounter_type: StringName) -> Array:
	var event_state: Dictionary = context.event_state.duplicate(true)
	if event_state.is_empty():
		event_state = EventService.get_event_state(context, pos)
	var completed: bool = bool(event_state.get("completed", false))
	var raw_options: Array = event_state.get("options", [])
	var options: Array = []
	for raw_option in raw_options:
		if not (raw_option is Dictionary):
			continue
		var option_id: StringName = StringName(raw_option.get("id", &""))
		var enabled: bool = bool(raw_option.get("enabled", true))
		var disabled_reason: String = "" if enabled else _event_disabled_reason(context, encounter_type, option_id)
		options.append(EncounterContract.make_option(
			option_id,
			String(raw_option.get("label", option_id)),
			_event_cost(context, encounter_type, option_id),
			_event_expected_reward(encounter_type, option_id),
			_event_risk(encounter_type, option_id),
			option_id != &"leave",
			option_id != &"leave",
			not enabled,
			disabled_reason,
			&"select_encounter_option",
			{"option_id": option_id}
		))
	if completed and options.is_empty():
		options.append(EncounterContract.make_option(&"leave", "Close", {}, {}, {}, false, false, false, "", &"select_encounter_option", {"option_id": &"leave"}))
	return options


static func _search_disabled_reason(context: RunContext, pos: Vector2i, is_chest: bool) -> String:
	if context == null:
		return "not_ready"
	var key: String = context.cell_key(pos)
	if context.searched_cells.has(key):
		return "searched"
	if is_chest and context.current_room_type != &"Chest":
		return "not_chest"
	if not is_chest and context.current_room_type != &"Normal":
		return "not_search_room"
	return ""


static func _is_completed(context: RunContext, room_type: StringName, pos: Vector2i) -> bool:
	if context == null:
		return false
	var key: String = context.cell_key(pos)
	match room_type:
		&"Normal", &"Chest":
			return context.searched_cells.has(key)
		&"Event":
			return context.interacted_cells.has(key)
	return false


static func _title_for(room_type: StringName, encounter_type: StringName) -> String:
	match room_type:
		&"Normal":
			return "Search encounter"
		&"Chest":
			return "Reward encounter"
		&"Event":
			return "Event encounter: %s" % String(encounter_type)
		&"Monster":
			return "Combat encounter"
		&"Exit":
			return "Extraction encounter"
	return "%s encounter" % String(room_type)


static func _description_for(context: RunContext, room_type: StringName, encounter_type: StringName, completed: bool) -> String:
	if completed:
		return "This encounter has already been resolved."
	match room_type:
		&"Normal":
			return "Search the room through the existing search command path."
		&"Chest":
			return "Open the reward container through the existing search command path."
		&"Event":
			return "Choose an event option. Resolution stays in existing event rules."
		&"Monster":
			return "Combat is reserved for a later combat encounter stage."
		&"Exit":
			return "Extraction remains on existing request/confirm extract commands."
	return "No active encounter option for %s." % String(encounter_type)


static func _event_disabled_reason(context: RunContext, encounter_type: StringName, option_id: StringName) -> String:
	match encounter_type:
		&"trader":
			if option_id == &"sell_best_item":
				return "no_inventory_item"
		&"dice":
			if option_id == &"bet_small":
				return "not_enough_black_coin"
		&"altar":
			if option_id == &"offer_hp":
				return "not_enough_hp"
	return "event_option_unavailable"


static func _event_cost(context: RunContext, encounter_type: StringName, option_id: StringName) -> Dictionary:
	match encounter_type:
		&"dice":
			if option_id == &"bet_small":
				return {"black_coin": EventService.DICE_BET}
		&"altar":
			if option_id == &"offer_hp":
				return {"hp": 10}
	return {}


static func _event_expected_reward(encounter_type: StringName, option_id: StringName) -> Dictionary:
	match encounter_type:
		&"trader":
			if option_id == &"sell_best_item":
				return {"gold_coin": "sell_best_inventory_item"}
		&"dice":
			if option_id == &"bet_small":
				return {"black_coin": "roll_dependent"}
		&"altar":
			if option_id == &"offer_hp":
				return {"black_coin": 8, "items": 1, "status_effects": 1}
		&"trap":
			if option_id == &"disarm":
				return {"black_coin": "power_dependent", "items": "power_dependent"}
	return {}


static func _event_risk(encounter_type: StringName, option_id: StringName) -> Dictionary:
	match encounter_type:
		&"dice":
			if option_id == &"bet_small":
				return {"black_coin_loss": EventService.DICE_BET}
		&"altar":
			if option_id == &"offer_hp":
				return {"hp_loss": 10}
		&"trap":
			if option_id == &"disarm":
				return {"hp_loss": 1, "pressure": 5}
	return {}
