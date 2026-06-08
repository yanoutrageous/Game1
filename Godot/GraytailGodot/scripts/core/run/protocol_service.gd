extends RefCounted
class_name ProtocolService

const MAX_PRESSURE := 100


static func level_for_pressure(pressure: int) -> int:
	if pressure >= 80:
		return 1
	if pressure >= 60:
		return 2
	if pressure >= 40:
		return 3
	if pressure >= 20:
		return 4
	return 5


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
