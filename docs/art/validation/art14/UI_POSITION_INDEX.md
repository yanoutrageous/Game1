# ART-14 UI Position Index

## 0. 定位

本文件是 ART-14 的 UI 位置总索引。它只整理策划案、参考图和历史截图中的 UI 表面，不授权实现、导入素材或修改 Godot。

来源摘要：

- Base Docs：主菜单、出发探索、局内地图、局内流程、房间 / 遭遇、战斗、M3 物品闭环、长期系统、结算 / 历史战绩、UI 信息架构。
- 参考图：`Base Art\Base`、`Base Art\M1`、`Base Art\ART-13`。
- 当前截图：`docs/art/validation/art10r`、`art11`、`art11r2`、`art13`。

## 1. UI 位置索引

| id | ui_position | source_doc | product_role | visible_info | forbidden_info | interaction | current_godot_surface | spec_status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| UI-01 | 主菜单 | 主菜单策划案 / UI修改策划案 | 第一层入口与基地氛围 | 出发探索、长期系统、设置、退出、角色展示、短公告、红点 | 资源明细、背包、地图真实内容、局内状态详情 | 大入口、快捷入口、设置、退出确认 | art11r2 / art11 截图 | needs_art_asset_spec |
| UI-02 | 出发探索总页 | 出发探索修正案 | 出发前准备总框架 | 地图、仓库、申领、目标、出勤配置入口与摘要 | 真实地图布局、真实房间内容、结算报告本体 | tab 切换、开始 / 继续 / 放弃探索 | art11r2 / art13 deploy 截图 | needs_layer_spec |
| UI-03 | 出发探索-地图页 | 出发探索修正案 / 局内地图案 | 选择地图模式、难度、区域、规则 | 模式、风险倾向、收益倾向、解锁、推荐 | 真实撤离点、Boss 位置、真实房间分布 | 卡片选择、筛选、详情弹窗 | art11r2 deploy 截图 | needs_asset_matrix |
| UI-04 | 出发探索-仓库页 | 出发探索修正案 / M3 | 出勤视角下的仓库选择 | 可带入装备、消耗品、容量、适配提示 | 完整仓库管理、结算报告、历史战绩 | 装备/消耗品选择、详情、回跳 | current_screenshot_missing | needs_current_screenshot |
| UI-05 | 出发探索-申领页 | 出发探索修正案 | 出发前购买 / 领取 / 合法出售入口 | 推荐内容、价格、领取条件、地图适配 | 普通局内背包自由出售 | 购买、领取、出售确认 | current_screenshot_missing | needs_current_screenshot |
| UI-06 | 出发探索-目标页 | 出发探索修正案 / 长期系统整合 | 单局目标选择 | 目标条件、失败条件、奖励类型、适配状态 | 长期任务完整管理 | 选择目标、详情、匹配提示 | current_screenshot_missing | needs_current_screenshot |
| UI-07 | 出发探索-出勤配置页 | 出发探索修正案 | 汇总出发配置合法性 | 地图、装备、消耗品、目标、背包容量、风险提示 | 深层仓库 / 结算 / 历史 | 开始、继续、放弃、跳转修改 | art11r2 deploy 截图 | needs_layer_spec |
| UI-08 | 长期系统总页 | 长期系统整合 / 长期系统界面 | 长期系统入口壳 | 目标、图鉴、研究、个人资历、抽奖、收藏入口 | 局内配置、直接结算、局内状态修改 | 模块切换、红点、跳转 | art11r2 / art11 long_term 截图 | needs_redraw |
| UI-09 | 长期系统-目标 | 长期系统整合 | 长期目标 / 成就 / 委托聚合 | 可见目标、完成状态、奖励、红点 | 单局委托本体长期化误读 | 领取、筛选、详情 | current_screenshot_missing | needs_new_screen |
| UI-10 | 长期系统-图鉴 | 长期系统整合 | 内容资料库 | 地图、怪物、藏品、装备、事件、规则发现状态 | 未发现内容全量泄露 | 筛选、详情、来源跳转 | art11r2 long_term 可参考 | needs_asset_spec |
| UI-11 | 长期系统-研究 | 长期系统整合 | 研究 / 解锁提示 | 研究项、进度、条件、奖励 | 直接修改仓库或局内状态 | 研究详情、领取 / 查看 | current_screenshot_missing | needs_new_screen |
| UI-12 | 长期系统-个人资历 / 历史战绩 | 长期系统整合 / 结算历史案 | 玩家履历与战绩入口 | 等级、统计、历史战绩摘要、称号、徽章 | 重新结算历史收益 | 筛选、打开战绩详情 | current_screenshot_missing | needs_new_screen |
| UI-13 | 长期系统-抽奖 | 长期系统整合 | 抽奖 / 奖励入口 | 可抽取池、凭证、保底、结果 | 主菜单直接承载抽奖主界面 | 抽取、结果、红点 | current_screenshot_missing | deferred |
| UI-14 | 长期系统-收藏 / 外观 | 长期系统整合 / 主菜单策划案 | 外观、收藏展示 | 已拥有外观、展示、解锁来源 | 修改局内背包 | 预览、装备、筛选 | current_screenshot_missing | deferred |
| UI-15 | 局内 HUD | 局内流程 / ART-13 | 局内决策总界面 | 当前房间、压力、协议、收益、操作、状态 | Debug schema、CommandBus、TruthMap 内部字段 | 搜索、背包、掉落、地图、清理、撤离、暂停 | art13 final_hud | needs_p0_assets |
| UI-16 | 小地图 MiniMap | 局内地图 | 核心地图玩法局内常驻层 | 当前格、未知/已知/扫描/标记/撤离/雷数 | 真实未揭示层、测试工具数据 | 展开地图、标记、查看风险 | art13 final_hud / baseline | needs_p0_assets |
| UI-17 | 展开地图 MapOverlay | 局内地图 | 大范围地图与格子详情 | 房间摘要、状态、标记、回传、撤离、风险 | TruthMap 原始调试信息 | 选格、标记、回传、关闭 | art13 final_map_overlay | needs_p0_assets |
| UI-18 | 房间主视图 | 局内流程 / 房间类型 / ART-13 | 中央可玩空间 | 房间背景、角色、怪物/事件/箱子/出口对象 | 整屏参考图直用 | 移动、搜索、遭遇处理 | art13 final_hud | needs_room_asset_pass |
| UI-19 | 普通房 | 房间类型 | 基础探索房间 | 雷数、搜索状态、普通掉落 | 复合房型误读 | 搜索、移动、回传 | art13 room screenshot | p0 |
| UI-20 | 雷房 | 房间类型 / 局内地图 | 风险房间 | 雷险、触发、损失、污染/警示 | 提前泄露未揭示雷 | 触发、失败/损失反馈 | reference_only | p0 |
| UI-21 | 宝箱房 | 房间类型 / M3 | 物资获取房间 | 宝箱状态、开启、掉落 | 唯一物普通掉落 | 开启、拾取、背包满提示 | existing_props | p0 |
| UI-22 | 事件房 | 房间类型 / 局内流程 | 事件选择空间 | 事件对象、选项、结果、风险 | 完整事件池提前泄露 | 选择、确认、结果反馈 | art13 right panel | p1 |
| UI-23 | 怪物 / 战斗房 | 战斗案 / 房间类型 | 战斗遭遇空间 | 怪物、HP、技能警告、清理状态、奖励 | 怪物完整数值表泄露 | 战斗、撤退、清理 | reference_only | p1 |
| UI-24 | 商人 / 回收终端 | 房间类型 / M3 | 特殊交易 / 安全收益 | 商人台、出售、回收、安全收益 | 普通背包自由出售误用 | 交易、确认、收益锁定 | existing_prop_candidate | p1 |
| UI-25 | 撤离点 | 局内流程 / 房间类型 | 成功撤离入口 | 撤离装置、可撤离状态、确认 | 非出口直接撤离 | 激活、确认、结算跳转 | existing_prop_candidate | p0 |
| UI-26 | 搜索反馈 | 局内流程 / M3 | 搜索过程与结果 | 搜索中、成功、空、掉落、不可搜索 | 内部 reason code | 触发搜索、结果 toast | art13 final_search_feedback | p0 |
| UI-27 | 事件选择 | 局内流程 / 房间类型 | 事件决策弹窗 | 选项、代价、风险、结果 | 事件池内部 id | 选择、确认、取消 | current_screenshot_missing | p1 |
| UI-28 | 战斗反馈 | 战斗案 | 战斗即时反馈 | 命中、受击、技能预警、清理 | 伤害调试日志 | 攻击、闪避、撤退 | current_screenshot_missing | p1 |
| UI-29 | GroundLoot | M3 | 地面物品池 | 地面物品、可拾取、容量不足 | 后端实例 id | 拾取、详情、关闭 | art13 final_ground_loot | p0 |
| UI-30 | Inventory | M3 | 局内背包 | 容量、黑币、安全收益、物品、装备、tooltip | 仓库完整管理、source id | 使用、丢弃、详情 | art13 final_inventory | p0 |
| UI-31 | Item Tooltip | 物品资产模型 / M3 | 物品详情层 | 名称、类型、稀有度、重量、效果、标签 | instance_id、source_path | 悬停 / 选择显示 | art13 inventory | p0 |
| UI-32 | 物品拾取 / 丢弃 / 替换 / 使用确认 | M3 | 物品流转确认 | 行为、目标物、容量、结果 | 规则绕过 | 确认、取消、替换 | current_screenshot_missing | p0 |
| UI-33 | 背包满 / 重量不足提示 | M3 | 阻塞反馈 | 容量不足、重量不足、留在地面 | blocked_capacity 直出 | toast、shake、详情 | art13 ground_loot | p0 |
| UI-34 | 撤离确认 | 局内流程 / 结算案 | 撤离前确认 | 当前收益、风险、未拾取物、目标状态 | 非撤离点误触 | 确认 / 取消 | current_screenshot_missing | p0 |
| UI-35 | 失败 / 放弃确认 | 局内流程 / 结算案 | 失败或主动放弃确认 | 损失、抢救、放弃后果 | 视作成功撤离 | 确认 / 取消 | current_screenshot_missing | p0 |
| UI-36 | 本局结算报告 | 结算历史案 / M3 | 当局结果反馈 | 成功/失败/放弃、资源、物品、图鉴、研究、历史写入 | 仓库完整管理 | 确认、跳转、回主菜单 | current_screenshot_missing | p0 |
| UI-37 | 历史战绩列表 | 结算历史案 / 长期系统 | 长期战绩查询 | 地图、结果、收益、步数、委托、日期 | 重新结算 | 筛选、打开详情 | current_screenshot_missing | p1 |
| UI-38 | 历史战绩详情 | 结算历史案 | 单局快照回看 | 结算快照、物品、事件、地图摘要 | 随当前仓库变化 | 返回、筛选、跳转图鉴 | current_screenshot_missing | p1 |
| UI-39 | 设置 | 主菜单策划案 | 系统设置 | 画面、音频、操作、语言、动效、红点、公告 | 修改存档核心状态 | 开关、滑杆、保存 | current_screenshot_missing | p1 |
| UI-40 | 暂停菜单 | 局内流程 / UI修改案 | 局内临时暂停 | 返回、设置、放弃、操作提示 | 结算结果 | 继续、设置、放弃确认 | art13 / baseline pause risk | p0 |
| UI-41 | 通用弹窗 | UI修改案 | 详情 / 确认容器 | 标题、正文、主次按钮 | 无遮罩直接压复杂背景 | 确认、取消、关闭 | multiple screenshots | p0 |
| UI-42 | 通用 toast / notice / warning | UI修改案 | 短反馈层 | 成功、警告、奖励、阻塞 | 后端 code | 自动消失、堆叠、reduce motion | art13 feedback | p0 |
| UI-43 | 红点 / 角标 | 主菜单 / 长期系统整合 | 待处理提示 | 新增、可领取、未读、警告 | 资源具体数值 | 点击跳转、清除 | current_screenshot_missing | p1 |
| UI-44 | Debug UI dev-only | UI修改案 | 开发诊断层 | schema、debug、TruthMap、CommandBus | 玩家界面直出 | dev gate、折叠、禁生产 | ART11R2 warnings | dev_only |

