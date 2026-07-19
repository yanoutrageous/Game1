extends RefCounted
class_name G41CombatSimulation

const RngScript := preload("res://scripts/gameplay/combat/g41_deterministic_rng.gd")
const MonsterCatalogScript := preload("res://scripts/gameplay/combat/g41_monster_catalog.gd")

const FIXED_STEP := 1.0 / 60.0
const MAX_FRAME_DELTA := 0.25
const ROOM_MIN := 0.055
const ROOM_MAX := 0.945
const PLAYER_SPEED := 0.385
const PLAYER_ACCELERATION := 16.0
const PLAYER_DECELERATION := 22.0
const PLAYER_RADIUS := 0.055
const PLAYER_ATTACK_RANGE := 0.21
const PLAYER_ATTACK_CONE_DOT := 0.50
const PLAYER_ATTACK_COOLDOWN := 0.85
const PLAYER_INVULNERABILITY := 0.90
const PLAYER_ATTACK_WINDUP := 0.08
const PLAYER_ATTACK_ACTIVE := 0.12
const PLAYER_ATTACK_RECOVERY := 0.16
const PROJECTILE_SPEED := 0.80
const PROJECTILE_RADIUS := 0.06
const LASER_RADIUS := 0.05
const EPSILON := 0.0000001

var active: bool = false
var paused: bool = false
var cleared: bool = false
var defeated: bool = false
var reward_emitted: bool = false
var tick_index: int = 0
var event_index: int = 0
var accumulator: float = 0.0
var encounter_seed: int = 1
var rng: G41DeterministicRng
var player: Dictionary = {}
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var lasers: Array[Dictionary] = []
var pending_events: Array[Dictionary] = []
var move_input := Vector2.ZERO
var aim_input := Vector2.RIGHT
var attack_queued: bool = false
var next_projectile_index: int = 1


func start(config: Dictionary = {}) -> void:
	encounter_seed = RngScript.normalize_seed(int(config.get("seed", 1)))
	rng = RngScript.new(encounter_seed)
	active = true
	paused = false
	cleared = false
	defeated = false
	reward_emitted = false
	tick_index = 0
	event_index = 0
	accumulator = 0.0
	pending_events.clear()
	enemies.clear()
	projectiles.clear()
	lasers.clear()
	next_projectile_index = 1
	move_input = Vector2.ZERO
	aim_input = _normalized_or(Vector2(config.get("player_facing", Vector2.RIGHT)), Vector2.RIGHT)
	attack_queued = false
	player = {
		"pos": _clamp_position(Vector2(config.get("player_pos", Vector2(0.28, 0.50)))),
		"velocity": Vector2.ZERO,
		"facing": aim_input,
		"hp": maxi(1, int(config.get("player_hp", 100))),
		"max_hp": maxi(1, int(config.get("player_max_hp", 100))),
		"power": maxi(1, int(config.get("player_power", 10))),
		"state": &"idle",
		"state_timer": 0.0,
		"attack_cooldown": 0.0,
		"invulnerability": 0.0,
	}
	player["hp"] = mini(int(player["hp"]), int(player["max_hp"]))
	var monster_types: Array = config.get("monster_types", MonsterCatalogScript.default_encounter())
	for monster_index in range(monster_types.size()):
		_spawn_enemy(StringName(monster_types[monster_index]), monster_index)
	_emit_event(&"combat_started", {"seed": encounter_seed, "enemy_count": enemies.size()})


func set_paused(next_paused: bool) -> void:
	paused = next_paused


func set_player_input(next_move: Vector2, next_aim: Vector2 = Vector2.ZERO) -> void:
	move_input = next_move.limit_length(1.0)
	if next_aim.length_squared() > EPSILON:
		aim_input = next_aim.normalized()
	elif move_input.length_squared() > EPSILON:
		aim_input = move_input.normalized()


func queue_player_attack() -> bool:
	if not active or paused or defeated:
		return false
	attack_queued = true
	return true


func advance_frame(delta: float) -> int:
	if not active or paused or delta <= 0.0:
		return 0
	accumulator += minf(delta, MAX_FRAME_DELTA)
	var advanced := 0
	while accumulator + EPSILON >= FIXED_STEP:
		accumulator -= FIXED_STEP
		_step()
		advanced += 1
	return advanced


