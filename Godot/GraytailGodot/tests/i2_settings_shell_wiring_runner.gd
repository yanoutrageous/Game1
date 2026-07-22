extends SceneTree

const SettingsManagerScript := preload("res://scripts/core/settings/settings_manager.gd")
const AppShellScript := preload("res://scripts/ui/app_shell/app_shell.gd")
const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const DeployPrepLayoutContractScript := preload("res://scripts/ui/deploy_prep/deploy_prep_layout_contract.gd")
const LongTermLayoutContractScript := preload("res://scripts/ui/long_term/long_term_layout_contract.gd")

const PASS_MARKER := "I2_SETTINGS_SHELL_WIRING=PASS"
const FAIL_MARKER := "I2_SETTINGS_SHELL_WIRING=FAIL"
const TEST_PATH := "user://i2_tests/settings_shell_wiring.cfg"
const DEFAULT_PATH := "user://settings.cfg"
const REDUCE_MOTION_KEY := "accessibility/reduce_motion"
const EXPECTED_FIELDS := [
	"window_mode",
	"resolution_id",
	"vsync_mode",
	"frame_limit",
	"master_volume",
	"reduce_motion",
]

var failures: Array[String] = []
var had_reduce_motion_setting := false
var previous_reduce_motion_value: Variant = null
var captured_page_changes: Array[StringName] = []


class FakeClock:
	extends RefCounted
	var now := 1000

	func now_msec() -> int:
		return now


class FakeDisplayAdapter:
	extends RefCounted
	var calls: Array[Dictionary] = []

	func apply_settings(settings: Dictionary, _resolution_size: Vector2i) -> Dictionary:
		calls.append(settings.duplicate(true))
		return {"ok": true}


class RejectingSettingsManager:
	extends Node

	func begin_transaction() -> bool:
		return false

	func is_persistence_read_only() -> bool:
		return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	had_reduce_motion_setting = ProjectSettings.has_setting(REDUCE_MOTION_KEY)
	previous_reduce_motion_value = ProjectSettings.get_setting(REDUCE_MOTION_KEY, false)
	_cleanup_test_files()
	_require(_default_settings_files_absent(), "runner requires an isolated user root without default settings files")
	root.size = Vector2i(1280, 720)

	var detached_autoload := root.get_node_or_null("SettingsManager")
	var detached_autoload_index := -1
	if detached_autoload != null:
		detached_autoload_index = detached_autoload.get_index()
		root.remove_child(detached_autoload)

	var shell := AppShellScript.new() as AppShell
	shell.name = "I2SettingsAppShell"
	root.add_child(shell)
	shell.build()
	await _frames(3)

	var owner := shell.get_owned_settings_manager()
	var owner_ref: WeakRef = weakref(owner) if owner != null else null
	var panel := shell.get_settings_panel()
	var main := shell.get_main_page()
	var deploy := shell.get_deploy_page()
	var long_term := shell.get_long_term_page()
	_require(owner != null, "AppShell did not create a default SettingsManager without injection/autoload")
	_require(shell.owns_bound_settings_manager(), "AppShell did not mark its default manager as owned")
	_require(shell.get_bound_settings_manager() == owner, "AppShell default manager was not the bound manager")
	_require(owner == null or owner.get_parent() == shell, "AppShell default manager was not owned as a child")
	_require(_owned_manager_child_count(shell) == 1, "AppShell did not expose exactly one owned default manager")
	_require(panel != null, "AppShell did not mount the production SettingsPanel")
	if owner != null and panel != null:
		await _check_production_default_panel(shell, panel, owner, main, deploy, long_term)

	var clock := FakeClock.new()
	var adapter := FakeDisplayAdapter.new()
	var manager = SettingsManagerScript.new(TEST_PATH, adapter, Callable(clock, "now_msec"))
	manager.name = "I2SettingsShellManager"
	root.add_child(manager)
	shell.bind_settings_manager(manager)
	await _frames(3)

	_require(shell.get_bound_settings_manager() == manager, "AppShell did not retain the injected manager")
	_require(not shell.owns_bound_settings_manager(), "AppShell still reported owned-manager authority after injection")
	_require(shell.get_owned_settings_manager() == null, "AppShell retained a second owned manager after injection")
	_require(shell.get_node_or_null("OwnedSettingsManager") == null, "owned default manager remained in the AppShell tree after injection")
	_require(panel == null or panel.get("settings_manager") == manager, "production SettingsPanel did not rebind to the injected manager")
	if detached_autoload != null:
		_restore_autoload(detached_autoload, detached_autoload_index)
	await _frames(3)
	_require(owner_ref == null or owner_ref.get_ref() == null, "released default manager was not freed after injected rebind")
	_require(shell.get_bound_settings_manager() == manager, "restoring the autoload displaced explicit manager injection")

	_require(not bool(main.call("is_reduced_motion_enabled")), "main started with stale reduce-motion")
	_require(not bool(deploy.call("is_reduced_motion_enabled")), "deploy started with stale reduce-motion")
	_require(not bool(long_term.call("is_reduced_motion_enabled")), "long-term started with stale reduce-motion")
	_require(bool(main.call("is_page_active")), "main was not active after settings close/rebind")
	_require(not bool(deploy.call("is_page_active")) and not bool(long_term.call("is_page_active")), "hidden pages started active")

	if panel != null:
		await _check_real_panel_timeout_rollback(shell, panel, manager, clock, main, deploy, long_term)
	await _check_main_transition_snap(shell, manager, main, deploy, long_term)
	await _check_deploy_tween_snap(manager, deploy)
	await _check_navigation_transition_interruption_boundaries(shell, main, deploy, long_term)
	await _check_long_term_tween_snap(shell, manager, deploy, long_term)
	await _check_settings_open_failure_route(shell, main)

	manager.call("close_transaction")
	shell.queue_free()
	manager.queue_free()
	await _frames(4)
	if detached_autoload != null and detached_autoload.get_parent() == null:
		_restore_autoload(detached_autoload, detached_autoload_index)
	ProjectSettings.set_setting(
		REDUCE_MOTION_KEY,
		previous_reduce_motion_value if had_reduce_motion_setting else null
	)
	_cleanup_test_files()
	_require(_default_settings_files_absent(), "production default owner polluted user://settings.cfg")
	_finish()


