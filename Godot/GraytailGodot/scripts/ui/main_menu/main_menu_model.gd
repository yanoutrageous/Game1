extends RefCounted
class_name MainMenuModel

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")


static func build() -> Dictionary:
	return {
		"title": "灰尾回收",
		"subtitle": "基地门厅 / 中控入口",
		"scene_hint": "主菜单固定承担分流：出发探索、长期系统、设置、退出。M1 标准局作为当前可玩快捷入口保留，不替代正式出发页流程。",
		"role_hint": "当前角色展示占位：外观和穿搭入口后续归入长期系统。",
		"art09_visuals": {
			"background": PresentationMappingScript.main_menu_background_ref(),
		},
		"entries": [
			{
				"id": &"deploy",
				"label": "出发探索",
				"description": "进入出发探索页查看本次出勤配置 preview；开始/继续探索的正式归属在该页，当前仍未接真实配置启动。",
				"target": NavigationIntentScript.TARGET_DEPLOY,
				"requires_confirm": false,
				"has_badge": false,
				"art09_asset_ref": PresentationMappingScript.main_menu_entry_icon_ref(&"deploy"),
			},
			{
				"id": &"long_term",
				"label": "长期系统",
				"description": "进入任务、图鉴、研究、收藏等长期系统入口占位。",
				"target": NavigationIntentScript.TARGET_LONG_TERM,
				"requires_confirm": false,
				"has_badge": false,
				"art09_asset_ref": PresentationMappingScript.main_menu_entry_icon_ref(&"long_term"),
			},
			{
				"id": &"settings",
				"label": "设置",
				"description": "进入设置入口占位；完整设置系统后置。",
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
		"notices": [
			"公司公告：主菜单只保留固定分流入口；复杂配置进入出发探索页。",
			"提示：M1 当前可通过快捷入口开始 standard_10x10 验证局。",
			"安全说明：退出游戏不会在主菜单中放弃进行中的探索。",
		],
		"shortcuts": [
			{
				"id": &"shortcut_standard_10x10",
				"label": "快捷：开始标准局",
				"description": "M1 当前可玩入口；复用 AppShell / CommandBus / RunScene 标准局路径，不让主菜单实现 run 规则。",
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
