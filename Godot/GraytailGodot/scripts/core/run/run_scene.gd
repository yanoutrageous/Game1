extends Node2D

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const HUDScene := preload("res://scenes/ui/hud/hud.tscn")
const MiniMapScene := preload("res://scenes/ui/minimap/minimap_panel.tscn")
const ResultPanelScene := preload("res://scenes/ui/result/result_panel.tscn")
const MapOverlayScene := preload("res://scenes/ui/map_overlay/map_overlay_panel.tscn")
const TutorialPopupScene := preload("res://scenes/ui/tutorial/tutorial_popup_panel.tscn")
const RoomScene := preload("res://scenes/room/room_scene.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const G9ShellPanelScript := preload("res://scripts/ui/shell/g9_shell_panel.gd")
const AppShellScript := preload("res://scripts/ui/app_shell/app_shell.gd")
const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const PageRouterScript := preload("res://scripts/ui/app_shell/page_router.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const GroundLootPanelScript := preload("res://scripts/ui/ground_loot/ground_loot_panel.gd")
const LootResultPanelScript := preload("res://scripts/ui/loot_result/loot_result_panel.gd")
const DevDiagnosticsPanelScript := preload("res://scripts/ui/dev/dev_diagnostics_panel.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const G10ArtSmokeRegistry := preload("res://scripts/presentation/g10_art_smoke_registry.gd")
const RunSurfaceScript := preload("res://scripts/ui/run_surface/run_surface.gd")
const RunSurfaceModel := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const RuntimeModalLayoutModelScript := preload("res://scripts/ui/run_surface/runtime_modal_layout_model.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const SaveManagerScript := preload("res://scripts/core/save/save_manager.gd")
const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")
const Art21R2RunSmokeSeederScript := preload("res://scripts/core/run/art21r2_run_smoke_seeder.gd")
const RunSceneDebugPanelControllerScript := preload("res://scripts/core/run/run_scene_debug_panel_controller.gd")
const RunSceneUIBridgeScript := preload("res://scripts/core/run/run_scene_ui_bridge.gd")
const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")
const RunSceneInputRouterScript := preload("res://scripts/core/run/run_scene_input_router.gd")
const RunSceneRouteControllerScript := preload("res://scripts/core/run/run_scene_route_controller.gd")
const RunSceneCommandFeedbackScript := preload("res://scripts/core/run/run_scene_command_feedback.gd")
const RunSceneResultControllerScript := preload("res://scripts/core/run/run_scene_result_controller.gd")
const RunSceneResponsibilityBudgetScript := preload("res://scripts/core/run/run_scene_responsibility_budget.gd")
const RunSceneRefreshControllerScript := preload("res://scripts/core/run/run_scene_refresh_controller.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const PlayerAppearanceConfigScript := preload("res://scripts/core/content/player_appearance_config.gd")
const RunSceneModalControllerScript := preload("res://scripts/core/run/run_scene_modal_controller.gd")
const SettingsPanelScript := preload("res://scripts/ui/settings/settings_panel.gd")
const G41RoomRuntimeViewScript := preload("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
const G41RuntimeLayoutScript := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")
const Art25GameplayBackdropScript := preload("res://scripts/presentation/art25_gameplay_backdrop.gd")
const RuntimeTextureCacheScript := preload("res://scripts/presentation/runtime_texture_cache.gd")
const Art24RuntimeAnimationCatalogScript := preload("res://scripts/presentation/art24/art24_runtime_animation_catalog.gd")
const Art24EnemyVisualCatalogScript := preload("res://scripts/presentation/art24/art24_enemy_visual_catalog.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")
const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")
const PlayerFeedbackServiceScript := preload("res://scripts/presentation/player_feedback_service.gd")

const SCREEN_MAIN_MENU := &"main_menu"
const SCREEN_DEPLOY := &"deploy_shell"
const SCREEN_LONG_TERM := &"long_term_shell"
const SCREEN_SETTINGS := &"settings_shell"
const SCREEN_RUN := &"run"
const COMBAT_FLEE_EDGE_DISTANCE := 0.15
const COMBAT_FLEE_DOOR_ALIGN_HALF := 0.18
const COMBAT_FACING_LOCK_STATES := [&"attack_windup", &"attack_active", &"attack_recovery"]
const TRANSITION_REJECTION_COOLDOWN_SECONDS := 0.35
const TRANSITION_REJECTION_RELEASE_THRESHOLD := 0.20

const G9_UI_NODE_VALIDATION_MARKERS := [
	"MainMenuPanel",
	"ModeEntryPanel",
	"DeployShellPanel",
	"DeployShellTabs",
	"StartStandard10x10Button",
	"LongTermSystemPanel",
	"InventoryPanel",
	"GroundLootPanel",
	"ResultPanel",
	"RunOverlayRoot",
	"LeftSidebar",
	"RightUtilityRail",
	"ProtocolStatusPanel",
	"BottomActionBar",
	"BottomActionBarButtons",
	"DebugToggleButton",
	"EventOptionPanel",
	"LootResultPanel",
	"ExtractConfirmPanel",
]

var run_context: RunContext
var command_bus: CommandBus
var runtime_controller
var in_run_runtime
var meta_progress_adapter: MetaProgressAdapter
var save_manager
var ui_root: Control
var ui_shell: Control
var main_menu_panel: Control
var deploy_shell_panel: Control
var long_term_shell_panel: Control
var run_overlay_root: Control
var run_surface
var room_badge: Label
var protocol_badge: Label
var command_result_label: Label
var debug_panel: PanelContainer
var debug_content: VBoxContainer
var debug_scroll: ScrollContainer
var debug_x_spin: SpinBox
var debug_y_spin: SpinBox
var debug_toggle_button: Button
var debug_log: Label
var layout_profile_label: Label
var pause_panel: PanelContainer
var pause_status_label: Label
var runtime_modal_input_shield: ColorRect
var pause_continue_button: Button
var pause_settings_button: Button
var pause_abandon_button: Button
var runtime_settings_panel: Control
var abandon_confirm_panel: PanelContainer
var abandon_confirm_cancel_button: Button
var abandon_confirm_button: Button
var dev_diagnostics_panel: Control
var event_panel: PanelContainer
var event_title_label: Label
var event_body_label: Label
var event_options_box: VBoxContainer
var loot_panel: Control
var extract_panel: PanelContainer
var extract_title_label: Label
var extract_body_label: Label
var extract_items_scroll: ScrollContainer
var extract_items_box: VBoxContainer
var extract_confirm_button: Button
var extract_cancel_button: Button
var inventory_panel: Control
var ground_loot_panel: Control
var hud: Hud
var minimap_panel: MiniMapPanel
var result_panel: ResultPanel
var map_overlay_panel: MapOverlayPanel
var tutorial_popup_panel: TutorialPopupPanel
var room_controller: RoomSceneController
var player_controller: PlayerController
var room_runtime_view
var gameplay_backdrop: Art25GameplayBackdrop
var screen_state: StringName = SCREEN_MAIN_MENU
var current_layout_profile_id: StringName = &"desktop"
var last_command_result: Dictionary = {}
var m1_debug_panel_enabled: bool = false
var pause_exit_confirm_pending: bool = false
var modal_controller
var debug_panel_controller
var abandon_dispatch_in_flight: bool = false
var refresh_controller
var last_combat_texture_prewarm_report: Dictionary = {}
var last_combat_texture_preflight_report: Dictionary = {}
var combat_texture_prewarm_degraded: bool = false
var extract_modal_mode: StringName = &"extract"
var pending_combat_flee_direction := Vector2i.ZERO
var pending_exit_interaction_id := ""
var pending_exit_interaction_position := Vector2.ZERO
var pending_exit_interaction_authorized := false
var player_feedback_service
var _processed_combat_feedback_events: Dictionary = {}
var _ui_scale_factor := 1.0
var _transition_rejection_direction := Vector2i.ZERO
var _transition_rejection_cooldown_remaining := 0.0
var _transition_rejection_awaiting_release := false


func _ready() -> void:
	_ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	m1_debug_panel_enabled = DebugGateScript.is_debug_tools_enabled()
	player_feedback_service = PlayerFeedbackServiceScript.new()
	player_feedback_service.name = "PlayerFeedbackService"
	add_child(player_feedback_service)
	var feedback_settings_manager := get_node_or_null("/root/SettingsManager")
	if feedback_settings_manager != null:
		player_feedback_service.bind_settings_manager(feedback_settings_manager)
	modal_controller = RunSceneModalControllerScript.new()
	debug_panel_controller = RunSceneDebugPanelControllerScript.new()
	refresh_controller = RunSceneRefreshControllerScript.new()
	save_manager = SaveManagerScript.new()
	save_manager.load_manifest()
	meta_progress_adapter = MetaProgressAdapterScript.new()
	save_manager.configure_meta_adapter(meta_progress_adapter)
	runtime_controller = RunRuntimeControllerScript.new()
	runtime_controller.bind_meta_progress_adapter(meta_progress_adapter)
	run_context = runtime_controller.context
	command_bus = runtime_controller.command_bus
	in_run_runtime = runtime_controller.in_run_runtime
	command_bus.state_changed.connect(_on_state_changed)
	command_bus.result_available.connect(_on_result_available)
	_build_playfield_visuals()
	_build_accessible_ui()
	debug_panel_controller.bind_targets(
		m1_debug_panel_enabled,
		run_context,
		meta_progress_adapter,
		save_manager,
		command_bus,
		player_controller,
		run_overlay_root,
		debug_panel,
		debug_x_spin,
		debug_y_spin,
		debug_log,
		ui_shell,
		Callable(self, "_dispatch_command"),
		Callable(self, "_show_command_feedback"),
		Callable(self, "_shell_snapshot"),
		Callable(self, "_show_loot_panel"),
		Callable(self, "_runtime_modal_is_top"),
		Callable(self, "_pop_runtime_modal"),
		func() -> void: get_viewport().gui_release_focus(),
		Callable(self, "_show_pause_panel")
	)
	_bind_runtime_modal_controller()
	refresh_controller.bind_targets(
		run_context,
		in_run_runtime,
		run_surface,
		hud,
		Callable(self, "_build_hud_view_model"),
		dev_diagnostics_panel,
		debug_log,
		Callable(self, "_shell_snapshot"),
		Callable(self, "_apply_dev_diagnostics")
	)
	_show_main_menu()


func set_ui_scale_factor(value: float) -> bool:
	_ui_scale_factor = Art10UISkinKitScript.set_runtime_ui_scale_factor(value)
	_apply_ui_scale_to_runtime_controls(true)
	if run_context != null and refresh_controller != null:
		_refresh_view_models()
	return is_equal_approx(_ui_scale_factor, Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value))


func get_ui_scale_factor() -> float:
	return _ui_scale_factor


func _apply_ui_scale_to_runtime_controls(sync_shell: bool) -> void:
	var targets: Array[Node] = [run_surface, tutorial_popup_panel, map_overlay_panel, result_panel, inventory_panel, ground_loot_panel, loot_panel, runtime_settings_panel]
	if sync_shell:
		targets.push_front(ui_shell)
	for target in targets:
		if target != null and target.has_method("set_ui_scale_factor"):
			target.call("set_ui_scale_factor", _ui_scale_factor)


func _on_app_shell_ui_scale_changed(value: float) -> void:
	_ui_scale_factor = Art10UISkinKitScript.set_runtime_ui_scale_factor(value)
	_apply_ui_scale_to_runtime_controls(false)
	if run_context != null and refresh_controller != null:
		_refresh_view_models()


func _process(delta: float) -> void:
	if screen_state != SCREEN_RUN:
		return
	if player_controller == null or command_bus == null or run_context == null:
		return
	var runtime_paused := _is_runtime_modal_open() or (map_overlay_panel != null and map_overlay_panel.visible) or run_context.has_blocking_tutorial_popup()
	_sync_player_input_enabled()
	if room_runtime_view != null:
		room_runtime_view.set_context_ui_suppressed(runtime_paused)
	if in_run_runtime != null:
		in_run_runtime.sync_room(player_controller.get_local_position())
		in_run_runtime.set_paused(runtime_paused)
	if runtime_paused:
		if room_runtime_view != null:
			room_runtime_view.advance(0.0, player_controller.get_local_position(), in_run_runtime.build_read_only_snapshot() if in_run_runtime != null else {})
		return
	var move_vector := player_controller.get_move_vector()
	_advance_transition_rejection_debounce(delta, move_vector)
	if in_run_runtime != null and in_run_runtime.has_active_combat():
		var combat_aim := move_vector if move_vector.length_squared() > 0.0001 else player_controller.get_facing_vector()
		var combat_snapshot: Dictionary = in_run_runtime.advance_frame(delta, move_vector, combat_aim)
		_route_combat_domain_feedback(combat_snapshot)
		if run_surface != null and run_surface.has_method("apply_combat_attack_state"):
			run_surface.call("apply_combat_attack_state", combat_snapshot.get("attack_input", {}))
		player_controller.set_local_position(in_run_runtime.get_player_local_position(player_controller.get_local_position()))
		var combat_player: Dictionary = combat_snapshot.get("player", {})
		var combat_player_state := StringName(combat_player.get("state", &"idle"))
		player_controller.sync_authoritative_combat_facing(
			Vector2(combat_player.get("facing", combat_aim)),
			combat_player_state in COMBAT_FACING_LOCK_STATES
		)
		player_controller.set_runtime_visual_state(combat_player_state)
		if room_runtime_view != null:
			room_runtime_view.advance(delta, player_controller.get_local_position(), combat_snapshot)
		var combat_transition := player_controller.requested_transition(move_vector)
		if combat_transition != Vector2i.ZERO:
			_attempt_room_transition(combat_transition)
		return
	if run_surface != null and run_surface.has_method("apply_combat_attack_state"):
		run_surface.call("apply_combat_attack_state", {})
	player_controller.release_authoritative_combat_facing()
	var local_result := player_controller.move_local(move_vector, delta)
	if StringName(local_result.get("status", &"")) == &"transition":
		_attempt_room_transition(local_result.get("direction", Vector2i.ZERO))
	if room_runtime_view != null:
		room_runtime_view.advance(delta, player_controller.get_local_position(), in_run_runtime.build_read_only_snapshot() if in_run_runtime != null else {})


func _input(event: InputEvent) -> void:
	if RuntimeInputProfileScript.observe_input_event(event):
		call_deferred("_refresh_input_device_hints")
	if player_feedback_service != null and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		player_feedback_service.set_active_joypad_device(event.device)
	if _handle_cancel_input(event):
		get_viewport().set_input_as_handled()
		return


func _refresh_input_device_hints() -> void:
	if run_context != null and refresh_controller != null:
		_refresh_view_models()
	if get_tree() != null:
		get_tree().call_group(
			RuntimeInputProfileScript.HINT_CONSUMER_GROUP,
			&"refresh_input_hints"
		)


func _unhandled_input(event: InputEvent) -> void:
	if _handle_cancel_input(event):
		get_viewport().set_input_as_handled()
		return
	# Gameplay actions run only after Controls have had the chance to consume
	# their keyboard, pointer, or gamepad activation. This prevents a focused
	# button from also interacting with the world underneath it.
	if _handle_run_action_input(event):
		get_viewport().set_input_as_handled()
		return


func _handle_cancel_input(event: InputEvent) -> bool:
	if RunSceneInputRouterScript.cancel_action(event) != RunSceneInputRouterScript.ACTION_CANCEL:
		return false
	# A blocking tutorial prompt owns the current input context. Escape/Back
	# must not open another modal above the teaching decision.
	if screen_state == SCREEN_RUN and run_context != null and run_context.has_blocking_tutorial_popup():
		return true
	if _close_top_runtime_modal():
		return true
	if ui_shell != null and ui_shell.visible and ui_shell.has_method("handle_cancel_event"):
		if bool(ui_shell.call("handle_cancel_event", event)):
			return true
	if screen_state in [SCREEN_DEPLOY, SCREEN_LONG_TERM, SCREEN_SETTINGS]:
		_show_main_menu()
		return true
	if screen_state == SCREEN_RUN:
		_show_pause_panel()
		return true
	return false


func _handle_run_action_input(event: InputEvent) -> bool:
	if screen_state != SCREEN_RUN or run_context == null:
		return false
	if run_context.has_blocking_tutorial_popup():
		return false
	var run_action := RunSceneInputRouterScript.run_action(event)
	# Q is a reversible field-bag drawer. Handle its close action before the
	# generic modal guard, otherwise the open panel consumes the state that would
	# allow the same shortcut to close it again.
	if inventory_panel != null and inventory_panel.visible and run_action == RunSceneInputRouterScript.ACTION_OPEN_INVENTORY:
		_close_inventory_modal()
		return true
	# The expanded map is the one deliberate read-only child of the inventory
	# drawer. Keep the real M shortcut reachable while the drawer owns focus;
	# every other run action remains blocked by the modal guard below.
	if _runtime_modal_is_top(&"inventory") and run_action == RunSceneInputRouterScript.ACTION_OPEN_MAP:
		_open_map_from_ui(&"keyboard")
		return true
	if _is_runtime_modal_open():
		return false
	if map_overlay_panel != null and map_overlay_panel.visible:
		return false
	var step_direction := _direction_from_input_event(event)
	if step_direction != Vector2.ZERO and player_controller != null:
		player_controller.play_step(step_direction)
		return true

	match run_action:
		RunSceneInputRouterScript.ACTION_INTERACT:
			_handle_interact_pressed()
			return true
		RunSceneInputRouterScript.ACTION_FIGHT:
			if event is InputEventMouseButton:
				if in_run_runtime == null or not in_run_runtime.has_active_combat():
					return false
				if not _pointer_targets_playfield(event as InputEventMouseButton):
					return false
				_fight_and_show_result(_pointer_attack_aim(event as InputEventMouseButton))
			else:
				_fight_and_show_result()
			return true
		RunSceneInputRouterScript.ACTION_FLAG_CURRENT:
			_dispatch_command(&"flag_current_cell")
			return true
		RunSceneInputRouterScript.ACTION_OPEN_INVENTORY:
			_show_inventory_panel()
			return true
		RunSceneInputRouterScript.ACTION_OPEN_GROUND_LOOT:
			_activate_world_context_primary()
			return true
		RunSceneInputRouterScript.ACTION_REQUEST_EXTRACT:
			_request_extract_from_ui()
			return true
		RunSceneInputRouterScript.ACTION_OPEN_MAP:
			_open_map_from_ui(&"keyboard")
			return true
		RunSceneInputRouterScript.ACTION_DEBUG_RESTART_RUN:
			_debug_restart_run_from_ui()
			return true
		_:
			return false


func _is_primary_pointer_attack(event: InputEvent) -> bool:
	return (
		event is InputEventMouseButton
		and RuntimeInputProfileScript.event_pressed(event, RuntimeInputProfileScript.ACTION_ATTACK)
	)


func _pointer_targets_playfield(event: InputEventMouseButton) -> bool:
	if room_runtime_view == null:
		return false
	var world_context_popup := room_runtime_view.get("context_popup") as Control
	if (
		world_context_popup != null
		and world_context_popup.visible
		and world_context_popup.get_global_rect().has_point(event.position)
	):
		return false
	if run_surface != null and run_surface.has_method("blocks_world_pointer"):
		if bool(run_surface.call("blocks_world_pointer", event.position)):
			return false
	if tutorial_popup_panel != null and tutorial_popup_panel.has_method("blocks_world_pointer"):
		if bool(tutorial_popup_panel.call("blocks_world_pointer", event.position)):
			return false
	var room_local: Vector2 = room_runtime_view.to_local(event.position)
	return G41RuntimeLayoutScript.ROOM_RECT.has_point(room_local)


func _pointer_attack_aim(event: InputEventMouseButton) -> Vector2:
	if room_runtime_view == null or player_controller == null:
		return Vector2.ZERO
	var pointer_local: Vector2 = room_runtime_view.to_local(event.position)
	var player_local: Vector2 = room_runtime_view.to_local(player_controller.global_position)
	var aim: Vector2 = pointer_local - player_local
	if aim.length_squared() > 0.0001:
		return aim.normalized()
	return player_controller.get_facing_vector()


func _direction_from_input_event(event: InputEvent) -> Vector2:
	return RunSceneInputRouterScript.movement_direction(event)


# Characterization runners may still call the historical helper name. It is an
# alias only; the implementation remains InputMap-owned.
func _direction_from_key_event(event: InputEvent) -> Vector2:
	return _direction_from_input_event(event)


func _build_playfield_visuals() -> void:
	var room_layer := get_node("RoomLayer") as Node2D
	var player_layer := get_node("PlayerLayer") as Node2D
	gameplay_backdrop = Art25GameplayBackdropScript.new() as Art25GameplayBackdrop
	add_child(gameplay_backdrop)
	room_controller = RoomScene.instantiate() as RoomSceneController
	room_controller.name = "RoomSceneController"
	room_layer.add_child(room_controller)
	room_runtime_view = G41RoomRuntimeViewScript.new()
	room_runtime_view.name = "G41RoomRuntimeView"
	room_runtime_view.context_action_requested.connect(_on_world_context_action_requested)
	room_layer.add_child(room_runtime_view)
	player_controller = PlayerScene.instantiate() as PlayerController
	player_controller.name = "PlayerController"
	player_layer.add_child(player_controller)
	_suppress_runtime_scene_labels()


func _build_accessible_ui() -> void:
	var ui_layer := get_node("UILayer") as CanvasLayer
	ui_root = Control.new()
	ui_root.name = "G9FinalUIRoot"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Structural UI roots must never consume an otherwise unobstructed
	# playfield click. Interactive descendants keep their own STOP/PASS filters.
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Art10UISkinKitScript.apply_player_ui_theme(ui_root)
	ui_layer.add_child(ui_root)
	_build_shell_pages()
	_build_run_overlay()
	_build_runtime_modals()
	_apply_ui_scale_to_runtime_controls(false)


func _build_shell_pages() -> void:
	ui_shell = AppShellScript.new() as Control
	ui_shell.name = "AppShell"
	ui_root.add_child(ui_shell)
	ui_shell.call("build")
	ui_shell.connect("host_route_requested", _on_app_shell_host_route_requested)
	ui_shell.connect("page_changed", _on_app_shell_page_changed)
	ui_shell.connect("meta_action_requested", _on_m7_meta_action_requested)
	ui_shell.connect("ui_scale_changed", _on_app_shell_ui_scale_changed)
	main_menu_panel = ui_shell.call("get_main_page") as Control
	deploy_shell_panel = ui_shell.call("get_deploy_page") as Control
	long_term_shell_panel = ui_shell.call("get_long_term_page") as Control


func _build_run_overlay() -> void:
	run_overlay_root = Control.new()
	run_overlay_root.name = "RunOverlayRoot"
	run_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	run_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(run_overlay_root)

	run_surface = RunSurfaceScript.new()
	run_surface.name = "RunSurface"
	run_surface.build()
	run_surface.interact_requested.connect(_handle_interact_pressed)
	run_surface.inventory_requested.connect(_show_inventory_panel)
	run_surface.ground_loot_requested.connect(_activate_world_context_primary)
	run_surface.map_requested.connect(_open_map_from_ui)
	run_surface.combat_requested.connect(_fight_and_show_result)
	run_surface.extract_requested.connect(_request_extract_from_ui)
	run_surface.pause_requested.connect(_show_pause_panel)
	run_surface.encounter_option_selected.connect(_on_encounter_option_selected)
	run_overlay_root.add_child(run_surface)

	hud = run_surface.get_hud()
	minimap_panel = run_surface.get_minimap_panel()
	var surface_overlay_slot: Control = run_surface.get_overlay_slot()
	# The nearby-loot/chest panel tracks world anchors, but it is an interactive
	# UI surface.  Hosting it in the overlay slot keeps mouse input above the
	# full-screen HUD without replacing the runtime view that owns its state.
	room_runtime_view.attach_context_popup(surface_overlay_slot)

	debug_toggle_button = _add_button(run_overlay_root, "DebugToggleButton", Rect2(1010, 226, 170, 34), "诊断", func() -> void: _toggle_debug_panel())
	debug_toggle_button.visible = false
	debug_toggle_button.disabled = not m1_debug_panel_enabled
	debug_toggle_button.tooltip_text = "m1_debug_panel=true; dev/test-only cheat panel"
	var debug_view := RunSceneDebugPanelControllerScript.build_panel_view(
		run_overlay_root,
		func() -> void: debug_panel_controller.close_panel()
	)
	debug_panel = debug_view.get("panel") as PanelContainer
	debug_content = debug_view.get("content") as VBoxContainer
	debug_scroll = debug_view.get("scroll") as ScrollContainer
	debug_x_spin = debug_view.get("x_spin") as SpinBox
	debug_y_spin = debug_view.get("y_spin") as SpinBox
	debug_log = debug_view.get("log") as Label
	RunSceneDebugPanelControllerScript.add_section(debug_content, "只读状态 · 不污染")
	RunSceneDebugPanelControllerScript.add_button(debug_content, "刷新状态摘要", func() -> void: debug_panel_controller.meta_summary(), false)
	RunSceneDebugPanelControllerScript.add_button(debug_content, "捕获失败证据包", func() -> void: debug_panel_controller.capture_failure_bundle(), false)
	RunSceneDebugPanelControllerScript.add_section(debug_content, "局内写命令 · 标记 TAINTED")
	RunSceneDebugPanelControllerScript.add_button(debug_content, "重新开始标准测试局", func() -> void: _start_standard_from_ui())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "传送到撤离点", func() -> void: debug_panel_controller.teleport_to_exit())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "传送到最近宝箱房", func() -> void: _debug_teleport_to_room_type(&"Chest"))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "传送到最近事件房", func() -> void: _debug_teleport_to_room_type(&"Event"))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "传送到最近战斗房", func() -> void: _debug_teleport_to_room_type(&"Monster"))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "传送到最近雷区房", func() -> void: _debug_teleport_to_room_type(&"Mine"))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "移动到坐标（不触发）", func() -> void: debug_panel_controller.teleport_xy(false))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "进入坐标并触发", func() -> void: debug_panel_controller.teleport_xy(true))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "局内黑币 +100", func() -> void: _dispatch_command(&"debug_add_run_black_coin", {"amount": 100, "source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "揭示完整地图", func() -> void: _dispatch_command(&"debug_reveal_full_map", {"source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "生成地面测试物品", func() -> void: _dispatch_command(&"debug_spawn_test_item_floor", {"source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "生成背包测试物品", func() -> void: _dispatch_command(&"debug_spawn_test_item_backpack", {"source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "恢复全部生命", func() -> void: _dispatch_command(&"debug_heal_full", {"source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "切换减弱动态效果", func() -> void: debug_panel_controller.toggle_reduced_motion())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "强制撤离成功", func() -> void: _dispatch_command(&"debug_force_extract", {"source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "强制本局失败", func() -> void: _dispatch_command(&"debug_force_fail", {"reason": "debug_forced_failure", "source": "debug"}))
	RunSceneDebugPanelControllerScript.add_section(debug_content, "真实运行命令")
	RunSceneDebugPanelControllerScript.add_button(debug_content, "向上移动一格", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(0, -1), "source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "向下移动一格", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(0, 1), "source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "向左移动一格", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(-1, 0), "source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "向右移动一格", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(1, 0), "source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "标记当前格", func() -> void: _dispatch_command(&"flag_current_cell", {"source": "debug"}))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "搜索当前房间", func() -> void: debug_panel_controller.search_and_show_loot())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "拾取地面物品", func() -> void: _pickup_floor_from_ui())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "丢弃背包物品", func() -> void: _drop_inventory_from_ui())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "请求撤离", func() -> void: _request_extract_from_ui())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "确认撤离", func() -> void: _dispatch_command(&"confirm_extract", {"source": "debug"}))
	RunSceneDebugPanelControllerScript.add_section(debug_content, "沙盒长期数据写入 · 标记 TAINTED")
	RunSceneDebugPanelControllerScript.add_button(debug_content, "长期金币 +1000", func() -> void: debug_panel_controller.meta_add_gold())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "长期金币设为 0", func() -> void: debug_panel_controller.meta_set_gold(0))
	RunSceneDebugPanelControllerScript.add_button(debug_content, "清空长期金币", func() -> void: debug_panel_controller.meta_clear_gold())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "添加仓库测试物品", func() -> void: debug_panel_controller.meta_add_warehouse_item())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "清空测试仓库", func() -> void: debug_panel_controller.meta_clear_warehouse())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "立即保存沙盒档", func() -> void: debug_panel_controller.meta_save())
	RunSceneDebugPanelControllerScript.add_button(debug_content, "清空沙盒存档", func() -> void: debug_panel_controller.meta_clear_save())
	inventory_panel = InventoryPanelScript.new() as Control
	inventory_panel.name = "InventoryPanel"
	inventory_panel.connect("drop_item_requested", _on_inventory_drop_requested)
	inventory_panel.connect("use_item_requested", _on_inventory_use_requested)
	inventory_panel.connect("close_requested", _close_inventory_modal)
	surface_overlay_slot.add_child(inventory_panel)

	result_panel = ResultPanelScene.instantiate() as ResultPanel
	result_panel.name = "ResultPanel"
	result_panel.return_main_requested.connect(_return_from_result_to_main)
	result_panel.return_deploy_requested.connect(_return_from_result_to_deploy)
	result_panel.failure_salvage_confirmed.connect(_confirm_failure_salvage_from_result)
	result_panel.retry_save_requested.connect(_retry_terminal_commit_from_result)
	result_panel.discard_unsaved_result_requested.connect(_discard_unsaved_result_from_result)
	result_panel.hide_result()
	surface_overlay_slot.add_child(result_panel)

	dev_diagnostics_panel = DevDiagnosticsPanelScript.new() as Control
	dev_diagnostics_panel.name = "DevDiagnosticsPanel"
	dev_diagnostics_panel.connect("close_requested", func() -> void: dev_diagnostics_panel.call("hide_panel"))
	ui_root.add_child(dev_diagnostics_panel)

	map_overlay_panel = MapOverlayScene.instantiate() as MapOverlayPanel
	map_overlay_panel.name = "MapOverlayPanel"
	map_overlay_panel.cell_action_requested.connect(_on_map_overlay_cell_action_requested)
	map_overlay_panel.visibility_changed.connect(_on_map_overlay_visibility_changed)
	surface_overlay_slot.add_child(map_overlay_panel)

	tutorial_popup_panel = TutorialPopupScene.instantiate() as TutorialPopupPanel
	tutorial_popup_panel.name = "TutorialPopupPanel"
	tutorial_popup_panel.confirmed.connect(_on_tutorial_popup_confirmed)
	surface_overlay_slot.add_child(tutorial_popup_panel)