func _check_production_default_panel(
	shell: AppShell,
	panel,
	owner: Node,
	main: Control,
	deploy: Control,
	long_term: Control
) -> void:
	_require(panel.get("settings_manager") == owner, "production SettingsPanel was not bound to the default owner")
	_require(panel.call("field_control_names") == PackedStringArray(EXPECTED_FIELDS), "production SettingsPanel field scope expanded beyond I2.1C")
	shell.show_settings()
	await _frames(3)
	_require(shell.get_visible_page_id() == &"settings_placeholder", "show_settings did not expose the production settings route")
	_require(panel.visible and panel.is_visible_in_tree(), "show_settings did not open the real SettingsPanel")
	_require(StringName(owner.call("get_transaction_state")) == &"editing", "show_settings did not begin a real settings transaction")
	_require(not bool(main.call("is_page_active")) and not bool(deploy.call("is_page_active")) and not bool(long_term.call("is_page_active")), "settings overlay left a page lifecycle active")
	var settings_close := shell.get_node_or_null("SettingsOverlay/SettingsCloseButton") as Button
	_require(settings_close != null, "production settings close control is missing from the route contract")
	_require(settings_close == panel.get("close_button"), "settings route retained a fake close button instead of the panel control")
	for fake_name: String in ["SettingsVisualToggle", "SettingsMusicSlider", "SettingsEffectsSlider", "SettingsBoundaryCopy"]:
		_require(shell.get_node_or_null("SettingsOverlay/%s" % fake_name) == null, "fake settings control remained mounted: %s" % fake_name)
	var focus := root.gui_get_focus_owner()
	_require(focus == panel.get("window_mode_option"), "show_settings did not focus the first real field")
	if settings_close != null:
		settings_close.pressed.emit()
	await _frames(3)
	_require(shell.get_visible_page_id() == &"main_menu", "real settings close did not restore main route authority")
	_require(not panel.visible, "real SettingsPanel remained visible after close")
	_require(StringName(owner.call("get_transaction_state")) == &"idle", "real settings close did not close the transaction")
	_require(bool(main.call("is_page_active")), "main lifecycle did not reactivate after settings close")
	focus = root.gui_get_focus_owner()
	_require(focus != null and (focus == main or main.is_ancestor_of(focus)), "settings close did not restore main-menu focus")