func advance_ticks(count: int) -> void:
	if paused:
		return
	for _unused in range(maxi(0, count)):
		if not active:
			break
		_step()


func drain_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in pending_events:
		result.append(event.duplicate(true))
	pending_events.clear()
	return result


func mark_reward_committed() -> void:
	reward_emitted = true


func sync_player_durable_stats(hp: int, max_hp: int, power: int) -> void:
	if defeated:
		return
	player["max_hp"] = maxi(1, max_hp)
	player["hp"] = clampi(hp, 0, int(player["max_hp"]))
	player["power"] = maxi(1, power)
	if int(player["hp"]) <= 0:
		player["state"] = &"dead"
		defeated = true
		active = false


func build_snapshot() -> Dictionary:
	return {
		"active": active,
		"paused": paused,
		"cleared": cleared,
		"defeated": defeated,
		"reward_emitted": reward_emitted,
		"tick": tick_index,
		"seed": encounter_seed,
		"player": player.duplicate(true),
		"enemies": enemies.duplicate(true),
		"projectiles": projectiles.duplicate(true),
		"lasers": lasers.duplicate(true),
	}


func build_canonical_snapshot() -> Dictionary:
	var canonical_enemies: Array[Dictionary] = []
	for enemy in enemies:
		canonical_enemies.append({
			"enemy_id": String(enemy.get("enemy_id", "")),
			"monster_type": String(enemy.get("monster_type", &"")),
			"hp": int(enemy.get("hp", 0)),
			"state": String(enemy.get("state", &"idle")),
			"pos": _canonical_vector(Vector2(enemy.get("pos", Vector2.ZERO))),
		})
	var canonical_projectiles: Array[Dictionary] = []
	for projectile in projectiles:
		canonical_projectiles.append({
			"projectile_id": String(projectile.get("projectile_id", "")),
			"owner_id": String(projectile.get("owner_id", "")),
			"pos": _canonical_vector(Vector2(projectile.get("pos", Vector2.ZERO))),
		})
	return {
		"active": active,
		"cleared": cleared,
		"defeated": defeated,
		"tick": tick_index,
		"player_hp": int(player.get("hp", 0)),
		"player_state": String(player.get("state", &"idle")),
		"player_pos": _canonical_vector(Vector2(player.get("pos", Vector2.ZERO))),
		"enemies": canonical_enemies,
		"projectiles": canonical_projectiles,
		"laser_count": lasers.size(),
		"rng_state": 0 if rng == null else rng.state,
	}


func _step() -> void:
	tick_index += 1
	_update_player(FIXED_STEP)
	var enemy_count_at_step_start := enemies.size()
	for enemy_index in range(enemy_count_at_step_start):
		if enemy_index >= enemies.size():
			break
		_update_enemy(enemy_index, FIXED_STEP)
	_update_projectiles(FIXED_STEP)
	_update_lasers(FIXED_STEP)
	_check_terminal_state()


func _update_player(delta: float) -> void:
	if defeated:
		return
	player["attack_cooldown"] = maxf(0.0, float(player.get("attack_cooldown", 0.0)) - delta)
	player["invulnerability"] = maxf(0.0, float(player.get("invulnerability", 0.0)) - delta)
	var current_velocity := Vector2(player.get("velocity", Vector2.ZERO))
	var movement_scale := 0.55 if StringName(player.get("state", &"idle")) in [&"attack_windup", &"attack_active", &"attack_recovery"] else 1.0
	var target_velocity := move_input * PLAYER_SPEED * movement_scale
	var acceleration := PLAYER_ACCELERATION if move_input.length_squared() > EPSILON else PLAYER_DECELERATION
	current_velocity = current_velocity.move_toward(target_velocity, acceleration * delta)
	player["velocity"] = current_velocity
	player["pos"] = _clamp_position(Vector2(player.get("pos", Vector2.ZERO)) + current_velocity * delta)
	if aim_input.length_squared() > EPSILON:
		player["facing"] = aim_input.normalized()
	_update_player_attack(delta)


