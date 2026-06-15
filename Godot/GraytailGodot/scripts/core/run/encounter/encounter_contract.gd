extends RefCounted
class_name EncounterContract

# G15 public encounter contract helpers.
# These dictionaries are display/command contracts; they do not own rule state.

const TYPE_NONE := &"none"
const TYPE_SEARCH := &"search_basic"
const TYPE_CHEST := &"chest_basic"
const TYPE_EVENT := &"event"
const TYPE_COMBAT := &"combat"
const TYPE_COMBAT_BASIC := &"combat_basic"
const TYPE_MONSTER_BASIC := &"monster_basic"
const TYPE_EXTRACT := &"extract"
const TYPE_LOTTERY := &"lottery"

const OPTION_ATTACK_BASIC := &"attack_basic"

const STATE_UNAVAILABLE := &"unavailable"
const STATE_AVAILABLE := &"available"
const STATE_COMPLETED := &"completed"
const STATE_RESERVED := &"reserved"


static func make_option(
	option_id: StringName,
	title: String,
	cost: Dictionary = {},
	expected_reward: Dictionary = {},
	risk: Dictionary = {},
	one_shot: bool = false,
	requires_confirm: bool = false,
	disabled: bool = false,
	disabled_reason: String = "",
	command_name: StringName = &"select_encounter_option",
	command_payload: Dictionary = {}
) -> Dictionary:
	var payload: Dictionary = command_payload.duplicate(true)
	if not payload.has("option_id"):
		payload["option_id"] = option_id
	return {
		"id": option_id,
		"title": title,
		"cost": cost.duplicate(true),
		"expected_reward": expected_reward.duplicate(true),
		"risk": risk.duplicate(true),
		"one_shot": one_shot,
		"requires_confirm": requires_confirm,
		"disabled": disabled,
		"disabled_reason": disabled_reason,
		"command_name": command_name,
		"command_payload": payload,
	}


static func make_state(
	encounter_type: StringName,
	state_id: StringName,
	title: String,
	description: String,
	completed: bool = false,
	tags: Array = []
) -> Dictionary:
	return {
		"encounter_type": encounter_type,
		"state": state_id,
		"title": title,
		"description": description,
		"completed": completed,
		"tags": tags.duplicate(true),
	}


static func make_effect_summary(
	black_coin_delta: int = 0,
	gold_coin_delta: int = 0,
	item_delta: int = 0,
	backpack_delta: int = 0,
	status_effects: Array = [],
	hp_delta: int = 0,
	pressure_delta: int = 0,
	room_state_delta: Dictionary = {},
	encounter_state_delta: Dictionary = {},
	settlement_summary: Dictionary = {}
) -> Dictionary:
	return {
		"black_coin_delta": black_coin_delta,
		"gold_coin_delta": gold_coin_delta,
		"item_delta": item_delta,
		"backpack_delta": backpack_delta,
		"status_effects": status_effects.duplicate(true),
		"hp_delta": hp_delta,
		"pressure_delta": pressure_delta,
		"room_state_delta": room_state_delta.duplicate(true),
		"encounter_state_delta": encounter_state_delta.duplicate(true),
		"settlement_summary": settlement_summary.duplicate(true),
	}


static func make_result(
	ok: bool,
	encounter_type: StringName,
	option_id: StringName = &"",
	effect_summary: Dictionary = {},
	log_entries: Array = [],
	messages: Array = [],
	blocked_reason: String = ""
) -> Dictionary:
	return {
		"ok": ok,
		"encounter_type": encounter_type,
		"option_id": option_id,
		"effect_summary": effect_summary.duplicate(true),
		"log_entries": log_entries.duplicate(true),
		"messages": messages.duplicate(true),
		"blocked_reason": blocked_reason,
	}


static func make_log_entry(entry_type: StringName, message: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"type": entry_type,
		"message": message,
		"payload": payload.duplicate(true),
	}


