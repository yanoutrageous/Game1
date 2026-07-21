extends RefCounted

signal stack_changed(depth: int, top_modal_id: StringName)
signal close_requested(modal_id: StringName, reason: StringName)

var _entries: Array[Dictionary] = []


func push(
	modal_id: StringName,
	modal_root: Control,
	preferred_focus: Control = null,
	cancel_handler: Callable = Callable()
) -> bool:
	_prune_invalid_entries()
	if modal_id == &"" or modal_root == null or not is_instance_valid(modal_root):
		return false
	if contains(modal_id):
		return false
	var previous_focus: Control = null
	var viewport := modal_root.get_viewport()
	if viewport != null:
		previous_focus = viewport.gui_get_focus_owner()
	_entries.append({
		"id": modal_id,
		"modal": weakref(modal_root),
		"preferred_focus": weakref(preferred_focus) if preferred_focus != null else null,
		"previous_focus": weakref(previous_focus) if previous_focus != null else null,
		"cancel_handler": cancel_handler,
	})
	modal_root.show()
	_grab_focus_deferred(preferred_focus)
	_emit_stack_changed()
	return true


func pop(modal_id: StringName = &"", restore_focus: bool = true) -> bool:
	_prune_invalid_entries()
	if _entries.is_empty():
		return false
	var entry: Dictionary = _entries[_entries.size() - 1]
	if modal_id != &"" and StringName(entry.get("id", &"")) != modal_id:
		return false
	_entries.pop_back()
	var modal_root := _control_from_weak_ref(entry.get("modal"))
	if modal_root != null:
		modal_root.hide()
	if restore_focus:
		_restore_focus(entry)
	_emit_stack_changed()
	return true


func request_cancel_top(reason: StringName = &"cancel") -> bool:
	_prune_invalid_entries()
	if _entries.is_empty():
		return false
	var entry: Dictionary = _entries[_entries.size() - 1]
	var modal_id := StringName(entry.get("id", &""))
	close_requested.emit(modal_id, reason)
	var cancel_handler: Callable = entry.get("cancel_handler", Callable())
	if cancel_handler.is_valid():
		cancel_handler.call(reason)
	else:
		pop(modal_id)
	return true


func handle_cancel_event(event: InputEvent) -> bool:
	if event == null or event.is_echo():
		return false
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		return request_cancel_top(&"input_cancel")
	return false


func clear(restore_focus: bool = true) -> void:
	while not _entries.is_empty():
		pop(&"", restore_focus and _entries.size() == 1)


func contains(modal_id: StringName) -> bool:
	for entry in _entries:
		if StringName(entry.get("id", &"")) == modal_id:
			return true
	return false


func depth() -> int:
	_prune_invalid_entries()
	return _entries.size()


func top_modal_id() -> StringName:
	_prune_invalid_entries()
	if _entries.is_empty():
		return &""
	return StringName(_entries[_entries.size() - 1].get("id", &""))


func _restore_focus(entry: Dictionary) -> void:
	var previous_focus := _control_from_weak_ref(entry.get("previous_focus"))
	if _can_receive_focus(previous_focus):
		_grab_focus_deferred(previous_focus)
		return
	if _entries.is_empty():
		return
	var parent_entry: Dictionary = _entries[_entries.size() - 1]
	var parent_focus := _control_from_weak_ref(parent_entry.get("preferred_focus"))
	if _can_receive_focus(parent_focus):
		_grab_focus_deferred(parent_focus)


func _grab_focus_deferred(control: Control) -> void:
	if _can_receive_focus(control):
		control.call_deferred("grab_focus")


func _can_receive_focus(control: Control) -> bool:
	return (
		control != null
		and is_instance_valid(control)
		and control.is_inside_tree()
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
	)


func _control_from_weak_ref(reference: Variant) -> Control:
	if reference == null or not reference is WeakRef:
		return null
	var value: Variant = reference.get_ref()
	return value as Control if value != null and is_instance_valid(value) else null


func _prune_invalid_entries() -> void:
	var changed := false
	for index in range(_entries.size() - 1, -1, -1):
		if _control_from_weak_ref(_entries[index].get("modal")) == null:
			_entries.remove_at(index)
			changed = true
	if changed:
		_emit_stack_changed()


func _emit_stack_changed() -> void:
	var top_id := &"" if _entries.is_empty() else StringName(_entries[_entries.size() - 1].get("id", &""))
	stack_changed.emit(_entries.size(), top_id)