func _update_player_attack(delta: float) -> void:
	var state := StringName(player.get("state", &"idle"))
	if attack_queued and state in [&"idle", &"move"] and float(player.get("attack_cooldown", 0.0)) <= EPSILON:
		attack_queued = false
		state = &"attack_windup"
		player["state"] = state
		player["state_timer"] = PLAYER_ATTACK_WINDUP
		player["attack_cooldown"] = PLAYER_ATTACK_COOLDOWN
		_emit_event(&"player_attack_started", {"facing": player.get("facing", Vector2.RIGHT)})
	if state in [&"attack_windup", &"attack_active", &"attack_recovery"]:
		player["state_timer"] = float(player.get("state_timer", 0.0)) - delta
		if float(player["state_timer"]) <= EPSILON:
			match state:
				&"attack_windup":
					player["state"] = &"attack_active"
					player["state_timer"] = PLAYER_ATTACK_ACTIVE
					_perform_player_attack()
				&"attack_active":
					player["state"] = &"attack_recovery"
					player["state_timer"] = PLAYER_ATTACK_RECOVERY
				&"attack_recovery":
					player["state"] = &"move" if move_input.length_squared() > EPSILON else &"idle"
					player["state_timer"] = 0.0
	else:
		player["state"] = &"move" if move_input.length_squared() > EPSILON else &"idle"


func _perform_player_attack() -> void:
	var origin := Vector2(player.get("pos", Vector2.ZERO))
	var facing := _normalized_or(Vector2(player.get("facing", Vector2.RIGHT)), Vector2.RIGHT)
	var hit_ids: Array[String] = []
	for enemy_index in range(enemies.size()):
		var enemy := enemies[enemy_index]
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var offset := Vector2(enemy.get("pos", Vector2.ZERO)) - origin
		var distance := offset.length()
		if distance > PLAYER_ATTACK_RANGE or distance <= EPSILON:
			continue
		if facing.dot(offset / distance) + EPSILON < PLAYER_ATTACK_CONE_DOT:
			continue
		var enemy_id := String(enemy.get("enemy_id", ""))
		_damage_enemy(enemy_index, int(player.get("power", 1)))
		hit_ids.append(enemy_id)
	_emit_event(&"player_attack_resolved", {"hit_enemy_ids": hit_ids, "hit_count": hit_ids.size()})


func _update_enemy(enemy_index: int, delta: float) -> void:
	var enemy := enemies[enemy_index]
	if int(enemy.get("hp", 0)) <= 0:
		return
	var monster_type := StringName(enemy.get("monster_type", &"slime"))
	match monster_type:
		MonsterCatalogScript.TYPE_SLIME, MonsterCatalogScript.TYPE_SLIMELING:
			_update_melee_enemy(enemy_index, delta)
		MonsterCatalogScript.TYPE_BAT:
			_update_bat(enemy_index, delta)
		MonsterCatalogScript.TYPE_DRONE:
			_update_drone(enemy_index, delta)


func _update_melee_enemy(enemy_index: int, delta: float) -> void:
	var enemy := enemies[enemy_index]
	var definition := MonsterCatalogScript.definition(StringName(enemy.get("monster_type", &"slime")))
	var state := StringName(enemy.get("state", &"idle"))
	var distance := Vector2(enemy.get("pos", Vector2.ZERO)).distance_to(Vector2(player.get("pos", Vector2.ZERO)))
	if state == &"warning":
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		if float(enemy["state_timer"]) <= EPSILON:
			enemy["state"] = &"active"
			enemy["state_timer"] = float(definition.get("active_seconds", 0.2))
			enemy["attack_done"] = false
	elif state == &"active":
		if not bool(enemy.get("attack_done", false)):
			if distance <= float(definition.get("attack_radius", 0.2)) + PLAYER_RADIUS:
				_damage_player(MonsterCatalogScript.base_damage(int(player.get("power", 1)), StringName(enemy.get("monster_type", &"slime"))), String(enemy.get("enemy_id", "")), &"melee")
			enemy["attack_done"] = true
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		if float(enemy["state_timer"]) <= EPSILON:
			enemy["state"] = &"cooldown"
			enemy["state_timer"] = float(definition.get("cooldown_seconds", 0.5))
	elif state == &"cooldown":
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		if float(enemy["state_timer"]) <= EPSILON:
			enemy["state"] = &"idle"
	else:
		if distance <= float(definition.get("attack_radius", 0.2)):
			enemy["state"] = &"warning"
			enemy["state_timer"] = float(definition.get("warning_seconds", 0.5))
			_emit_event(&"melee_warning_started", {"enemy_id": enemy.get("enemy_id", "")})
		else:
			enemy["state"] = &"move"
			var direction := _melee_move_direction(enemy, delta)
			enemy["pos"] = _clamp_position(Vector2(enemy.get("pos", Vector2.ZERO)) + direction * float(definition.get("move_speed", 0.18)) * delta)
	enemies[enemy_index] = enemy