func _build_runtime_modals() -> void:
	runtime_modal_input_shield = ColorRect.new()
	runtime_modal_input_shield.name = "RuntimeModalInputShield"
	runtime_modal_input_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	runtime_modal_input_shield.color = Color(0.0, 0.0, 0.0, 0.52)
	runtime_modal_input_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	runtime_modal_input_shield.hide()
	var runtime_modal_parent: Control = run_overlay_root
	if run_surface != null:
		runtime_modal_parent = run_surface.get_modal_slot()
	runtime_modal_parent.add_child(runtime_modal_input_shield)

	event_panel = _new_modal_panel("EventOptionPanel", Rect2(420, 140, 450, 360))
	var event_content := VBoxContainer.new()
	event_content.name = "EventOptionContent"
	event_content.add_theme_constant_override("separation", 8)
	event_panel.add_child(event_content)
	event_title_label = Label.new()
	event_title_label.text = "事件"
	event_title_label.add_theme_font_size_override("font_size", 20)
	event_content.add_child(event_title_label)
	event_body_label = Label.new()
	event_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_body_label.custom_minimum_size = Vector2(250, 78)
	event_content.add_child(event_body_label)
	event_options_box = VBoxContainer.new()
	event_options_box.name = "EventOptionButtons"
	event_content.add_child(event_options_box)
	_add_menu_button(event_content, "关闭", func() -> void: _cancel_event_modal(&"button_cancel"))

	if run_surface != null:
		run_surface.apply_legacy_modal_style(event_panel, &"mini.event")

	loot_panel = LootResultPanelScript.new() as Control
	loot_panel.name = "LootResultPanel"
	loot_panel.connect("close_requested", func() -> void: _cancel_loot_modal(&"button_cancel"))
	var modal_parent: Control = run_overlay_root
	if run_surface != null:
		modal_parent = run_surface.get_modal_slot()
	modal_parent.add_child(loot_panel)

	extract_panel = _new_modal_panel("ExtractConfirmPanel", Rect2(430, 180, 430, 260))
	var extract_content := VBoxContainer.new()
	extract_content.name = "ExtractConfirmContent"
	extract_content.add_theme_constant_override("separation", 8)
	extract_panel.add_child(extract_content)
	extract_title_label = Label.new()
	extract_title_label.text = "确认撤离"
	extract_title_label.add_theme_font_size_override("font_size", 20)
	extract_content.add_child(extract_title_label)
	extract_body_label = Label.new()
	extract_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	extract_body_label.custom_minimum_size = Vector2(250, 66)
	extract_content.add_child(extract_body_label)
	extract_items_scroll = ScrollContainer.new()
	extract_items_scroll.name = "ExtractCarriedItemsScroll"
	extract_items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	extract_items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	extract_items_scroll.custom_minimum_size = Vector2(0, 78)
	extract_items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	extract_content.add_child(extract_items_scroll)
	extract_items_box = VBoxContainer.new()
	extract_items_box.name = "ExtractCarriedItems"
	extract_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extract_items_box.add_theme_constant_override("separation", 4)
	extract_items_scroll.add_child(extract_items_box)
	var extract_buttons := HBoxContainer.new()
	extract_content.add_child(extract_buttons)
	extract_confirm_button = _add_menu_button(extract_buttons, "确认", func() -> void: _confirm_extract_from_ui())
	extract_cancel_button = _add_menu_button(extract_buttons, "取消", func() -> void: _cancel_extract_from_ui())

	if run_surface != null:
		run_surface.apply_legacy_modal_style(extract_panel, &"mini.exit")
		run_surface.apply_legacy_button_style(extract_confirm_button, &"primary")
		run_surface.apply_legacy_button_style(extract_cancel_button, &"secondary")

	pause_panel = _new_modal_panel("PauseSettingsOverlayPanel", Rect2(440, 146, 400, 400))
	var pause_content := VBoxContainer.new()
	pause_content.name = "PauseSettingsOverlayContent"
	pause_content.add_theme_constant_override("separation", 8)
	pause_panel.add_child(pause_content)
	var pause_title := Label.new()
	pause_title.text = "探索已暂停"
	pause_title.add_theme_font_size_override("font_size", 20)
	pause_content.add_child(pause_title)
	pause_status_label = Label.new()
	pause_status_label.name = "PauseSettingsOverlayStatus"
	pause_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_status_label.text = "当前探索会停留在此处。"
	pause_content.add_child(pause_status_label)
	var diagnostics_button: Button
	if m1_debug_panel_enabled:
		diagnostics_button = _add_menu_button(pause_content, "诊断面板", func() -> void: debug_panel_controller.open_from_pause())
	pause_continue_button = _add_menu_button(pause_content, "继续探索", func() -> void: _continue_from_pause())
	pause_settings_button = _add_menu_button(pause_content, "设置", func() -> void: _open_settings_from_pause())
	var deploy_button := _add_menu_button(pause_content, "返回出发", func() -> void: _return_from_pause_to_deploy())
	var main_button := _add_menu_button(pause_content, "返回主菜单", func() -> void: _return_from_pause_to_main())
	pause_abandon_button = _add_menu_button(pause_content, "放弃本次探索", func() -> void: _request_abandon_from_pause())
	if run_surface != null:
		run_surface.apply_legacy_modal_style(pause_panel, &"ui.accent")
		if diagnostics_button != null:
			run_surface.apply_legacy_button_style(diagnostics_button, &"secondary")
		run_surface.apply_legacy_button_style(pause_continue_button, &"primary")
		run_surface.apply_legacy_button_style(pause_settings_button, &"secondary")
		run_surface.apply_legacy_button_style(deploy_button, &"secondary")
		run_surface.apply_legacy_button_style(main_button, &"secondary")
		run_surface.apply_legacy_button_style(pause_abandon_button, &"danger")
	pause_title.add_theme_color_override("font_color", Color(0.98, 0.81, 0.42, 1.0))
	pause_status_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.70, 1.0))

	runtime_settings_panel = SettingsPanelScript.new() as Control
	runtime_settings_panel.name = "RuntimeSettingsPanel"
	var settings_parent: Control = run_overlay_root
	if run_surface != null:
		settings_parent = run_surface.get_modal_slot()
	settings_parent.add_child(runtime_settings_panel)
	runtime_settings_panel.call("set_external_cancel_authority", true)
	runtime_settings_panel.call("bind_settings_manager", ui_shell.call("get_bound_settings_manager"))
	runtime_settings_panel.connect("close_requested", _on_runtime_settings_close_requested)
	if run_surface != null:
		run_surface.apply_legacy_modal_style(runtime_settings_panel, &"ui.accent")

	abandon_confirm_panel = _new_modal_panel("PauseAbandonConfirmPanel", Rect2(420, 210, 520, 250))
	var abandon_content := VBoxContainer.new()
	abandon_content.name = "PauseAbandonConfirmContent"
	abandon_content.add_theme_constant_override("separation", 12)
	abandon_confirm_panel.add_child(abandon_content)
	var abandon_title := Label.new()
	abandon_title.name = "PauseAbandonConfirmTitle"
	abandon_title.text = "确认放弃本次探索？"
	abandon_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abandon_title.add_theme_font_size_override("font_size", 20)
	abandon_content.add_child(abandon_title)
	var abandon_body := Label.new()
	abandon_body.name = "PauseAbandonConfirmBody"
	abandon_body.text = "本局尚未保全的物资与收益会按放弃规则结算。"
	abandon_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	abandon_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abandon_body.custom_minimum_size = Vector2(360, 76)
	abandon_content.add_child(abandon_body)
	var abandon_actions := HBoxContainer.new()
	abandon_actions.name = "PauseAbandonConfirmActions"
	abandon_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	abandon_actions.add_theme_constant_override("separation", 12)
	abandon_content.add_child(abandon_actions)
	abandon_confirm_cancel_button = _add_menu_button(abandon_actions, "取消", func() -> void: _cancel_abandon_from_pause())
	abandon_confirm_button = _add_menu_button(abandon_actions, "确认放弃", func() -> void: _confirm_abandon_from_pause())
	if run_surface != null:
		run_surface.apply_legacy_modal_style(abandon_confirm_panel, &"ui.danger")
		run_surface.apply_legacy_button_style(abandon_confirm_cancel_button, &"secondary")
		run_surface.apply_legacy_button_style(abandon_confirm_button, &"danger")
	_apply_runtime_modal_layout(_current_layout_profile())


