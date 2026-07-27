extends SceneTree

# Production-state evidence generator for I3R rework.
#
# This runner instantiates res://scenes/main/main.tscn exactly once. It uses
# RunScene and CommandBus for ordinary state changes. States that cannot be
# reached repeatedly in one non-destructive journey (armed/triggered mine,
# exit, and combat in the same current cell) are explicit authority fixtures
# and are labelled as such in every case metadata file.
#
# PNG generation proves only that a production state was constructed and
# rendered. It is not visual acceptance and it never instantiates the legacy
# ART24 hand-drawn preview.

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")

const PASS_MARKER := "I3R_PRODUCTION_STATE_GALLERY=PASS"
const FAIL_MARKER := "I3R_PRODUCTION_STATE_GALLERY=FAIL"
const READY_MARKER := "I3R_PRODUCTION_STATE_GALLERY=INTERACTIVE_READY"
const PRODUCTION_MAIN_SCENE := "res://scenes/main/main.tscn"
const FIXED_SEED := 13
const EXPECTED_SPAWN := Vector2i(2, 6)
const EXPECTED_CASES: Array[String] = [
	"chest_closed",
	"chest_open_contents",
	"event_modal",
	"ground_loot_nearby",
	"door_available",
	"mine_armed_before",
	"mine_triggered_after",
	"mine_departed_clear",
	"exit_summary",
	"door_combat_locked",
	"combat_enemy_telegraph",
	"combat_player_attack_geometry",
]
const GLOBAL_FAILURE_CRITERIA: Array[String] = [
	"production main.tscn is instantiated zero times or more than once",
	"the fixed seed or audited spawn is not preserved",
	"a required production state cannot be constructed",
	"a state assertion is false at capture time",
	"a PNG, metadata JSON, or SHA-256 sidecar is missing or empty",
	"the production renderer returns a size different from the requested window",
	"legacy ART24 hand-drawn preview code is instantiated or represented as production evidence",
	"automatic mode fails to terminate with a complete manifest",
]

var output_dir := ""
var manifest_path := ""
var physical_size := Vector2i(1280, 720)
var interactive_combat := false
var started_msec := 0
var main_instance_count := 0
var capture_index := 0
var main: Node
var run_scene: Node
var cases: Array[Dictionary] = []
var failures: Array[String] = []
var setup_trace: Array[String] = []
var quit_scheduled := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	started_msec = Time.get_ticks_msec()
	var options := _parse_options(OS.get_cmdline_user_args())
	output_dir = _absolute_path(String(options.get("output-dir", "")))
	manifest_path = _absolute_path(String(options.get(
		"manifest-output",
		output_dir.path_join("manifest.json") if not output_dir.is_empty() else ""
	)))
	physical_size = Vector2i(
		int(options.get("width", 1280)),
		int(options.get("height", 720))
	)
	interactive_combat = _parse_bool(String(options.get("interactive-combat", "false")))
	if output_dir.is_empty() or manifest_path.is_empty():
		_fail_setup("missing --output-dir or --manifest-output")
		_finish()
		return
	if physical_size.x < 960 or physical_size.y < 540:
		_fail_setup("capture size must be at least 960x540")
		_finish()
		return
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		_fail_setup("could not create output directory: %s" % error_string(mkdir_error))
		_finish()
		return

	root.size = physical_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_factor = 1.0
	root.transparent_bg = false
	root.title = "I3R production state gallery"

	var packed := load(PRODUCTION_MAIN_SCENE) as PackedScene
	if packed == null:
		_fail_setup("production main.tscn could not be loaded")
		_finish()
		return
	main = packed.instantiate()
	main_instance_count += 1
	root.add_child(main)
	setup_trace.append("instantiate production res://scenes/main/main.tscn")
	await _frames(18)
	run_scene = main.get_node_or_null("RunScene")
	if run_scene == null:
		_fail_setup("production RunScene is missing")
		_finish()
		return
	if not await _start_fixed_seed_run():
		_finish()
		return
	if not await _produce_gallery():
		_finish()
		return
	_finish()


func _produce_gallery() -> bool:
	if not await _transition_room(Vector2i.RIGHT, Vector2i(3, 6), &"Chest"):
		return false
	if not await _focus_interactable(&"chest"):
		return false
	if not await _capture_case(
		"chest_closed",
		"command_bus_transition_plus_production_player_controller_position_fixture",
		[],
		[
			"CommandBus.attempt_room_transition RIGHT",
			"PlayerController.set_local_position near projected chest",
			"production proximity popup refresh",
		],
		_chest_closed_assertions(),
		[
			"current room is not the audited Chest room",
			"the chest is already searched",
			"the production proximity popup is absent or not a closed chest",
		]
	):
		return false

	run_scene.call("_handle_interact_pressed")
	if not await _wait_until(func() -> bool:
		var snapshot := _status()
		return bool((snapshot.get("search_state_data", {}) as Dictionary).get("searched", false))
	, 3.0):
		_fail_setup("production chest search command did not settle")
		return false
	if not await _wait_until(func() -> bool:
		return StringName(_first_interactable(&"chest").get("visual_state", &"")) == &"opened"
	, 2.0):
		_fail_setup("production chest opening presentation did not settle")
		return false
	if not await _capture_case(
		"chest_open_contents",
		"production_run_scene_interaction_plus_command_bus",
		[],
		[
			"RunScene._handle_interact_pressed",
			"CommandBus.search_current_room",
			"G41RoomRuntimeView.apply_chest_search_result",
		],
		_chest_open_assertions(),
		[
			"authoritative search state is not searched",
			"the chest is not visibly opened",
			"the production popup does not expose authoritative container items",
		]
	):
		return false

	var chest_items := _context_items()
	if chest_items.is_empty():
		_fail_setup("opened chest exposed no item to carry into the ground-loot state")
		return false
	var carried_before := (_status().get("inventory_items", []) as Array).size()
	run_scene.call("_pickup_floor_from_ui", String((chest_items[0] as Dictionary).get("instance_id", "")))
	if not await _wait_until(func() -> bool:
		return (_status().get("inventory_items", []) as Array).size() > carried_before
	, 3.0):
		_fail_setup("production chest pickup command did not add an inventory item")
		return false

	if not await _transition_room(Vector2i.UP, Vector2i(3, 5), &"Event"):
		return false
	if not await _focus_interactable(&"event"):
		return false
	run_scene.call("_handle_interact_pressed")
	if not await _wait_until(func() -> bool:
		var panel := run_scene.get("event_panel") as Control
		return panel != null and panel.visible
	, 2.0):
		_fail_setup("production event modal did not open")
		return false
	if not await _capture_case(
		"event_modal",
		"command_bus_transition_plus_production_event_ui",
		[],
		[
			"CommandBus.attempt_room_transition UP",
			"PlayerController.set_local_position near projected event",
			"RunScene._handle_interact_pressed",
			"production Event modal and focus stack",
		],
		_event_assertions(),
		[
			"event state is empty or already completed",
			"the production Event modal is not visible",
			"the modal focus stack does not own the event",
		]
	):
		return false
	run_scene.call("_select_event_option", &"leave")
	await _frames(8)
	if _modal_depth() > 0:
		_fail_setup("event modal did not close after the production leave option")
		return false

	if not await _transition_room(Vector2i.UP, Vector2i(3, 4), &"Normal"):
		return false
	var inventory_items: Array = _status().get("inventory_items", [])
	if inventory_items.is_empty():
		_fail_setup("no carried item remained for the production ground-loot state")
		return false
	var drop_instance_id := String((inventory_items[0] as Dictionary).get("instance_id", ""))
	var inventory_before_drop := inventory_items.size()
	run_scene.call("_drop_inventory_from_ui", drop_instance_id)
	if not await _wait_until(func() -> bool:
		var snapshot := _status()
		return (
			(snapshot.get("inventory_items", []) as Array).size() < inventory_before_drop
			and int(snapshot.get("room_floor_item_count", 0)) > 0
		)
	, 3.0):
		_fail_setup("production drop command did not create floor loot")
		return false
	if not await _focus_interactable(&"ground_loot"):
		return false
	if not await _capture_case(
		"ground_loot_nearby",
		"production_run_scene_drop_command_plus_player_position_fixture",
		[],
		[
			"RunScene._drop_inventory_from_ui",
			"CommandBus.drop_inventory_item",
			"PlayerController.set_local_position near projected floor loot",
			"production automatic proximity popup",
		],
		_ground_loot_assertions(),
		[
			"authoritative room floor inventory is empty",
			"no production ground-loot entity exists",
			"approaching the item does not automatically expose its contents",
		]
	):
		return false

	if not await _focus_available_door():
		return false
	if not await _capture_case(
		"door_available",
		"production_door_projection_plus_player_position_fixture",
		[],
		[
			"read public production door projection",
			"PlayerController.set_local_position near an available door",
			"production available-door cue refresh",
		],
		_door_available_assertions(),
		[
			"no public door projection is available",
			"the nearby door cue is not the available state",
			"the production door is hidden or represented as blocked",
		]
	):
		return false

	if not await _prepare_mine_before():
		return false
	if not await _capture_case(
		"mine_armed_before",
		"authority_fixture_truth_room_type_and_trigger_flags",
		[
			"RunContext.current_room_type",
			"TruthMap.rooms[current].room_type",
			"TruthMap.rooms[current].triggered",
			"RunContext.entered_cells[current]",
		],
		[
			"convert the current audited cell to Mine through TruthMap.set_room_type",
			"clear current entered/triggered flags for a before-state fixture",
			"refresh only through production RunScene and G41RoomRuntimeView",
			"PlayerController.set_local_position near projected mine",
		],
		_mine_before_assertions(),
		[
			"the authoritative current room is not Mine",
			"the truth cell is already triggered",
			"the projected mine is not armed",
			"the production proximity popup does not expose the armed mine",
		]
	):
		return false

	if not await _trigger_mine_through_room_resolver():
		return false
	if not await _capture_case(
		"mine_triggered_after",
		"authority_fixture_then_production_room_resolver",
		[
			"fixture predecessor: RunContext.entered_cells[current]",
			"fixture predecessor: TruthMap.rooms[current].triggered",
		],
		[
			"RoomResolver.enter_room on the armed authority fixture",
			"RunScene._apply_room_entry_result",
			"production mine feedback cue and room projection",
		],
		_mine_after_assertions(),
		[
			"RoomResolver does not report a first trigger",
			"the truth cell remains untriggered",
			"mine consequence feedback is not active",
			"the projected mine does not change to resolved",
		]
	):
		return false

	if not await _leave_triggered_mine():
		return false
	if not await _capture_case(
		"mine_departed_clear",
		"production_player_position_after_resolved_mine_feedback",
		[],
		[
			"advance the production Mine feedback through its fixed duration",
			"PlayerController.set_local_position outside the projected mine footprint",
			"refresh production proximity and static world-object depth",
		],
		_mine_departed_assertions(),
		[
			"resolved Mine feedback remains visible after its duration",
			"the player remains geometrically overlapped with the Mine fixture",
			"the static Mine is no longer below the player layer",
		]
	):
		return false

	if not await _prepare_exit_summary():
		return false
	if not await _capture_case(
		"exit_summary",
		"authority_fixture_exit_cell_then_production_request_extract_command",
		[
			"TruthMap.rooms[current].room_type",
			"TruthMap.rooms[current].exit_id",
			"TruthMap.exits",
		],
		[
			"convert the current audited cell to Exit",
			"RoomResolver.enter_room",
			"PlayerController.set_local_position near projected exit beacon",
			"RunScene._request_extract_from_ui",
			"CommandBus.request_extract",
			"production extraction summary modal",
		],
		_exit_summary_assertions(),
		[
			"exit authority has no exit_id",
			"the proximity exit projection is unavailable",
			"request_extract does not enter confirm_extract",
			"the production extraction summary modal is not visible",
		]
	):
		return false
	run_scene.call("_cancel_extract_from_ui")
	if not await _wait_until(func() -> bool:
		var panel := run_scene.get("extract_panel") as Control
		return (
			(panel == null or not panel.visible)
			and StringName(_status().get("phase", &"")) == &"running"
		)
	, 2.0):
		_fail_setup("production exit summary did not cancel back to running")
		return false

	if not await _prepare_combat():
		return false
	if not await _capture_case(
		"door_combat_locked",
		"authority_fixture_room_type_then_production_combat_runtime",
		[
			"TruthMap.rooms[current].room_type",
			"TruthMap.rooms[current].exit_id",
			"TruthMap.exits",
		],
		[
			"convert the current audited cell to Monster",
			"RoomResolver.enter_room",
			"G41InRunRuntime.sync_room",
			"G41CombatSimulation start",
			"production combat-restricted door projection",
		],
		_door_combat_assertions(),
		[
			"production combat is not active",
			"combat authority does not lock doors",
			"door projections do not expose combat_restricted",
		]
	):
		return false

	if not await _wait_for_enemy_telegraph():
		_fail_setup("production combat did not expose a melee warning telegraph within timeout")
		return false
	if not await _capture_case(
		"combat_enemy_telegraph",
		"production_combat_simulation_natural_warning",
		[
			"fixture predecessor: current cell room_type=Monster",
		],
		[
			"G41CombatSimulation fixed-step advance",
			"natural slime approach and melee warning state",
			"G41RoomRuntimeView production warning geometry draw",
		],
		_combat_telegraph_assertions(),
		[
			"no enemy reaches the production warning state",
			"warning_radius is zero",
			"production room view does not receive visible warning geometry",
		]
	):
		return false

	if not await _prepare_occluded_player_attack_fixture():
		return false
	var runtime = run_scene.get("in_run_runtime")
	var attack_result: Dictionary = runtime.request_attack() if runtime != null else {}
	if not bool(attack_result.get("ok", false)):
		_fail_setup("production combat runtime rejected the attack request")
		return false
	if not await _wait_for_player_attack_geometry():
		_fail_setup("production combat did not expose player attack geometry within timeout")
		return false
	if not await _capture_case(
		"combat_player_attack_geometry",
		"authority_fixture_occluded_attack_then_production_g41_request_attack",
		[
			"fixture predecessor: current cell room_type=Monster",
			"G41CombatSimulation.player position/facing",
			"G41CombatSimulation first enemy position/state",
		],
		[
			"place player above the visible altar so the lower attack arc is clipped",
			"G41InRunRuntime.request_attack",
			"G41CombatSimulation queued attack and reached the fixed-step active phase",
			"G41CombatSimulation obstacle-clipped player_attack_geometry snapshot",
			"G41RoomRuntimeView consumes authoritative visible_arc_points",
		],
		_combat_attack_assertions(),
		[
			"the production attack request is rejected",
			"player_attack_geometry.visible never becomes true",
			"the geometry is not the production sector contract",
			"the altar does not clip any visual sample",
			"the attack visual cites a different obstacle authority",
			"the production room view does not receive the attack snapshot",
		]
	):
		return false
	return true