func _melee_move_direction(enemy: Dictionary, delta: float) -> Vector2:
	if StringName(enemy.get("monster_type", &"slime")) != MonsterCatalogScript.TYPE_SLIMELING:
		return _direction_to_player(enemy)
	var wander_timer := float(enemy.get("wander_timer", 0.0)) - delta
	if wander_timer <= EPSILON:
		var angle := rng.range_float(-PI, PI)
		enemy["wander_direction"] = Vector2.from_angle(angle)
		enemy["wander_timer"] = rng.range_float(0.45, 1.10)
	else:
		enemy["wander_timer"] = wander_timer
	var player_direction := _direction_to_player(enemy)
	return _normalized_or(Vector2(enemy.get("wander_direction", player_direction)).lerp(player_direction, 0.35), player_direction)


func _update_bat(enemy_index: int, delta: float) -> void:
	var enemy := enemies[enemy_index]
	var definition := MonsterCatalogScript.definition(MonsterCatalogScript.TYPE_BAT)
	var state := StringName(enemy.get("state", &"idle"))
	if state == &"aim":
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		if float(enemy["state_timer"]) <= EPSILON:
			_spawn_bat_spread(enemy, definition)
			enemy["state"] = &"fire"
			enemy["state_timer"] = FIXED_STEP
	elif state == &"fire":
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		if float(enemy["state_timer"]) <= EPSILON:
			enemy["state"] = &"cooldown"
			enemy["state_timer"] = float(definition.get("attack_interval", 1.5))
	elif state == &"cooldown":
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		_move_keep_distance(enemy, definition, delta)
		if float(enemy["state_timer"]) <= EPSILON:
			enemy["state"] = &"aim"
			enemy["state_timer"] = float(definition.get("aim_seconds", 0.5))
	else:
		enemy["state"] = &"aim"
		enemy["state_timer"] = float(definition.get("aim_seconds", 0.5))
		_emit_event(&"ranged_aim_started", {"enemy_id": enemy.get("enemy_id", ""), "attack": &"spread"})
	enemies[enemy_index] = enemy


func _update_drone(enemy_index: int, delta: float) -> void:
	var enemy := enemies[enemy_index]
	var definition := MonsterCatalogScript.definition(MonsterCatalogScript.TYPE_DRONE)
	var state := StringName(enemy.get("state", &"idle"))
	if state == &"aim":
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		if float(enemy["state_timer"]) <= EPSILON:
			_spawn_drone_laser(enemy, definition)
			enemy["state"] = &"fire"
			enemy["state_timer"] = float(definition.get("laser_seconds", 1.2))
	elif state == &"fire":
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		if float(enemy["state_timer"]) <= EPSILON:
			enemy["state"] = &"move"
			enemy["dash_timer"] = float(definition.get("dash_seconds", 0.5))
			_emit_event(&"drone_dash_started", {"enemy_id": enemy.get("enemy_id", "")})
	elif state == &"move" and float(enemy.get("dash_timer", 0.0)) > EPSILON:
		enemy["dash_timer"] = float(enemy.get("dash_timer", 0.0)) - delta
		var dash_direction := -_direction_to_player(enemy)
		enemy["pos"] = _clamp_position(Vector2(enemy.get("pos", Vector2.ZERO)) + dash_direction * float(definition.get("move_speed", 0.1)) * float(definition.get("dash_speed_multiplier", 2.0)) * delta)
		if float(enemy["dash_timer"]) <= EPSILON:
			enemy["state"] = &"cooldown"
			enemy["state_timer"] = float(definition.get("attack_interval", 2.5))
	elif state == &"cooldown":
		enemy["state_timer"] = float(enemy.get("state_timer", 0.0)) - delta
		_move_keep_distance(enemy, definition, delta)
		if float(enemy["state_timer"]) <= EPSILON:
			enemy["state"] = &"aim"
			enemy["state_timer"] = float(definition.get("aim_seconds", 0.5))
	else:
		enemy["state"] = &"aim"
		enemy["state_timer"] = float(definition.get("aim_seconds", 0.5))
		_emit_event(&"ranged_aim_started", {"enemy_id": enemy.get("enemy_id", ""), "attack": &"laser"})
	enemies[enemy_index] = enemy