func _bind_runtime_modal_controller() -> void:
	modal_controller.bind_views(
		runtime_modal_input_shield,
		run_surface,
		{
			&"event": event_panel,
			&"loot_result": loot_panel,
			&"extract_confirm": extract_panel,
			&"combat_flee_confirm": extract_panel,
			&"result": result_panel,
			&"pause": pause_panel,
			&"settings": runtime_settings_panel,
			&"abandon_confirm": abandon_confirm_panel,
			&"inventory": inventory_panel,
			&"map": map_overlay_panel,
		},
		Callable(self, "_sync_player_input_enabled")
	)


func _new_modal_panel(node_name: String, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.offset_left = rect.position.x
	panel.offset_top = rect.position.y
	panel.offset_right = rect.position.x + rect.size.x
	panel.offset_bottom = rect.position.y + rect.size.y
	panel.visible = false
	var modal_parent: Control = run_overlay_root
	if run_surface != null:
		modal_parent = run_surface.get_modal_slot()
	modal_parent.add_child(panel)
	return panel


func _apply_runtime_modal_layout(profile: Dictionary) -> void:
	var layout: Dictionary = RuntimeModalLayoutModelScript.build(profile)
	_set_control_rect(event_panel, layout.get("event", Rect2()) as Rect2)
	if loot_panel != null:
		loot_panel.call("apply_layout_profile", profile)
	_set_control_rect(extract_panel, layout.get("extract", Rect2()) as Rect2)
	_set_control_rect(pause_panel, layout.get("pause", Rect2()) as Rect2)
	_set_control_rect(runtime_settings_panel, layout.get("settings", Rect2()) as Rect2)
	_set_control_rect(abandon_confirm_panel, layout.get("abandon", Rect2()) as Rect2)
	_set_control_rect(debug_panel, layout.get("debug", Rect2()) as Rect2)
	if debug_scroll != null:
		debug_scroll.custom_minimum_size = layout.get("debug_scroll_minimum", Vector2.ZERO) as Vector2


func _shell_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	if run_context != null:
		snapshot = run_context.get_status_snapshot()
		if not run_context.result_snapshot.is_empty():
			snapshot["last_result_snapshot"] = run_context.result_snapshot.duplicate(true)
	if in_run_runtime != null:
		snapshot["combat_runtime"] = in_run_runtime.build_read_only_snapshot()
	snapshot["meta_progress_summary"] = _meta_progress_summary()
	snapshot["run_scene_responsibility_budget"] = RunSceneResponsibilityBudgetScript.describe()
	return snapshot


func _meta_progress_summary() -> Dictionary:
	return runtime_controller.meta_progress_summary() if runtime_controller != null else {}


func _show_main_menu() -> void:
	debug_panel_controller.end_test_room_if_ready()
	screen_state = SCREEN_MAIN_MENU
	_set_gameplay_visible(false)
	ui_shell.call("show_main")
	ui_shell.call("apply_snapshot", _shell_snapshot())
	run_overlay_root.visible = false
	_hide_runtime_popups()


func _show_deploy_shell(selected_tab: StringName = &"config") -> void:
	screen_state = SCREEN_DEPLOY
	_set_gameplay_visible(false)
	ui_shell.call("apply_snapshot", _shell_snapshot())
	ui_shell.call("show_deploy", _normalize_deploy_tab(selected_tab))
	run_overlay_root.visible = false
	_hide_runtime_popups()


func _show_long_term_shell(entry_id: StringName = &"tasks") -> void:
	screen_state = SCREEN_LONG_TERM
	_set_gameplay_visible(false)
	ui_shell.call("apply_snapshot", _shell_snapshot())
	ui_shell.call("show_long_term", entry_id)
	run_overlay_root.visible = false
	_hide_runtime_popups()


func _show_settings_shell() -> bool:
	_set_gameplay_visible(false)
	var opened := bool(ui_shell.call("show_settings"))
	screen_state = SCREEN_SETTINGS if opened else SCREEN_MAIN_MENU
	run_overlay_root.visible = false
	_hide_runtime_popups()
	return opened


func _show_run_screen() -> bool:
	var prewarm_report := _prewarm_combat_actor_textures()
	if not bool(prewarm_report.get("ok", false)):
		_record_combat_texture_prewarm_failure(prewarm_report)
		return false
	combat_texture_prewarm_degraded = false
	screen_state = SCREEN_RUN
	_set_gameplay_visible(true)
	ui_shell.visible = false
	run_overlay_root.visible = true
	get_viewport().gui_release_focus()
	_hide_runtime_popups()
	_refresh_view_models()
	return true


func _prewarm_combat_actor_textures() -> Dictionary:
	var paths: Array[String] = []
	paths.append_array(Art24RuntimeAnimationCatalogScript.production_texture_paths())
	paths.append_array(Art24EnemyVisualCatalogScript.production_texture_paths())
	last_combat_texture_prewarm_report = RuntimeTextureCacheScript.prewarm(paths)
	return last_combat_texture_prewarm_report.duplicate(true)


func _run_start_asset_admission() -> Dictionary:
	var report := _prewarm_combat_actor_textures()
	report["status"] = &"combat_actor_assets_ready" if bool(report.get("ok", false)) else &"combat_texture_prewarm_failed"
	if not bool(report.get("ok", false)):
		report["reason_code"] = &"combat_actor_assets_unavailable"
	last_combat_texture_preflight_report = report.duplicate(true)
	combat_texture_prewarm_degraded = not bool(report.get("ok", false))
	return report


func _record_combat_texture_prewarm_failure(prewarm_report: Dictionary) -> void:
	combat_texture_prewarm_degraded = true
	last_command_result = {
		"ok": false,
		"status": &"combat_texture_prewarm_failed",
		"reason": &"combat_actor_assets_unavailable",
		"prewarm_report": prewarm_report.duplicate(true),
	}
	_show_command_feedback(last_command_result)
	push_error(
		"Combat actor texture prewarm failed: cached=%d/%d missing=%d failures=%d rejected=%d"
		% [
			int(prewarm_report.get("cached", 0)),
			int(prewarm_report.get("declared", 0)),
			int(prewarm_report.get("missing", 0)),
			int(prewarm_report.get("failures", 0)),
			int(prewarm_report.get("rejected", 0)),
		]
	)


func _set_gameplay_visible(visible: bool) -> void:
	var room_layer := get_node_or_null("RoomLayer") as Node2D
	var player_layer := get_node_or_null("PlayerLayer") as Node2D
	if room_layer != null:
		room_layer.visible = visible
	if player_layer != null:
		player_layer.visible = visible
	if gameplay_backdrop != null:
		gameplay_backdrop.visible = visible
	if ui_shell != null:
		ui_shell.visible = not visible
		if ui_shell.has_method("set_shell_active"):
			ui_shell.call("set_shell_active", not visible)
	if not visible and player_controller != null:
		player_controller.set_input_enabled(false)
	else:
		_sync_player_input_enabled()


func _show_pause_panel() -> void:
	if pause_panel == null:
		return
	if _is_runtime_modal_open():
		return
	pause_exit_confirm_pending = false
	if pause_status_label != null and run_context != null:
		var snapshot: Dictionary = run_context.get_status_snapshot()
		pause_status_label.text = "探索已暂停\n当前位置：%s" % [
			_run_room_label(StringName(snapshot.get("current_room", &"Unknown"))),
		]
	_apply_runtime_modal_layout(_current_layout_profile())
	if not _push_runtime_modal(&"pause", pause_panel, pause_continue_button, Callable(self, "_cancel_pause_modal")):
		pause_panel.hide()


func _open_settings_from_pause() -> void:
	pause_exit_confirm_pending = false
	if runtime_settings_panel == null or not _runtime_modal_is_top(&"pause"):
		return
	runtime_settings_panel.call("bind_settings_manager", ui_shell.call("get_bound_settings_manager"))
	if not bool(runtime_settings_panel.call("open_panel")):
		if pause_status_label != null:
			pause_status_label.text = "设置暂时无法打开，当前探索仍保持暂停。"
		return
	var pushed := _push_runtime_modal(
		&"settings",
		runtime_settings_panel,
		runtime_settings_panel.call("preferred_focus_control") as Control,
		Callable(self, "_cancel_runtime_settings")
	)
	if not pushed:
		runtime_settings_panel.call("close_panel", false)


func _continue_from_pause() -> void:
	if not _runtime_modal_is_top(&"pause"):
		return
	pause_exit_confirm_pending = false
	_pop_runtime_modal(&"pause")


func _return_from_pause_to_deploy() -> void:
	if not _runtime_modal_is_top(&"pause"):
		return
	pause_exit_confirm_pending = false
	_clear_runtime_modal_stack(false)
	_show_deploy_shell(&"config")


func _return_from_pause_to_main() -> void:
	if not _runtime_modal_is_top(&"pause"):
		return
	if _has_active_run_for_pause_exit():
		pause_exit_confirm_pending = false
		if pause_status_label != null:
			pause_status_label.text = "当前探索仍在进行。请先选择“放弃本次探索”完成结算，再返回主菜单。"
		return
	_clear_runtime_modal_stack(false)
	_show_main_menu()


func _request_abandon_from_pause() -> void:
	if not _has_active_run_for_pause_exit():
		pause_exit_confirm_pending = false
		if pause_status_label != null:
			pause_status_label.text = "当前没有可放弃的探索，可直接返回出发页或主菜单。"
		return
	if not _runtime_modal_is_top(&"pause"):
		return
	pause_exit_confirm_pending = true
	var pushed := _push_runtime_modal(
		&"abandon_confirm",
		abandon_confirm_panel,
		abandon_confirm_cancel_button,
		Callable(self, "_cancel_abandon_modal")
	)
	if not pushed:
		pause_exit_confirm_pending = false
		abandon_confirm_panel.hide()


func _cancel_abandon_from_pause() -> void:
	_cancel_abandon_modal(&"button_cancel")


func _cancel_abandon_modal(_reason: StringName = &"cancel") -> void:
	pause_exit_confirm_pending = false
	_pop_runtime_modal(&"abandon_confirm")


func _confirm_abandon_from_pause() -> void:
	if abandon_dispatch_in_flight or not _runtime_modal_is_top(&"abandon_confirm"):
		return
	abandon_dispatch_in_flight = true
	pause_exit_confirm_pending = false
	_pop_runtime_modal(&"abandon_confirm", false)
	_pop_runtime_modal(&"pause", false)
	var result := _dispatch_command(
		&"abandon_run",
		{"reason": "player_pause_exit_current_run", "source": "pause_panel", "confirmed": true},
		true,
		false
	)
	abandon_dispatch_in_flight = false
	if bool(result.get("ok", false)) and result_panel != null and not result_panel.visible and run_context != null:
		if not run_context.result_snapshot.is_empty():
			_on_result_available(run_context.result_snapshot)
	elif not bool(result.get("ok", false)):
		_show_pause_panel()
		if pause_status_label != null:
			pause_status_label.text = "未能放弃本次探索，请稍后重试。"


func _has_active_run_for_pause_exit() -> bool:
	if run_context == null:
		return false
	var snapshot: Dictionary = run_context.get_status_snapshot()
	if bool(snapshot.get("run_active", false)):
		return true
	var phase := StringName(snapshot.get("phase", &""))
	return phase in [&"running", &"event", &"combat", &"extract_pending"]


func _push_runtime_modal(
	modal_id: StringName,
	modal_root: Control,
	preferred_focus: Control = null,
	cancel_handler: Callable = Callable()
) -> bool:
	if modal_controller == null:
		return false
	return bool(modal_controller.push(modal_id, modal_root, preferred_focus, cancel_handler))


func _runtime_modal_is_top(modal_id: StringName) -> bool:
	return modal_controller != null and modal_controller.is_top(modal_id)


func _pop_runtime_modal(modal_id: StringName, restore_focus: bool = true, hide_modal: bool = true) -> bool:
	if modal_controller == null:
		return false
	return bool(modal_controller.pop(modal_id, restore_focus, hide_modal))


func _clear_runtime_modal_stack(restore_focus: bool = true) -> void:
	if modal_controller != null:
		modal_controller.clear(restore_focus)


func _cancel_pause_modal(_reason: StringName = &"cancel") -> void:
	pause_exit_confirm_pending = false
	_pop_runtime_modal(&"pause")


func _cancel_runtime_settings(_reason: StringName = &"cancel") -> void:
	if runtime_settings_panel != null:
		runtime_settings_panel.call("close_panel", false)
	_pop_runtime_modal(&"settings")


func _on_runtime_settings_close_requested() -> void:
	_pop_runtime_modal(&"settings", true, false)


func _close_inventory_modal() -> void:
	if _runtime_modal_is_top(&"inventory"):
		_pop_runtime_modal(&"inventory")
		return
	if inventory_panel != null:
		inventory_panel.call("hide_panel")


func _cancel_inventory_modal(_reason: StringName = &"cancel") -> void:
	_close_inventory_modal()


func _cancel_map_modal(_reason: StringName = &"cancel") -> void:
	if map_overlay_panel != null and map_overlay_panel.visible:
		map_overlay_panel.hide_overlay()
	if _runtime_modal_is_top(&"map"):
		_pop_runtime_modal(&"map", true, false)


func _on_map_overlay_visibility_changed() -> void:
	if map_overlay_panel == null:
		return
	if tutorial_popup_panel != null:
		tutorial_popup_panel.set_presentation_occluded(map_overlay_panel.visible)
	if map_overlay_panel.visible:
		return
	if _runtime_modal_is_top(&"map"):
		_pop_runtime_modal(&"map", true, false)


func _preferred_modal_focus(modal_root: Control) -> Control:
	if modal_controller == null:
		return null
	return modal_controller.preferred_focus(modal_root)


func _return_from_result_to_main() -> void:
	if not _runtime_modal_is_top(&"result"):
		return
	if result_panel != null and not result_panel.normal_exit_allowed():
		return
	_pop_runtime_modal(&"result", false)
	get_viewport().gui_release_focus()
	_show_main_menu()


func _return_from_result_to_deploy() -> void:
	if debug_panel_controller.is_test_room_active():
		_return_from_result_to_main()
		return
	if not _runtime_modal_is_top(&"result"):
		return
	if result_panel != null and not result_panel.normal_exit_allowed():
		return
	_pop_runtime_modal(&"result", false)
	get_viewport().gui_release_focus()
	_show_deploy_shell(&"config")


func _normalize_deploy_tab(tab_id: StringName) -> StringName:
	match tab_id:
		&"loadout":
			return &"config"
		&"settings":
			return &"settings"
		_:
			return tab_id


func _on_app_shell_host_route_requested(intent: Dictionary) -> void:
	if debug_panel_controller.start_test_room_if_requested(intent, Callable(self, "_run_start_asset_admission"), Callable(self, "_show_run_screen"), Callable(self, "_show_main_menu")):
		return
	var target := NavigationIntentScript.target(intent)
	match target:
		NavigationIntentScript.TARGET_RUN:
			_start_run_from_route(intent)
		_:
			_show_main_menu()


func _on_app_shell_page_changed(page_id: StringName, _payload: Dictionary) -> void:
	var next_screen_state := PageRouterScript.screen_state_for_page(page_id)
	if next_screen_state == &"":
		return
	screen_state = next_screen_state
	_set_gameplay_visible(false)
	if run_overlay_root != null:
		run_overlay_root.visible = false
	_hide_runtime_popups()


func _on_main_entry_requested(entry_id: StringName) -> void:
	match entry_id:
		&"deploy", &"deploy_config":
			_show_deploy_shell(&"config")
		&"long_term":
			_show_long_term_shell()
		&"settings":
			_show_settings_shell()
		_:
			_show_main_menu()


func _on_deploy_entry_requested(entry_id: StringName) -> void:
	match entry_id:
		&"back_main":
			_show_main_menu()
		&"long_term":
			_show_long_term_shell()


func _on_long_term_entry_requested(entry_id: StringName) -> void:
	match entry_id:
		&"back_main":
			_show_main_menu()
		&"deploy":
			_show_deploy_shell()
		_:
			_show_long_term_shell(entry_id)


func _on_m7_meta_action_requested(action: Dictionary) -> void:
	if runtime_controller == null:
		return
	var envelope: Dictionary = runtime_controller.execute_meta_action(action)
	var result := (envelope.get("result", {}) as Dictionary).duplicate(true)
	last_command_result = result.duplicate(true)
	_show_command_feedback(result)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())
		if ui_shell.has_method("apply_meta_action_result"):
			ui_shell.call("apply_meta_action_result", envelope)


