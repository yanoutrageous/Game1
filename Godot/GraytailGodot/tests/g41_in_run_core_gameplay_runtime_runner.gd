extends SceneTree

const CombatSimulationScript := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const VisualContractScript := preload("res://scripts/gameplay/runtime/g41_runtime_visual_contract.gd")
const RuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RoomRuntimeViewScript := preload("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
const RuntimeActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
const ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")
const ItemVisualCatalogScript := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const PlayerControllerScript := preload("res://scripts/gameplay/player/player_controller.gd")

var failures: Array[String] = []
var integration_context
var integration_bus
var integration_chest_commit_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	_check_visual_contract()
	_check_runtime_visual_states_and_swap()
	_check_reduced_motion_contract()
	_check_item_visual_catalog()
	_check_program_collision_contract()
	_check_outer_frame_determinism()
	_check_render_interpolation()
	_check_laser_visual_bounds()
	_check_pause_contract()
	_check_cone_and_split()
	_check_monster_behaviors()
	_check_invulnerability_defeat_and_swept_projectile()
	_check_integrated_chest_and_ground_loot()
	_check_integrated_combat_reward_and_flee()
	_check_lifecycle_cleanup()
	_finish()


func _check_visual_contract() -> void:
	var contract := VisualContractScript.build_contract_snapshot()
	_check((contract.get("anchors", []) as Array).size() == 8, "Visual contract must expose eight stable anchors")
	_check(VisualContractScript.supports_state(&"player", &"attack_active"), "Player attack_active state is absent")
	_check(VisualContractScript.supports_state(&"slime", &"split"), "Slime split state is absent")
	_check(not bool(contract.get("collision_depends_on_texture_size", true)), "Collision still depends on art dimensions")


func _check_runtime_visual_states_and_swap() -> void:
	var actor = RuntimeActorViewScript.new()
	actor.name = "G41VisualContractActor"
	root.add_child(actor)
	actor.configure(&"unknown", {
		"enemy_id": "visual-contract-enemy",
		"state": &"warning",
		"hp": 12,
		"max_hp": 24,
		"pos": Vector2(0.5, 0.5),
	})
	for anchor_name: StringName in VisualContractScript.REQUIRED_ANCHORS:
		_check(actor.get_node_or_null(String(anchor_name)) != null, "Runtime actor omitted visual anchor %s" % String(anchor_name))
	var placeholder := actor.get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	var state_label := actor.get_node_or_null("PromptAnchor/StateLabel") as Label
	_check(placeholder != null and placeholder.visible, "Missing art did not retain the program placeholder")
	_check(state_label != null and not state_label.visible and state_label.text == "warning", "Runtime state was not retained behind the production no-floating-copy policy")
	actor.configure(&"slime", {
		"enemy_id": "visual-contract-enemy",
		"state": &"active",
		"hp": 12,
		"max_hp": 24,
		"pos": Vector2(0.5, 0.5),
	})
	var art_visual := actor.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	var ground_shadow := actor.get_node_or_null("VisualRoot/GroundShadow") as Sprite2D
	_check(art_visual != null and art_visual.texture != null, "ART24 slime visual was not projected from the gameplay state")
	_check(ground_shadow != null and ground_shadow.texture != null, "ART24 enemy visual omitted the reusable ground shadow")
	_check(placeholder != null and not placeholder.visible, "ART24 enemy visual did not hide only the program placeholder")
	_check(actor.visual_state == &"active", "VisualRoot replacement altered the gameplay-provided state")
	var base_texture_path := art_visual.texture.resource_path
	actor.configure(&"slime", {
		"enemy_id": "visual-contract-enemy",
		"state": &"active",
		"visual_variant": &"art24_generated",
		"hp": 12,
		"max_hp": 24,
		"pos": Vector2(0.5, 0.5),
	})
	_check(actor.visual_variant == &"art24_generated", "ART24 generated monster variant was not retained by the presentation interface")
	_check(art_visual.texture != null and art_visual.texture.resource_path != base_texture_path, "ART24 generated monster variant did not swap the presentation texture")
	_check(actor.hp == 12 and actor.max_hp == 24 and actor.visual_state == &"active", "Monster visual variant altered gameplay-provided state")
	actor.free()


func _check_reduced_motion_contract() -> void:
	var setting_key := "accessibility/reduce_motion"
	var had_setting := ProjectSettings.has_setting(setting_key)
	var previous_value: Variant = ProjectSettings.get_setting(setting_key, false)
	ProjectSettings.set_setting(setting_key, true)
	var actor = RuntimeActorViewScript.new()
	root.add_child(actor)
	actor.configure(&"bat", {
		"enemy_id": "reduced-motion-bat",
		"state": &"idle",
		"hp": 8,
		"max_hp": 8,
		"pos": Vector2(0.5, 0.5),
	})
	actor.animation_frame = 3
	actor.animation_elapsed = 1.0
	actor.call("_process", 0.25)
	var actor_sprite := actor.get_node("VisualRoot/ArtVisual") as Sprite2D
	_check(actor.animation_frame == 0 and is_zero_approx(actor.animation_elapsed), "Reduced motion did not freeze enemy texture animation")
	_check(is_zero_approx(actor_sprite.position.y + 14.0), "Reduced motion retained enemy bob displacement")
	var player = PlayerControllerScript.new()
	root.add_child(player)
	player.animation_frame = 3
	player.call("_apply_art24_frame", true)
	player.call("_apply_idle_motion", true)
	var player_sprite := player.get_node("Sprite") as Sprite2D
	_check(player.last_texture_path.ends_with("down_walk_a.png"), "Reduced motion did not retain a readable player movement pose")
	_check(is_equal_approx(player_sprite.position.y, -20.0), "Reduced motion retained player idle bob")
	ProjectSettings.set_setting(setting_key, false)
	actor.call("_process", 0.50)
	_check(actor.animation_frame != 0, "Full motion did not restore enemy texture animation")
	actor.free()
	player.free()
	ProjectSettings.set_setting(setting_key, previous_value if had_setting else null)


func _check_item_visual_catalog() -> void:
	var all_items: Array[Dictionary] = ItemCatalogScript.all_items()
	_check(all_items.size() == 43, "M3 item visual validation expected 43 catalog items")
	for item in all_items:
		var item_id := String(item.get("item_id", ""))
		_check(ItemVisualCatalogScript.has_explicit_mapping(item_id), "ART24 item visual catalog omitted %s" % item_id)
		var texture_path := ItemVisualCatalogScript.texture_path(item)
		_check(ResourceLoader.exists(texture_path, "Texture2D"), "ART24 item texture is missing for %s: %s" % [item_id, texture_path])


func _check_program_collision_contract() -> void:
	var player = PlayerControllerScript.new()
	player.set_local_position(Vector2(0.30, 0.44))
	player.set_logical_obstacles([Rect2(Vector2(0.44, 0.38), Vector2(0.12, 0.12))])
	for _step in range(120):
		player.move_local(Vector2.RIGHT, 1.0 / 60.0)
	var stopped_pos: Vector2 = player.get_local_position()
	_check(stopped_pos.x <= 0.3851, "Player crossed a texture-independent logical obstacle")
	_check(is_equal_approx(stopped_pos.y, 0.44), "Obstacle response introduced unintended vertical drift")
	player.free()


func _check_outer_frame_determinism() -> void:
	var at_30 := _run_schedule([1.0 / 30.0], 3.0)
	var at_60 := _run_schedule([1.0 / 60.0], 3.0)
	var at_144 := _run_schedule([1.0 / 144.0], 3.0)
	var with_hitch := _run_schedule([0.2, 1.0 / 60.0, 1.0 / 30.0, 1.0 / 144.0], 3.0)
	_check(at_30.get("state", {}) == at_60.get("state", {}), "30 Hz outer schedule diverged from 60 Hz canonical state")
	_check(at_144.get("state", {}) == at_60.get("state", {}), "144 Hz outer schedule diverged from 60 Hz canonical state")
	_check(with_hitch.get("state", {}) == at_60.get("state", {}), "0.2 second hitch schedule diverged from canonical state")
	_check(at_30.get("events", []) == at_60.get("events", []), "30 Hz outer schedule changed the domain-event order")
	_check(at_144.get("events", []) == at_60.get("events", []), "144 Hz outer schedule changed the domain-event order")
	_check(with_hitch.get("events", []) == at_60.get("events", []), "0.2 second hitch schedule changed the domain-event order")
	var canonical_state: Dictionary = at_60.get("state", {})
	_check(int(canonical_state.get("tick", 0)) == 180, "Three simulated seconds must resolve to 180 fixed ticks")


func _check_render_interpolation() -> void:
	var simulation := CombatSimulationScript.new()
	simulation.start(_base_config())
	simulation.set_player_input(Vector2.RIGHT, Vector2.RIGHT)
	for _unused in range(3):
		simulation.advance_frame(1.0 / 144.0)
	var snapshot: Dictionary = simulation.build_snapshot()
	var player_snapshot: Dictionary = snapshot.get("player", {})
	var previous_pos := Vector2(player_snapshot.get("previous_pos", Vector2.ZERO))
	var render_pos := Vector2(player_snapshot.get("pos", Vector2.ZERO))
	var simulation_pos := Vector2(player_snapshot.get("simulation_pos", Vector2.ZERO))
	_check(float(snapshot.get("render_alpha", -1.0)) > 0.0, "144 Hz presentation snapshot did not expose interpolation alpha")
	_check(render_pos.x > previous_pos.x and render_pos.x < simulation_pos.x, "Presentation position did not interpolate between fixed simulation states")


func _check_laser_visual_bounds() -> void:
	var view = RoomRuntimeViewScript.new()
	var room_rect := Rect2(205.0, 30.0, 634.0, 450.0)
	var origin := Vector2(600.0, 160.0)
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1.0, 0.65), Vector2(0.75, -1.0)]:
		var endpoint: Vector2 = view.call("_ray_endpoint_inside_room", origin, direction.normalized(), room_rect)
		_check(endpoint.x >= room_rect.position.x - 0.01 and endpoint.x <= room_rect.end.x + 0.01, "Laser presentation escaped the room horizontally")
		_check(endpoint.y >= room_rect.position.y - 0.01 and endpoint.y <= room_rect.end.y + 0.01, "Laser presentation escaped the room vertically")
		_check(endpoint.distance_to(origin) > 1.0, "Laser presentation collapsed before reaching the room boundary")
	view.free()


