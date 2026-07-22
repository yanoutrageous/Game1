extends SceneTree

const RuntimeModalLayoutModelScript := preload("res://scripts/ui/run_surface/runtime_modal_layout_model.gd")

const CASES := [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var failures: Array[String] = []


func _initialize() -> void:
	for viewport_size in CASES:
		_test_layout(viewport_size)
	_test_run_scene_delegation()
	_finish()


func _test_layout(viewport_size: Vector2i) -> void:
	var profile := {
		"supported_size": Vector2(viewport_size),
		"actual_viewport_size": viewport_size,
	}
	var layout: Dictionary = RuntimeModalLayoutModelScript.build(profile)
	var viewport := layout.get("viewport", Rect2()) as Rect2
	var margin := float(layout.get("safe_margin", 0.0))
	_check(bool(layout.get("read_only", false)), "Layout model did not identify its read-only projection")
	_check(viewport.size == Vector2(viewport_size), "Layout model changed the viewport size")
	for modal_id in [&"extract", &"pause", &"settings", &"abandon"]:
		var rect := layout.get(String(modal_id), Rect2()) as Rect2
		_check(_inside_with_margin(viewport, rect, margin), "%s escaped the safe viewport at %s" % [modal_id, viewport_size])
		_check(is_equal_approx(rect.get_center().x, viewport.get_center().x), "%s is not horizontally centered at %s" % [modal_id, viewport_size])
		_check(is_equal_approx(rect.get_center().y, viewport.get_center().y), "%s is not vertically centered at %s" % [modal_id, viewport_size])
	var event_rect := layout.get("event", Rect2()) as Rect2
	_check(_inside_with_margin(viewport, event_rect, margin), "Event rail escaped the safe viewport at %s" % viewport_size)
	_check(event_rect.get_center().x > viewport.get_center().x, "Event rail stopped using the right-side information region at %s" % viewport_size)
	var debug_rect := layout.get("debug", Rect2()) as Rect2
	_check(_inside_with_margin(viewport, debug_rect, margin), "Debug panel escaped the safe viewport at %s" % viewport_size)
	_check((layout.get("debug_scroll_minimum", Vector2.ZERO) as Vector2).x > 0.0, "Debug scroll projection is empty at %s" % viewport_size)


func _test_run_scene_delegation() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/core/run/run_scene.gd")
	_check(source.contains("RuntimeModalLayoutModelScript.build(profile)"), "RunScene does not delegate modal geometry to the layout model")
	_check(not source.contains("func _centered_runtime_modal_rect"), "RunScene still owns centered modal geometry")
	_check(not source.contains("func _apply_debug_panel_layout"), "RunScene still owns debug panel geometry")


func _inside_with_margin(viewport: Rect2, rect: Rect2, margin: float) -> bool:
	return (
		rect.position.x >= viewport.position.x + margin - 0.01
		and rect.position.y >= viewport.position.y + margin - 0.01
		and rect.end.x <= viewport.end.x - margin + 0.01
		and rect.end.y <= viewport.end.y - margin + 0.01
	)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I3_RUNTIME_MODAL_LAYOUT_MODEL=PASS cases=5 owner=RuntimeModalLayoutModel run_scene_helpers_removed=2")
		quit(0)
		return
	for failure in failures:
		push_error("I3 runtime modal layout model: " + failure)
	print("I3_RUNTIME_MODAL_LAYOUT_MODEL=FAIL failures=%d" % failures.size())
	quit(1)