func _check_real_panel_timeout_rollback(
	shell: AppShell,
	panel,
	manager: Node,
	clock: FakeClock,
	main: Control,
	deploy: Control,
	long_term: Control
) -> void:
	shell.show_settings()
	await _frames(3)
	_require(root.gui_get_focus_owner() == panel.get("window_mode_option"), "injected SettingsPanel did not restore first-field focus")
	panel.get("reduce_motion_check").button_pressed = true
	panel.get("master_volume_slider").value = 55.0
	panel.get("resolution_option").select(3)
	panel.call("_on_apply_pressed")
	await _frames(2)
	_require(bool(manager.call("is_confirmation_pending")), "real SettingsPanel skipped dangerous display confirmation")
	_require_equal(manager.call("get_applied_settings").get("resolution_id"), "1600x900", "dangerous preview resolution")
	_require_equal(manager.call("get_applied_settings").get("master_volume"), 55, "dangerous preview master volume")
	_require_equal(manager.call("get_applied_settings").get("reduce_motion"), true, "dangerous preview reduce-motion")
	_require(panel.get("confirmation_box").visible, "real SettingsPanel did not expose the dangerous confirmation controls")
	_require(not bool(main.call("is_page_active")) and not bool(deploy.call("is_page_active")) and not bool(long_term.call("is_page_active")), "dangerous preview revived a page behind the overlay")
	clock.now = 16001
	manager.call("_process", 0.0)
	await _frames(2)
	_require(not bool(manager.call("is_confirmation_pending")), "dangerous preview did not time out")
	_require_equal(manager.call("get_applied_settings").get("resolution_id"), "auto", "timeout resolution rollback")
	_require_equal(manager.call("get_applied_settings").get("master_volume"), 80, "timeout master-volume rollback")
	_require_equal(manager.call("get_applied_settings").get("reduce_motion"), false, "timeout reduce-motion rollback")
	_require(not panel.get("confirmation_box").visible, "real SettingsPanel kept stale confirmation controls after rollback")
	_require(not bool(main.call("is_page_active")) and not bool(deploy.call("is_page_active")) and not bool(long_term.call("is_page_active")), "timeout rollback activated a page behind the overlay")
	var settings_close := shell.get_node_or_null("SettingsOverlay/SettingsCloseButton") as Button
	if settings_close != null:
		settings_close.pressed.emit()
	await _frames(3)
	_require(shell.get_visible_page_id() == &"main_menu", "closing the rolled-back real panel did not restore main")
	_require(StringName(manager.call("get_transaction_state")) == &"idle", "closing the rolled-back real panel did not settle idle")
	var focus := root.gui_get_focus_owner()
	_require(focus != null and (focus == main or main.is_ancestor_of(focus)), "rolled-back settings close did not restore main focus")
	_require_equal(ProjectSettings.get_setting(REDUCE_MOTION_KEY, true), false, "ProjectSettings rollback")