func _check_pause_contract() -> void:
	var simulation := CombatSimulationScript.new()
	simulation.start(_base_config())
	simulation.set_player_input(Vector2(0.0, 0.35), Vector2.RIGHT)
	_advance_exact(simulation, [1.0 / 60.0], 1.0)
	var before_pause: Dictionary = simulation.build_canonical_snapshot()
	simulation.set_paused(true)
	simulation.advance_frame(5.0)
	var during_pause: Dictionary = simulation.build_canonical_snapshot()
	_check(before_pause == during_pause, "Five paused seconds advanced combat state")
	simulation.set_paused(false)
	_advance_exact(simulation, [1.0 / 60.0], 1.0)
	var continuous := _run_schedule([1.0 / 60.0], 2.0)
	_check(simulation.build_canonical_snapshot() == continuous.get("state", {}), "Unpausing did not resume from the exact prior tick")


func _check_cone_and_split() -> void:
	var away := CombatSimulationScript.new()
	away.start({
		"seed": 91,
		"player_pos": Vector2(0.52, 0.50),
		"player_facing": Vector2.LEFT,
		"player_power": 40,
		"monster_types": [&"slime"],
	})
	away.queue_player_attack()
	away.advance_ticks(20)
	_check(_alive_enemy_count(away.build_snapshot()) == 1, "Attack cone hit a target behind the player")

	var toward := CombatSimulationScript.new()
	toward.start({
		"seed": 91,
		"player_pos": Vector2(0.52, 0.50),
		"player_facing": Vector2.RIGHT,
		"player_power": 40,
		"monster_types": [&"slime"],
	})
	toward.queue_player_attack()
	toward.advance_ticks(20)
	var split_count := 0
	for enemy in (toward.build_snapshot().get("enemies", []) as Array):
		if StringName((enemy as Dictionary).get("monster_type", &"")) == &"slimeling" and int((enemy as Dictionary).get("hp", 0)) > 0:
			split_count += 1
	_check(split_count == 2, "Defeated slime did not split into two stable slimelings")


