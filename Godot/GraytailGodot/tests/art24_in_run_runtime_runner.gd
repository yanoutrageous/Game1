extends SceneTree

const PreviewScript := preload("res://scripts/presentation/art24/art24_in_run_preview.gd")
const Catalog := preload("res://scripts/presentation/art24/art24_state_catalog.gd")
const Assets := preload("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if Catalog.STATES.size() != 54:
		failures.append("state_count=%d" % Catalog.STATES.size())
	var seen := {}
	for raw_state: Dictionary in Catalog.STATES:
		var state_id := StringName(raw_state.secondary_id)
		if seen.has(state_id):
			failures.append("duplicate_state=%s" % String(state_id))
		seen[state_id] = true

	var required_keys := [
		&"visual.art24.room.normal",
		&"visual.art24.room.mine",
		&"visual.art24.room.chest",
		&"visual.art24.room.event",
		&"visual.art24.room.monster",
		&"visual.art24.room.exit",
		&"visual.art24.actor.player.down.idle_a",
		&"visual.art24.actor.player.left.walk_a",
		&"visual.art24.actor.player.right.hit",
		&"visual.art24.actor.player.up.interact",
		&"visual.art24.actor.player.down.attack_impact",
		&"visual.art24.actor.ironback.attack_impact",
		&"visual.art24.item.world_loot.emergency_bandage",
		&"visual.art24.ui.left_rail",
		&"visual.art24.ui.bottom_bar",
		&"visual.art24.ui.protocol.level_1",
		&"visual.art24.ui.map_frame",
		&"visual.art24.ui.modal_frame",
		&"visual.art24.ui.item_row.selected",
		&"visual.art24.ui.toast.danger",
		&"visual.art24.fx.pickup_beam.7",
		&"visual.art24.fx.combat_slash.5",
		&"visual.art24.fx.chest_opening.5",
	]
	for visual_key: StringName in required_keys:
		if Assets.texture(visual_key) == null:
			failures.append("missing_visual_key=%s" % String(visual_key))

	root.size = Vector2i(1280, 720)
	var preview := PreviewScript.new() as Control
	preview.size = Vector2(1280, 720)
	root.add_child(preview)
	await _frames(12)
	for raw_state: Dictionary in Catalog.STATES:
		var state := raw_state.duplicate(true)
		preview.call("apply_state", StringName(state.secondary_id), state)
		await _frames(1)
		if StringName(preview.get("state_id")) != StringName(state.secondary_id):
			failures.append("state_apply_failed=%s" % String(state.secondary_id))
	if failures.is_empty():
		print("ART24_IN_RUN_RUNTIME=PASS primary_modules=8 secondary_states=54 required_visual_keys=%d" % required_keys.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("ART24_IN_RUN_RUNTIME=FAIL failures=%d" % failures.size())
		quit(2)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame
