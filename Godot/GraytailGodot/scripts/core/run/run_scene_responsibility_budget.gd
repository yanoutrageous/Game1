extends RefCounted
class_name RunSceneResponsibilityBudget

const STAGE_ID := "G38"
const ROLE := "scene_lifecycle_node_wiring_signal_coordination"
const RUNTIME_OWNER := "RunRuntimeController"
const LIFECYCLE_OWNER := "RunStateMachine"
const MODAL_LAYOUT_OWNER := "RuntimeModalLayoutModel"


static func describe() -> Dictionary:
	return {
		"stage_id": STAGE_ID,
		"run_scene_role": ROLE,
		"runtime_owner": RUNTIME_OWNER,
		"lifecycle_owner": LIFECYCLE_OWNER,
		"modal_layout_owner": MODAL_LAYOUT_OWNER,
		"run_scene_may": [
			"instantiate scenes and UI nodes",
			"wire signals",
			"coordinate viewport and modal visibility",
			"delegate input, route, command feedback, result, debug meta, and scoped refresh work to helpers",
		],
		"run_scene_must_not": [
			"own a second RunContext or CommandBus",
			"write context.phase directly",
			"call context.fail_run directly",
			"decide settlement or MetaProgress commit inline",
			"own refresh metric keys or lightweight combat refresh policy inline",
			"bypass DebugGate for debug actions",
		],
		"read_only": true,
		"display_only": true,
		"no_persistence": true,
	}