func _move_keep_distance(enemy: Dictionary, definition: Dictionary, delta: float) -> void:
	var offset := Vector2(player.get("pos", Vector2.ZERO)) - Vector2(enemy.get("pos", Vector2.ZERO))
	var distance := offset.length()
	var ideal := float(definition.get("ideal_distance", 0.4))
	var direction := Vector2.ZERO
	if distance > ideal + 0.05:
		direction = _normalized_or(offset, Vector2.RIGHT)
	elif distance < ideal - 0.05:
		direction = -_normalized_or(offset, Vector2.RIGHT)
	else:
		direction = _normalized_or(offset, Vector2.RIGHT).orthogonal() * (1.0 if int(enemy.get("strafe_sign", 1)) >= 0 else -1.0)
	enemy["state"] = &"move" if StringName(enemy.get("state", &"idle")) != &"cooldown" else &"cooldown"
	enemy["pos"] = _clamp_position(Vector2(enemy.get("pos", Vector2.ZERO)) + direction * float(definition.get("move_speed", 0.2)) * delta)


func _spawn_bat_spread(enemy: Dictionary, definition: Dictionary) -> void:
	var base_direction := _normalized_or(Vector2(player.get("pos", Vector2.ZERO)) - Vector2(enemy.get("pos", Vector2.ZERO)), Vector2.LEFT)
	var count := int(definition.get("spread_count", 3))
	var half_angle := deg_to_rad(float(definition.get("spread_half_angle_degrees", 25.0)))
	for spread_index in range(count):
		var ratio := 0.5 if count <= 1 else float(spread_index) / float(count - 1)
		_spawn_projectile(String(enemy.get("enemy_id", "")), Vector2(enemy.get("pos", Vector2.ZERO)), base_direction.rotated(lerpf(-half_angle, half_angle, ratio)), MonsterCatalogScript.base_damage(int(player.get("power", 1)), MonsterCatalogScript.TYPE_BAT))
	_emit_event(&"ranged_fired", {"enemy_id": enemy.get("enemy_id", ""), "projectile_count": count})


func _spawn_projectile(owner_id: String, origin: Vector2, direction: Vector2, damage: int) -> void:
	var projectile_id := "projectile_%04d" % next_projectile_index
	next_projectile_index += 1
	projectiles.append({
		"projectile_id": projectile_id,
		"owner_id": owner_id,
		"pos": origin,
		"velocity": _normalized_or(direction, Vector2.LEFT) * PROJECTILE_SPEED,
		"radius": PROJECTILE_RADIUS,
		"damage": maxi(1, damage),
		"state": &"active",
	})


func _spawn_drone_laser(enemy: Dictionary, definition: Dictionary) -> void:
	var direction := _normalized_or(Vector2(player.get("pos", Vector2.ZERO)) - Vector2(enemy.get("pos", Vector2.ZERO)), Vector2.LEFT)
	lasers.append({
		"owner_id": String(enemy.get("enemy_id", "")),
		"origin": Vector2(enemy.get("pos", Vector2.ZERO)),
		"direction": direction,
		"remaining": float(definition.get("laser_seconds", 1.2)),
		"tick_timer": 0.0,
		"tick_seconds": float(definition.get("laser_tick_seconds", 0.3)),
		"turn_speed": float(definition.get("laser_turn_speed", 24.0)),
		"damage": MonsterCatalogScript.base_damage(int(player.get("power", 1)), MonsterCatalogScript.TYPE_DRONE),
		"radius": LASER_RADIUS,
	})
	_emit_event(&"laser_started", {"enemy_id": enemy.get("enemy_id", "")})


