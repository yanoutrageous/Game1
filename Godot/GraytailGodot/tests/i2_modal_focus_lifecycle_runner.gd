extends SceneTree

const ModalFocusStackScript := preload("res://scripts/ui/shell/modal_focus_stack.gd")

const PASS_MARKER := "I2_MODAL_FOCUS_LIFECYCLE=PASS"
const FAIL_MARKER := "I2_MODAL_FOCUS_LIFECYCLE=FAIL"

var failures: Array[String] = []
var focus_stack: RefCounted
var callback_reason := &""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.name = "ModalFocusTestHost"
	root.add_child(host)
	var base_button := _make_button("BaseButton")
	host.add_child(base_button)
	var first_modal := Control.new()
	first_modal.name = "FirstModal"
	host.add_child(first_modal)
	var first_button := _make_button("FirstButton")
	first_modal.add_child(first_button)
	first_modal.hide()
	var second_modal := Control.new()
	second_modal.name = "SecondModal"
	host.add_child(second_modal)
	var second_button := _make_button("SecondButton")
	second_modal.add_child(second_button)
	second_modal.hide()

	base_button.grab_focus()
	await process_frame
	_require_equal(root.gui_get_focus_owner(), base_button, "base focus")

	focus_stack = ModalFocusStackScript.new()
	_require(
		focus_stack.push(&"first", first_modal, first_button, Callable(self, "_cancel_first")),
		"first modal push"
	)
	await process_frame
	_require_equal(focus_stack.depth(), 1, "first modal depth")
	_require_equal(root.gui_get_focus_owner(), first_button, "first modal focus")
	_require(not focus_stack.push(&"first", first_modal, first_button), "duplicate modal id was accepted")

	_require(focus_stack.push(&"second", second_modal, second_button), "second modal push")
	await process_frame
	_require_equal(focus_stack.top_modal_id(), &"second", "nested top modal")
	_require_equal(root.gui_get_focus_owner(), second_button, "second modal focus")
	_require(not first_modal.visible, "covered parent modal stayed visible")
	_require(not focus_stack.pop(&"first"), "out-of-order modal pop was accepted")
	_require(focus_stack.request_cancel_top(&"escape"), "top modal cancel")
	await process_frame
	_require_equal(focus_stack.top_modal_id(), &"first", "top-only cancel lifecycle")
	_require(not second_modal.visible, "cancelled nested modal stayed visible")
	_require(first_modal.visible, "parent modal was not restored after nested cancel")
	_require_equal(root.gui_get_focus_owner(), first_button, "focus after nested cancel")

	_require(focus_stack.request_cancel_top(&"user_close"), "callback modal cancel")
	await process_frame
	_require_equal(callback_reason, &"user_close", "cancel callback reason")
	_require_equal(focus_stack.depth(), 0, "stack after callback close")
	_require(not first_modal.visible, "callback-closed modal stayed visible")
	_require_equal(root.gui_get_focus_owner(), base_button, "base focus restoration")

	_require(focus_stack.push(&"input", first_modal, first_button), "input modal push")
	await process_frame
	var cancel_event := InputEventAction.new()
	cancel_event.action = &"ui_cancel"
	cancel_event.pressed = true
	_require(focus_stack.handle_cancel_event(cancel_event), "cancel input was not consumed")
	await process_frame
	_require_equal(focus_stack.depth(), 0, "input cancel did not close top modal")
	_require_equal(root.gui_get_focus_owner(), base_button, "focus after input cancel")
	host.free()
	_finish()


func _cancel_first(reason: StringName) -> void:
	callback_reason = reason
	focus_stack.pop(&"first")


func _make_button(control_name: String) -> Button:
	var button := Button.new()
	button.name = control_name
	button.text = control_name
	button.focus_mode = Control.FOCUS_ALL
	return button


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I2 modal focus lifecycle failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