func _check_monster_behaviors() -> void:
	var simulation := CombatSimulationScript.new()
	simulation.start({
		"seed": 7331,
		"player_pos": Vector2(0.45, 0.50),
		"player_hp": 500,
		"player_max_hp": 500,
		"player_power": 10,
		"monster_types": [&"slime", &"bat", &"drone"],
	})
	_advance_exact(simulation, [1.0 / 60.0], 4.0)
	var events := simulation.drain_events()
	var event_types: Array[StringName] = []
	var spread_count := 0
	for event in events:
		var event_type := StringName(event.get("event_type", &""))
		event_types.append(event_type)
		if event_type == &"ranged_fired":
			spread_count = maxi(spread_count, int(event.get("projectile_count", 0)))
	_check(&"melee_warning_started" in event_types, "Slime did not expose a melee warning window")
	_check(spread_count == 3, "Bat did not fire the UE-reference three-shot spread")
	_check(&"laser_started" in event_types and &"laser_tick" in event_types, "Drone laser did not expose start and tick events")
	_check(&"drone_dash_started" in event_types, "Drone did not expose its post-laser dash")


func _check_invulnerability_defeat_and_swept_projectile() -> void:
	var invulnerability_simulation := CombatSimulationScript.new()
	invulnerability_simulation.start({
		"seed": 141,
		"player_pos": Vector2(0.69, 0.39),
		"player_hp": 50,
		"player_max_hp": 50,
		"monster_types": [&"slime", &"slime"],
	})
	_advance_exact(invulnerability_simulation, [1.0 / 60.0], 1.10)
	var damage_event_count := 0
	for event in invulnerability_simulation.drain_events():
		if StringName(event.get("event_type", &"")) == &"player_damaged":
			damage_event_count += 1
	_check(damage_event_count == 1, "Overlapping melee attacks bypassed the player invulnerability window")

	var defeat_simulation := CombatSimulationScript.new()
	defeat_simulation.start({
		"seed": 141,
		"player_pos": Vector2(0.70, 0.50),
		"player_hp": 1,
		"player_max_hp": 1,
		"monster_types": [&"slime"],
	})
	_advance_exact(defeat_simulation, [1.0 / 60.0], 1.20)
	var defeat_event_types: Array[StringName] = []
	for event in defeat_simulation.drain_events():
		defeat_event_types.append(StringName(event.get("event_type", &"")))
	_check(&"player_defeated" in defeat_event_types and defeat_simulation.defeated, "Combat defeat did not emit the authoritative failure event")

	var projectile_simulation := CombatSimulationScript.new()
	projectile_simulation.start({
		"seed": 717,
		"player_pos": Vector2(0.50, 0.50),
		"player_hp": 20,
		"player_max_hp": 20,
		"monster_types": [],
	})
	projectile_simulation.projectiles.append({
		"projectile_id": "sweep_test",
		"owner_id": "sweep_source",
		"pos": Vector2(0.20, 0.50),
		"velocity": Vector2(30.0, 0.0),
		"radius": 0.01,
		"damage": 3,
		"state": &"active",
	})
	projectile_simulation.advance_ticks(1)
	_check(int(projectile_simulation.player.get("hp", 20)) == 17, "Swept projectile segment tunneled through the player")


