extends RefCounted
class_name DeployPrepModel

const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")


static func build(snapshot: Dictionary = {}) -> Dictionary:
	var config := DeployConfigScript.default_config()
	var run_active := bool(snapshot.get("run_active", false))
	var preview := DeployConfigScript.build_preview_lines(config)
	return {
		"title": "出发探索",
		"subtitle": "本局准备中心 / DeployPrepShell foundation",
		"boundary": "G18-R3 只提供准备页壳层、五个占位页签和 public config preview；不启动探索。",
		"tabs": DeployTabModelScript.build_tabs(),
		"active_tab": DeployTabModelScript.DEFAULT_TAB,
		"config": config,
		"run_start_config": DeployConfigScript.build_run_start_config(config),
		"preview_lines": preview,
		"actions": {
			"start": {
				"label": "生成出勤预览",
				"tooltip": "只生成 DeployConfig / RunStartConfig preview，不启动探索。",
				"disabled": false,
			},
			"continue": {
				"label": "继续探索",
				"tooltip": "继续探索后置，当前仅预留入口。",
				"disabled": true,
				"has_active_run": run_active,
			},
			"abandon": {
				"label": "放弃探索",
				"tooltip": "放弃探索结算后置，当前不执行。",
				"disabled": true,
			},
		},
	}


static func model_with_tab(model: Dictionary, tab_id: StringName) -> Dictionary:
	var next_model := model.duplicate(true)
	next_model["active_tab"] = tab_id
	return next_model
