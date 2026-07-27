extends RefCounted
class_name RunSceneModalController

const ModalFocusStackScript := preload("res://scripts/ui/shell/modal_focus_stack.gd")

var _focus_stack: RefCounted
var _input_shield: ColorRect
var _run_surface: Variant
var _modal_roots: Dictionary = {}
var _sync_player_input: Callable


func _init() -> void:
	_focus_stack = ModalFocusStackScript.new()
	_focus_stack.stack_changed.connect(_on_stack_changed)


func bind_views(
	input_shield: ColorRect,
	run_surface: Variant,
	modal_roots: Dictionary,
	sync_player_input: Callable
) -> void:
	_input_shield = input_shield
	_run_surface = run_surface
	_modal_roots = modal_roots.duplicate(false)
	_sync_player_input = sync_player_input
	_on_stack_changed(_focus_stack.depth(), _focus_stack.top_modal_id())


func push(
	modal_id: StringName,
	modal_root: Control,
	preferred_focus: Control = null,
	cancel_handler: Callable = Callable()
) -> bool:
	var registered_root := _modal_root(modal_id)
	if registered_root == null or registered_root != modal_root:
		return false
	return bool(_focus_stack.push(modal_id, modal_root, preferred_focus, cancel_handler))


func is_top(modal_id: StringName) -> bool:
	return top_modal_id() == modal_id


func top_modal_id() -> StringName:
	return _focus_stack.top_modal_id()


func depth() -> int:
	return _focus_stack.depth()


func blocks_gameplay_input() -> bool:
	return _focus_stack.blocks_gameplay_input()


func request_cancel_top(reason: StringName = &"cancel") -> bool:
	return bool(_focus_stack.request_cancel_top(reason))


func pop(modal_id: StringName, restore_focus: bool = true, hide_modal: bool = true) -> bool:
	return bool(_focus_stack.pop(modal_id, restore_focus, hide_modal))


func clear(restore_focus: bool = true) -> void:
	_focus_stack.clear(restore_focus)


func snapshot() -> Dictionary:
	return _focus_stack.snapshot()


func preferred_focus(modal_root: Control) -> Control:
	if modal_root == null:
		return null
	if modal_root.has_method("preferred_focus_control"):
		return modal_root.call("preferred_focus_control") as Control
	return _first_focusable_descendant(modal_root)


func describe_authority() -> Dictionary:
	var registered_modal_ids: Array[StringName] = []
	for raw_modal_id: Variant in _modal_roots.keys():
		registered_modal_ids.append(StringName(raw_modal_id))
	registered_modal_ids.sort()
	return {
		"owner": &"RunSceneModalController",
		"stack_owner": &"ModalFocusStack",
		"owns_modal_root_registry": true,
		"owns_input_shield_routing": true,
		"owns_preferred_focus_resolution": true,
		"views_bound": _input_shield != null and not _modal_roots.is_empty() and _sync_player_input.is_valid(),
		"registered_modal_ids": registered_modal_ids,
		"mutates_game_state": false,
		"persists_state": false,
	}


func _on_stack_changed(_depth: int, top_modal_id: StringName) -> void:
	if _sync_player_input.is_valid():
		_sync_player_input.call()
	if _run_surface != null and is_instance_valid(_run_surface) and _run_surface.has_method("apply_modal_visibility_policy"):
		_run_surface.call("apply_modal_visibility_policy", top_modal_id)
	_route_input_shield(top_modal_id)


func _route_input_shield(top_modal_id: StringName) -> void:
	if _input_shield == null or not is_instance_valid(_input_shield):
		return
	var top_root := _modal_root(top_modal_id)
	if top_root == null or top_root.get_parent() == null:
		_input_shield.hide()
		return
	var desired_parent := top_root.get_parent() as Control
	if desired_parent == null:
		_input_shield.hide()
		return
	if _input_shield.get_parent() != desired_parent:
		_input_shield.reparent(desired_parent, false)
		_input_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var target_index := top_root.get_index()
	if _input_shield.get_index() < target_index:
		target_index -= 1
	desired_parent.move_child(_input_shield, target_index)
	_input_shield.show()


func _modal_root(modal_id: StringName) -> Control:
	var value: Variant = _modal_roots.get(modal_id)
	return value as Control if value != null and is_instance_valid(value) else null


func _first_focusable_descendant(root_control: Control) -> Control:
	for child in root_control.get_children():
		var control := child as Control
		if control == null:
			continue
		var disabled_button := control is BaseButton and (control as BaseButton).disabled
		if (
			control.focus_mode != Control.FOCUS_NONE
			and control.visible
			and not disabled_button
			and not control.is_queued_for_deletion()
		):
			return control
		var nested := _first_focusable_descendant(control)
		if nested != null:
			return nested
	return null