func _check_integrated_chest_and_ground_loot() -> void:
	var controller = RuntimeControllerScript.new()
	controller.start_demo_run(controller.command_bus.room_resolver)
	integration_context = controller.context
	integration_bus = controller.command_bus
	_enter_test_room(controller, Vector2i(1, 1))
	var view = RoomRuntimeViewScript.new()
	view.name = "G41IntegratedRoomView"
	# Match the production composition: the room is ScaleToFit-transformed while
	# the contextual panel is hosted in an unscaled full-screen UI overlay.
	view.position = Vector2(136, -34)
	view.scale = Vector2.ONE * 1.18
	root.add_child(view)
	var context_overlay := Control.new()
	context_overlay.name = "G41IntegratedContextOverlay"
	context_overlay.size = Vector2(1280, 720)
	root.add_child(context_overlay)
	view.attach_context_popup(context_overlay)
	var debug_inventory_before: int = integration_context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size()
	var debug_backpack_result: Dictionary = integration_bus.dispatch(&"debug_spawn_test_item_backpack", {"source": "g41_art_qa"})
	var debug_inventory_after: int = integration_context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size()
	_check(bool(debug_backpack_result.get("ok", false)), "Backpack QA seed command was rejected")
	_check(debug_inventory_after == debug_inventory_before + 1, "Backpack QA seed command did not create an inventory item")
	view.interaction_commit_requested.connect(_on_integration_interaction_commit)
	view.configure_room(integration_context.get_status_snapshot())
	var request: Dictionary = view.request_nearest_interaction(Vector2(0.68, 0.53))
	_check(bool(request.get("accepted", false)) and bool(request.get("pending", false)), "Chest did not require the opening state before commit")
	view.advance(0.30, Vector2(0.68, 0.53), {})
	_check(integration_chest_commit_count == 1, "Chest opening did not commit exactly once")
	_check(integration_context.searched_cells.has(integration_context.cell_key(Vector2i(1, 1))), "Chest commit did not mark the room searched")
	view.resolve_chest_commit(true)
	var floor_after_open: Array[Dictionary] = integration_context.asset_ledger.get_room_floor_items(Vector2i(1, 1))
	_check(not floor_after_open.is_empty(), "Chest reward did not enter room_floor")
	view.configure_room(integration_context.get_status_snapshot())
	_check(view.chest != null and view.chest.is_opened(), "Committed chest did not retain its opened state")
	view.advance(0.0, Vector2(0.68, 0.53), {})
	_check(view.context_popup != null and view.context_popup.visible, "Approaching the chest did not reveal its contextual popup")
	var chest_anchor_ui: Vector2 = view.chest.get_global_transform().origin
	var chest_popup_rect := Rect2(view.context_popup.position, view.context_popup.size * view.context_popup.scale)
	_check(not chest_popup_rect.has_point(chest_anchor_ui), "Scaled room-to-UI mapping placed the contextual popup over the visible chest")
	var reward_count_before_reopen := floor_after_open.size()
	_check(view.chest.toggle_container(), "Opened chest could not be closed")
	_check(not view.chest.is_container_open(), "Closing the opened chest did not update its container state")
	_check(view.chest.toggle_container(), "Opened chest could not be reopened")
	_check(view.chest.is_container_open(), "Reopening the chest did not restore its container state")
	_check(integration_context.asset_ledger.get_room_floor_items(Vector2i(1, 1)).size() == reward_count_before_reopen, "Repeated chest open/close duplicated its contents")
	_check(integration_chest_commit_count == 1, "Repeated chest open/close committed search more than once")
	var view_snapshot: Dictionary = view.build_read_only_snapshot()
	var ground_entity_count := 0
	var target_ground_id := ""
	var target_ground_pos := Vector2.ZERO
	for interactable in (view_snapshot.get("interactables", []) as Array):
		if StringName((interactable as Dictionary).get("interaction_kind", &"")) == &"ground_loot":
			ground_entity_count += 1
			target_ground_id = String((interactable as Dictionary).get("interaction_id", ""))
			target_ground_pos = Vector2((interactable as Dictionary).get("local_pos", Vector2.ZERO))
	_check(ground_entity_count == floor_after_open.size(), "Room-floor ledger instances were not projected one-to-one as world entities")
	var first_projection := _ground_projection(view_snapshot)
	view.configure_room(integration_context.get_status_snapshot())
	_check(_ground_projection(view.build_read_only_snapshot()) == first_projection, "Repeated room-view configuration duplicated or moved a ledger projection")
	var rebuilt_view = RoomRuntimeViewScript.new()
	rebuilt_view.name = "G41RebuiltRoomView"
	root.add_child(rebuilt_view)
	rebuilt_view.configure_room(integration_context.get_status_snapshot())
	_check(_ground_projection(rebuilt_view.build_read_only_snapshot()) == first_projection, "Room-view rebuild failed to restore stable ground-loot positions")
	rebuilt_view.free()
	var pickup_request: Dictionary = view.request_nearest_interaction(target_ground_pos)
	_check(StringName(pickup_request.get("interaction_kind", &"")) == &"ground_loot", "Nearby ground entity did not win interaction focus")
	var pickup_result: Dictionary = integration_bus.dispatch(&"pickup_ground_item", {"instance_id": target_ground_id, "source": "g41_test"})
	_check(bool(pickup_result.get("ok", false)), "Ground entity could not be picked up through CommandBus")
	view.configure_room(integration_context.get_status_snapshot())
	_check((view.build_read_only_snapshot().get("interactables", []) as Array).size() == 1, "Picked instance remained in the room world projection")

	var used_before_full: int = int(integration_context.asset_ledger.get_backpack_used())
	integration_context.asset_ledger.backpack_capacity = used_before_full
	var full_ground_result: Dictionary = integration_context.asset_ledger.add_reward_items([ItemCatalogScript.debug_item()], RunAssetLedger.LOCATION_ROOM_FLOOR, Vector2i(1, 1), "g41_full_bag_test")
	var full_ground_items: Array = full_ground_result.get("ground_items", [])
	_check(not full_ground_items.is_empty(), "Full-bag setup did not create a floor item")
	var full_ground_id := String((full_ground_items[0] as Dictionary).get("instance_id", ""))
	var blocked_pickup: Dictionary = integration_bus.dispatch(&"pickup_ground_item", {"instance_id": full_ground_id, "source": "g41_test"})
	_check(not bool(blocked_pickup.get("ok", true)), "Full backpack pickup incorrectly succeeded")
	_check(_item_location(integration_context, full_ground_id) == RunAssetLedger.LOCATION_ROOM_FLOOR, "Blocked pickup consumed or moved the floor item")
	var inventory_items: Array[Dictionary] = integration_context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY)
	_check(not inventory_items.is_empty(), "Replacement setup has no inventory item")
	if not inventory_items.is_empty():
		var drop_id := String(inventory_items[0].get("instance_id", ""))
		var replace_result: Dictionary = integration_bus.dispatch(&"replace_ground_item", {"ground_instance_id": full_ground_id, "drop_instance_id": drop_id, "source": "g41_test"})
		_check(bool(replace_result.get("ok", false)), "Full backpack replacement failed")
		_check(_item_location(integration_context, full_ground_id) == RunAssetLedger.LOCATION_INVENTORY, "Replacement target did not enter inventory")
		_check(_item_location(integration_context, drop_id) == RunAssetLedger.LOCATION_ROOM_FLOOR, "Replaced inventory item did not become a world-floor ledger item")
		view.configure_room(integration_context.get_status_snapshot())
		var replacement_ids := _ground_projection_ids(view.build_read_only_snapshot())
		_check(drop_id in replacement_ids and not (full_ground_id in replacement_ids), "Replacement result was not reflected by the world-floor projection")

	var floor_count_before_repeat: int = int(integration_context.asset_ledger.get_room_floor_items(Vector2i(1, 1)).size())
	var black_before_repeat: int = int(integration_context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK))
	integration_bus.dispatch(&"search_current_room", {"source": "g41_test_repeat"})
	_check(integration_context.asset_ledger.get_room_floor_items(Vector2i(1, 1)).size() == floor_count_before_repeat, "Repeated chest search duplicated items")
	_check(integration_context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK) == black_before_repeat, "Repeated chest search duplicated currency")
	view.free()
	_release_controller(controller)
	integration_context = null
	integration_bus = null


