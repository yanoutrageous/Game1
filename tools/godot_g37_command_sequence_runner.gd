extends SceneTree

const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")


func _init() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	var start_result: Dictionary = bus.dispatch(&"start_tutorial_run")
	_require_ok(start_result, "start_tutorial_run")
	_clear_tutorial_popup(controller, bus)
	_require_ok(bus.dispatch(&"move_by", {"delta": Vector2i(1, 0)}), "move_by")
	_clear_tutorial_popup(controller, bus)
	_require_dictionary(bus.dispatch(&"search_current_room"), "search_current_room")
	_clear_tutorial_popup(controller, bus)
	var exits: Array = controller.context.truth_map.get_exits()
	if exits.is_empty():
		_fail("missing tutorial exit")
	var exit_pos: Vector2i = exits[0]
	controller.context.player_pos = exit_pos
	controller.context.current_pos = exit_pos
	bus.room_resolver.enter_room(controller.context)
	_clear_tutorial_popup(controller, bus)
	if controller.context.current_room_type != &"Exit":
		_fail("expected exit room after test setup, got %s" % str(controller.context.current_room_type))
	if controller.context.exit_id == &"":
		_fail("expected exit id after test setup")
	_require_ok(bus.dispatch(&"request_extract"), "request_extract")
	var confirm_result: Dictionary = bus.dispatch(&"confirm_extract")
	_require_ok(confirm_result, "confirm_extract")
	if not controller.context.extracted:
		_fail("context not extracted after confirm_extract")
	if controller.context.phase != &"extracted":
		_fail("expected extracted phase, got %s" % str(controller.context.phase))
	print("G37_COMMAND_SEQUENCE_REGRESSION=PASS")
	quit(0)


func _clear_tutorial_popup(controller: Variant, bus: Variant) -> void:
	var guard := 0
	while controller.context.has_blocking_tutorial_popup() and guard < 8:
		_require_ok(bus.dispatch(&"confirm_tutorial_popup"), "confirm_tutorial_popup")
		guard += 1
	if controller.context.has_blocking_tutorial_popup():
		_fail("tutorial popup remained blocking after confirmations")


func _require_ok(result: Dictionary, label: String) -> void:
	_require_dictionary(result, label)
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _require_dictionary(result: Variant, label: String) -> void:
	if not (result is Dictionary):
		_fail("%s did not return Dictionary" % label)


func _fail(message: String) -> void:
	printerr("G37_COMMAND_SEQUENCE_REGRESSION=FAIL:%s" % message)
	quit(1)