## 2. 统一边界

- UI 不直接拼接 `res://` 路径，不直接读取 Base Art / Draw。
- UI 不显示 TruthMap、RunContext、CommandBus、Ledger 内部状态。
- Debug UI 必须 dev-only，不进入玩家主界面。
- 出发探索页不提前生成或显示真实地图。
- 结算报告只展示当局结果，历史战绩只保存快照，不重新结算。

## 3. current_code_surface 与图片事实校正

本节补充当前 Godot 代码与 runtime 图片实际情况，避免只按策划案判断 UI 和美术缺口。

| ui_position | current_code_surface | current_asset_state | corrected_status |
| --- | --- | --- | --- |
| UI-01 主菜单 | `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd`；当前代码动态构建背景、角色展示、顶部入口、大按钮、公告和 key bar，仍有固定 `Rect2` 布局 | `assets/ui/main_menu/main_menu_bg_no_text.png` 已存在，1672x941，manifest asset_id 为 `ui.main_menu.background.no_text` | 不是缺主菜单背景；缺的是入口按钮组状态、角色展示正式素材、公告板和红点角标 |
| UI-02/03/04/05/06/07 出发探索 | `scripts/ui/deploy_prep/deploy_prep_shell.gd`、`deploy_tab_model.gd`、`deploy_prep_model.gd`；代码已有 tab、filter、card、summary、action 区 | `ui.deploy.button.*`、`ui.deploy.icon.*`、`ui.deploy.panel.*` 已在 Godot assets / manifest；多项 note 为 not wired | 优先判断接线和语义审核，不应重复导入同类按钮 / icon |
| UI-08/09/10/11/12/13/14 长期系统 | `scripts/ui/long_term/long_term_shell.gd`、`long_term_content_framework.gd`；代码已有 6 模块和卡片框架 | 当前缺专用 long-term 卡面素材，主要依赖 Skin Kit panel | 缺口是真正图鉴 / 档案 / 研究 / 抽奖 / 收藏卡面和 badge，不是缺页面入口 |
| UI-15 HUD / Run Surface | `scripts/ui/run_surface/run_surface.gd`、`scripts/ui/shell/run_ui_view_model.gd`、`scripts/ui/hud/hud_view_model.gd`；代码已有 left scanner、room area、right status、bottom actions、feedback label | `assets/ui/hud/*.png`、`assets/rooms/*.png`、`assets/props/*.png` 已存在 | P0 应补交互反馈 visual、room object state、combat/event object，而不是重做所有 HUD panel |
| UI-16 MiniMap | `scripts/ui/minimap/minimap_panel.gd`、`minimap_view_model.gd`；scene 为 `scenes/ui/minimap/minimap_panel.tscn` | 32x32 minimap tile / marker / number 1-3 已存在 | P0 缺 number 4-8、selected、danger、polluted、unresolved 等状态 |
| UI-17 MapOverlay | `scripts/ui/map_overlay/map_overlay_panel.gd`；scene 为 `scenes/ui/map_overlay/map_overlay_panel.tscn` | 复用 minimap 图标和 Skin Kit panel | P0 缺大地图 frame、selected marker、detail state visual |
| UI-29 GroundLoot | `scripts/ui/ground_loot/ground_loot_panel.gd` | item icons 已存在，card / feedback 素材不足 | 缺拾取卡、阻断反馈、容量提示，而不是缺基础物品图标 |
| UI-30 Inventory | `scripts/ui/inventory/inventory_panel.gd` | item icons 已存在，capacity / rarity / tooltip 专用素材不足 | 缺 inventory card、tooltip panel、capacity bar state |
| UI-36 Settlement / Result | `scripts/ui/result/result_panel.gd`；scene 为 `scenes/ui/result/result_panel.tscn` | 当前未见专用结算报告图片资产 | 代码入口存在，视觉缺口是 success/fail/abandon report panel 与 history thumbnail |
| UI-44 Debug UI | `scripts/ui/dev/dev_diagnostics_panel.gd` | 不应有玩家 runtime asset | 继续保持 dev-only，不能把 schema / reason code / debug 图纳入美术规格 |

实际图片结论：
- 当前 `Godot/GraytailGodot/assets` 下已有 74 张 PNG，覆盖 minimap、HUD panel、room background、props、item、deploy UI、key prompt、main menu background、player idle sprite。
- `Base Art/05_export_runtime_candidates/art07_first_batch` 下有 52 张候选 PNG，很多已进入 Godot runtime；后续导入前必须去重。
- `Draw/30_game_ready` 下有角色帧和调试检测图，角色可作为后续候选，`debug_detected_boxes.png` 禁止导入。