func _check_integrated_combat_reward_and_flee() -> void:
	var controller = RuntimeControllerScript.new()
	controller.start_demo_run(controller.command_bus.room_resolver)
	var context = controller.context
	var bus = controller.command_bus
	context.max_hp = 500
	context.hp = 500
	context.power = 50
	_enter_test_room(controller, Vector2i(1, 5))
	controller.in_run_runtime.sync_room(Vector2(0.50, 0.50))
	_check(controller.in_run_runtime.has_active_combat(), "Monster room did not create an active fixed-step simulation")
	var view_rebuild_snapshot: Dictionary = controller.in_run_runtime.build_read_only_snapshot()
	var tick_before_view_rebuild := int(view_rebuild_snapshot.get("tick", 0))
	var first_combat_view = RoomRuntimeViewScript.new()
	root.add_child(first_combat_view)
	first_combat_view.configure_room(context.get_status_snapshot())
	first_combat_view.apply_combat_snapshot(view_rebuild_snapshot)
	var projected_enemy_count: int = int(first_combat_view.enemy_views.size())
	first_combat_view.free()
	var rebuilt_combat_view = RoomRuntimeViewScript.new()
	root.add_child(rebuilt_combat_view)
	rebuilt_combat_view.configure_room(context.get_status_snapshot())
	rebuilt_combat_view.apply_combat_snapshot(view_rebuild_snapshot)
	_check(rebuilt_combat_view.enemy_views.size() == projected_enemy_count, "Combat-view rebuild duplicated or omitted stable enemy projections")
	_check(int(controller.in_run_runtime.build_read_only_snapshot().get("tick", -1)) == tick_before_view_rebuild, "Combat-view rebuild reset or advanced the authoritative simulation")
	rebuilt_combat_view.free()
	var step_count := 0
	while controller.in_run_runtime.has_active_combat() and step_count < 3600:
		var combat: Dictionary = controller.in_run_runtime.build_read_only_snapshot()
		var combat_player: Dictionary = combat.get("player", {})
		var player_pos := Vector2(combat_player.get("pos", Vector2(0.5, 0.5)))
		var target := _first_alive_enemy(combat)
		var aim := Vector2.RIGHT
		var move := Vector2.ZERO
		if not target.is_empty():
			var offset := Vector2(target.get("pos", player_pos)) - player_pos
			aim = offset.normalized() if offset.length_squared() > 0.000001 else Vector2.RIGHT
			if offset.length() > 0.18:
				move = aim
			if offset.length() <= 0.21 and float(combat_player.get("attack_cooldown", 0.0)) <= 0.0001 and StringName(combat_player.get("state", &"idle")) in [&"idle", &"move"]:
				controller.in_run_runtime.request_attack()
		controller.in_run_runtime.advance_frame(1.0 / 60.0, move, aim)
		step_count += 1
	_check(context.truth_map.is_cleared(Vector2i(1, 5)), "Combat clear did not commit the room-cleared effect")
	var combat_floor_items: Array = context.asset_ledger.get_room_floor_items(Vector2i(1, 5))
	_check(not combat_floor_items.is_empty(), "Combat reward did not create an actual room-floor monster drop")
	var reward_view = RoomRuntimeViewScript.new()
	root.add_child(reward_view)
	reward_view.configure_room(context.get_status_snapshot())
	_check(_ground_projection(reward_view.build_read_only_snapshot()).size() == combat_floor_items.size(), "Combat reward ledger entries did not become world entities")
	reward_view.free()
	var floor_count_before_duplicate: int = combat_floor_items.size()
	var resolved_snapshot: Dictionary = controller.in_run_runtime.build_read_only_snapshot()
	bus.dispatch(&"resolve_runtime_combat", {"source": "g41_combat_simulation", "combat_snapshot": resolved_snapshot, "combat_seed": resolved_snapshot.get("seed", 0)})
	_check(context.asset_ledger.get_room_floor_items(Vector2i(1, 5)).size() == floor_count_before_duplicate, "Combat reward was committed more than once")

	var flee_room := Vector2i(0, 0)
	context.truth_map.set_room_type(flee_room, &"Monster")
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 100, "g41_flee_test")
	var common_item := ItemCatalogScript.collectible_items()[0]
	context.asset_ledger.add_reward_items([common_item], RunAssetLedger.LOCATION_INVENTORY, flee_room, "g41_flee_test")
	_enter_test_room(controller, flee_room)
	controller.in_run_runtime.sync_room(Vector2(0.50, 0.50))
	var black_before_flee: int = int(context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK))
	var flee_result: Dictionary = controller.in_run_runtime.request_flee()
	_check(bool(flee_result.get("ok", false)), "Combat flee request failed")
	_check(context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK) == black_before_flee - int(floor(float(black_before_flee) * 0.10)), "Flee did not lose exactly ten percent pending black coin")
	_check(not context.truth_map.is_cleared(flee_room), "Flee incorrectly cleared the monster room")
	for instance_id in (flee_result.get("dropped_instance_ids", []) as Array):
		_check(_item_location(context, String(instance_id)) == RunAssetLedger.LOCATION_ROOM_FLOOR, "Flee-selected item was deleted instead of moved to room_floor")
	controller.in_run_runtime.sync_room(Vector2(0.50, 0.50))
	_check(controller.in_run_runtime.has_active_combat(), "Re-entering an uncleared fled room did not restart combat")
	controller.start_demo_run(bus.room_resolver)
	_check(not controller.in_run_runtime.has_active_combat() and controller.in_run_runtime.encounter_ordinals.is_empty(), "Starting a new run did not clear G41 runtime lifecycle state")
	_release_controller(controller)


