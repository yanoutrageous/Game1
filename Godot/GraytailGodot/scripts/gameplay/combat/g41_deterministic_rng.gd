extends RefCounted
class_name G41DeterministicRng

# Park-Miller minimal standard generator. Its explicit integer state makes
# simulation results independent of Godot's global RNG and render frame rate.

const MODULUS := 2147483647
const MULTIPLIER := 48271

var state: int = 1


func _init(seed_value: int = 1) -> void:
	state = normalize_seed(seed_value)


func next_int() -> int:
	state = int((state * MULTIPLIER) % MODULUS)
	if state <= 0:
		state += MODULUS - 1
	return state


func next_float() -> float:
	return float(next_int()) / float(MODULUS)


func range_float(minimum: float, maximum: float) -> float:
	return lerpf(minimum, maximum, next_float())


func range_int(minimum: int, maximum_inclusive: int) -> int:
	if maximum_inclusive <= minimum:
		return minimum
	return minimum + next_int() % (maximum_inclusive - minimum + 1)


static func normalize_seed(seed_value: int) -> int:
	var normalized := absi(seed_value) % (MODULUS - 1)
	return normalized + 1


static func derive_seed(run_seed: int, room_pos: Vector2i, encounter_ordinal: int) -> int:
	var mixed: int = run_seed
	mixed = int((mixed * 1103515245 + room_pos.x * 73856093 + room_pos.y * 19349663 + encounter_ordinal * 83492791) & 0x7fffffff)
	return normalize_seed(mixed)
