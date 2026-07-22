extends RefCounted
class_name MainMenuModel

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")


static func build() -> Dictionary:
	return {
		"title": "灰尾回收",
		"subtitle": "灰尾基地 · 门厅",
		"scene_hint": "洞口通往本次探索，基地下层保存长期成长。",
		"role_hint": "当前出勤角色",
		"art09_visuals": {
			"background": PresentationMappingScript.main_menu_background_ref(),
		},
		"entries": [
			{
				"id": &"deploy",
				"label": "出发探索",
				"description": "进入洞口前往整备区，确认地图、携带物与本局委托。",
				"target": NavigationIntentScript.TARGET_DEPLOY,
				"requires_confirm": false,
				"has_badge": false,
				"art09_asset_ref": PresentationMappingScript.main_menu_entry_icon_ref(&"deploy"),
			},
			{
				"id": &"long_term",
				"label": "长期系统",
				"description": "前往基地下层，查看天赋树、档案与长期记录。",
				"target": NavigationIntentScript.TARGET_LONG_TERM,
				"requires_confirm": false,
				"has_badge": false,
				"art09_asset_ref": PresentationMappingScript.main_menu_entry_icon_ref(&"long_term"),
			},
			{
				"id": &"settings",
				"label": "设置",
				"description": "调整画面、主音量与动态表现；变更可以确认或恢复。",
				"target": NavigationIntentScript.TARGET_SETTINGS,
				"requires_confirm": false,
				"has_badge": false,
				"art09_asset_ref": PresentationMappingScript.main_menu_entry_icon_ref(&"settings"),
			},
			{
				"id": &"exit_game",
				"label": "退出游戏",
				"description": "打开退出确认；退出不等于放弃探索。",
				"target": NavigationIntentScript.TARGET_EXIT,
				"requires_confirm": true,
				"has_badge": false,
				"art09_asset_ref": PresentationMappingScript.main_menu_entry_icon_ref(&"exit_game"),
			},
		],
		"notice": {
			"title": "基地公告",
			"body": "今日回收区域已开放；完成整备后从洞口出发，长期记录可在基地下层查看。",
		},
		"shortcuts": [
			{
				"id": &"shortcut_standard_10x10",
				"label": "快捷：开始标准局",
				"description": "沿用已确认配置快速开始标准探索。",
				"target": NavigationIntentScript.TARGET_RUN,
				"payload": {
					"entry_id": &"standard_10x10",
					"entry_label": "开始标准局",
					"playable_route": true,
					"route_mode": &"standard_run",
				},
				"has_badge": true,
				"art09_asset_ref": PresentationMappingScript.key_prompt_ref(&"interact", true),
			},
			{
				"id": &"shortcut_warehouse",
				"label": "快捷：仓库",
				"description": "前往出发探索页管理当前仓库。",
				"target": NavigationIntentScript.TARGET_DEPLOY,
				"payload": {"tab": &"warehouse"},
				"has_badge": false,
			},
			{
				"id": &"shortcut_codex",
				"label": "快捷：图鉴",
				"description": "前往长期系统查看已记录的图鉴。",
				"target": NavigationIntentScript.TARGET_LONG_TERM,
				"payload": {"entry_id": &"codex"},
				"has_badge": false,
			},
		],
	}
