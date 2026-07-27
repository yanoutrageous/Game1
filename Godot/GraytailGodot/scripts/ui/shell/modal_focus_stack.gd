extends RefCounted

signal stack_changed(depth: int, top_modal_id: StringName)
signal close_requested(modal_id: StringName, reason: StringName)

const PRIORITY_DRAWER := 100
const PRIORITY_READ_ONLY_OVERLAY := 200
const PRIORITY_BLOCKING := 300
const PRIORITY_NESTED_SETTINGS := 400
const PRIORITY_IRREVERSIBLE_CONFIRM := 500
const PRIORITY_TERMINAL := 600

const MODAL_POLICIES := {
	&"inventory": {"priority": PRIORITY_DRAWER, "kind": &"drawer", "blocks_gameplay_input": true},
	&"map": {"priority": PRIORITY_READ_ONLY_OVERLAY, "kind": &"read_only_overlay", "blocks_gameplay_input": true},
	&"event": {"priority": PRIORITY_BLOCKING, "kind": &"decision", "blocks_gameplay_input": true},
	&"loot_result": {"priority": PRIORITY_BLOCKING, "kind": &"acknowledgement", "blocks_gameplay_input": true},
	&"pause": {"priority": PRIORITY_BLOCKING, "kind": &"pause", "blocks_gameplay_input": true},
	&"settings": {"priority": PRIORITY_NESTED_SETTINGS, "kind": &"settings", "blocks_gameplay_input": true},
	&"extract_confirm": {"priority": PRIORITY_IRREVERSIBLE_CONFIRM, "kind": &"irreversible_confirm", "blocks_gameplay_input": true, "requires_confirmation": true},
	&"combat_flee_confirm": {"priority": PRIORITY_IRREVERSIBLE_CONFIRM, "kind": &"destructive_confirm", "blocks_gameplay_input": true, "requires_confirmation": true},
	&"abandon_confirm": {"priority": PRIORITY_IRREVERSIBLE_CONFIRM, "kind": &"destructive_confirm", "blocks_gameplay_input": true, "requires_confirmation": true},
	&"deploy_abandon": {"priority": PRIORITY_IRREVERSIBLE_CONFIRM, "kind": &"destructive_confirm", "blocks_gameplay_input": true, "requires_confirmation": true},
	&"warehouse_batch_sell": {"priority": PRIORITY_IRREVERSIBLE_CONFIRM, "kind": &"destructive_confirm", "blocks_gameplay_input": true, "requires_confirmation": true},
	&"exit_confirm": {"priority": PRIORITY_IRREVERSIBLE_CONFIRM, "kind": &"irreversible_confirm", "blocks_gameplay_input": true, "requires_confirmation": true},
	&"result": {"priority": PRIORITY_TERMINAL, "kind": &"terminal", "blocks_gameplay_input": true},
}

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
	var policy := policy_for(modal_id)
	if not _entries.is_empty():
		var top_policy := _entries[_entries.size() - 1].get("policy", {}) as Dictionary
		if int(policy.get("priority", PRIORITY_BLOCKING)) < int(top_policy.get("priority", PRIORITY_BLOCKING)):
			return false
	var covered_modal: Control = null
	if not _entries.is_empty():
		covered_modal = _control_from_weak_ref(_entries[_entries.size() - 1].get("modal"))
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
		"policy": policy,
	})
	if covered_modal != null and covered_modal != modal_root:
		covered_modal.hide()
	modal_root.show()
	_grab_focus_deferred(preferred_focus)
	_emit_stack_changed()
	return true


func pop(modal_id: StringName = &"", restore_focus: bool = true, hide_modal: bool = true) -> bool:
	_prune_invalid_entries()
	if _entries.is_empty():
		return false
	var entry: Dictionary = _entries[_entries.size() - 1]
	if modal_id != &"" and StringName(entry.get("id", &"")) != modal_id:
		return false
	_entries.pop_back()
	var modal_root := _control_from_weak_ref(entry.get("modal"))
	if hide_modal and modal_root != null:
		modal_root.hide()
	_show_top_modal_root(modal_root)
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
	if event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
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


func blocks_gameplay_input() -> bool:
	_prune_invalid_entries()
	if _entries.is_empty():
		return false
	var policy := _entries[_entries.size() - 1].get("policy", {}) as Dictionary
	return bool(policy.get("blocks_gameplay_input", true))


func snapshot() -> Dictionary:
	_prune_invalid_entries()
	var order: Array[Dictionary] = []
	for entry in _entries:
		var policy := (entry.get("policy", {}) as Dictionary).duplicate(true)
		policy["id"] = StringName(entry.get("id", &""))
		order.append(policy)
	return {
		"depth": _entries.size(),
		"top_modal_id": top_modal_id(),
		"blocks_gameplay_input": blocks_gameplay_input(),
		"close_order": order,
	}


static func policy_for(modal_id: StringName) -> Dictionary:
	var policy := (MODAL_POLICIES.get(modal_id, {
		"priority": PRIORITY_BLOCKING,
		"kind": &"blocking",
		"blocks_gameplay_input": true,
	}) as Dictionary).duplicate(true)
	policy["requires_confirmation"] = bool(policy.get("requires_confirmation", false))
	return policy


static func requires_confirmation(modal_id: StringName) -> bool:
	return bool(policy_for(modal_id).get("requires_confirmation", false))


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
	if control == null or not is_instance_valid(control):
		return
	Callable(self, "_grab_focus_reference_if_valid").bind(weakref(control)).call_deferred()


func _grab_focus_reference_if_valid(reference: WeakRef) -> void:
	var control := _control_from_weak_ref(reference)
	if _can_receive_focus(control):
		control.grab_focus()


func _can_receive_focus(control: Control) -> bool:
	return (
		control != null
		and is_instance_valid(control)
		and control.is_inside_tree()
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
		and not (control is BaseButton and (control as BaseButton).disabled)
	)


func _control_from_weak_ref(reference: Variant) -> Control:
	if reference == null or not reference is WeakRef:
		return null
	var value: Variant = reference.get_ref()
	return value as Control if value != null and is_instance_valid(value) else null


func _show_top_modal_root(excluded_root: Control = null) -> void:
	if _entries.is_empty():
		return
	var top_root := _control_from_weak_ref(_entries[_entries.size() - 1].get("modal"))
	if top_root != null and top_root != excluded_root:
		top_root.show()


func _prune_invalid_entries() -> void:
	var changed := false
	for index in range(_entries.size() - 1, -1, -1):
		if _control_from_weak_ref(_entries[index].get("modal")) == null:
			_entries.remove_at(index)
			changed = true
	if changed:
		_show_top_modal_root()
		_emit_stack_changed()


func _emit_stack_changed() -> void:
	var top_id := &"" if _entries.is_empty() else StringName(_entries[_entries.size() - 1].get("id", &""))
	stack_changed.emit(_entries.size(), top_id)