func _update_projectiles(delta: float) -> void:
	var survivors: Array[Dictionary] = []
	for projectile in projectiles:
		var from := Vector2(projectile.get("pos", Vector2.ZERO))
		var to := from + Vector2(projectile.get("velocity", Vector2.ZERO)) * delta
		if _distance_point_to_segment(Vector2(player.get("pos", Vector2.ZERO)), from, to) <= float(projectile.get("radius", PROJECTILE_RADIUS)) + PLAYER_RADIUS:
			_damage_player(int(projectile.get("damage", 1)), String(projectile.get("owner_id", "")), &"projectile")
			_emit_event(&"projectile_hit", {"projectile_id": projectile.get("projectile_id", "")})
			continue
		if to.x < -0.10 or to.x > 1.10 or to.y < -0.10 or to.y > 1.10:
			_emit_event(&"projectile_despawned", {"projectile_id": projectile.get("projectile_id", "")})
			continue
		projectile["pos"] = to
		survivors.append(projectile)
	projectiles = survivors


func _update_lasers(delta: float) -> void:
	var survivors: Array[Dictionary] = []
	for laser in lasers:
		var owner := _enemy_by_id(String(laser.get("owner_id", "")))
		if owner.is_empty() or int(owner.get("hp", 0)) <= 0:
			continue
		laser["origin"] = Vector2(owner.get("pos", Vector2.ZERO))
		var desired := _normalized_or(Vector2(player.get("pos", Vector2.ZERO)) - Vector2(laser.get("origin", Vector2.ZERO)), Vector2.LEFT)
		laser["direction"] = _normalized_or(Vector2(laser.get("direction", Vector2.LEFT)).lerp(desired, minf(1.0, float(laser.get("turn_speed", 24.0)) * delta)), desired)
		laser["remaining"] = float(laser.get("remaining", 0.0)) - delta
		laser["tick_timer"] = float(laser.get("tick_timer", 0.0)) - delta
		if float(laser["tick_timer"]) <= EPSILON:
			laser["tick_timer"] += float(laser.get("tick_seconds", 0.3))
			var origin := Vector2(laser.get("origin", Vector2.ZERO))
			var endpoint := origin + Vector2(laser.get("direction", Vector2.LEFT)) * 2.0
			if _distance_point_to_segment(Vector2(player.get("pos", Vector2.ZERO)), origin, endpoint) <= float(laser.get("radius", LASER_RADIUS)) + PLAYER_RADIUS:
				_damage_player(int(laser.get("damage", 1)), String(laser.get("owner_id", "")), &"laser")
			_emit_event(&"laser_tick", {"enemy_id": laser.get("owner_id", "")})
		if float(laser["remaining"]) > EPSILON:
			survivors.append(laser)
		else:
			_emit_event(&"laser_ended", {"enemy_id": laser.get("owner_id", "")})
	lasers = survivors


