extends RefCounted
class_name MainMenuModel

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")


static func build() -> Dictionary:
	return {
		"title": "灰尾回收",
		"subtitle": "基地门厅 / 中控入口",
		"scene_hint": "主菜单提供当前可玩探索入口；出发探索页仍是配置 preview，不承担真实出发配置启动。",
		"role_hint": "当前角色展示占位：外观和穿搭入口后续归入长期系统。",
		"entries": [
			{
				"id": &"quick_start_demo",
				"label": "快速开始 / Demo Run",
				"description": "进入当前可玩探索路线；复用已有 RunScene start path，不改出发配置、奖励、结算或存档规则。",
				"target": NavigationIntentScript.TARGET_RUN,
				"payload": {
					"entry_id": &"quick_start_demo",
					"entry_label": "当前可玩探索",
					"playable_route": true,
					"route_mode": &"demo_run",
				},
				"requires_confirm": false,
				"has_badge": true,
			},
			{
				"id": &"deploy",
				"label": "出发探索",
				"description": "进入出发探索页查看资产出勤 preview；完整出发配置启动未接入。",
				"target": NavigationIntentScript.TARGET_DEPLOY,
				"requires_confirm": false,
				"has_badge": false,
			},
			{
				"id": &"long_term",
				"label": "长期系统",
				"description": "进入任务、图鉴、研究、收藏等长期系统入口占位。",
				"target": NavigationIntentScript.TARGET_LONG_TERM,
				"requires_confirm": false,
				"has_badge": false,
			},
			{
				"id": &"settings",
				"label": "设置",
				"description": "进入设置入口占位；完整设置系统后置。",
				"target": NavigationIntentScript.TARGET_SETTINGS,
				"requires_confirm": false,
				"has_badge": false,
			},
			{
				"id": &"exit_game",
				"label": "退出游戏",
				"description": "打开退出确认；退出不等于放弃探索。",
				"target": NavigationIntentScript.TARGET_EXIT,
				"requires_confirm": true,
				"has_badge": false,
			},
		],
		"notices": [
			"公司公告：当前可从快速开始进入可玩探索路线。",
			"提示：出发探索、长期系统和设置仍按 preview / display-only 边界展示。",
			"安全说明：退出游戏不会在主菜单中放弃进行中的探索。",
		],
		"shortcuts": [
			{
				"id": &"shortcut_warehouse",
				"label": "快捷：仓库",
				"description": "跳转到长期系统占位；完整仓库后置。",
				"target": NavigationIntentScript.TARGET_LONG_TERM,
				"payload": {"entry_id": &"warehouse"},
				"has_badge": false,
			},
			{
				"id": &"shortcut_codex",
				"label": "快捷：图鉴",
				"description": "跳转到长期系统占位；完整图鉴后置。",
				"target": NavigationIntentScript.TARGET_LONG_TERM,
				"payload": {"entry_id": &"codex"},
				"has_badge": false,
			},
		],
	}