static func make_monster_summary(
	monster_id: String,
	display_name: String,
	tags: Array,
	base_power: int,
	current_power: int,
	player_power: int,
	cleared: bool,
	reward_preview: Dictionary = {},
	risk_summary: Dictionary = {},
	codex_ref: String = ""
) -> Dictionary:
	return {
		"monster_id": monster_id,
		"display_name": display_name,
		"tags": tags.duplicate(true),
		"base_power": base_power,
		"current_power": current_power,
		"enemy_power": current_power,
		"player_power": player_power,
		"cleared": cleared,
		"alive": not cleared,
		"reward_preview": reward_preview.duplicate(true),
		"risk_summary": risk_summary.duplicate(true),
		"codex_ref": codex_ref,
	}


static func make_combat_result_summary(
	action_result: Dictionary,
	encounter_type: StringName = TYPE_MONSTER_BASIC,
	option_id: StringName = OPTION_ATTACK_BASIC
) -> Dictionary:
	if action_result.is_empty():
		return make_result(false, encounter_type, option_id, make_effect_summary(), [], [], "")
	var damage := int(action_result.get("damage", 0))
	var cleared := bool(action_result.get("cleared", false))
	var player_win := bool(action_result.get("player_win", cleared))
	var black_coin_delta := int(action_result.get("black_coin_delta", action_result.get("reward_gold", 0)))
	var effect_summary := make_effect_summary(
		black_coin_delta,
		0,
		0,
		0,
		[],
		-damage,
		0,
		{"cleared": cleared},
		{
			"fought": bool(action_result.get("fought", false)),
			"player_win": player_win,
			"enemy_power": int(action_result.get("enemy_power", 0)),
			"player_power": int(action_result.get("player_power", 0)),
			"power_gain": int(action_result.get("power_gain", 0)),
		},
		{}
	)
	var messages: Array = []
	var message := String(action_result.get("message", ""))
	if message != "":
		messages.append(message)
	elif bool(action_result.get("fought", false)):
		messages.append("Combat resolved: damage %d, reward +%d black coin." % [damage, black_coin_delta])
	var log_entries: Array = [
		make_log_entry(&"combat", "Combat resolved through deterministic command combat.", action_result)
	]
	return make_result(
		bool(action_result.get("ok", false)),
		encounter_type,
		option_id,
		effect_summary,
		log_entries,
		messages,
		String(action_result.get("blocked_reason", action_result.get("reason", "")))
	)


static func make_view_model(
	encounter_id: String,
	encounter_type: StringName,
	room_type: StringName,
	position: Vector2i,
	state: Dictionary,
	options: Array,
	result_summary: Dictionary = {}
) -> Dictionary:
	return {
		"encounter_id": encounter_id,
		"encounter_type": encounter_type,
		"room_type": room_type,
		"position": position,
		"state": state.duplicate(true),
		"options": options.duplicate(true),
		"result_summary": result_summary.duplicate(true),
	}


static func summarize_action_result(action_result: Dictionary) -> Dictionary:
	if action_result.is_empty():
		return make_result(false, TYPE_NONE, &"", make_effect_summary(), [], [], "")
	if bool(action_result.get("fought", false)):
		return make_combat_result_summary(action_result)
	var messages: Array = []
	var message: String = String(action_result.get("message", ""))
	if message != "":
		messages.append(message)
	var item_count: int = 0
	item_count += _array_size(action_result.get("items", []))
	item_count += _array_size(action_result.get("inventory_items", []))
	item_count += _array_size(action_result.get("ground_items", []))
	var settlement_summary: Dictionary = _dictionary_from_variant(action_result.get("settlement", {}))
	var summary: Dictionary = make_effect_summary(
		int(action_result.get("black_coin_delta", action_result.get("pending_gold_delta", action_result.get("gold", 0)))),
		int(action_result.get("gold_coin_delta", action_result.get("safe_gold", 0))),
		item_count,
		0,
		_array_from_variant(action_result.get("status_effects", [])),
		int(action_result.get("hp_delta", 0)),
		int(action_result.get("pressure_delta", 0)),
		{},
		{},
		settlement_summary
	)
	return make_result(
		bool(action_result.get("ok", false)),
		StringName(action_result.get("event_type", action_result.get("encounter_type", TYPE_NONE))),
		StringName(action_result.get("option_id", &"")),
		summary,
		_array_from_variant(action_result.get("produced_events", [])),
		messages,
		String(action_result.get("blocked_reason", action_result.get("reason", "")))
	)


static func _array_size(value: Variant) -> int:
	if value is Array:
		return value.size()
	return 0


static func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []


static func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