func _check_lifecycle_cleanup() -> void:
	var extract_controller = RuntimeControllerScript.new()
	extract_controller.start_demo_run(extract_controller.command_bus.room_resolver)
	_enter_test_room(extract_controller, Vector2i(1, 5))
	extract_controller.in_run_runtime.sync_room(Vector2(0.5, 0.5))
	_check(extract_controller.in_run_runtime.has_active_combat(), "Extraction lifecycle setup did not start combat")
	_enter_test_room(extract_controller, Vector2i(6, 6))
	var extract_request: Dictionary = extract_controller.command_bus.dispatch(&"request_extract", {"source": "g41_lifecycle_test"})
	var extract_confirm: Dictionary = extract_controller.command_bus.dispatch(&"confirm_extract", {"source": "g41_lifecycle_test"})
	_check(bool(extract_request.get("ok", false)) and bool(extract_confirm.get("ok", false)), "Normal extraction lifecycle did not complete")
	_check(_runtime_is_clean(extract_controller), "Normal extraction left G41 runtime state alive")
	_release_controller(extract_controller)

	var failure_controller = RuntimeControllerScript.new()
	failure_controller.start_demo_run(failure_controller.command_bus.room_resolver)
	_enter_test_room(failure_controller, Vector2i(1, 5))
	failure_controller.in_run_runtime.sync_room(Vector2(0.5, 0.5))
	var failure_result: Dictionary = failure_controller.fail_run("g41_lifecycle_test")
	_check(bool(failure_result.get("ok", false)) and _runtime_is_clean(failure_controller), "Failure lifecycle left G41 runtime state alive")
	_release_controller(failure_controller)

	var combat_defeat_controller = RuntimeControllerScript.new()
	combat_defeat_controller.start_demo_run(combat_defeat_controller.command_bus.room_resolver)
	combat_defeat_controller.context.hp = 1
	combat_defeat_controller.context.max_hp = 1
	_enter_test_room(combat_defeat_controller, Vector2i(1, 5))
	combat_defeat_controller.in_run_runtime.sync_room(Vector2(0.70, 0.50))
	var defeat_steps := 0
	while combat_defeat_controller.context.run_active and defeat_steps < 900:
		combat_defeat_controller.in_run_runtime.advance_frame(1.0 / 60.0, Vector2.ZERO, Vector2.LEFT)
		defeat_steps += 1
	_check(combat_defeat_controller.context.failed, "Natural runtime combat defeat did not end the run")
	_check(not combat_defeat_controller.context.result_snapshot.is_empty(), "Natural runtime combat defeat did not produce a result snapshot")
	_check(_runtime_is_clean(combat_defeat_controller), "Natural runtime combat defeat left G41 runtime state alive")
	_release_controller(combat_defeat_controller)

	var abandon_controller = RuntimeControllerScript.new()
	abandon_controller.start_demo_run(abandon_controller.command_bus.room_resolver)
	_enter_test_room(abandon_controller, Vector2i(1, 5))
	abandon_controller.in_run_runtime.sync_room(Vector2(0.5, 0.5))
	var abandon_result: Dictionary = abandon_controller.abandon_run("g41_lifecycle_test")
	_check(bool(abandon_result.get("ok", false)) and _runtime_is_clean(abandon_controller), "Abandon lifecycle left G41 runtime state alive")
	_release_controller(abandon_controller)