func _handle_interact_pressed() -> void:
	if command_bus == null or run_context == null or _is_runtime_modal_open():
		return
	if room_runtime_view != null and player_controller != null:
		var world_request: Dictionary = room_runtime_view.request_nearest_interaction(
			player_controller.get_local_position(),
			true
		)
		if bool(world_request.get("accepted", false)):
			match StringName(world_request.get("interaction_kind", &"none")):
				&"ground_loot":
					var payload: Dictionary = world_request.get("payload", {})
					var instance_id := String(payload.get("instance_id", ""))
					var pickup_result := _dispatch_command(
						&"pickup_ground_item",
						{"source": "g41_world_interaction", "instance_id": instance_id},
						true,
						false
					)
					var pickup_cue := (
						PlayerFeedbackServiceScript.CUE_PICKUP
						if bool(pickup_result.get("ok", false))
						else PlayerFeedbackServiceScript.CUE_UI_REJECT
					)
					if bool(pickup_result.get("ok", false)):
						_emit_feedback_for_result(
							pickup_result,
							pickup_cue,
							_feedback_event_id("world_pickup", pickup_result)
						)
						if run_surface != null:
							run_surface.clear_command_feedback()
					else:
						_show_command_feedback(
							pickup_result,
							pickup_cue,
							_feedback_event_id("world_pickup", pickup_result)
						)
					room_runtime_view.show_pickup_result(instance_id, bool(pickup_result.get("ok", false)))
					if not bool(pickup_result.get("ok", false)):
						room_runtime_view.show_context_result(pickup_result)
					return
				&"chest":
					var intent := StringName(world_request.get("intent", &""))
					if intent == &"search_current_room":
						# The explicit input owns the command submission.  Animation and
						# later view advances only observe the authoritative result.
						var chest_result := _dispatch_command(
							&"search_current_room",
							{"source": "g41_world_interaction"},
							true,
							false
						)
						var chest_cue := (
							PlayerFeedbackServiceScript.CUE_CHEST_OPEN
							if bool(chest_result.get("ok", false))
							else PlayerFeedbackServiceScript.CUE_UI_REJECT
						)
						if bool(chest_result.get("ok", false)):
							_emit_feedback_for_result(
								chest_result,
								chest_cue,
								_feedback_event_id("chest_open", chest_result)
							)
							if run_surface != null:
								run_surface.clear_command_feedback()
						else:
							_show_command_feedback(
								chest_result,
								chest_cue,
								_feedback_event_id("chest_open", chest_result)
							)
						var chest_snapshot := run_context.get_status_snapshot()
						room_runtime_view.apply_chest_search_result(chest_result, chest_snapshot)
						if not bool(chest_result.get("ok", false)):
							room_runtime_view.show_context_result({
								"ok": false,
								"message": String(chest_result.get("message", chest_result.get("reason", "物资箱无法打开。"))),
							})
					return
				&"event":
					var event_state: Dictionary = run_context.get_status_snapshot().get("event_state", {})
					if not event_state.is_empty() and not bool(event_state.get("completed", false)):
						_show_event_panel(event_state)
					else:
						_show_command_feedback({"ok": false, "reason": &"event_completed", "message": "这里的事件已经处理完毕。"})
					return
				&"exit":
					# The keyboard path already passed the governed world request,
					# including its visible-focus grace contract. Do not replace
					# that result with a second strict-radius query.
					_request_extract_from_ui(true)
					return
				&"mine":
					_show_command_feedback({"ok": true, "status": &"mine_inspected", "message": String((world_request.get("payload", {}) as Dictionary).get("summary", "机关状态已显示。"))})
					return
	var snapshot := run_context.get_status_snapshot()
	var current_room: StringName = StringName(snapshot.get("current_room", &"Unknown"))
	var search_data: Dictionary = snapshot.get("search_state_data", {})
	if current_room == &"Event":
		_show_command_feedback({"ok": false, "reason": &"event_out_of_range", "message": "靠近事件标记后再选择处理方式。"})
		return
	if current_room == &"Exit":
		_show_command_feedback({"ok": false, "reason": &"exit_out_of_range", "message": "靠近撤离信标后再查看并申请撤离。"})
		return
	if current_room == &"Mine":
		_show_command_feedback({"ok": true, "status": &"mine_inspected", "message": "靠近机关可查看其当前状态。"})
		return
	if current_room == &"Chest":
		_show_command_feedback({"ok": false, "reason": &"interactable_out_of_range", "message": "靠近物资箱后再查看其中物品。"})
		return
	if bool(search_data.get("can_search", false)):
		_search_and_show_loot()
		return
	var result := _dispatch_command(&"interact_current_room")
	_show_command_feedback(result)


func _search_and_show_loot() -> void:
	var result := _dispatch_command(&"search_current_room", {}, true, false)
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_world_reward_feedback(result, reward, &"search")
	else:
		_show_command_feedback(
			result,
			PlayerFeedbackServiceScript.CUE_SEARCH_REVEAL if bool(result.get("ok", false)) else PlayerFeedbackServiceScript.CUE_UI_REJECT,
			_feedback_event_id("search", result)
		)


func _fight_and_show_result(requested_facing: Vector2 = Vector2.ZERO) -> void:
	if _is_runtime_modal_open():
		return
	if in_run_runtime != null and in_run_runtime.has_active_combat():
		var attack_result: Dictionary = in_run_runtime.request_attack(requested_facing)
		last_command_result = attack_result.duplicate(true)
		if bool(attack_result.get("ok", false)) and requested_facing.length_squared() > 0.0001:
			player_controller.set_facing_vector(requested_facing)
		if StringName(attack_result.get("status", &"")) == &"attack_cooling_down":
			if run_surface != null and run_surface.has_method("apply_combat_attack_state"):
				run_surface.call(
					"apply_combat_attack_state",
					in_run_runtime.build_read_only_snapshot().get("attack_input", {})
				)
			return
		_show_command_feedback(attack_result)
		return
	var result := _dispatch_command(&"fight_current_enemy", {}, true, false)
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_world_reward_feedback(result, reward, &"combat")


