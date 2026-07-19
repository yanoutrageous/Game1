extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	if main_scene == null:
		_fail("main.tscn could not be loaded")
		_finish()
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await _frames(12)
	var run_scene := main.get_node_or_null("RunScene")
	if run_scene == null:
		_fail("RunScene missing")
		_finish()
		return
	run_scene.call("_start_standard_from_ui")
	await _frames(12)
	run_scene.call("_debug_teleport_to_room_type", &"Chest")
	await _frames(12)
	var view = run_scene.get("room_runtime_view")
	var player = run_scene.get("player_controller")
	if view == null or view.chest == null or view.context_popup == null or player == null:
		_fail("production room/context nodes were not constructed")
		_finish()
		return
	view.advance(0.0, player.get_local_position(), {})
	await _frames(4)
	var target_ui: Vector2 = view.chest.get_global_transform().origin
	var popup_rect := Rect2(view.context_popup.position, view.context_popup.size * view.context_popup.scale)
	var target_visual_rect := Rect2(target_ui - Vector2(38, 34), Vector2(76, 68))
	print("ART24_CONTEXT_ANCHOR_DIAGNOSTIC target_ui=%s popup=%s room_transform=%s overlay_size=%s" % [
		target_ui,
		popup_rect,
		view.get_global_transform(),
		(view.context_popup.get_parent() as Control).size,
	])
	if popup_rect.intersects(target_visual_rect):
		_fail("production contextual popup overlaps transformed chest visual: popup=%s target=%s" % [popup_rect, target_visual_rect])
	_finish()


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _fail(message: String) -> void:
	failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("ART24_CONTEXT_ANCHOR_INTEGRATION=PASS room=scaled overlay=unscaled target_clear")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("ART24_CONTEXT_ANCHOR_INTEGRATION=FAIL count=%d" % failures.size())
	quit(1)