func _start_fixed_seed_run() -> bool:
	run_scene.call("_show_deploy_shell", &"config")
	await _frames(8)
	var ui_shell = run_scene.get("ui_shell")
	if ui_shell == null or not ui_shell.has_method("get_deploy_page"):
		_fail_setup("production AppShell does not expose Deploy for fixed-seed setup")
		return false
	var deploy_page = ui_shell.call("get_deploy_page")
	if deploy_page == null:
		_fail_setup("production Deploy page is missing for fixed-seed setup")
		return false
	deploy_page.call("_on_map_requested", &"classic_7x7_simple")
	await _frames(5)
	var deploy_config: Dictionary = deploy_page.call("_config")
	if String(deploy_config.get("map_config_id", "")) != "classic_7x7_simple":
		_fail_setup("production Deploy did not accept the fixed-seed standard map")
		return false
	var run_start_preview := DeployConfigScript.build_run_start_config(deploy_config)
	run_start_preview["seed_value"] = FIXED_SEED
	var route_payload := RunStartRouteAdapterScript.payload_from_deploy_preview(
		run_start_preview,
		{
			"route_mode": &"standard_run",
			"entry_id": &"i3r_state_gallery_fixed_seed",
			"uses_existing_route": true,
		}
	)
	run_scene.call(
		"_start_run_from_route",
		NavigationIntentScript.make_run(
			&"i3r_production_state_gallery",
			route_payload
		)
	)
	setup_trace.append("RunScene._start_run_from_route standard_run fixed seed 13")
	if not await _wait_until(func() -> bool:
		var context = run_scene.get("run_context")
		return (
			context != null
			and bool(context.get("run_active"))
			and StringName(run_scene.get("screen_state")) == &"run"
		)
	, 6.0):
		_fail_setup(
			"fixed-seed production route did not start: %s"
			% JSON.stringify(run_scene.get("last_command_result"))
		)
		return false
	await _frames(12)
	var context = run_scene.get("run_context")
	if int(context.get("seed_value")) != FIXED_SEED:
		_fail_setup("production route did not preserve fixed seed 13")
		return false
	if context.get_current_pos() != EXPECTED_SPAWN:
		_fail_setup("seed-13 audited spawn changed: %s" % str(context.get_current_pos()))
		return false
	return true


func _transition_room(direction: Vector2i, expected_pos: Vector2i, expected_type: StringName) -> bool:
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	var player = run_scene.get("player_controller")
	if context == null or bus == null or player == null:
		_fail_setup("production transition authority is missing")
		return false
	var before: Vector2i = context.get_current_pos()
	var result: Dictionary = bus.dispatch(&"attempt_room_transition", {
		"direction": direction,
		"source": "i3r_production_state_gallery",
	})
	run_scene.call("_apply_room_entry_result", result)
	if bool(result.get("ok", false)) and context.get_current_pos() != before:
		player.place_from_entry(direction)
	else:
		_fail_setup(
			"CommandBus transition failed direction=%s result=%s"
			% [str(direction), JSON.stringify(_json_safe(result))]
		)
		return false
	run_scene.call("_refresh_view_models")
	await _frames(10)
	var run_surface = run_scene.get("run_surface")
	if run_surface != null and run_surface.has_method("clear_command_feedback"):
		run_surface.call("clear_command_feedback")
		await _frames(2)
	var snapshot := _status()
	if (
		Vector2i(snapshot.get("position", Vector2i(-1, -1))) != expected_pos
		or StringName(snapshot.get("current_room", &"Unknown")) != expected_type
	):
		_fail_setup(
			"transition reached unexpected state pos=%s room=%s"
			% [str(snapshot.get("position", Vector2i(-1, -1))), String(snapshot.get("current_room", &"Unknown"))]
		)
		return false
	return true


func _focus_interactable(kind: StringName) -> bool:
	var target := _first_interactable(kind)
	var player = run_scene.get("player_controller")
	if target.is_empty() or player == null:
		_fail_setup("production interactable is missing: %s" % String(kind))
		return false
	var local_pos := Vector2(target.get("local_pos", Vector2(-1, -1)))
	var radius := float(target.get("interaction_radius", 0.0))
	var offset := minf(0.08, maxf(0.025, radius * 0.45))
	var focus_pos := Vector2(local_pos.x, clampf(local_pos.y + offset, 0.07, 0.93))
	player.set_local_position(focus_pos)
	await _frames(10)
	if _context_kind() != kind:
		_fail_setup("production proximity popup did not focus %s" % String(kind))
		return false
	return true


