extends SceneTree

const UILayerContract := preload("res://scripts/ui/shell/ui_layer_contract.gd")


func _initialize() -> void:
	var bottom_overlay := NinePatchRect.new()
	bottom_overlay.name = "Art21RunBottomOverlay"
	var action_bar := HBoxContainer.new()
	action_bar.name = "RunBottomActionButtons"
	var modal := Control.new()
	modal.name = "RunInventoryModal"
	var generic_overlay := Control.new()
	generic_overlay.name = "RunMapOverlay"
	var protocol_plate := TextureRect.new()
	protocol_plate.name = "RunProtocolLevelPlate"
	var protocol_pressure := ColorRect.new()
	protocol_pressure.name = "RunProtocolPressureFill"
	var failures: Array[String] = []
	_assert_route(bottom_overlay, &"RunActionOverlayRoot", failures)
	_assert_route(action_bar, &"RunActionOverlayRoot", failures)
	_assert_route(modal, &"RunModalRoot", failures)
	_assert_route(generic_overlay, &"RunOverlayRoot", failures)
	_assert_route(protocol_plate, &"RunTopRightStatusRoot", failures)
	_assert_route(protocol_pressure, &"RunTopRightStatusRoot", failures)
	bottom_overlay.free()
	action_bar.free()
	modal.free()
	generic_overlay.free()
	protocol_plate.free()
	protocol_pressure.free()
	if failures.is_empty():
		print("ART24_RUN_SURFACE_LAYER_ROUTING=PASS bottom_skin_and_buttons=action_root")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(2)


func _assert_route(node: Node, expected: StringName, failures: Array[String]) -> void:
	var actual := UILayerContract.run_root_for_node(node)
	if actual != expected:
		failures.append("route_%s=%s_expected_%s" % [node.name, actual, expected])