func _check_main_transition_snap(shell: AppShell, manager: Node, main: Control, deploy: Control, long_term: Control) -> void:
	var entry_by_id: Dictionary = main.get("entry_by_id")
	var deploy_entry: Dictionary = entry_by_id.get(&"deploy", {})
	_require(not deploy_entry.is_empty(), "main deploy entry fixture missing")
	captured_page_changes.clear()
	var callback := Callable(self, "_capture_page_changed")
	if not shell.is_connected("page_changed", callback):
		shell.connect("page_changed", callback)
	main.call("_activate_entry", deploy_entry)
	_require(bool(main.get("transition_active")), "main transition fixture did not start")
	var before_snap: Dictionary = shell.get_navigation_transition_snapshot()
	var active_token := int(before_snap.get("active_token", 0))
	_require(StringName(before_snap.get("state", &"")) == &"playing", "main transition coordinator did not enter PLAYING")
	_require(StringName(before_snap.get("profile_id", &"")) == &"enter_cave", "main transition did not use enter_cave")
	_require(active_token > 0, "main transition coordinator did not issue a token")
	_apply_manager_reduce_motion(manager, true)
	await _frames(2)
	_require_equal(manager.call("get_applied_settings").get("reduce_motion"), true, "main apply setting")
	_require(not bool(main.get("transition_active")), "reduce-motion left main transition active")
	var transition_texture := main.get("transition_texture") as ColorRect
	_require(transition_texture == null or not transition_texture.visible, "main transition texture did not snap hidden")
	_require(shell.get_visible_page_id() == &"deploy_prep", "main pending route did not complete immediately")
	var after_snap: Dictionary = shell.get_navigation_transition_snapshot()
	var last_result := after_snap.get("last_result", {}) as Dictionary
	_require(StringName(after_snap.get("state", &"")) == &"idle", "reduce-motion transition did not settle coordinator IDLE")
	_require(int(last_result.get("token", 0)) == active_token, "reduce-motion transition completed a different token")
	_require(StringName(last_result.get("outcome", &"")) == &"committed", "reduce-motion transition did not commit")
	_require(int(last_result.get("commit_count", 0)) == 1, "reduce-motion transition did not commit exactly once")
	_require(captured_page_changes == [&"deploy_prep"], "reduce-motion transition emitted duplicate or false page changes")
	_require(not bool(main.call("is_page_active")) and bool(deploy.call("is_page_active")), "main route lifecycle did not settle on deploy")
	_require(not main.is_processing(), "hidden reduced-motion main kept processing")
	_require(not deploy.is_processing(), "active reduced-motion deploy kept idle processing")
	_require(not bool(long_term.call("is_page_active")) and not long_term.is_processing(), "hidden long-term was revived by apply")
	if shell.is_connected("page_changed", callback):
		shell.disconnect("page_changed", callback)


func _check_deploy_tween_snap(manager: Node, deploy: Control) -> void:
	_apply_manager_reduce_motion(manager, false)
	await _frames(2)
	_require_equal(manager.call("get_applied_settings").get("reduce_motion"), false, "deploy resume setting")
	_require(deploy.is_processing(), "active deploy did not resume after reduce-motion was disabled")
	_require(_particles_match(deploy.get("ambient_particles"), true), "active deploy particles did not resume")
	deploy.call("set_parchment_collapsed", true, true)
	var collapse_tween: Variant = deploy.get("collapse_tween")
	_require(collapse_tween != null and collapse_tween.is_valid(), "deploy collapse tween fixture did not start")
	_apply_manager_reduce_motion(manager, true)
	await _frames(2)
	collapse_tween = deploy.get("collapse_tween")
	_require(collapse_tween == null or not collapse_tween.is_valid(), "reduce-motion did not kill deploy collapse tween")
	var parchment_group := deploy.get("parchment_group") as Control
	_require(parchment_group != null and parchment_group.position.is_equal_approx(DeployPrepLayoutContractScript.COLLAPSED_OFFSET), "deploy parchment did not snap to collapsed target")
	_require(not deploy.is_processing(), "reduced-motion deploy process did not stop")
	_require(_particles_match(deploy.get("ambient_particles"), false), "reduced-motion deploy particles kept emitting")
	_apply_manager_reduce_motion(manager, false)
	await _frames(2)
	_require(deploy.is_processing(), "deploy did not resume after its snap test")