func _on_integration_interaction_commit(interaction_kind: StringName, _payload: Dictionary) -> void:
	if interaction_kind != &"chest" or integration_bus == null:
		return
	integration_chest_commit_count += 1
	integration_bus.dispatch(&"search_current_room", {"source": "g41_test_chest"})


func _enter_test_room(controller, pos: Vector2i) -> void:
	controller.context.player_pos = pos
	controller.context.current_pos = pos
	controller.command_bus.room_resolver.enter_room(controller.context)


func _item_location(context, instance_id: String) -> StringName:
	return StringName((context.asset_ledger.item_instances.get(instance_id, {}) as Dictionary).get("location_state", &"missing"))


func _first_alive_enemy(combat: Dictionary) -> Dictionary:
	for raw_enemy in (combat.get("enemies", []) as Array):
		if raw_enemy is Dictionary and int((raw_enemy as Dictionary).get("hp", 0)) > 0:
			return (raw_enemy as Dictionary).duplicate(true)
	return {}


func _ground_projection(snapshot: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_interactable in (snapshot.get("interactables", []) as Array):
		if not (raw_interactable is Dictionary):
			continue
		var interactable := raw_interactable as Dictionary
		if StringName(interactable.get("interaction_kind", &"")) != &"ground_loot":
			continue
		result.append({
			"instance_id": String(interactable.get("interaction_id", "")),
			"local_pos": Vector2(interactable.get("local_pos", Vector2.ZERO)),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("instance_id", "")) < String(b.get("instance_id", "")))
	return result


func _ground_projection_ids(snapshot: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for projection in _ground_projection(snapshot):
		result.append(String(projection.get("instance_id", "")))
	return result


func _runtime_is_clean(controller) -> bool:
	return (
		not controller.in_run_runtime.has_active_combat()
		and controller.in_run_runtime.encounter_ordinals.is_empty()
		and controller.in_run_runtime.recent_domain_events.is_empty()
		and controller.in_run_runtime.current_room_key.is_empty()
	)


func _release_controller(controller) -> void:
	if controller == null:
		return
	controller.in_run_runtime.bind(null)
	controller.command_bus.bind_runtime_controller(null)


func _base_config() -> Dictionary:
	return {
		"seed": 424242,
		"player_pos": Vector2(0.28, 0.50),
		"player_facing": Vector2.RIGHT,
		"player_hp": 500,
		"player_max_hp": 500,
		"player_power": 10,
		"monster_types": [&"slime", &"bat", &"drone"],
	}


func _run_schedule(schedule: Array[float], seconds: float) -> Dictionary:
	var simulation := CombatSimulationScript.new()
	simulation.start(_base_config())
	simulation.set_player_input(Vector2(0.0, 0.35), Vector2.RIGHT)
	_advance_exact(simulation, schedule, seconds)
	return {
		"state": simulation.build_canonical_snapshot(),
		"events": simulation.drain_events(),
	}


func _advance_exact(simulation: G41CombatSimulation, schedule: Array[float], seconds: float) -> void:
	var remaining := seconds
	var schedule_index := 0
	while remaining > 0.00000001:
		var frame_delta := minf(schedule[schedule_index % schedule.size()], remaining)
		simulation.advance_frame(frame_delta)
		remaining -= frame_delta
		schedule_index += 1


func _alive_enemy_count(snapshot: Dictionary) -> int:
	var result := 0
	for enemy in (snapshot.get("enemies", []) as Array):
		if int((enemy as Dictionary).get("hp", 0)) > 0:
			result += 1
	return result


func _finish() -> void:
	if failures.is_empty():
		print("G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS fixed_hz=60 outer_schedules=30,60,144,hitch monsters=slime,slimeling,bat,drone visual_contract=v1")
		quit(0)
		return
	for failure in failures:
		push_error("G41 runtime failure: " + failure)
	print("G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=FAIL failures=%d" % failures.size())
	quit(1)
