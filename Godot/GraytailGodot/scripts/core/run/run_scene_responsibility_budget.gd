extends RefCounted
class_name RunSceneResponsibilityBudget

const STAGE_ID := "G38"
const ROLE := "scene_lifecycle_node_wiring_signal_coordination"
const RUNTIME_OWNER := "RunRuntimeController"
const LIFECYCLE_OWNER := "RunStateMachine"
const MODAL_LAYOUT_OWNER := "RuntimeModalLayoutModel"
const MODAL_COORDINATION_OWNER := "RunSceneModalController"
const I3R_SOURCE_LINE_BASELINE := 2959
const MAX_SOURCE_LINE_GROWTH := 21
const MAX_SOURCE_LINES := I3R_SOURCE_LINE_BASELINE + MAX_SOURCE_LINE_GROWTH
const MAX_FUNCTION_COUNT := 176


static func describe() -> Dictionary:
	return {
		"stage_id": STAGE_ID,
		"run_scene_role": ROLE,
		"runtime_owner": RUNTIME_OWNER,
		"lifecycle_owner": LIFECYCLE_OWNER,
		"modal_layout_owner": MODAL_LAYOUT_OWNER,
		"modal_coordination_owner": MODAL_COORDINATION_OWNER,
		"source_line_baseline": I3R_SOURCE_LINE_BASELINE,
		"max_source_line_growth": MAX_SOURCE_LINE_GROWTH,
		"max_source_lines": MAX_SOURCE_LINES,
		"max_function_count": MAX_FUNCTION_COUNT,
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
			"own the modal root registry, focus traversal, or input-shield ordering inline",
			"bypass DebugGate for debug actions",
		],
		"read_only": true,
		"display_only": true,
		"no_persistence": true,
	}