func _check_navigation_transition_interruption_boundaries(
	shell: AppShell,
	main: Control,
	deploy: Control,
	long_term: Control
) -> void:
	shell.show_main()
	await _frames(2)
	var entry_by_id: Dictionary = main.get("entry_by_id")
	var deploy_entry: Dictionary = entry_by_id.get(&"deploy", {})
	_require(not deploy_entry.is_empty(), "transition interruption deploy fixture missing")
	captured_page_changes.clear()
	var callback := Callable(self, "_capture_page_changed")
	if not shell.is_connected("page_changed", callback):
		shell.connect("page_changed", callback)

	main.call("_activate_entry", deploy_entry)
	var playing_before_direct: Dictionary = shell.get_navigation_transition_snapshot()
	var direct_token := int(playing_before_direct.get("active_token", 0))
	_require(StringName(playing_before_direct.get("state", &"")) == &"playing", "direct-intent race fixture did not enter PLAYING")
	shell.call(
		"_on_navigation_intent_requested",
		NavigationIntentScript.make_long_term(&"i2_transition_race", &"codex")
	)
	var playing_after_direct: Dictionary = shell.get_navigation_transition_snapshot()
	_require(StringName(playing_after_direct.get("state", &"")) == &"playing", "busy direct intent changed coordinator state")
	_require(int(playing_after_direct.get("active_token", 0)) == direct_token, "busy direct intent replaced the active token")
	_require(shell.get_visible_page_id() == &"main_menu", "busy direct intent changed the visible page")
	_require(captured_page_changes.is_empty(), "busy direct intent emitted a false page change")
	_require(bool(main.get("transition_active")), "busy direct intent cancelled the active presenter")
	shell.call("_on_main_menu_navigation_transition_cancel_requested", direct_token, &"test_cancel")
	await _frames(2)
	var after_direct_cancel: Dictionary = shell.get_navigation_transition_snapshot()
	_require(StringName(after_direct_cancel.get("state", &"")) == &"idle", "direct-intent fixture cancel left coordinator busy")
	_require(shell.get_visible_page_id() == &"main_menu", "direct-intent fixture cancel did not preserve Main")

	main.call("_activate_entry", deploy_entry)
	var playing_before_show: Dictionary = shell.get_navigation_transition_snapshot()
	var show_token := int(playing_before_show.get("active_token", 0))
	_require(StringName(playing_before_show.get("state", &"")) == &"playing", "external show race fixture did not enter PLAYING")
	shell.show_long_term(&"codex")
	await _frames(2)
	var after_show: Dictionary = shell.get_navigation_transition_snapshot()
	var show_result := after_show.get("last_result", {}) as Dictionary
	_require(StringName(after_show.get("state", &"")) == &"idle", "external show left coordinator busy")
	_require(int(show_result.get("token", 0)) == show_token, "external show cancelled the wrong token")
	_require(StringName(show_result.get("outcome", &"")) == &"cancelled", "external show did not record cancellation")
	_require(StringName(show_result.get("reason_code", &"")) == &"external_page_change", "external show recorded the wrong cancellation reason")
	_require(int(show_result.get("commit_count", -1)) == 0, "external show committed the cancelled route")
	_require(shell.get_visible_page_id() == &"long_term", "external show did not expose its requested page")
	_require(captured_page_changes.is_empty(), "external show emitted an authoritative route commit")
	_require(not bool(main.get("transition_active")) and int(main.get("transition_token")) == 0, "external show left the Main presenter active")
	_require((main.get("transition_root_base_positions") as Dictionary).is_empty(), "external show left Main scene roots displaced")
	_require(not bool(main.call("is_page_active")) and not bool(deploy.call("is_page_active")) and bool(long_term.call("is_page_active")), "external show left page lifecycle inconsistent")

	shell.show_main()
	await _frames(2)
	var coordinator := shell.get("_navigation_transition_coordinator") as RefCounted
	_require(coordinator != null, "commit-in-flight fixture could not access the production coordinator")
	if coordinator != null:
		var commit_request: Dictionary = coordinator.call(
			"request_transition",
			&"main_menu",
			&"deploy_prep",
			&"enter_cave",
			&"deploy",
			false,
			{}
		)
		var commit_token := int(commit_request.get("token", 0))
		coordinator.call("mark_prepared", commit_token, true)
		coordinator.call("mark_playback_finished", commit_token)
		var issued := coordinator.call("take_commit", commit_token) as Dictionary
		_require(bool(issued.get("ok", false)), "commit-in-flight fixture did not issue its commit")
		var before_reentrant_show := shell.get_navigation_transition_snapshot()
		shell.show_long_term(&"codex")
		var after_reentrant_show := shell.get_navigation_transition_snapshot()
		_require(StringName(before_reentrant_show.get("state", &"")) == &"committing", "commit-in-flight fixture did not enter COMMITTING")
		_require(StringName(after_reentrant_show.get("state", &"")) == &"committing", "reentrant public show mutated COMMITTING state")
		_require(int(after_reentrant_show.get("active_token", 0)) == commit_token, "reentrant public show replaced the committing token")
		_require(shell.get_visible_page_id() == &"main_menu", "reentrant public show changed page after cancel was rejected")
		_require(bool(main.call("is_page_active")) and not bool(long_term.call("is_page_active")), "reentrant public show changed lifecycle after cancel was rejected")
		coordinator.call("resolve_commit", commit_token, false, &"test_cleanup")
	if shell.is_connected("page_changed", callback):
		shell.disconnect("page_changed", callback)