func _pickup_floor_from_ui(instance_id: String = "") -> void:
	var payload: Dictionary = {"source": "ui"}
	if instance_id != "":
		payload["instance_id"] = instance_id
	var refresh_count_before := _full_refresh_count()
	var result := _dispatch_command(&"pickup_ground_item", payload, false, false)
	_refresh_if_dispatch_was_unsignaled(refresh_count_before)
	_emit_feedback_for_result(
		result,
		PlayerFeedbackServiceScript.CUE_PICKUP if bool(result.get("ok", false)) else PlayerFeedbackServiceScript.CUE_UI_REJECT,
		_feedback_event_id("pickup", result)
	)
	if room_runtime_view != null and not bool(result.get("ok", false)):
		room_runtime_view.show_context_result(result)
	if ground_loot_panel != null:
		ground_loot_panel.call("show_command_result", result)
	if inventory_panel != null:
		inventory_panel.call("show_command_result", result)


func _replace_floor_from_ui(instance_id: String = "", drop_instance_id: String = "") -> void:
	var payload: Dictionary = {"source": "ui"}
	if instance_id != "":
		payload["ground_instance_id"] = instance_id
	if drop_instance_id != "":
		payload["drop_instance_id"] = drop_instance_id
	var refresh_count_before := _full_refresh_count()
	var result := _dispatch_command(&"replace_ground_item", payload, false, false)
	_refresh_if_dispatch_was_unsignaled(refresh_count_before)
	_emit_feedback_for_result(
		result,
		PlayerFeedbackServiceScript.CUE_PICKUP if bool(result.get("ok", false)) else PlayerFeedbackServiceScript.CUE_UI_REJECT,
		_feedback_event_id("replace_pickup", result)
	)
	if room_runtime_view != null and not bool(result.get("ok", false)):
		room_runtime_view.show_context_result(result)
	if ground_loot_panel != null:
		ground_loot_panel.call("show_command_result", result)
	if inventory_panel != null:
		inventory_panel.call("show_command_result", result)


func _drop_inventory_from_ui(instance_id: String = "") -> void:
	var payload: Dictionary = {"source": "ui"}
	if instance_id != "":
		payload["instance_id"] = instance_id
	var refresh_count_before := _full_refresh_count()
	var result := _dispatch_command(&"drop_inventory_item", payload, false, false)
	_refresh_if_dispatch_was_unsignaled(refresh_count_before)
	_emit_feedback_for_result(
		result,
		PlayerFeedbackServiceScript.CUE_UI_CONFIRM if bool(result.get("ok", false)) else PlayerFeedbackServiceScript.CUE_UI_REJECT,
		_feedback_event_id("drop_item", result)
	)
	if inventory_panel != null:
		inventory_panel.call("show_command_result", result)
	if ground_loot_panel != null:
		ground_loot_panel.call("show_command_result", result)


func _use_inventory_item_from_ui(instance_id: String = "") -> void:
	var payload: Dictionary = {"source": "ui"}
	if instance_id != "":
		payload["instance_id"] = instance_id
	var refresh_count_before := _full_refresh_count()
	var result := _dispatch_command(&"use_item", payload, false, false)
	_refresh_if_dispatch_was_unsignaled(refresh_count_before)
	_emit_feedback_for_result(
		result,
		PlayerFeedbackServiceScript.CUE_ITEM_RECOVERY if bool(result.get("ok", false)) else PlayerFeedbackServiceScript.CUE_UI_REJECT,
		_feedback_event_id("use_item", result)
	)
	if inventory_panel != null:
		inventory_panel.call("show_command_result", result)
	if ground_loot_panel != null:
		ground_loot_panel.call("show_command_result", result)


func _show_inventory_panel() -> void:
	if inventory_panel == null:
		return
	if _is_runtime_modal_open():
		return
	inventory_panel.call("apply_snapshot", run_context.get_status_snapshot())
	inventory_panel.call("show_panel")
	var pushed := _push_runtime_modal(
		&"inventory",
		inventory_panel,
		_preferred_modal_focus(inventory_panel),
		Callable(self, "_cancel_inventory_modal")
	)
	if not pushed:
		inventory_panel.call("hide_panel")


func _activate_world_context_primary() -> void:
	if _is_runtime_modal_open():
		return
	if room_runtime_view != null and room_runtime_view.activate_context_primary():
		return
	_show_command_feedback({"ok": false, "reason": &"world_context_out_of_range", "message": "靠近地面物品、物资箱或特殊房间标记后再操作。"})


func _world_interaction_in_range(expected_kind: StringName) -> bool:
	# UI buttons and shortcuts are alternate inputs for the governed world
	# interaction, not room-wide command authorities. Missing runtime state must
	# fail closed so a stale/legacy surface cannot bypass proximity.
	if run_context == null or room_runtime_view == null or player_controller == null:
		return false
	var expected_room := &"Event" if expected_kind == &"event" else (&"Exit" if expected_kind == &"exit" else &"Unknown")
	if expected_room != &"Unknown" and run_context.current_room_type != expected_room:
		return false
	var request: Dictionary = room_runtime_view.request_nearest_interaction(player_controller.get_local_position())
	return bool(request.get("accepted", false)) and StringName(request.get("interaction_kind", &"none")) == expected_kind


func _require_world_interaction(expected_kind: StringName) -> bool:
	if _world_interaction_in_range(expected_kind):
		return true
	var is_exit := expected_kind == &"exit"
	_show_command_feedback({
		"ok": false,
		"accepted": false,
		"reason": &"exit_out_of_range" if is_exit else &"event_out_of_range",
		"message": "靠近撤离信标后再申请撤离。" if is_exit else "靠近事件标记后再选择处理方式。",
	})
	return false


func _show_ground_loot_panel() -> void:
	_activate_world_context_primary()


func _on_world_context_action_requested(action: StringName, payload: Dictionary) -> void:
	if _is_runtime_modal_open():
		return
	match action:
		&"pickup":
			_pickup_floor_from_ui(String(payload.get("instance_id", "")))
		&"replace":
			_replace_floor_from_ui(String(payload.get("instance_id", "")), String(payload.get("drop_instance_id", "")))
		&"chest_open":
			_handle_interact_pressed()
		&"event_open":
			var event_state: Dictionary = run_context.get_status_snapshot().get("event_state", {})
			if not event_state.is_empty() and not bool(event_state.get("completed", false)):
				_show_event_panel(event_state)
		&"exit_request":
			_request_extract_from_ui()


func _on_inventory_drop_requested(instance_id: String) -> void:
	if not _runtime_modal_is_top(&"inventory"):
		return
	_drop_inventory_from_ui(instance_id)


func _on_inventory_use_requested(instance_id: String) -> void:
	if not _runtime_modal_is_top(&"inventory"):
		return
	_use_inventory_item_from_ui(instance_id)


func _on_ground_loot_pickup_requested(instance_id: String) -> void:
	if _is_runtime_modal_open():
		return
	_pickup_floor_from_ui(instance_id)


func _on_ground_loot_replace_requested(instance_id: String) -> void:
	if _is_runtime_modal_open():
		return
	_replace_floor_from_ui(instance_id)


func _show_event_panel(event_state: Dictionary) -> void:
	if event_panel == null or _is_runtime_modal_open():
		return
	if not _require_world_interaction(&"event"):
		return
	event_title_label.text = "事件：%s" % _event_type_label(StringName(event_state.get("event_type", &"event")))
	event_body_label.text = "选择处理方式。事件完成后不会重复结算奖励。"
	event_body_label.text = RunSurfaceModel.event_modal_text(event_state)
	for child in event_options_box.get_children():
		child.queue_free()
	var options: Array = event_state.get("options", [])
	for option: Dictionary in options:
		var option_id: StringName = StringName(option.get("id", &"leave"))
		var option_label := RunSurfaceModel.event_option_label(StringName(event_state.get("event_type", &"event")), option)
		var button := _add_menu_button(event_options_box, option_label, func() -> void: _select_event_option(option_id))
		button.disabled = not bool(option.get("enabled", true))
		button.tooltip_text = RunSurfaceModel.event_option_detail(option)
		if run_surface != null:
			run_surface.apply_legacy_button_style(button, &"primary" if not button.disabled else &"secondary")
	_apply_runtime_modal_layout(_current_layout_profile())
	var pushed := _push_runtime_modal(
		&"event",
		event_panel,
		_preferred_modal_focus(event_panel),
		Callable(self, "_cancel_event_modal")
	)
	if not pushed:
		event_panel.hide()


func _cancel_event_modal(_reason: StringName = &"cancel") -> void:
	if _runtime_modal_is_top(&"event"):
		_pop_runtime_modal(&"event")


func _select_event_option(option_id: StringName) -> void:
	if not _runtime_modal_is_top(&"event"):
		return
	if not _require_world_interaction(&"event"):
		return
	_pop_runtime_modal(&"event")
	var result := _dispatch_command(
		&"select_event_option",
		{"option_id": option_id, "source": "ui"},
		true,
		false
	)
	var action_result: Dictionary = result.get("action_result", {})
	_show_world_reward_feedback(result, action_result, &"event")


func _on_encounter_option_selected(_option_id: StringName, command_payload: Dictionary) -> void:
	if _is_runtime_modal_open():
		return
	if in_run_runtime != null and in_run_runtime.has_active_combat():
		_fight_and_show_result()
		return
	if run_context != null and run_context.current_room_type == &"Chest":
		_handle_interact_pressed()
		return
	if run_context != null and run_context.current_room_type == &"Event" and not _require_world_interaction(&"event"):
		return
	var payload := command_payload.duplicate(true)
	if not payload.has("option_id"):
		_show_command_feedback({
			"ok": false,
			"accepted": false,
			"reason_code": &"encounter_option_payload_missing",
			"message_key": &"ui.encounter.option_payload_missing",
			"command_id": &"select_encounter_option",
		})
		return
	payload["source"] = "ui"
	var result := _dispatch_command(&"select_encounter_option", payload, true, false)
	var action_result: Dictionary = result.get("action_result", {})
	_show_world_reward_feedback(result, action_result, &"encounter")


func _request_extract_from_ui(prevalidated_world_interaction: bool = false) -> void:
	if _is_runtime_modal_open():
		return
	if in_run_runtime != null and in_run_runtime.has_active_combat():
		_request_combat_flee_from_ui()
		return
	if in_run_runtime != null and bool(in_run_runtime.flee_authorized):
		var retry_direction := _combat_flee_direction_for_player()
		if retry_direction != Vector2i.ZERO:
			_reset_transition_rejection_debounce()
			_attempt_room_transition(retry_direction)
		else:
			_show_command_feedback({
				"ok": false,
				"accepted": false,
				"reason": &"combat_flee_transition_pending",
				"message": "逃离代价已结算；请回到刚才的有效门边再次通过，不会重复扣除。",
			})
		return
	if not prevalidated_world_interaction and not _require_world_interaction(&"exit"):
		return
	_capture_exit_interaction_authorization()
	var result := _dispatch_command(&"request_extract")
	if bool(result.get("ok", false)):
		_show_extract_panel(run_context.get_status_snapshot())
	else:
		_clear_exit_interaction_authorization()
		_show_command_feedback(result)


func _show_extract_panel(snapshot: Dictionary) -> void:
	if StringName(snapshot.get("phase", &"running")) != &"confirm_extract" or _is_runtime_modal_open():
		return
	extract_modal_mode = &"extract"
	pending_combat_flee_direction = Vector2i.ZERO
	var risky := int(snapshot.get("protocol_level", 5)) <= 1
	extract_title_label.text = "高危撤离确认" if risky else "确认撤离"
	extract_body_label.text = RunSurfaceModel.extract_modal_text(snapshot)
	_apply_extract_item_preview(RunSurfaceModel.extract_carried_item_models(snapshot))
	extract_confirm_button.text = "确认撤离"
	extract_cancel_button.text = "继续探索"
	if run_surface != null:
		run_surface.apply_legacy_modal_style(extract_panel, &"ui.danger" if risky else &"mini.exit")
		run_surface.apply_legacy_button_style(extract_confirm_button, &"danger" if risky else &"primary")
		run_surface.apply_legacy_button_style(extract_cancel_button, &"secondary")
	extract_title_label.add_theme_color_override(
		"font_color",
		PresentationTheme.color_for_key(&"ui.danger") if risky else PresentationTheme.text_color()
	)
	_apply_runtime_modal_layout(_current_layout_profile())
	var pushed := _push_runtime_modal(
		&"extract_confirm",
		extract_panel,
		extract_cancel_button,
		Callable(self, "_cancel_extract_modal")
	)
	if not pushed:
		extract_panel.hide()
		_clear_exit_interaction_authorization()


func _confirm_extract_from_ui() -> void:
	if _runtime_modal_is_top(&"combat_flee_confirm"):
		_confirm_combat_flee_from_ui()
		return
	if not _runtime_modal_is_top(&"extract_confirm"):
		return
	var has_opening_authorization := _exit_interaction_authorization_matches()
	if pending_exit_interaction_authorized and not has_opening_authorization:
		_clear_exit_interaction_authorization()
	if not has_opening_authorization and not _require_world_interaction(&"exit"):
		return
	_clear_exit_interaction_authorization()
	_pop_runtime_modal(&"extract_confirm")
	_dispatch_command(&"confirm_extract", {}, true, false)


func _cancel_extract_from_ui() -> void:
	if _runtime_modal_is_top(&"combat_flee_confirm"):
		_cancel_combat_flee_modal(&"button_cancel")
		return
	_cancel_extract_modal(&"button_cancel")


func _cancel_extract_modal(_reason: StringName = &"cancel") -> void:
	if not _runtime_modal_is_top(&"extract_confirm"):
		return
	_clear_exit_interaction_authorization()
	_pop_runtime_modal(&"extract_confirm")
	_dispatch_command(&"cancel_extract")


func _capture_exit_interaction_authorization() -> void:
	if room_runtime_view == null or player_controller == null:
		_clear_exit_interaction_authorization()
		return
	var room_snapshot: Dictionary = room_runtime_view.build_read_only_snapshot()
	pending_exit_interaction_id = String(room_snapshot.get("focused_interaction_id", ""))
	pending_exit_interaction_position = player_controller.get_local_position()
	pending_exit_interaction_authorized = not pending_exit_interaction_id.is_empty()


func _exit_interaction_authorization_matches() -> bool:
	if not pending_exit_interaction_authorized or room_runtime_view == null or player_controller == null:
		return false
	var room_snapshot: Dictionary = room_runtime_view.build_read_only_snapshot()
	return (
		String(room_snapshot.get("focused_interaction_id", "")) == pending_exit_interaction_id
		and player_controller.get_local_position().distance_to(pending_exit_interaction_position) <= 0.001
	)


func _clear_exit_interaction_authorization() -> void:
	pending_exit_interaction_id = ""
	pending_exit_interaction_position = Vector2.ZERO
	pending_exit_interaction_authorized = false


func _request_combat_flee_from_ui() -> void:
	if in_run_runtime == null or not in_run_runtime.has_active_combat() or player_controller == null:
		return
	var direction := _combat_flee_direction_for_player()
	if direction == Vector2i.ZERO:
		_show_command_feedback({
			"ok": false,
			"accepted": false,
			"reason": &"combat_flee_door_required",
			"message": "请先靠近一处可通行的门，再使用 %s 撤离战斗。" % SemanticActionHintScript.display_label(&"request_extract"),
		})
		return
	_show_combat_flee_panel(direction)