func _focus_available_door() -> bool:
	var runtime_snapshot := _runtime_view_snapshot()
	var available := _first_door_with_state(runtime_snapshot, &"available")
	var player = run_scene.get("player_controller")
	if available.is_empty() or player == null:
		_fail_setup("no available public production door exists in the audited normal room")
		return false
	var anchor := Vector2(available.get("ground_anchor_local", available.get("local_pos", Vector2(0.5, 0.5))))
	var direction := Vector2i((available.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
	var inward := Vector2(-direction.x, -direction.y) * 0.04
	player.set_local_position(anchor + inward)
	await _frames(10)
	return true


func _prepare_mine_before() -> bool:
	var context = run_scene.get("run_context")
	if context == null or context.truth_map == null:
		_fail_setup("mine fixture authority is missing")
		return false
	var pos: Vector2i = context.get_current_pos()
	var key: String = String(context.cell_key(pos))
	context.truth_map.set_room_type(pos, &"Mine")
	var cell: Dictionary = context.truth_map.rooms.get(key, {})
	cell["room_type"] = &"Mine"
	cell["mine"] = true
	cell["triggered"] = false
	context.truth_map.rooms[key] = cell
	context.entered_cells.erase(key)
	context.current_room_type = &"Mine"
	context.event_state = {}
	context.enemy_state = {}
	run_scene.call("_refresh_view_models")
	await _frames(8)
	if not await _focus_interactable(&"mine"):
		return false
	return await _position_player_relative_to_mine(Vector2(-0.14, 0.0))


func _trigger_mine_through_room_resolver() -> bool:
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	var view = run_scene.get("room_runtime_view")
	if context == null or bus == null or view == null:
		_fail_setup("mine RoomResolver authority is missing")
		return false
	if not await _position_player_relative_to_mine(Vector2.ZERO):
		return false
	var result: Dictionary = bus.room_resolver.enter_room(context)
	var entry: Dictionary = result.get("room_entry_result", {})
	if (
		not bool(result.get("ok", false))
		or not bool(entry.get("first_trigger", false))
		or StringName(entry.get("cause", &"")) != &"mine_triggered"
	):
		_fail_setup("production RoomResolver did not produce a first mine trigger")
		return false
	run_scene.call("_apply_room_entry_result", result)
	run_scene.call("_refresh_view_models")
	view.apply_room_entry_result(entry)
	await _focus_interactable(&"mine")
	await _frames(2)
	return true


func _leave_triggered_mine() -> bool:
	var view = run_scene.get("room_runtime_view")
	if view == null:
		_fail_setup("production Mine view is missing before departure evidence")
		return false
	view.advance(0.30, _mine_local_pos() + Vector2(0.22, 0.0), {})
	if not await _position_player_relative_to_mine(Vector2(0.22, 0.0)):
		return false
	await _frames(3)
	return true


func _position_player_relative_to_mine(offset: Vector2) -> bool:
	var player = run_scene.get("player_controller")
	var view = run_scene.get("room_runtime_view")
	var mine := _first_interactable(&"mine")
	if player == null or view == null or mine.is_empty():
		_fail_setup("production Mine/player geometry is missing")
		return false
	var target := Vector2(mine.get("local_pos", Vector2(-1, -1))) + offset
	player.set_local_position(target)
	view.advance(0.0, player.get_local_position(), {})
	await _frames(4)
	return true


func _mine_local_pos() -> Vector2:
	var mine := _first_interactable(&"mine")
	return Vector2(mine.get("local_pos", Vector2(0.5, 0.5)))


func _prepare_exit_summary() -> bool:
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	if context == null or context.truth_map == null or bus == null:
		_fail_setup("exit fixture authority is missing")
		return false
	var pos: Vector2i = context.get_current_pos()
	var key: String = String(context.cell_key(pos))
	context.truth_map.set_room_type(pos, &"Exit")
	var cell: Dictionary = context.truth_map.rooms.get(key, {})
	cell["room_type"] = &"Exit"
	cell["mine"] = false
	cell["exit_id"] = &"i3r_gallery_exit"
	cell["random_exit"] = false
	context.truth_map.rooms[key] = cell
	if not context.truth_map.exits.has(pos):
		context.truth_map.exits.append(pos)
	var result: Dictionary = bus.room_resolver.enter_room(context)
	if not bool(result.get("ok", false)) or context.current_room_type != &"Exit":
		_fail_setup("production RoomResolver did not admit the exit fixture")
		return false
	run_scene.call("_apply_room_entry_result", result)
	run_scene.call("_refresh_view_models")
	await _frames(8)
	if not await _focus_interactable(&"exit"):
		return false
	run_scene.call("_request_extract_from_ui")
	if not await _wait_until(func() -> bool:
		var panel := run_scene.get("extract_panel") as Control
		return (
			panel != null
			and panel.visible
			and StringName(_status().get("phase", &"")) == &"confirm_extract"
		)
	, 2.0):
		_fail_setup("production request_extract did not open its summary")
		return false
	return true


func _prepare_combat() -> bool:
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	var player = run_scene.get("player_controller")
	if context == null or context.truth_map == null or bus == null or player == null:
		_fail_setup("combat fixture authority is missing")
		return false
	var pos: Vector2i = context.get_current_pos()
	var key: String = String(context.cell_key(pos))
	context.truth_map.set_room_type(pos, &"Monster")
	var cell: Dictionary = context.truth_map.rooms.get(key, {})
	cell["room_type"] = &"Monster"
	cell["mine"] = false
	cell.erase("exit_id")
	cell.erase("random_exit")
	context.truth_map.rooms[key] = cell
	context.truth_map.exits.erase(pos)
	context.max_hp = maxi(100, int(context.max_hp))
	context.hp = context.max_hp
	player.set_local_position(Vector2(0.50, 0.50))
	var result: Dictionary = bus.room_resolver.enter_room(context)
	if not bool(result.get("ok", false)) or context.current_room_type != &"Monster":
		_fail_setup("production RoomResolver did not admit the combat fixture")
		return false
	run_scene.call("_apply_room_entry_result", result)
	run_scene.call("_refresh_view_models")
	if not await _wait_until(func() -> bool:
		var runtime = run_scene.get("in_run_runtime")
		return runtime != null and runtime.has_active_combat()
	, 3.0):
		_fail_setup("production G41 combat runtime did not start")
		return false
	await _frames(3)
	return true


func _wait_for_enemy_telegraph() -> bool:
	return await _wait_until(func() -> bool:
		var combat := _combat_snapshot()
		for raw_enemy in combat.get("enemies", []) as Array:
			if raw_enemy is Dictionary:
				var enemy := raw_enemy as Dictionary
				if (
					StringName(enemy.get("state", &"")) == &"warning"
					and float(enemy.get("warning_radius", 0.0)) > 0.0
				):
					return true
		return false
	, 5.0)


func _prepare_occluded_player_attack_fixture() -> bool:
	var runtime = run_scene.get("in_run_runtime")
	var simulation = runtime.get("simulation") if runtime != null else null
	var player = run_scene.get("player_controller")
	if simulation == null or player == null or simulation.enemies.is_empty():
		_fail_setup("production occluded-attack fixture authority is missing")
		return false
	for enemy_index in range(simulation.enemies.size()):
		var inactive_enemy: Dictionary = simulation.enemies[enemy_index]
		inactive_enemy["hp"] = 0
		inactive_enemy["state"] = &"dead"
		simulation.enemies[enemy_index] = inactive_enemy
	var target: Dictionary = simulation.enemies[0]
	target["pos"] = Vector2(0.48, 0.33)
	target["hp"] = maxi(50, int(target.get("max_hp", 1)))
	target["max_hp"] = maxi(50, int(target.get("max_hp", 1)))
	target["state"] = &"hurt"
	target["state_timer"] = 999.0
	target["attack_done"] = false
	simulation.enemies[0] = target
	var origin := Vector2(0.285, 0.33)
	var facing := Vector2.RIGHT
	simulation.player["pos"] = origin
	simulation.player["velocity"] = Vector2.ZERO
	simulation.player["facing"] = facing
	simulation.player["state"] = &"idle"
	simulation.player["state_timer"] = 0.0
	simulation.player["attack_cooldown"] = 0.0
	simulation.aim_input = facing
	simulation.move_input = Vector2.ZERO
	simulation.attack_queued = false
	simulation.attack_buffer_remaining = 0.0
	simulation.active_player_attack.clear()
	simulation.active = true
	simulation.cleared = false
	simulation.defeated = false
	simulation.call("_capture_previous_transforms")
	player.set_local_position(origin)
	player.set_facing_vector(facing)
	await _frames(2)
	return true


func _wait_for_player_attack_geometry() -> bool:
	return await _wait_until(func() -> bool:
		var geometry: Dictionary = _combat_snapshot().get("player_attack_geometry", {})
		return (
			bool(geometry.get("visible", false))
			and StringName(geometry.get("phase", &"")) == &"attack_active"
		)
	, 1.5)


func _capture_case(
	state_id: String,
	fixture_method: String,
	authority_fields_mutated: Array,
	construction_steps: Array,
	assertions: Dictionary,
	failure_criteria: Array
) -> bool:
	capture_index += 1
	await _frames(2)
	var prefix := "%02d_%s" % [capture_index, state_id]
	var png_path := output_dir.path_join(prefix + ".png")
	var metadata_path := output_dir.path_join(prefix + ".metadata.json")
	var sha_path := output_dir.path_join(prefix + ".sha256")
	var image := root.get_texture().get_image()
	if image == null:
		_fail_setup("renderer returned no image for %s" % state_id)
		return false
	if image.get_width() != physical_size.x or image.get_height() != physical_size.y:
		_fail_setup(
			"renderer size mismatch for %s: %dx%d expected=%dx%d"
			% [state_id, image.get_width(), image.get_height(), physical_size.x, physical_size.y]
		)
		return false
	var png_error := image.save_png(png_path)
	if png_error != OK:
		_fail_setup("PNG save failed for %s: %s" % [state_id, error_string(png_error)])
		return false
	var png_bytes := FileAccess.get_file_as_bytes(png_path).size()
	var png_sha256 := FileAccess.get_sha256(png_path).to_upper()
	if png_bytes <= 0 or png_sha256.is_empty():
		_fail_setup("PNG hash failed for %s" % state_id)
		return false
	var assertions_pass := _all_assertions_pass(assertions)
	var metadata := {
		"schema_version": 1,
		"suite_id": "I3R_production_state_gallery_case",
		"status": "GENERATED_REVIEW_REQUIRED" if assertions_pass else "FAIL_STATE_ASSERTION",
		"visual_acceptance": "NOT_RUN",
		"visual_acceptance_notice": "Rendered evidence requires human visual review; generation is not visual signoff.",
		"state_id": state_id,
		"sequence": capture_index,
		"production_scene_path": PRODUCTION_MAIN_SCENE,
		"production_main_instances": main_instance_count,
		"fixed_seed": FIXED_SEED,
		"route": "production_standard_run_seed_13_single_main_instance",
		"fixture_method": fixture_method,
		"player_journey": false,
		"player_journey_notice": "This gallery uses production commands plus labelled position/authority fixtures; use the registered production input journey for genuine player-input evidence.",
		"authority_fields_mutated": authority_fields_mutated,
		"construction_steps": construction_steps,
		"assertions": assertions,
		"assertions_pass": assertions_pass,
		"failure_criteria": failure_criteria,
		"production_snapshot": _snapshot_summary(),
		"physical_size": [physical_size.x, physical_size.y],
		"logical_canvas_size": [root.content_scale_size.x, root.content_scale_size.y],
		"canvas_content_scale_factor": root.content_scale_factor,
		"png_path": png_path,
		"png_bytes": png_bytes,
		"png_sha256": png_sha256,
		"legacy_art24_hand_drawn_preview_instantiated": false,
		"production_geometry_note": "Combat geometry is drawn by G41RoomRuntimeView from the production combat snapshot; no debug overlay is fabricated.",
		"generated_utc": Time.get_datetime_string_from_system(true, true),
	}
	if not _write_json(metadata_path, metadata):
		_fail_setup("metadata save failed for %s" % state_id)
		return false
	var metadata_bytes := FileAccess.get_file_as_bytes(metadata_path).size()
	var metadata_sha256 := FileAccess.get_sha256(metadata_path).to_upper()
	if metadata_bytes <= 0 or metadata_sha256.is_empty():
		_fail_setup("metadata hash failed for %s" % state_id)
		return false
	var sha_text := "%s  %s\n%s  %s\n" % [
		png_sha256,
		png_path.get_file(),
		metadata_sha256,
		metadata_path.get_file(),
	]
	if not _write_text(sha_path, sha_text):
		_fail_setup("SHA sidecar save failed for %s" % state_id)
		return false
	var case_entry := {
		"state_id": state_id,
		"sequence": capture_index,
		"status": metadata["status"],
		"assertions_pass": assertions_pass,
		"fixture_method": fixture_method,
		"player_journey": false,
		"png_path": png_path,
		"png_bytes": png_bytes,
		"png_sha256": png_sha256,
		"metadata_path": metadata_path,
		"metadata_bytes": metadata_bytes,
		"metadata_sha256": metadata_sha256,
		"sha256_path": sha_path,
	}
	cases.append(case_entry)
	if not assertions_pass:
		var failed_names: Array[String] = []
		for key in assertions:
			if not bool(assertions[key]):
				failed_names.append(String(key))
		_fail_setup("%s assertions failed: %s" % [state_id, ", ".join(failed_names)])
		return false
	print(
		"I3R_PRODUCTION_STATE_GALLERY_CASE=PASS state=%s png=%s metadata=%s sha=%s"
		% [state_id, png_path, metadata_path, sha_path]
	)
	return true


func _chest_closed_assertions() -> Dictionary:
	var search: Dictionary = _status().get("search_state_data", {})
	var chest := _first_interactable(&"chest")
	return {
		"screen_is_run": StringName(run_scene.get("screen_state")) == &"run",
		"room_is_chest": StringName(_status().get("current_room", &"")) == &"Chest",
		"authority_not_searched": not bool(search.get("searched", false)),
		"context_kind_is_chest": _context_kind() == &"chest",
		"context_opened_once_is_false": not _context_opened_once(),
		"chest_visual_is_closed": StringName(chest.get("visual_state", &"")) == &"closed",
		"global_feedback_is_hidden": _global_feedback_is_hidden(),
	}


func _chest_open_assertions() -> Dictionary:
	var search: Dictionary = _status().get("search_state_data", {})
	var chest := _first_interactable(&"chest")
	return {
		"room_is_chest": StringName(_status().get("current_room", &"")) == &"Chest",
		"authority_searched": bool(search.get("searched", false)),
		"context_kind_is_chest": _context_kind() == &"chest",
		"context_opened_once_is_true": _context_opened_once(),
		"context_has_items": _context_items().size() > 0,
		"chest_visual_is_opened": StringName(chest.get("visual_state", &"")) == &"opened",
		"global_feedback_is_hidden": _global_feedback_is_hidden(),
	}


func _event_assertions() -> Dictionary:
	var panel := run_scene.get("event_panel") as Control
	var event_state: Dictionary = _status().get("event_state", {})
	return {
		"room_is_event": StringName(_status().get("current_room", &"")) == &"Event",
		"event_state_exists": not event_state.is_empty(),
		"event_not_completed": not bool(event_state.get("completed", false)),
		"event_panel_visible": panel != null and panel.visible,
		"modal_top_is_event": _modal_top() == &"event",
		"global_feedback_is_hidden": _global_feedback_is_hidden(),
	}


func _ground_loot_assertions() -> Dictionary:
	var ground := _first_interactable(&"ground_loot")
	return {
		"room_is_normal": StringName(_status().get("current_room", &"")) == &"Normal",
		"room_floor_count_positive": int(_status().get("room_floor_item_count", 0)) > 0,
		"ground_entity_exists": not ground.is_empty(),
		"context_kind_is_ground_loot": _context_kind() == &"ground_loot",
		"context_has_items": _context_items().size() > 0,
		"global_feedback_is_hidden": _global_feedback_is_hidden(),
	}


func _door_available_assertions() -> Dictionary:
	var runtime_snapshot := _runtime_view_snapshot()
	return {
		"available_projection_exists": not _first_door_with_state(runtime_snapshot, &"available").is_empty(),
		"nearby_door_state_available": StringName(runtime_snapshot.get("nearby_door_state", &"")) == &"available",
		"combat_door_lock_is_false": not bool(runtime_snapshot.get("door_locked", false)),
	}


func _mine_before_assertions() -> Dictionary:
	var detail: Dictionary = _status().get("current_room_detail", {})
	var mine := _first_interactable(&"mine")
	var assertions := {
		"room_is_mine": StringName(_status().get("current_room", &"")) == &"Mine",
		"authority_triggered_is_false": not bool(detail.get("triggered", false)),
		"mine_projection_exists": not mine.is_empty(),
		"mine_visual_is_armed": StringName(mine.get("visual_state", &"")) == &"armed",
		"context_kind_is_mine": _context_kind() == &"mine",
		"mine_feedback_inactive": not bool(_runtime_view_snapshot().get("mine_feedback_active", false)),
	}
	assertions.merge(_mine_player_layer_assertions(false, false), true)
	return assertions


func _mine_after_assertions() -> Dictionary:
	var detail: Dictionary = _status().get("current_room_detail", {})
	var runtime_snapshot := _runtime_view_snapshot()
	var mine := _first_interactable(&"mine")
	var entry: Dictionary = runtime_snapshot.get("room_entry_result", {})
	var assertions := {
		"room_is_mine": StringName(_status().get("current_room", &"")) == &"Mine",
		"authority_triggered_is_true": bool(detail.get("triggered", false)),
		"mine_visual_is_resolved": StringName(mine.get("visual_state", &"")) == &"resolved",
		"entry_is_first_trigger": bool(entry.get("first_trigger", false)),
		"entry_cause_is_mine_triggered": StringName(entry.get("cause", &"")) == &"mine_triggered",
		"mine_feedback_active": bool(runtime_snapshot.get("mine_feedback_active", false)),
	}
	assertions.merge(_mine_player_layer_assertions(true, true), true)
	return assertions


func _mine_departed_assertions() -> Dictionary:
	var detail: Dictionary = _status().get("current_room_detail", {})
	var mine := _first_interactable(&"mine")
	var assertions := {
		"room_is_mine": StringName(_status().get("current_room", &"")) == &"Mine",
		"authority_triggered_stays_true": bool(detail.get("triggered", false)),
		"mine_visual_stays_resolved": StringName(mine.get("visual_state", &"")) == &"resolved",
		"mine_feedback_finished": not bool(_runtime_view_snapshot().get("mine_feedback_active", false)),
		"context_cleared_after_departure": _context_kind() != &"mine",
	}
	assertions.merge(_mine_player_layer_assertions(false, false), true)
	return assertions


func _mine_player_layer_assertions(expect_overlap: bool, expect_burst: bool) -> Dictionary:
	var view = run_scene.get("room_runtime_view")
	var player = run_scene.get("player_controller")
	var room_layer := run_scene.get_node_or_null("RoomLayer") as Node2D
	var player_layer := run_scene.get_node_or_null("PlayerLayer") as Node2D
	var mine_entity = _special_entity_node(&"mine")
	var mine_sprite := (
		mine_entity.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
		if mine_entity != null
		else null
	)
	var player_sprite := player.get_node_or_null("Sprite") as Sprite2D if player != null else null
	var burst := view.get_node_or_null("SpecialRoomFx/MineBurst") as Sprite2D if view != null else null
	var projection := mine_entity.build_snapshot() as Dictionary if mine_entity != null else {}
	var visual_rect := Rect2(projection.get("visual_rect_local", Rect2()))
	var body_rect := Rect2(projection.get("body_rect", Rect2()))
	var displayed_size := mine_sprite.texture.get_size() * mine_sprite.scale if mine_sprite != null and mine_sprite.texture != null else Vector2.ZERO
	var overlaps := (
		_sprite_opaque_rect(mine_sprite).intersects(_sprite_opaque_rect(player_sprite))
		if mine_sprite != null and player_sprite != null
		else false
	)
	return {
		"mine_static_z_is_floor": mine_entity != null and mine_entity.z_index == 0,
		"player_uses_shared_world_z": player != null and player.z_index == 0,
		"room_branch_precedes_player_branch": room_layer != null and player_layer != null and room_layer.get_index() < player_layer.get_index(),
		"floor_and_player_disable_y_sort": room_layer != null and player_layer != null and not room_layer.y_sort_enabled and not player_layer.y_sort_enabled,
		"mine_static_draws_before_player": mine_entity != null and player != null and mine_entity.z_index == player.z_index and room_layer.get_index() < player_layer.get_index(),
		"mine_uses_center_pivot": Vector2(projection.get("pivot_normalized", Vector2.INF)).is_equal_approx(Vector2(0.5, 0.5)),
		"mine_uses_projected_72px_display": displayed_size.is_equal_approx(Vector2(72.0, 72.0)),
		"mine_body_is_inside_visual": visual_rect.encloses(body_rect),
		"mine_player_overlap_matches_fixture": overlaps == expect_overlap,
		"mine_burst_matches_transient_state": burst != null and burst.visible == expect_burst,
		"mine_burst_stays_above_static_and_player": burst != null and burst.get_parent() is CanvasItem and (burst.get_parent() as CanvasItem).z_index > maxi(mine_entity.z_index if mine_entity != null else 0, player.z_index if player != null else 0),
	}


func _special_entity_node(kind: StringName):
	var view = run_scene.get("room_runtime_view")
	if view == null:
		return null
	for entity in (view.get("special_entities") as Dictionary).values():
		if entity != null and StringName(entity.interaction_kind) == kind:
			return entity
	return null


func _sprite_opaque_rect(sprite: Sprite2D) -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2()
	var image := sprite.texture.get_image()
	if image == null:
		return Rect2()
	var used := Rect2(image.get_used_rect())
	var texture_size := sprite.texture.get_size()
	var local_rect := Rect2(used.position - texture_size * 0.5, used.size)
	var transform := sprite.get_global_transform_with_canvas()
	var points := [
		transform * local_rect.position,
		transform * Vector2(local_rect.end.x, local_rect.position.y),
		transform * local_rect.end,
		transform * Vector2(local_rect.position.x, local_rect.end.y),
	]
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for point: Vector2 in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _exit_summary_assertions() -> Dictionary:
	var panel := run_scene.get("extract_panel") as Control
	return {
		"room_is_exit": StringName(_status().get("current_room", &"")) == &"Exit",
		"exit_id_present": String(_status().get("exit_id", "")).strip_edges() != "",
		"exit_projection_exists": not _first_interactable(&"exit").is_empty(),
		"phase_is_confirm_extract": StringName(_status().get("phase", &"")) == &"confirm_extract",
		"extract_summary_visible": panel != null and panel.visible,
		"modal_top_is_extract_confirm": _modal_top() == &"extract_confirm",
	}


func _door_combat_assertions() -> Dictionary:
	var runtime_snapshot := _runtime_view_snapshot()
	return {
		"room_is_monster": StringName(_status().get("current_room", &"")) == &"Monster",
		"combat_active": bool(_combat_snapshot().get("active", false)),
		"door_locked": bool(runtime_snapshot.get("door_locked", false)),
		"combat_restricted_door_exists": not _first_door_with_state(runtime_snapshot, &"combat_restricted").is_empty(),
	}


func _combat_telegraph_assertions() -> Dictionary:
	var combat := _combat_snapshot()
	var warning_count := 0
	var positive_radius_count := 0
	for raw_enemy in combat.get("enemies", []) as Array:
		if raw_enemy is Dictionary:
			var enemy := raw_enemy as Dictionary
			if StringName(enemy.get("state", &"")) == &"warning":
				warning_count += 1
				if float(enemy.get("warning_radius", 0.0)) > 0.0:
					positive_radius_count += 1
	return {
		"combat_active": bool(combat.get("active", false)),
		"warning_enemy_count_positive": warning_count > 0,
		"warning_radius_positive": positive_radius_count > 0,
		"room_view_received_same_combat_tick": int((_runtime_view_snapshot().get("combat", {}) as Dictionary).get("tick", -1)) == int(combat.get("tick", -2)),
	}


func _combat_attack_assertions() -> Dictionary:
	var combat := _combat_snapshot()
	var geometry: Dictionary = combat.get("player_attack_geometry", {})
	var view_geometry: Dictionary = (_runtime_view_snapshot().get("combat", {}) as Dictionary).get("player_attack_geometry", {})
	var visibility_samples: Array = geometry.get("occlusion_samples", [])
	var visible_arc_points: Array = geometry.get("visible_arc_points", [])
	return {
		"combat_active": bool(combat.get("active", false)),
		"attack_geometry_visible": bool(geometry.get("visible", false)),
		"attack_geometry_shape_sector": StringName(geometry.get("shape", &"")) == &"sector",
		"attack_geometry_range_positive": float(geometry.get("range", 0.0)) > 0.0,
		"attack_geometry_visual_contract_clipped": StringName(geometry.get("visual_contract", &"")) == &"occlusion_clipped_sector_v1",
		"attack_geometry_uses_arena_contract": StringName(geometry.get("occlusion_contract", &"")) == StringName(combat.get("arena_contract", &"")),
		"attack_geometry_occluded_by_altar": bool(geometry.get("occluded", false)) and int(geometry.get("occluded_sample_count", 0)) > 0,
		"attack_geometry_visibility_points_complete": not visibility_samples.is_empty() and visible_arc_points.size() == visibility_samples.size(),
		"room_view_received_visible_geometry": bool(view_geometry.get("visible", false)),
		"room_view_received_same_visibility_points": view_geometry.get("visible_arc_points", []) == visible_arc_points,
		"room_view_received_same_occlusion_contract": view_geometry.get("occlusion_contract", &"") == geometry.get("occlusion_contract", &""),
		"no_fabricated_debug_overlay": true,
	}


func _snapshot_summary() -> Dictionary:
	var status := _status()
	var runtime_snapshot := _runtime_view_snapshot()
	var combat := _combat_snapshot()
	var enemies: Array[Dictionary] = []
	for raw_enemy in combat.get("enemies", []) as Array:
		if raw_enemy is Dictionary:
			var enemy := raw_enemy as Dictionary
			enemies.append({
				"enemy_id": String(enemy.get("enemy_id", "")),
				"monster_type": String(enemy.get("monster_type", &"")),
				"state": String(enemy.get("state", &"")),
				"hp": int(enemy.get("hp", 0)),
				"warning_radius": float(enemy.get("warning_radius", 0.0)),
			})
	var doors: Array[Dictionary] = []
	for raw_door in runtime_snapshot.get("doors", []) as Array:
		if raw_door is Dictionary:
			var door := raw_door as Dictionary
			doors.append({
				"orientation": String(door.get("orientation", &"")),
				"visual_state": String(door.get("visual_state", &"")),
			})
	var attack: Dictionary = combat.get("player_attack_geometry", {})
	return {
		"screen_state": String(run_scene.get("screen_state")),
		"position": _vector2i_array(Vector2i(status.get("position", Vector2i(-1, -1)))),
		"room_type": String(status.get("current_room", &"Unknown")),
		"phase": String(status.get("phase", &"")),
		"hp": int(status.get("hp", 0)),
		"pressure": int(status.get("pressure", 0)),
		"adjacent_mines": int(status.get("adjacent_mines", 0)),
		"room_floor_item_count": int(status.get("room_floor_item_count", 0)),
		"inventory_item_count": (status.get("inventory_items", []) as Array).size(),
		"context_kind": String(_context_kind()),
		"context_item_count": _context_items().size(),
		"modal_top": String(_modal_top()),
		"doors": doors,
		"door_locked": bool(runtime_snapshot.get("door_locked", false)),
		"mine_feedback_active": bool(runtime_snapshot.get("mine_feedback_active", false)),
		"combat": {
			"active": bool(combat.get("active", false)),
			"tick": int(combat.get("tick", -1)),
			"seed": int(combat.get("seed", 0)),
			"enemy_count": enemies.size(),
			"enemies": enemies,
			"player_attack_geometry": {
				"visible": bool(attack.get("visible", false)),
				"phase": String(attack.get("phase", &"")),
				"shape": String(attack.get("shape", &"")),
				"range": float(attack.get("range", 0.0)),
				"visual_contract": String(attack.get("visual_contract", &"")),
				"occlusion_contract": String(attack.get("occlusion_contract", &"")),
				"occluded": bool(attack.get("occluded", false)),
				"occluded_sample_count": int(attack.get("occluded_sample_count", 0)),
				"visible_arc_point_count": (attack.get("visible_arc_points", []) as Array).size(),
			},
		},
	}


func _finish() -> void:
	var expected_complete := cases.size() == EXPECTED_CASES.size()
	if not expected_complete and failures.is_empty():
		failures.append(
			"gallery emitted %d/%d required cases" % [cases.size(), EXPECTED_CASES.size()]
		)
	var status := "PASS_WITH_VISUAL_REVIEW_REQUIRED" if failures.is_empty() else "FAIL"
	var manifest := {
		"schema_version": 1,
		"suite_id": "I3R_production_state_gallery",
		"status": status,
		"visual_acceptance": "NOT_RUN",
		"visual_acceptance_notice": "All PNGs require human review. This manifest never upgrades rendering to visual acceptance.",
		"production_scene_path": PRODUCTION_MAIN_SCENE,
		"production_main_instances": main_instance_count,
		"fixed_seed": FIXED_SEED,
		"expected_spawn": _vector2i_array(EXPECTED_SPAWN),
		"expected_cases": EXPECTED_CASES,
		"generated_case_count": cases.size(),
		"expected_case_count": EXPECTED_CASES.size(),
		"cases_complete": expected_complete,
		"interactive_combat": interactive_combat,
		"interactive_input_transport": "production InputMap through RunScene" if interactive_combat else "not_requested",
		"interactive_notice": "After automatic evidence capture the same production combat remains open until the user closes the window." if interactive_combat else "",
		"legacy_art24_hand_drawn_preview_instantiated": false,
		"legacy_preview_paths_forbidden_as_evidence": [
			"res://scripts/presentation/art24/art24_in_run_preview.gd",
			"res://tests/art24_in_run_art_preview_runner.gd",
		],
		"combat_geometry_source": "G41CombatSimulation snapshot -> G41RoomRuntimeView production draw",
		"combat_debug_geometry_switch": "not_required; no safe debug overlay is used or fabricated",
		"player_journey_claim": false,
		"player_journey_notice": "Authority fixtures and direct production player positioning are labelled per case; this gallery is not a genuine-input journey.",
		"setup_trace": setup_trace,
		"global_failure_criteria": GLOBAL_FAILURE_CRITERIA,
		"failures": failures,
		"cases": cases,
		"output_dir": output_dir,
		"duration_msec_at_manifest": Time.get_ticks_msec() - started_msec,
		"generated_utc": Time.get_datetime_string_from_system(true, true),
	}
	if not _write_json(manifest_path, manifest):
		failures.append("could not write total manifest")
		status = "FAIL"
	if status == "FAIL":
		for failure in failures:
			push_error("I3R state gallery failure: " + failure)
		print(
			"%s failures=%d cases=%d manifest=%s"
			% [FAIL_MARKER, failures.size(), cases.size(), manifest_path]
		)
		_dispose_main()
		_schedule_quit(2)
		return

	print(
		"%s status=%s cases=%d main_instances=%d seed=%d manifest=%s interactive=%s"
		% [
			PASS_MARKER,
			status,
			cases.size(),
			main_instance_count,
			FIXED_SEED,
			manifest_path,
			str(interactive_combat).to_lower(),
		]
	)
	if interactive_combat:
		root.title = "I3R interactive combat - production input active - close window to exit"
		print(
			"%s seed=%d room=%s input=production_InputMap close_window_to_exit=true"
			% [READY_MARKER, FIXED_SEED, str(_status().get("position", Vector2i.ZERO))]
		)
		return
	_dispose_main()
	_schedule_quit(0)


func _status() -> Dictionary:
	var context = run_scene.get("run_context") if run_scene != null else null
	return context.get_status_snapshot() if context != null else {}


func _runtime_view_snapshot() -> Dictionary:
	var view = run_scene.get("room_runtime_view") if run_scene != null else null
	return view.build_read_only_snapshot() if view != null else {}


func _combat_snapshot() -> Dictionary:
	var runtime = run_scene.get("in_run_runtime") if run_scene != null else null
	return runtime.build_read_only_snapshot() if runtime != null else {}


func _first_interactable(kind: StringName) -> Dictionary:
	for raw in _runtime_view_snapshot().get("interactables", []) as Array:
		if raw is Dictionary:
			var interactable := raw as Dictionary
			if StringName(interactable.get("interaction_kind", &"")) == kind:
				return interactable
	return {}


func _first_door_with_state(runtime_snapshot: Dictionary, state: StringName) -> Dictionary:
	for raw in runtime_snapshot.get("doors", []) as Array:
		if raw is Dictionary:
			var door := raw as Dictionary
			if StringName(door.get("visual_state", &"")) == state:
				return door
	return {}


func _context_popup():
	var view = run_scene.get("room_runtime_view") if run_scene != null else null
	return view.get("context_popup") if view != null else null


func _context_kind() -> StringName:
	var popup = _context_popup()
	return StringName(popup.get("context_kind")) if popup != null and bool(popup.get("visible")) else &"none"


func _context_opened_once() -> bool:
	var popup = _context_popup()
	var context: Dictionary = popup.get("current_context") if popup != null else {}
	return bool(context.get("opened_once", false))


func _context_items() -> Array:
	var popup = _context_popup()
	return (popup.get("context_items") as Array).duplicate(true) if popup != null else []


func _global_feedback_is_hidden() -> bool:
	var surface = run_scene.get("run_surface") if run_scene != null else null
	var label = surface.get("command_feedback_label") if surface != null else null
	var frame = surface.get("command_feedback_art") if surface != null else null
	return (
		(label == null or not bool(label.visible))
		and (frame == null or not bool(frame.visible))
	)


func _modal_depth() -> int:
	var stack = run_scene.get("modal_controller") if run_scene != null else null
	return int(stack.depth()) if stack != null else 0


func _modal_top() -> StringName:
	var stack = run_scene.get("modal_controller") if run_scene != null else null
	return StringName(stack.top_modal_id()) if stack != null and stack.depth() > 0 else &"none"


func _all_assertions_pass(assertions: Dictionary) -> bool:
	for key in assertions:
		if not bool(assertions[key]):
			return false
	return true


func _wait_until(predicate: Callable, timeout_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await create_timer(0.016).timeout
	return bool(predicate.call())


func _frames(count: int) -> void:
	for _index in range(maxi(0, count)):
		await process_frame


func _write_json(path: String, value: Variant) -> bool:
	var directory_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if directory_error != OK:
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_json_safe(value), "\t") + "\n")
	file.close()
	return FileAccess.file_exists(path)


func _write_text(path: String, value: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(value)
	file.close()
	return FileAccess.file_exists(path)


func _json_safe(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value:
			result[String(key)] = _json_safe(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_json_safe(item))
		return result
	if value is Vector2i:
		return _vector2i_array(value)
	if value is Vector2:
		return [value.x, value.y]
	if value is Rect2:
		return {
			"position": [value.position.x, value.position.y],
			"size": [value.size.x, value.size.y],
		}
	if value is StringName:
		return String(value)
	return value


func _vector2i_array(value: Vector2i) -> Array[int]:
	return [value.x, value.y]


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for raw in arguments:
		var argument := String(raw)
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var separator := argument.find("=")
		result[argument.substr(2, separator - 2)] = argument.substr(separator + 1)
	return result


func _parse_bool(value: String) -> bool:
	return value.to_lower() in ["1", "true", "yes", "on"]


func _absolute_path(argument: String) -> String:
	if argument.is_empty():
		return ""
	return argument if argument.is_absolute_path() else ProjectSettings.globalize_path(argument)


func _fail_setup(message: String) -> void:
	if not failures.has(message):
		failures.append(message)


func _dispose_main() -> void:
	if main != null and is_instance_valid(main):
		main.free()
	main = null
	run_scene = null


func _schedule_quit(exit_code: int) -> void:
	if quit_scheduled:
		return
	quit_scheduled = true
	call_deferred("_quit_after_cleanup", exit_code)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	await process_frame
	quit(exit_code)