func _check_long_term_tween_snap(shell: AppShell, manager: Node, deploy: Control, long_term: Control) -> void:
	shell.show_long_term(&"goals")
	await _frames(2)
	_require(not bool(deploy.call("is_page_active")) and not deploy.is_processing(), "hidden deploy remained active before long-term test")
	_require(bool(long_term.call("is_page_active")) and long_term.is_processing(), "long-term did not activate")
	var secondary_ids: Array[StringName] = long_term.call("get_secondary_ids")
	if secondary_ids.size() > 1:
		long_term.call("show_secondary", secondary_ids[1])
	long_term.call("show_module", &"codex")
	long_term.call("set_archive_collapsed", true, true)
	var module_tween: Variant = long_term.get("module_tween")
	var collapse_tween: Variant = long_term.get("collapse_tween")
	var content_tween: Variant = long_term.get("content_tween")
	_require(module_tween != null and module_tween.is_valid(), "long-term module tween fixture did not start")
	_require(collapse_tween != null and collapse_tween.is_valid(), "long-term collapse tween fixture did not start")
	if secondary_ids.size() > 1:
		_require(content_tween != null and content_tween.is_valid(), "long-term content tween fixture did not start")
	_apply_manager_reduce_motion(manager, true)
	await _frames(2)
	module_tween = long_term.get("module_tween")
	collapse_tween = long_term.get("collapse_tween")
	content_tween = long_term.get("content_tween")
	_require(module_tween == null or not module_tween.is_valid(), "reduce-motion did not kill long-term module tween")
	_require(collapse_tween == null or not collapse_tween.is_valid(), "reduce-motion did not kill long-term collapse tween")
	_require(content_tween == null or not content_tween.is_valid(), "reduce-motion did not kill long-term content tween")
	_require(StringName(long_term.get("displayed_module_id")) == &"codex", "long-term module did not snap to requested target")
	_require(not bool(long_term.get("switch_running")), "long-term switch coroutine remained locked")
	var module_group := long_term.get("module_group") as Control
	_require(module_group != null and module_group.position.is_equal_approx(LongTermLayoutContractScript.COLLAPSED_OFFSET), "long-term archive did not snap to collapsed target")
	_require(not long_term.is_processing(), "reduced-motion long-term process did not stop")
	_require(_particles_match(long_term.get("ambient_particles"), false), "reduced-motion long-term particles kept emitting")
	await create_timer(0.30).timeout
	_apply_manager_reduce_motion(manager, false)
	await _frames(2)
	_require_equal(manager.call("get_applied_settings").get("reduce_motion"), false, "long-term resume setting")
	_require(long_term.is_processing(), "long-term did not resume after reduce-motion was disabled")
	_require(_particles_match(long_term.get("ambient_particles"), true), "active long-term particles did not resume")