func _show_combat_flee_panel(direction: Vector2i) -> void:
	if extract_panel == null or _is_runtime_modal_open():
		return
	extract_modal_mode = &"combat_flee"
	pending_combat_flee_direction = direction
	extract_title_label.text = "确认逃离战斗"
	extract_body_label.text = "逃离会失去当前楼层黑资的 10%。部分 T1 非消耗品可能遗留在本房间；具体结果以确认后的结算为准。"
	_clear_extract_item_preview()
	extract_confirm_button.text = "确认逃离"
	extract_cancel_button.text = "继续战斗"
	if run_surface != null:
		run_surface.apply_legacy_modal_style(extract_panel, &"ui.danger")
		run_surface.apply_legacy_button_style(extract_confirm_button, &"danger")
		run_surface.apply_legacy_button_style(extract_cancel_button, &"secondary")
	extract_title_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.danger"))
	_apply_runtime_modal_layout(_current_layout_profile())
	var pushed := _push_runtime_modal(
		&"combat_flee_confirm",
		extract_panel,
		extract_cancel_button,
		Callable(self, "_cancel_combat_flee_modal")
	)
	if not pushed:
		extract_panel.hide()
		pending_combat_flee_direction = Vector2i.ZERO


func _apply_extract_item_preview(item_models: Array[Dictionary]) -> void:
	if extract_items_scroll == null or extract_items_box == null:
		return
	_clear_extract_item_preview()
	extract_items_scroll.visible = true
	if item_models.is_empty():
		var empty_label := Label.new()
		empty_label.name = "ExtractCarriedItemsEmpty"
		empty_label.text = "没有随身物资可带回。"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		extract_items_box.add_child(empty_label)
		return
	var heading := Label.new()
	heading.name = "ExtractCarriedItemsHeading"
	heading.text = "本次带回物资 · %d 件" % item_models.size()
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
	extract_items_box.add_child(heading)
	for index in range(item_models.size()):
		var item_row := _build_extract_item_row(item_models[index])
		item_row.name = "ExtractCarriedItemRow%d" % index
		extract_items_box.add_child(item_row)


func _clear_extract_item_preview() -> void:
	if extract_items_box != null:
		for child in extract_items_box.get_children():
			extract_items_box.remove_child(child)
			child.queue_free()
	if extract_items_scroll != null:
		extract_items_scroll.visible = false


