extends RefCounted
class_name ProtocolService

const RunBalanceCatalogScript := preload("res://scripts/core/run/run_balance_catalog.gd")

const MAX_PRESSURE := RunBalanceCatalogScript.PROTOCOL_PRESSURE_MAX


static func level_for_pressure(pressure: int) -> int:
	return RunBalanceCatalogScript.protocol_level_for_pressure(pressure)


static func add_pressure(context: RunContext, amount: int) -> Dictionary:
	if context == null:
		return {"pressure": 0, "protocol_level": 5, "changed": false}
	var previous_level := context.protocol_level
	context.pressure = clampi(context.pressure + amount, 0, MAX_PRESSURE)
	context.protocol_level = level_for_pressure(context.pressure)
	return {
		"pressure": context.pressure,
		"protocol_level": context.protocol_level,
		"changed": previous_level != context.protocol_level,
		"penalty": false,
	}