func _check_settings_open_failure_route(shell: AppShell, main: Control) -> void:
	shell.show_main()
	await _frames(2)
	var rejecting_manager := RejectingSettingsManager.new()
	rejecting_manager.name = "RejectingSettingsManager"
	root.add_child(rejecting_manager)
	shell.bind_settings_manager(rejecting_manager)
	captured_page_changes.clear()
	var callback := Callable(self, "_capture_page_changed")
	if not shell.is_connected("page_changed", callback):
		shell.connect("page_changed", callback)
	main.call("_set_focus_state", &"settings")
	var settings_button := main.get_node_or_null("PrimaryActionRoot/MainMenuEntry_settings") as Button
	_require(settings_button != null, "settings failure route button missing")
	if settings_button != null:
		settings_button.pressed.emit()
	var playing: Dictionary = shell.get_navigation_transition_snapshot()
	_require(StringName(playing.get("state", &"")) == &"playing", "rejected settings route did not start production transition")
	_require(StringName(playing.get("profile_id", &"")) == &"open_overlay", "rejected settings route did not use open_overlay")
	main.call("_process", 0.25)
	await _frames(3)
	_require(shell.get_visible_page_id() == &"main_menu", "rejected settings open did not remain on main")
	_require(bool(main.call("is_page_active")), "rejected settings open did not restore main lifecycle")
	_require(captured_page_changes == [&"main_menu"], "rejected settings open emitted a false or duplicate page commit")
	var recovered: Dictionary = shell.get_navigation_transition_snapshot()
	var last_result := recovered.get("last_result", {}) as Dictionary
	var recovery := last_result.get("recovery", {}) as Dictionary
	_require(StringName(recovered.get("state", &"")) == &"idle", "rejected settings route left coordinator busy")
	_require(StringName(last_result.get("outcome", &"")) == &"failed", "rejected settings route did not record failure")
	_require(StringName(last_result.get("reason_code", &"")) == &"route_commit_failed", "rejected settings route recorded the wrong reason")
	_require(int(last_result.get("commit_count", 0)) == 1, "rejected settings route attempted an invalid number of commits")
	_require(StringName(recovery.get("focus_id", &"")) == &"settings", "rejected settings route lost source focus recovery")
	_require(StringName(main.get("current_focus")) == &"settings", "rejected settings route did not restore settings focus state")
	var focus_owner := root.gui_get_focus_owner()
	_require(focus_owner == settings_button, "rejected settings route did not restore the settings button focus owner")
	if shell.is_connected("page_changed", callback):
		shell.disconnect("page_changed", callback)
	rejecting_manager.queue_free()
	await _frames(2)


func _capture_page_changed(page_id: StringName, _payload: Dictionary) -> void:
	captured_page_changes.append(page_id)


func _apply_manager_reduce_motion(manager: Node, value: bool) -> void:
	if StringName(manager.call("get_transaction_state")) == &"idle":
		_require(bool(manager.call("begin_transaction")), "manager could not begin reduce-motion transaction")
	_require(bool(manager.call("set_draft_value", &"reduce_motion", value)), "manager rejected reduce-motion draft")
	_require(bool(manager.call("apply_draft")), "manager rejected reduce-motion apply")


func _owned_manager_child_count(shell: AppShell) -> int:
	var count := 0
	for child in shell.get_children():
		if child.name == "OwnedSettingsManager":
			count += 1
	return count


func _restore_autoload(autoload_manager: Node, original_index: int) -> void:
	if autoload_manager == null or not is_instance_valid(autoload_manager) or autoload_manager.get_parent() != null:
		return
	root.add_child(autoload_manager)
	root.move_child(autoload_manager, clampi(original_index, 0, root.get_child_count() - 1))


func _default_settings_files_absent() -> bool:
	for suffix: String in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(DEFAULT_PATH + suffix):
			return false
	return true


func _particles_match(raw_particles: Variant, expected: bool) -> bool:
	if not (raw_particles is Array) or (raw_particles as Array).is_empty():
		return false
	for raw_particle in raw_particles as Array:
		var particle := raw_particle as CPUParticles2D
		if particle == null or particle.emitting != expected:
			return false
	return true


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _cleanup_test_files() -> void:
	for suffix: String in ["", ".tmp", ".bak", ".corrupt"]:
		var path := TEST_PATH + suffix
		if not FileAccess.file_exists(path):
			continue
		var directory := DirAccess.open(path.get_base_dir())
		if directory != null:
			directory.remove(path.get_file())


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s owner=default_then_injected panel=production rollback=complete user_files=clean" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I2 settings shell wiring failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