func _damage_enemy(enemy_index: int, damage: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	var enemy := enemies[enemy_index]
	if int(enemy.get("hp", 0)) <= 0:
		return
	enemy["hp"] = maxi(0, int(enemy.get("hp", 0)) - maxi(1, damage))
	_emit_event(&"enemy_damaged", {"enemy_id": enemy.get("enemy_id", ""), "damage": damage, "hp": enemy["hp"]})
	if int(enemy["hp"]) <= 0:
		enemy["state"] = &"dead"
		enemies[enemy_index] = enemy
		_emit_event(&"enemy_defeated", {"enemy_id": enemy.get("enemy_id", ""), "monster_type": enemy.get("monster_type", &"")})
		if StringName(enemy.get("monster_type", &"")) == MonsterCatalogScript.TYPE_SLIME:
			_spawn_slimelings(enemy)
	else:
		enemy["state"] = &"hurt"
		enemies[enemy_index] = enemy


func _damage_player(damage: int, source_id: String, damage_kind: StringName) -> void:
	if defeated or float(player.get("invulnerability", 0.0)) > EPSILON:
		return
	var applied := maxi(1, damage)
	player["hp"] = maxi(0, int(player.get("hp", 0)) - applied)
	player["invulnerability"] = PLAYER_INVULNERABILITY
	player["state"] = &"hurt" if int(player["hp"]) > 0 else &"dead"
	player["state_timer"] = 0.12
	_emit_event(&"player_damaged", {"source_id": source_id, "damage_kind": damage_kind, "damage": applied, "hp": player["hp"]})
	if int(player["hp"]) <= 0:
		defeated = true
		active = false
		_emit_event(&"player_defeated", {"source_id": source_id, "damage_kind": damage_kind})


func _spawn_enemy(monster_type: StringName, encounter_index: int, forced_id: String = "", forced_pos: Variant = null) -> void:
	var definition := MonsterCatalogScript.definition(monster_type)
	if definition.is_empty():
		return
	var positions := [Vector2(0.70, 0.50), Vector2(0.68, 0.28), Vector2(0.70, 0.74), Vector2(0.56, 0.62)]
	var spawn_pos: Vector2 = positions[encounter_index % positions.size()]
	if forced_pos is Vector2:
		spawn_pos = forced_pos
	else:
		spawn_pos += Vector2(rng.range_float(-0.025, 0.025), rng.range_float(-0.025, 0.025))
	var enemy_id := forced_id if not forced_id.is_empty() else "enemy_%02d_%s" % [encounter_index + 1, String(monster_type)]
	enemies.append({
		"enemy_id": enemy_id,
		"monster_type": monster_type,
		"visual_key": G41RuntimeVisualContract.visual_key_for(monster_type),
		"hp": int(definition.get("max_hp", 1)),
		"max_hp": int(definition.get("max_hp", 1)),
		"pos": _clamp_position(spawn_pos),
		"state": &"idle",
		"state_timer": 0.0,
		"attack_done": false,
		"strafe_sign": -1 if encounter_index % 2 == 0 else 1,
		"wander_timer": 0.0,
		"wander_direction": Vector2.RIGHT,
	})


func _spawn_slimelings(slime: Dictionary) -> void:
	var split_count := int(MonsterCatalogScript.definition(MonsterCatalogScript.TYPE_SLIME).get("split_count", 2))
	var origin := Vector2(slime.get("pos", Vector2.ZERO))
	for split_index in range(split_count):
		var offset := Vector2(-0.055 if split_index == 0 else 0.055, 0.04 if split_index == 0 else -0.04)
		_spawn_enemy(MonsterCatalogScript.TYPE_SLIMELING, enemies.size(), "%s_split_%d" % [String(slime.get("enemy_id", "slime")), split_index + 1], _clamp_position(origin + offset))
	_emit_event(&"slime_split", {"enemy_id": slime.get("enemy_id", ""), "spawn_count": split_count})


func _check_terminal_state() -> void:
	if defeated or cleared:
		return
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0:
			return
	cleared = true
	active = false
	projectiles.clear()
	lasers.clear()
	_emit_event(&"combat_cleared", {"tick": tick_index})


func _direction_to_player(enemy: Dictionary) -> Vector2:
	return _normalized_or(Vector2(player.get("pos", Vector2.ZERO)) - Vector2(enemy.get("pos", Vector2.ZERO)), Vector2.LEFT)


func _enemy_by_id(enemy_id: String) -> Dictionary:
	for enemy in enemies:
		if String(enemy.get("enemy_id", "")) == enemy_id:
			return enemy
	return {}


func _emit_event(event_type: StringName, payload: Dictionary = {}) -> void:
	event_index += 1
	var event := payload.duplicate(true)
	event["event_type"] = event_type
	event["event_index"] = event_index
	event["tick"] = tick_index
	pending_events.append(event)


func _clamp_position(value: Vector2) -> Vector2:
	return Vector2(clampf(value.x, ROOM_MIN, ROOM_MAX), clampf(value.y, ROOM_MIN, ROOM_MAX))


func _normalized_or(value: Vector2, fallback: Vector2) -> Vector2:
	if value.length_squared() <= EPSILON:
		return fallback.normalized()
	return value.normalized()


func _distance_point_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= EPSILON:
		return point.distance_to(start)
	var ratio := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * ratio)


func _canonical_vector(value: Vector2) -> Array[float]:
	return [snappedf(value.x, 0.000001), snappedf(value.y, 0.000001)]