func _build_extract_item_row(item_model: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "ExtractCarriedItemRow"
	row.custom_minimum_size = Vector2(0, 46)
	row.tooltip_text = String(item_model.get("detail_text", ""))
	row.set_meta("instance_id", String(item_model.get("instance_id", "")))
	row.set_meta("collectible_level", int(item_model.get("collectible_level", 0)))
	var rarity: Dictionary = item_model.get("rarity", {}) if item_model.get("rarity", {}) is Dictionary else {}
	row.set_meta("rarity_border_token", rarity.get("border_token", &"rarity.border.unknown"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.028, 0.031, 0.92)
	style.border_color = Color(0.20, 0.50, 0.46, 0.56)
	style.set_border_width_all(1)
	style.content_margin_left = 6
	style.content_margin_top = 4
	style.content_margin_right = 6
	style.content_margin_bottom = 4
	row.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 7)
	row.add_child(line)
	var marker := ColorRect.new()
	marker.name = "ExtractItemRarityMarker"
	marker.custom_minimum_size = Vector2(4, 36)
	marker.color = Color(rarity.get("color", PresentationTheme.color_for_key(&"ui.muted")))
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.set_meta("rarity_border_token", rarity.get("border_token", &"rarity.border.unknown"))
	line.add_child(marker)
	var copy := VBoxContainer.new()
	copy.name = "ExtractItemCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	line.add_child(copy)
	var name_label := Label.new()
	name_label.name = "ExtractItemName"
	name_label.text = "%s ×%d" % [
		String(item_model.get("display_name", "未命名物资")),
		int(item_model.get("quantity", 1)),
	]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", PresentationTheme.text_color())
	copy.add_child(name_label)
	var item_meta: Array[String] = [String(item_model.get("rarity_text", "[?] 未鉴定"))]
	var collectible_level_text := String(item_model.get("collectible_level_text", ""))
	if collectible_level_text != "":
		item_meta.append(collectible_level_text)
	item_meta.append("重 %d" % int(item_model.get("weight", 0)))
	var meta_label := Label.new()
	meta_label.name = "ExtractItemMeta"
	meta_label.text = " · ".join(item_meta)
	meta_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	meta_label.add_theme_font_size_override("font_size", 12)
	meta_label.add_theme_color_override("font_color", marker.color)
	copy.add_child(meta_label)
	return row


func _confirm_combat_flee_from_ui() -> void:
	if not _runtime_modal_is_top(&"combat_flee_confirm") or in_run_runtime == null:
		return
	var direction := pending_combat_flee_direction
	var transition_check := _g41_transition_precheck(direction)
	if direction == Vector2i.ZERO or not _is_player_near_combat_door(direction) or not bool(transition_check.get("ok", false)):
		_pop_runtime_modal(&"combat_flee_confirm")
		pending_combat_flee_direction = Vector2i.ZERO
		_show_command_feedback({
			"ok": false,
			"accepted": false,
			"reason": &"combat_flee_door_changed",
			"message": "当前位置已无法从该门撤离，请重新靠近有效出口。",
		})
		return
	var flee_result: Dictionary = in_run_runtime.request_flee()
	last_command_result = flee_result.duplicate(true)
	_show_command_feedback(flee_result)
	if not bool(flee_result.get("ok", false)):
		_pop_runtime_modal(&"combat_flee_confirm")
		return
	_pop_runtime_modal(&"combat_flee_confirm", false)
	_reset_transition_rejection_debounce()
	_attempt_room_transition(direction)


func _cancel_combat_flee_modal(_reason: StringName = &"cancel") -> void:
	if not _runtime_modal_is_top(&"combat_flee_confirm"):
		return
	_pop_runtime_modal(&"combat_flee_confirm")
	pending_combat_flee_direction = Vector2i.ZERO


func _combat_flee_direction_for_player() -> Vector2i:
	if player_controller == null:
		return Vector2i.ZERO
	if pending_combat_flee_direction != Vector2i.ZERO and _is_player_near_combat_door(pending_combat_flee_direction):
		var pending_check := _g41_transition_precheck(pending_combat_flee_direction)
		if bool(pending_check.get("ok", false)):
			return pending_combat_flee_direction
	var local_pos: Vector2 = player_controller.get_local_position()
	var candidates: Array[Vector2i] = []
	if local_pos.x <= COMBAT_FLEE_EDGE_DISTANCE and absf(local_pos.y - 0.5) <= COMBAT_FLEE_DOOR_ALIGN_HALF:
		candidates.append(Vector2i.LEFT)
	if local_pos.x >= 1.0 - COMBAT_FLEE_EDGE_DISTANCE and absf(local_pos.y - 0.5) <= COMBAT_FLEE_DOOR_ALIGN_HALF:
		candidates.append(Vector2i.RIGHT)
	if local_pos.y <= COMBAT_FLEE_EDGE_DISTANCE and absf(local_pos.x - 0.5) <= COMBAT_FLEE_DOOR_ALIGN_HALF:
		candidates.append(Vector2i.UP)
	if local_pos.y >= 1.0 - COMBAT_FLEE_EDGE_DISTANCE and absf(local_pos.x - 0.5) <= COMBAT_FLEE_DOOR_ALIGN_HALF:
		candidates.append(Vector2i.DOWN)
	var facing: Vector2 = player_controller.get_facing_vector()
	var best_direction := Vector2i.ZERO
	var best_alignment := -2.0
	for candidate in candidates:
		var transition_check := _g41_transition_precheck(candidate)
		if not bool(transition_check.get("ok", false)):
			continue
		var alignment := facing.dot(Vector2(candidate))
		if alignment > best_alignment:
			best_alignment = alignment
			best_direction = candidate
	return best_direction


func _is_player_near_combat_door(direction: Vector2i) -> bool:
	if player_controller == null:
		return false
	var local_pos: Vector2 = player_controller.get_local_position()
	if direction == Vector2i.LEFT:
		return local_pos.x <= COMBAT_FLEE_EDGE_DISTANCE and absf(local_pos.y - 0.5) <= COMBAT_FLEE_DOOR_ALIGN_HALF
	if direction == Vector2i.RIGHT:
		return local_pos.x >= 1.0 - COMBAT_FLEE_EDGE_DISTANCE and absf(local_pos.y - 0.5) <= COMBAT_FLEE_DOOR_ALIGN_HALF
	if direction == Vector2i.UP:
		return local_pos.y <= COMBAT_FLEE_EDGE_DISTANCE and absf(local_pos.x - 0.5) <= COMBAT_FLEE_DOOR_ALIGN_HALF
	if direction == Vector2i.DOWN:
		return local_pos.y >= 1.0 - COMBAT_FLEE_EDGE_DISTANCE and absf(local_pos.x - 0.5) <= COMBAT_FLEE_DOOR_ALIGN_HALF
	return false


func _show_loot_panel(title: String, reward: Dictionary) -> void:
	if loot_panel == null or _is_runtime_modal_open():
		return
	_apply_runtime_modal_layout(_current_layout_profile())
	var pushed := _push_runtime_modal(
		&"loot_result",
		loot_panel,
		_preferred_modal_focus(loot_panel),
		Callable(self, "_cancel_loot_modal")
	)
	if not pushed:
		return
	loot_panel.call("show_result", title, reward, String(run_context.last_message))
	_refresh_view_models()


func _cancel_loot_modal(_reason: StringName = &"cancel") -> void:
	if _runtime_modal_is_top(&"loot_result"):
		_pop_runtime_modal(&"loot_result")


func _show_world_reward_feedback(result: Dictionary, reward: Dictionary, source: StringName) -> void:
	var ground_count := _reward_array_size(reward, "ground_items")
	var backpack_count := _reward_array_size(reward, "inventory_items") + _reward_array_size(reward, "equipped_items")
	var feedback := result.duplicate(true)
	if source == &"event" or source == &"encounter":
		feedback["message"] = RunSurfaceModel.event_result_feedback_text(reward)
	elif ground_count > 0:
		feedback["message"] = "发现 %d 件物资，已落在附近地面。靠近后可查看并拾取。" % ground_count
	elif backpack_count > 0:
		feedback["message"] = "回收 %d 件物资，已装入临时回收包。" % backpack_count
	elif source == &"combat":
		feedback["message"] = "威胁已清除，房间恢复通行。"
	else:
		feedback["message"] = "搜索完成，未发现新的可回收物。"
	feedback["ok"] = bool(result.get("ok", true))
	var cue := PlayerFeedbackServiceScript.CUE_UI_CONFIRM
	if not bool(feedback.get("ok", false)):
		cue = PlayerFeedbackServiceScript.CUE_UI_REJECT
	elif source == &"search":
		cue = PlayerFeedbackServiceScript.CUE_SEARCH_REVEAL
	elif source == &"combat":
		cue = PlayerFeedbackServiceScript.CUE_ENEMY_DEATH
	if source == &"search" and bool(feedback.get("ok", false)):
		_emit_feedback_for_result(feedback, cue, _feedback_event_id(String(source), result))
		if run_surface != null:
			run_surface.clear_command_feedback()
		return
	_show_command_feedback(feedback, cue, _feedback_event_id(String(source), result))


func _reward_array_size(reward: Dictionary, key: String) -> int:
	var value: Variant = reward.get(key, [])
	return (value as Array).size() if value is Array else 0


func _debug_restart_run_from_ui() -> void:
	var result := _dispatch_command(&"debug_restart_run")
	if bool(result.get("ok", false)) and player_controller != null:
		player_controller.reset_local_position()


func _event_type_label(event_type: StringName) -> String:
	match event_type:
		&"trader":
			return "旅商"
		&"dice":
			return "骰局"
		&"altar":
			return "祭坛"
		&"trap":
			return "机关"
		_:
			return "异常事件"


func _run_room_label(room_type: StringName) -> String:
	match room_type:
		&"Normal":
			return "普通房间"
		&"Chest":
			return "回收物资房"
		&"Monster":
			return "战斗房"
		&"Event":
			return "异常事件房"
		&"Mine":
			return "雷险房"
		&"Exit":
			return "撤离点"
		_:
			return "未知区域"


func _is_runtime_modal_open() -> bool:
	return (
		(modal_controller != null and modal_controller.blocks_gameplay_input())
		or (event_panel != null and event_panel.visible)
		or (loot_panel != null and loot_panel.visible)
		or (extract_panel != null and extract_panel.visible)
		or (ground_loot_panel != null and ground_loot_panel.visible)
		or (result_panel != null and result_panel.visible)
		or (dev_diagnostics_panel != null and dev_diagnostics_panel.visible)
		or (debug_panel != null and debug_panel.visible)
	)


func _sync_player_input_enabled() -> void:
	if player_controller == null:
		return
	var gameplay_input_enabled := (
		screen_state == SCREEN_RUN
		and run_context != null
		and not _is_runtime_modal_open()
		and (map_overlay_panel == null or not map_overlay_panel.visible)
		and not run_context.has_blocking_tutorial_popup()
	)
	player_controller.set_input_enabled(gameplay_input_enabled)


func _close_top_runtime_modal() -> bool:
	if modal_controller != null and modal_controller.depth() > 0:
		return bool(modal_controller.request_cancel_top(&"input_cancel"))
	if debug_panel != null and debug_panel.visible:
		debug_panel_controller.close_panel()
		return true
	if ground_loot_panel != null and ground_loot_panel.visible:
		ground_loot_panel.call("hide_panel")
		get_viewport().gui_release_focus()
		return true
	if dev_diagnostics_panel != null and dev_diagnostics_panel.visible:
		dev_diagnostics_panel.call("hide_panel")
		return true
	return false


func _hide_runtime_popups() -> void:
	_clear_runtime_modal_stack(false)
	extract_modal_mode = &"extract"
	pending_combat_flee_direction = Vector2i.ZERO
	_clear_exit_interaction_authorization()
	if event_panel != null:
		event_panel.visible = false
	if loot_panel != null:
		loot_panel.call("hide_panel")
	if extract_panel != null:
		extract_panel.visible = false
	if inventory_panel != null:
		inventory_panel.call("hide_panel")
	if ground_loot_panel != null:
		ground_loot_panel.call("hide_panel")
	if result_panel != null:
		result_panel.hide_result()
	if pause_panel != null:
		pause_panel.visible = false
	if dev_diagnostics_panel != null:
		dev_diagnostics_panel.call("hide_panel")
	if debug_panel_controller != null:
		debug_panel_controller.hide_panel(false)
	if map_overlay_panel != null:
		map_overlay_panel.hide_overlay()


func _on_state_changed(snapshot: Dictionary) -> void:
	refresh_controller.route_state_change(snapshot, Callable(self, "_apply_full_view_models"))
	_sync_player_input_enabled()


func _on_result_available(snapshot: Dictionary) -> void:
	screen_state = SCREEN_RUN
	_set_gameplay_visible(true)
	run_overlay_root.show()
	var outcome := String(snapshot.get("outcome", ""))
	var result_cue := (
		PlayerFeedbackServiceScript.CUE_EXTRACTION_SUCCESS
		if outcome in ["Extracted", "Training Complete"]
		else PlayerFeedbackServiceScript.CUE_EXTRACTION_FAILURE
	)
	_emit_feedback_cue(
		result_cue,
		"result:%s" % String(snapshot.get("result_id", "%s:%s" % [String(run_context.run_id), outcome])),
		{"outcome": outcome, "terminal_reason_code": snapshot.get("terminal_reason_code", &"")}
	)
	var display_snapshot := _build_result_display_snapshot(snapshot)
	_refresh_view_models()
	_hide_runtime_popups()
	if result_panel != null:
		result_panel.show_summary(display_snapshot)
		var pushed := _push_runtime_modal(
			&"result",
			result_panel,
			_preferred_modal_focus(result_panel),
			Callable(self, "_cancel_result_modal")
		)
		if not pushed:
			result_panel.hide_result()


func _cancel_result_modal(_reason: StringName = &"cancel") -> void:
	if not _runtime_modal_is_top(&"result"):
		return
	if result_panel != null and result_panel.requires_salvage_confirmation():
		return
	if result_panel != null and not result_panel.normal_exit_allowed():
		return
	_return_from_result_to_deploy()


func _confirm_failure_salvage_from_result(selected_instance_ids: Array) -> void:
	if not _runtime_modal_is_top(&"result"):
		return
	var result := _dispatch_command(&"confirm_failure_salvage", {"selected_instance_ids": selected_instance_ids})
	if not bool(result.get("ok", false)) and result_panel != null:
		result_panel.show_summary(_build_result_display_snapshot(run_context.result_snapshot))


func _retry_terminal_commit_from_result() -> void:
	if not _runtime_modal_is_top(&"result") or result_panel == null or not result_panel.retry_save_allowed():
		return
	_dispatch_command(&"retry_terminal_commit", {"source": "result_panel"}, false, false)
	result_panel.update_persistence_state(_build_result_display_snapshot(run_context.result_snapshot))
	result_panel.mark_retry_complete()


func _discard_unsaved_result_from_result() -> void:
	if not _runtime_modal_is_top(&"result") or result_panel == null or not result_panel.discard_unsaved_allowed():
		return
	# The panel owns the first/second confirmation interaction. The second
	# confirmation must still cross the runtime authority before the UI leaves,
	# otherwise carry-in instances would remain protected behind a hidden
	# save-failure result.
	var discard_result := _dispatch_command(
		&"discard_unsaved_terminal_commit",
		{"confirmed": true, "source": "result_panel"},
		false,
		false
	)
	if not bool(discard_result.get("ok", false)):
		result_panel.show_summary(_build_result_display_snapshot(run_context.result_snapshot))
		return
	_pop_runtime_modal(&"result", false)
	get_viewport().gui_release_focus()
	_show_deploy_shell(&"config")


func _build_result_display_snapshot(snapshot: Dictionary) -> Dictionary:
	var commit: Dictionary = runtime_controller.last_meta_commit if runtime_controller != null else {}
	return RunSceneResultControllerScript.build_result_display_snapshot(snapshot, _meta_progress_summary(), commit)


func get_refresh_metrics() -> Dictionary:
	return refresh_controller.get_metrics()


func reset_refresh_metrics() -> void:
	refresh_controller.reset_metrics()


func _full_refresh_count() -> int:
	if refresh_controller == null:
		return 0
	return int(refresh_controller.get_metrics().get("full_count", 0))


func _refresh_if_dispatch_was_unsignaled(refresh_count_before: int) -> void:
	if refresh_controller == null:
		return
	if _full_refresh_count() <= refresh_count_before:
		_refresh_view_models()


func _refresh_view_models() -> void:
	if run_context == null:
		return
	refresh_controller.run_full_refresh(Callable(self, "_apply_full_view_models"))


func _apply_full_view_models() -> void:
	var snapshot := _shell_snapshot()
	var layout_profile: Dictionary = _current_layout_profile()
	_apply_runtime_modal_layout(layout_profile)
	_apply_game_stage_layout(layout_profile)
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	if gameplay_backdrop != null:
		gameplay_backdrop.apply_room_type(StringName(snapshot.get("current_room", &"Normal")))
	var minimap_vm := RunSceneUIBridgeScript.minimap_from_snapshot_or_intel(snapshot, run_context)
	if run_surface != null:
		var surface_model := RunSceneUIBridgeScript.build_surface_model(snapshot, minimap_vm, layout_profile, last_command_result)
		run_surface.apply_layout_profile(layout_profile)
		run_surface.apply_surface_model(surface_model)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", snapshot)
	if run_surface == null and room_badge != null:
		room_badge.text = "模式：%s | 阶段：%s | 房间：%s\n坐标：(%d,%d) | 周围雷险：%s" % [
			String(snapshot.get("mode", &"")),
			String(snapshot.get("phase", &"")),
			String(snapshot.get("current_room", &"Unknown")),
			pos.x,
			pos.y,
			snapshot.get("adjacent_mines", 0),
		]
	if run_surface == null and protocol_badge != null:
		protocol_badge.text = "协议 %s\n压力：%s / 100\n状态：%s\n地面物品：%s" % [
			snapshot.get("protocol_level", 5),
			snapshot.get("pressure", 0),
			snapshot.get("outcome", "Running"),
			snapshot.get("room_floor_item_count", 0),
		]
	if room_controller != null:
		room_controller.configure(PresentationMapping.room_visual_from_snapshot(snapshot))
	_apply_player_presentation()
	if in_run_runtime != null and player_controller != null:
		in_run_runtime.sync_room(player_controller.get_local_position())
	if room_runtime_view != null:
		room_runtime_view.configure_room(snapshot)
		room_runtime_view.apply_combat_snapshot(in_run_runtime.build_read_only_snapshot() if in_run_runtime != null else {})
		if player_controller != null:
			player_controller.set_logical_obstacles(room_runtime_view.get_logical_obstacles())
			player_controller.set_door_projections(room_runtime_view.get_door_projections())
	_suppress_runtime_scene_labels()
	if hud != null:
		hud.apply_layout_profile(layout_profile)
		hud.apply_view_model(HUDViewModel.build_from_snapshot(snapshot))
	if minimap_panel != null:
		minimap_panel.apply_layout_profile(layout_profile)
		minimap_panel.apply_view_model(minimap_vm)
	if map_overlay_panel != null:
		map_overlay_panel.apply_layout_profile(layout_profile)
		map_overlay_panel.apply_view_model(minimap_vm)
	if run_surface == null and layout_profile_label != null:
		layout_profile_label.text = "Layout: %s" % current_layout_profile_id
	if tutorial_popup_panel != null:
		tutorial_popup_panel.set_presentation_occluded(map_overlay_panel != null and map_overlay_panel.visible)
		tutorial_popup_panel.apply_layout_profile(layout_profile)
		tutorial_popup_panel.apply_popup(snapshot.get("tutorial_popup", {}))
	if inventory_panel != null:
		inventory_panel.call("apply_layout_profile", layout_profile)
		inventory_panel.call("apply_snapshot", snapshot)
	if ground_loot_panel != null:
		ground_loot_panel.call("apply_layout_profile", layout_profile)
		ground_loot_panel.call("apply_snapshot", snapshot)
	if result_panel != null:
		result_panel.apply_layout_profile(layout_profile)
	if dev_diagnostics_panel != null and dev_diagnostics_panel.visible:
		_apply_dev_diagnostics(snapshot)
	if debug_log != null:
		debug_panel_controller.set_log_text(String(snapshot.get("last_message", "")))
	if debug_panel != null and debug_panel.visible:
		debug_panel_controller.sync_coordinates()
	if result_panel != null and bool(snapshot.get("run_active", false)):
		result_panel.hide_result()


func _apply_player_presentation() -> void:
	if player_controller == null:
		return
	var appearance_config: Variant = {}
	if run_context != null:
		appearance_config = run_context.run_start_config.get("player_appearance", {})
	var presentation := PlayerAppearanceConfigScript.runtime_presentation(appearance_config)
	var selection_id := StringName(presentation.get(
		"selection_id",
		PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID
	))
	var appearance_id := StringName(presentation.get(
		"appearance_id",
		PlayerAppearanceConfigScript.DEFAULT_APPEARANCE_ID
	))
	var animation_set_id := StringName(presentation.get(
		"animation_set_id",
		PlayerAppearanceConfigScript.DEFAULT_ANIMATION_SET_ID
	))
	var visual_modulate: Color = presentation.get(
		"visual_modulate",
		PlayerAppearanceConfigScript.DEFAULT_VISUAL_MODULATE
	)
	var current := player_controller.presentation_snapshot()
	var current_visual_modulate: Color = current.get("visual_modulate", Color.WHITE)
	if (
		StringName(current.get("selection_id", &"")) == selection_id
		and StringName(current.get("appearance_id", &"")) == appearance_id
		and StringName(current.get("animation_set_id", &"")) == animation_set_id
		and current_visual_modulate.is_equal_approx(visual_modulate)
	):
		return
	var registered_sets: Dictionary = {}
	var animation_set: Variant = presentation.get("animation_set", {})
	if animation_set is Dictionary and not (animation_set as Dictionary).is_empty():
		registered_sets[animation_set_id] = (animation_set as Dictionary).duplicate(true)
	player_controller.set_presentation_profile(
		appearance_id,
		animation_set_id,
		registered_sets,
		selection_id,
		visual_modulate
	)


func _build_hud_view_model(snapshot: Dictionary) -> HUDViewModel:
	return HUDViewModel.build_from_snapshot(snapshot)


func _apply_game_stage_layout(layout_profile: Dictionary) -> void:
	var room_layer := get_node_or_null("RoomLayer") as Node2D
	var player_layer := get_node_or_null("PlayerLayer") as Node2D
	if room_layer == null or player_layer == null:
		return
	var viewport_size := UILayerContractScript.viewport_size_from_profile(layout_profile)
	var width: float = maxf(1.0, viewport_size.x)
	var height: float = maxf(1.0, viewport_size.y)
	var left_width: float = UILayerContractScript.run_left_width(layout_profile)
	var gameplay_width: float = maxf(1.0, width - left_width)
	if gameplay_backdrop != null:
		gameplay_backdrop.apply_layout(viewport_size, left_width)
	var room_visual_size := Vector2(560.0, 560.0)
	var room_visual_center := Vector2(640.0, 360.0)
	if room_controller != null:
		var background_sprite := room_controller.get_node_or_null("Background/BackgroundSprite") as Sprite2D
		if background_sprite != null:
			room_visual_center = background_sprite.position
			if background_sprite.texture != null:
				room_visual_size = background_sprite.texture.get_size() * background_sprite.scale.abs()
	# The room, UE-aligned mine-risk plate, contextual information band and key
	# dock are four distinct vertical regions. The former hotbar-only budget let
	# the room extend underneath the other two frames and obscured its lower door.
	var footer_geometry := UILayerContractScript.run_footer_geometry(layout_profile)
	var room_top := 8.0
	var room_bottom := float(footer_geometry.get("room_bottom", height - 160.0))
	var stage_rect := Rect2(left_width, room_top, gameplay_width, maxf(1.0, room_bottom - room_top))
	if run_context != null and not run_context.tutorial_popup.is_empty():
		var blocking := bool(run_context.tutorial_popup.get("blocking", false))
		stage_rect = UILayerContractScript.run_tutorial_geometry(layout_profile, blocking).get(
			"room_stage_rect",
			stage_rect
		)
	var scale_value: float = minf(
		stage_rect.size.x / maxf(1.0, room_visual_size.x),
		stage_rect.size.y / maxf(1.0, room_visual_size.y)
	)
	# Tutorial copy owns a real safe zone beside the room. A 0.90 lower clamp
	# ignored that contract and let the room spill back underneath the modal.
	scale_value = clampf(scale_value, 0.32, 1.82)
	var gameplay_center := stage_rect.get_center()
	var origin := gameplay_center - room_visual_center * scale_value
	room_layer.position = origin
	player_layer.position = origin
	room_layer.scale = Vector2(scale_value, scale_value)
	player_layer.scale = Vector2(scale_value, scale_value)


func _suppress_runtime_scene_labels() -> void:
	if room_controller != null:
		var room_title := room_controller.get_node_or_null("RoomTitle") as Label
		if room_title != null:
			room_title.visible = false
			room_title.text = ""
		var legacy_prop := room_controller.get_node_or_null("Interactables/PropSprite") as Sprite2D
		if legacy_prop != null and room_runtime_view != null and room_runtime_view.room_type in [&"Chest", &"Event", &"Mine", &"Exit"]:
			# These room types now use the governed world-interaction projection.
			# Keeping the old centered prop would duplicate or misalign the target.
			legacy_prop.visible = false
	if player_controller != null:
		var player_label := player_controller.get_node_or_null("Label") as Label
		if player_label != null:
			player_label.visible = false
			player_label.text = ""


func _current_layout_profile() -> Dictionary:
	var viewport_size: Vector2 = get_viewport_rect().size
	var window := get_window()
	if window != null and window.size.x > 0 and window.size.y > 0:
		var window_size := Vector2(float(window.size.x), float(window.size.y))
		viewport_size = Vector2(min(viewport_size.x, window_size.x), min(viewport_size.y, window_size.y))
	var requested_resolution_size := Vector2i.ZERO
	if SettingsManager != null:
		requested_resolution_size = SettingsManager.get_current_resolution_size()
	var profile: Dictionary = UILayoutProfileScript.profile_for_size(viewport_size)
	profile["actual_viewport_size"] = Vector2i(int(viewport_size.x), int(viewport_size.y))
	profile["requested_resolution_size"] = requested_resolution_size
	profile["ui_scale_factor"] = _ui_scale_factor
	current_layout_profile_id = StringName(profile.get("profile_id", &"desktop"))
	return profile


func _show_dev_diagnostics_panel() -> void:
	var policy: Dictionary = DevDiagnosticsPanelScript.DEV_ONLY_POLICY
	var enabled: bool = G9ShellPanelScript.DEV_DIAGNOSTICS_ENABLED and bool(policy.get("dev_only", false)) and StringName(policy.get("unlock_condition", &"")) == &"dev_channel"
	if not enabled:
		_show_command_feedback({
			"ok": false,
			"accepted": false,
			"reason_code": &"dev_diagnostics_hidden",
			"message_key": &"ui.dev_diagnostics.hidden",
			"command_id": &"open_dev_diagnostics",
		})
		return
	if dev_diagnostics_panel == null:
		return
	var snapshot: Dictionary = {}
	if run_context != null:
		snapshot = run_context.get_status_snapshot()
	_apply_dev_diagnostics(snapshot)
	dev_diagnostics_panel.call("show_panel")


func _apply_dev_diagnostics(snapshot: Dictionary) -> void:
	if dev_diagnostics_panel == null:
		return
	var ui_state: Dictionary = {
		"page": screen_state,
		"panel": "DevDiagnosticsPanel",
		"layout_profile": current_layout_profile_id,
	}
	var art_report: Dictionary = G10ArtSmokeRegistry.build_smoke_report()
	dev_diagnostics_panel.call("apply_diagnostics", snapshot, last_command_result, ui_state, art_report)


func _dispatch_command(
	command_name: StringName,
	payload: Dictionary = {},
	release_focus: bool = true,
	show_feedback: bool = true
) -> Dictionary:
	if command_bus == null:
		return {}
	var result: Dictionary = command_bus.dispatch(command_name, payload)
	last_command_result = result.duplicate(true)
	_apply_room_entry_result(result)
	if show_feedback:
		_show_command_feedback(result)
	if release_focus:
		get_viewport().gui_release_focus()
	return result


func _show_command_feedback(
	result: Dictionary,
	cue_override: StringName = &"",
	event_id: String = ""
) -> void:
	_emit_feedback_for_result(result, cue_override, event_id)
	RunSceneCommandFeedbackScript.apply_feedback(
		result,
		run_surface,
		command_result_label,
		inventory_panel,
		ground_loot_panel,
		Callable(self, "_flash_blocked_reason")
	)


func _emit_feedback_for_result(
	result: Dictionary,
	cue_override: StringName = &"",
	event_id: String = ""
) -> void:
	if player_feedback_service == null or result.is_empty():
		return
	var resolved_event_id := event_id
	if resolved_event_id.is_empty():
		resolved_event_id = _feedback_event_id("command", result)
	player_feedback_service.emit_command_result(result, cue_override, resolved_event_id)


func _emit_feedback_cue(
	cue_id: StringName,
	event_id: String,
	metadata: Dictionary = {}
) -> void:
	if player_feedback_service != null:
		player_feedback_service.emit_cue(cue_id, event_id, metadata)


func _feedback_event_id(prefix: String, result: Dictionary) -> String:
	var request_id := String(result.get(
		"rule_request_id",
		result.get("request_id", result.get("command_request_id", ""))
	))
	if request_id.is_empty():
		return ""
	var command_id := String(result.get("command_id", ""))
	var status := String(result.get("status", result.get("reason", result.get("blocked_reason", ""))))
	return "%s:%s:%s:%s" % [prefix, command_id, request_id, status]


func _route_combat_domain_feedback(combat_snapshot: Dictionary) -> void:
	var room_key := String(combat_snapshot.get("room_key", ""))
	var seed := int(combat_snapshot.get("seed", 0))
	for raw_event in combat_snapshot.get("recent_events", []):
		if not raw_event is Dictionary:
			continue
		var event: Dictionary = raw_event
		var event_index := int(event.get("event_index", -1))
		var event_id := "combat:%s:%d:%d" % [room_key, seed, event_index]
		if _processed_combat_feedback_events.has(event_id):
			continue
		_processed_combat_feedback_events[event_id] = true
		var event_type := StringName(event.get("event_type", &""))
		match event_type:
			&"player_attack_started":
				_emit_feedback_cue(PlayerFeedbackServiceScript.CUE_ATTACK, event_id, event)
			&"player_attack_resolved":
				RunSceneCommandFeedbackScript.route_combat_attack_resolution(event, event_id, PlayerFeedbackServiceScript.CUE_HIT, Callable(self, "_emit_feedback_cue"), Callable(self, "_show_command_feedback"))
			&"player_damaged":
				if not bool(combat_snapshot.get("defeated", false)):
					_emit_feedback_cue(PlayerFeedbackServiceScript.CUE_PLAYER_HURT, event_id, event)
			&"enemy_defeated":
				_emit_feedback_cue(PlayerFeedbackServiceScript.CUE_ENEMY_DEATH, event_id, event)


func _flash_blocked_reason() -> void:
	if command_result_label == null:
		return
	command_result_label.name = "BlockedReasonFlash"
	var tween: Tween = create_tween()
	tween.tween_property(command_result_label, "modulate", Color(1.0, 0.55, 0.35, 1.0), 0.06)
	tween.tween_property(command_result_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)


func _open_map_from_ui(source: StringName = &"button") -> void:
	if map_overlay_panel == null:
		return
	if map_overlay_panel.visible:
		# Closing belongs to the overlay's own close/outside-click/Esc paths.
		# A shielded RunSurface signal must not be able to dismiss the top modal.
		return
	var top_modal: StringName = modal_controller.top_modal_id() if modal_controller != null else &""
	if top_modal not in [&"", &"inventory"]:
		return
	# A shielded RunSurface cannot legitimately click through the inventory.
	# Only the audited run-action shortcut may open the read-only child map.
	if top_modal == &"inventory" and source != &"keyboard":
		return
	if _is_runtime_modal_open() and top_modal != &"inventory":
		return
	map_overlay_panel.show_overlay()
	var pushed := _push_runtime_modal(
		&"map",
		map_overlay_panel,
		_preferred_modal_focus(map_overlay_panel),
		Callable(self, "_cancel_map_modal")
	)
	if not pushed:
		map_overlay_panel.hide_overlay()
		return
	_dispatch_command(&"open_map", {"source": source}, false, false)
	map_overlay_panel.show_open_feedback(source)


func _toggle_debug_panel() -> void:
	debug_panel_controller.toggle_panel()


func _open_debug_panel() -> void:
	debug_panel_controller.open_panel()


func _debug_teleport_to_room_type(room_type: StringName) -> void:
	debug_panel_controller.teleport_to_room_type(room_type)


func _on_tutorial_popup_confirmed() -> void:
	_dispatch_command(&"confirm_tutorial_popup")


func _start_standard_from_ui() -> void:
	_show_deploy_shell(&"config")
	if deploy_shell_panel != null and deploy_shell_panel.has_method("_on_primary_action_pressed"):
		deploy_shell_panel.call("_on_primary_action_pressed")


func _start_run_from_route(intent: Dictionary) -> void:
	var payload := NavigationIntentScript.payload(intent)
	if bool(payload.get("continue_active_run", false)):
		if run_context != null and run_context.run_active:
			last_command_result = {"ok": true, "status": &"continued_active_run"}
			_show_run_screen()
		else:
			last_command_result = {"ok": false, "status": &"no_active_run", "reason": "no_active_run_to_continue"}
			_show_command_feedback(last_command_result)
		return
	if bool(payload.get("abandon_active_run", false)):
		var abandon_payload := {"reason": String(payload.get("reason", "player_deploy_abandon")), "source": "deploy_prep", "confirmed": payload.get("confirmed", false)}
		var abandon_result := _dispatch_command(&"abandon_run", abandon_payload)
		if not bool(abandon_result.get("ok", false)):
			_show_deploy_shell(&"config")
			var abandon_feedback := "请在放弃确认窗口中再次确认；当前探索保持不变。" if StringName(abandon_result.get("status", &"")) == &"abandon_confirmation_required" else "放弃未完成，当前探索保持不变。"
			deploy_shell_panel.call("show_action_message", abandon_feedback)
		return
	var route_result := RunSceneRouteControllerScript.start_from_intent(
		intent,
		command_bus,
		Callable(self, "_run_start_asset_admission")
	)
	var admission_result: Dictionary = route_result.get("admission_result", {})
	if not bool(route_result.get("ok", false)) and not admission_result.is_empty() and not bool(admission_result.get("ok", false)):
		_record_combat_texture_prewarm_failure(admission_result)
		return
	var command_result: Dictionary = route_result.get("command_result", route_result)
	var feedback_result := command_result
	if bool(command_result.get("ok", false)) and not bool(route_result.get("ok", false)):
		feedback_result = route_result
	last_command_result = feedback_result.duplicate(true)
	_show_command_feedback(feedback_result)
	if bool(route_result.get("player_reset_requested", false)) and player_controller != null:
		player_controller.reset_local_position()
	if bool(route_result.get("ok", false)):
		_processed_combat_feedback_events.clear()
		_reset_transition_rejection_debounce()
		if player_feedback_service != null:
			player_feedback_service.clear_history_and_deduplication()
		Art21R2RunSmokeSeederScript.seed_if_requested(command_result, command_bus, run_context)
	if bool(route_result.get("run_screen_requested", false)):
		_show_run_screen()


func _attempt_room_transition(direction: Vector2i) -> void:
	if RunSceneRouteControllerScript.transition_attempt_is_suppressed(direction, _transition_rejection_direction, _transition_rejection_cooldown_remaining, _transition_rejection_awaiting_release):
		return
	if in_run_runtime != null and in_run_runtime.has_active_combat():
		var transition_check := _g41_transition_precheck(direction)
		if not bool(transition_check.get("ok", false)):
			pending_combat_flee_direction = Vector2i.ZERO
			last_command_result = transition_check.duplicate(true)
			_present_transition_rejection(direction, transition_check)
			player_controller.block_transition(direction)
			return
		pending_combat_flee_direction = direction
		var combat_blocked := {
			"ok": false,
			"accepted": false,
			"reason": &"combat_door_locked",
			"message": "战斗封锁中。停在有效门边后使用 %s，确认代价再撤离。" % SemanticActionHintScript.display_label(&"request_extract"),
			"direction": direction,
		}
		last_command_result = combat_blocked.duplicate(true)
		_present_transition_rejection(direction, combat_blocked)
		player_controller.block_transition(direction)
		return
	var before := run_context.get_current_pos()
	var result: Dictionary = command_bus.dispatch(&"attempt_room_transition", {"direction": direction})
	last_command_result = result.duplicate(true)
	_apply_room_entry_result(result)
	var moved: bool = bool(result.get("ok", false)) and run_context.get_current_pos() != before
	if moved:
		_show_command_feedback(result)
		pending_combat_flee_direction = Vector2i.ZERO
		_reset_transition_rejection_debounce()
		var entry_position := player_controller.place_from_entry(direction)
		if in_run_runtime != null and in_run_runtime.has_active_combat():
			var combat_entry_result: Dictionary = in_run_runtime.place_player_from_room_entry(
				entry_position,
				direction
			)
			if bool(combat_entry_result.get("applied", false)):
				player_controller.set_local_position(Vector2(
					combat_entry_result.get("position", entry_position)
				))
	else:
		_present_transition_rejection(direction, result)
		player_controller.block_transition(direction)


func _advance_transition_rejection_debounce(delta: float, move_vector: Vector2) -> void:
	_transition_rejection_cooldown_remaining = maxf(
		0.0,
		_transition_rejection_cooldown_remaining - maxf(0.0, delta)
	)
	if not _transition_rejection_awaiting_release or _transition_rejection_direction == Vector2i.ZERO:
		return
	var held_alignment := move_vector.dot(Vector2(_transition_rejection_direction))
	if held_alignment <= TRANSITION_REJECTION_RELEASE_THRESHOLD:
		_transition_rejection_awaiting_release = false


func _present_transition_rejection(direction: Vector2i, result: Dictionary) -> bool:
	var same_edge := direction == _transition_rejection_direction
	if same_edge and (
		_transition_rejection_awaiting_release
		or _transition_rejection_cooldown_remaining > 0.0
	):
		return false
	_transition_rejection_direction = direction
	_transition_rejection_cooldown_remaining = TRANSITION_REJECTION_COOLDOWN_SECONDS
	_transition_rejection_awaiting_release = true
	_show_command_feedback(result)
	return true


func _reset_transition_rejection_debounce() -> void:
	_transition_rejection_direction = Vector2i.ZERO
	_transition_rejection_cooldown_remaining = 0.0
	_transition_rejection_awaiting_release = false


func _apply_room_entry_result(command_result: Dictionary) -> void:
	var entry_result: Dictionary = command_result.get("room_entry_result", {})
	if entry_result.is_empty():
		var action_result: Dictionary = command_result.get("action_result", {})
		entry_result = action_result.get("room_entry_result", {})
	if entry_result.is_empty():
		return
	if (
		StringName(entry_result.get("cause", &"")) == &"mine_triggered"
		and bool(entry_result.get("first_trigger", false))
	):
		var mine_position: Vector2i = entry_result.get("position", Vector2i.ZERO)
		_emit_feedback_cue(
			PlayerFeedbackServiceScript.CUE_MINE_EXPLOSION,
			"mine:%s:%d,%d" % [String(run_context.run_id), mine_position.x, mine_position.y],
			{
				"hp_delta": int(entry_result.get("hp_delta", 0)),
				"pressure_delta": int(entry_result.get("pressure_delta", 0)),
				"fatal": bool(entry_result.get("fatal", false)),
			}
		)
	if StringName(entry_result.get("room_type", &"Unknown")) == &"Exit" and bool(entry_result.get("first_explore", false)):
		# The resolver owns first-discovery authority. Presentation only replaces
		# the generic move acknowledgement with a non-blocking player notice.
		command_result["status"] = &"exit_discovered"
		command_result["message"] = "发现撤离信标。靠近信标可查看本次携带物资与预计保全情况，再决定是否撤离。"
	if room_runtime_view != null and room_runtime_view.has_method("apply_room_entry_result"):
		room_runtime_view.call("apply_room_entry_result", entry_result)
	if player_controller != null and int(entry_result.get("hp_delta", 0)) < 0:
		player_controller.set_runtime_visual_state(&"hurt")


func _g41_transition_precheck(direction: Vector2i) -> Dictionary:
	if run_context == null or abs(direction.x) + abs(direction.y) != 1:
		return {"ok": false, "reason": &"invalid_direction"}
	var target := run_context.get_current_pos() + direction
	if not run_context.is_inside(target):
		return {"ok": false, "reason": &"out_of_bounds", "message": "No door exists beyond this boundary."}
	if run_context.intel_map != null and run_context.intel_map.is_flagged(target):
		return {"ok": false, "reason": &"blocked_flagged", "message": "The target room is flagged."}
	if run_context.move_requires_revealed and run_context.intel_map != null and not run_context.intel_map.is_revealed(target):
		return {"ok": false, "reason": &"blocked_hidden", "message": "The target room is not revealed."}
	return {"ok": true, "target": target}


func _on_map_overlay_cell_action_requested(marker: Dictionary) -> void:
	if command_bus == null or run_context == null or not _runtime_modal_is_top(&"map"):
		return
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var action_id := StringName(marker.get("action_id", &"inspect"))
	if action_id == &"toggle_flag":
		var flag_result: Dictionary = _dispatch_command(&"toggle_flag_cell", {"pos": pos}, false)
		if map_overlay_panel != null:
			map_overlay_panel.show_action_feedback(marker, flag_result)
		return
	if action_id == &"fast_return":
		if in_run_runtime != null and in_run_runtime.has_active_combat():
			var blocked_fast_return := {"ok": false, "reason": &"combat_door_locked", "message": "Fast return is unavailable during combat; reach a door to flee."}
			last_command_result = blocked_fast_return.duplicate(true)
			if map_overlay_panel != null:
				map_overlay_panel.show_action_feedback(marker, blocked_fast_return)
			return
		var result: Dictionary = _dispatch_command(&"teleport_to_explored", {"pos": pos}, false)
		if map_overlay_panel != null:
			map_overlay_panel.show_action_feedback(marker, result)
		if bool(result.get("ok", false)):
			if player_controller != null:
				player_controller.reset_local_position()
			if map_overlay_panel != null:
				map_overlay_panel.hide_overlay()
		return
	if map_overlay_panel != null:
		map_overlay_panel.show_action_feedback(marker, MiniMapViewModel.action_result_for_marker(marker))


func _add_color_rect(parent: Control, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	color_rect.color = color
	color_rect.offset_left = rect.position.x
	color_rect.offset_top = rect.position.y
	color_rect.offset_right = rect.position.x + rect.size.x
	color_rect.offset_bottom = rect.position.y + rect.size.y
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)
	return color_rect


func _add_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.position.x + rect.size.x
	label.offset_bottom = rect.position.y + rect.size.y
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", PresentationTheme.text_color())
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _add_button(parent: Control, node_name: String, rect: Rect2, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.offset_left = rect.position.x
	button.offset_top = rect.position.y
	button.offset_right = rect.position.x + rect.size.x
	button.offset_bottom = rect.position.y + rect.size.y
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
func _set_control_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _add_menu_button(parent: Control, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(110, 34)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
