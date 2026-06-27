extends RefCounted
class_name RunTextCatalog

# M2 effect-first copy boundary.
# Runtime scripts ask this catalog for player-facing text instead of duplicating copy.


static func run_started(run_id: StringName) -> String:
	return "Run started: %s." % String(run_id)


static func entered_room(room_type: StringName, adjacent_mines: int) -> String:
	return "Entered %s room. Adjacent mines: %d." % [String(room_type), adjacent_mines]


static func exit_ready() -> String:
	return "Exit room ready. Request extraction."


static func monster_available() -> String:
	return "Monster present. Fight is available."


static func event_available(event_type: Variant) -> String:
	return "Event available: %s." % String(event_type)


static func chest_searchable() -> String:
	return "Chest can be searched."


static func search_complete(black_coin: int, item_count: int, ground_count: int, blocked_reason: String = "") -> String:
	if blocked_reason != "":
		return "Search complete: +%d black coin, %d items, %d on room floor (%s)." % [black_coin, item_count, ground_count, blocked_reason]
	return "Search complete: +%d black coin, +%d items." % [black_coin, item_count]


static func mine_triggered(damage: int, pressure_delta: int) -> String:
	return "Mine triggered: -%d HP, +%d pressure." % [damage, pressure_delta]


static func mine_reentered() -> String:
	return "Triggered mine re-entered; no damage."


static func monster_cleared(damage: int, black_coin: int) -> String:
	return "Monster cleared: damage %d, reward +%d black coin." % [damage, black_coin]


static func event_already_resolved() -> String:
	return "Event already resolved."


static func event_left() -> String:
	return "Event left unresolved."


static func event_option_unavailable() -> String:
	return "Event option unavailable."


static func altar_result() -> String:
	return "Altar exchange complete: HP -10, black_coin +8, item +1."


static func trap_success() -> String:
	return "Mechanism opened: black_coin +25, item +2."


static func trap_failure() -> String:
	return "Mechanism triggered: HP -1, pressure +5."
