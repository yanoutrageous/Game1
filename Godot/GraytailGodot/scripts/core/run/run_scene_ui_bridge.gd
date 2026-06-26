extends RefCounted
class_name RunSceneUIBridge

const RunSurfaceModel := preload("res://scripts/ui/run_surface/run_surface_model.gd")


static func build_surface_model(snapshot: Dictionary, minimap_view_model: MiniMapViewModel, layout_profile: Dictionary, last_command_result: Dictionary) -> Dictionary:
	return RunSurfaceModel.build(snapshot, minimap_view_model, layout_profile, last_command_result)


static func minimap_from_snapshot_or_intel(snapshot: Dictionary, context: RunContext) -> MiniMapViewModel:
	var minimap_vm := MiniMapViewModel.build_from_run_map_snapshot(snapshot.get("run_map_snapshot", {}))
	if minimap_vm.room_markers.is_empty() and context != null:
		minimap_vm = MiniMapViewModel.build_from_intel(context.intel_map, context.get_current_pos())
	return minimap_vm
