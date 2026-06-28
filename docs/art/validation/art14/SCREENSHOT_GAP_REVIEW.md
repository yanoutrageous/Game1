# ART-14 Screenshot Gap Review

## 0. 定位

本文件把参考图、历史截图与当前截图作为差距证据。它不运行 Godot、不新增截图、不导入素材。

## 1. 参考与当前证据

| source | path | 用途 |
| --- | --- | --- |
| Base confirmed UI | `D:\AGAME1\Base Art\Base\主菜单确定.png`、`出发探索确定.png`、`长期系统确定.png` | 主菜单 / 出发探索 / 长期系统构图、字号、层级、按钮体量参考 |
| M1 / Lua demo | `D:\AGAME1\Base Art\M1\Lua demo.mp4`、抽帧截图 | 局内 HUD、左扫描器、中央房间、右状态、底部 key bar 参考 |
| ART-13 references | `D:\AGAME1\Base Art\ART-13` | 局内房间、展开地图、面板密度、像素 UI 语言参考 |
| ART-10R screenshots | `docs/art/validation/art10r` | ART-10 技术基线与早期三屏 UI 结果 |
| ART-11 screenshots | `docs/art/validation/art11` | 产品化 UI 系统后的三屏与 HUD 结果 |
| ART-11R2 screenshots | `docs/art/validation/art11r2` | 可读性返工后的三屏与 HUD 结果 |
| ART-13 screenshots | `docs/art/validation/art13` | 局内 UI 重构、MapOverlay、Inventory、GroundLoot 当前证据 |

## 2. 主要 UI 差距表

| ui_position | reference_screenshot | current_screenshot | gap_summary | required_layer_change | required_asset_change | required_motion_change |
| --- | --- | --- | --- | --- | --- | --- |
| 主菜单 | Base `主菜单确定.png` | `art11r2_main_menu_1280x720.png` / final checks | 构图已接近右侧入口，但基地门厅语义、角色展示和公告材质仍不足 | 增加 background_static、scene_midground、character_or_actor、notice panel 分层 | 需要基地门厅背景、角色展示、公告牌、四大入口按钮状态 | 页面进入淡入、按钮 hover、红点 ping |
| 出发探索总页 | Base `出发探索确定.png` | `art11r2_deploy_prep_1280x720.png` / ART13 baseline deploy | 左中右结构存在，但五页签资产、摘要面板、角色整备层仍偏工程面板 | 背景、角色区、tab、卡片、summary panel、slot 分层 | 需要地图卡、装备槽、消耗品槽、目标 badge、开始探索大按钮 | tab switch、卡片 selected、开始按钮 ready pulse |
| 出发探索-地图页 | Base deploy reference | art11 / art11r2 deploy | 地图页尚未形成地图卡专用视觉；真实地图不应提前显示 | tab + card + detail modal + lock overlay | 地图模式卡、难度 badge、风险/收益图标 | 卡片 hover、locked shake、detail modal |
| 出发探索-仓库页 | Base deploy reference | current_screenshot_missing | 缺少当前截图，需补仓库出勤视角 | inventory card、slot、capacity counter | 仓库物品卡、装备/消耗品图标、容量条 | add/remove loadout、capacity blocked |
| 出发探索-申领页 | Base deploy reference | current_screenshot_missing | 缺少当前截图，申领与仓库视觉需区分 | requisition list、price badge、confirm modal | 申领卡、价格图标、推荐 badge | purchase/claim feedback |
| 出发探索-目标页 | Base deploy reference | current_screenshot_missing | 缺少当前截图，单局目标卡未成型 | target card、condition badge、reward icon | 目标卡、失败条件图标、奖励 banner | select target、invalid pulse |
| 出发探索-出勤配置页 | Base `出发探索确定.png` | art11r2 deploy | 摘要已存在但信息分组和主按钮体量需强化 | summary panel、slot strip、primary action | 大号开始/继续/放弃按钮，配置合法性 badge | ready pulse、blocked shake |
| 长期系统总页 | Base `长期系统确定.png` | `art11r2_long_term_1280x720.png` | 左档案、中网格、右详情仍需美术资产；背景档案室语义不足 | archive background、profile rail、grid card、detail panel | 档案室背景、图鉴卡、锁定态、详情框 | module switch、unlock glow |
| 长期系统-目标 | Long-term reference | current_screenshot_missing | 目标系统只有结构需求，缺当前截图 | goal card、progress bar、reward badge | 目标卡、进度条、奖励图标 | progress fill、claim pulse |
| 长期系统-图鉴 | Long-term reference | art11r2 long_term 可参考 | 图鉴墙空间感不足，发现状态缺素材 | codex grid、silhouette、state badge | 问号轮廓、已遇到/已拥有/已补全状态 | card reveal、new ping |
| 长期系统-研究 | Long-term reference | current_screenshot_missing | 缺当前截图 | research tree/list、requirement panel | 研究节点、条件线、完成 badge | unlock route glow |
| 长期系统-个人资历 / 历史战绩 | 结算历史案 | current_screenshot_missing | 缺历史战绩入口和快照 UI | profile panel、history list、detail modal | 战绩缩略图、结果 banner、称号/徽章 | list enter、result badge |
| 长期系统-抽奖 | Long-term reference | current_screenshot_missing | 后续模块，当前暂缓 | draw panel、reward preview | 抽奖按钮、奖池卡、保底条 | draw animation、reward reveal |
| 长期系统-收藏 / 外观 | Main menu / long-term references | current_screenshot_missing | 后续模块，缺外观预览 | wardrobe preview、collection grid | 外观卡、角色预览、收藏 badge | preview swap、equip flash |
| 局内 HUD | M1 / ART-13 前三张 | `art13/final_hud_1280x720.png` | 结构已左中右底，但中央房间仍缺对象动效和房间状态差异 | scanner、room、protocol、bottom bar 已有；需 actor/monster/fx 层 | 怪物、事件对象、宝箱开关、撤离装置、状态 badge | room enter、search、danger ping、key press |
| 小地图 MiniMap | ART-13 / Lua MiniMap | `art13/final_hud_1280x720.png` | 可读性提升，但缺污染/高危/标记多状态资产 | tile、marker、number、pollution、selection | 32/64 map tile/marker 状态变体 | scan pulse、tile reveal、mark ping |
| 展开地图 MapOverlay | ART-13 第 4 张 | `art13/final_map_overlay_1280x720.png` | 地图变大但仍偏暗，格子详情和操作按钮需更产品化 | overlay dim、grid、detail、action bar | 64 map tiles、detail panel、marker icons | open fade、tile select、return confirm |
| 房间主视图 | ART-13 in-run refs / Lua DungeonRoom | `art13/final_hud_1280x720.png` | 中央房间成为主体，但普通/雷/怪/事件/撤离差异仍依赖少量资产 | room background、prop、actor、hotspot、fx | 房型背景、props、character、monster/event sprites | enter fade、object idle、fx feedback |
| 普通房 | 房间案 | `art13/final_hud_1280x720.png` | 普通房可用，但搜索/耗尽状态对象弱 | room background、search hotspot、loot fx | normal room、search marker、empty marker | search progress/success/empty |
| 雷房 | 房间案 / 地图案 | current_screenshot_missing | 缺雷房当前截图和触发反馈 | danger overlay、trap prop、warning badge | mine trap、danger marker、pollution flicker | trap trigger、warning flash |
| 宝箱房 | 房间案 / M3 | existing props / ART13 references | 有箱子素材候选，但开关状态和打开动效未规格化 | chest prop、state badge、loot fx | chest closed/open、loot burst | chest open、reward popup |
| 事件房 | 房间案 | current_screenshot_missing | 缺事件对象和选择 UI 当前截图 | event object、choice modal、result toast | event object、choice buttons、risk badge | event trigger、option selected |
| 怪物 / 战斗房 | 战斗案 | current_screenshot_missing | 缺怪物战斗可视态 | monster sprite、hp bar、skill warning、hit fx | monster sprite、warning icon、combat frame | appear、hit、defeat、clear |
| 商人 / 回收终端 | 房间案 / M3 | existing prop candidates | 有商人台/回收装置候选，缺 UI 交易态 | merchant prop、trade panel、safe yield badge | merchant table、terminal active/inactive | trade confirm、safe yield lock |
| 撤离点 | 局内流程 | existing prop candidates | 有撤离装置候选，缺激活态和确认层 | exit beacon、modal、reward summary | exit beacon off/on、extract button | activate, confirm, transition |
| 搜索反馈 | 局内流程 / M3 | `art13/final_search_feedback_1280x720.png` | 文案已清理，视觉仍偏 toast 文本 | progress bar、result badge、loot popup | search icon、empty/success/danger state | progress, success pop, empty fade |
| 事件选择 | 局内流程 | current_screenshot_missing | 缺当前截图 | modal, option cards, warning badge | modal panel, option button variants | modal dim, choice confirm |
| 战斗反馈 | 战斗案 | current_screenshot_missing | 缺当前截图 | hit fx, hp bar, warning overlay | hit sprites, skill telegraph | hit, warning, defeat |
| GroundLoot | M3 | `art13/final_ground_loot_1280x720.png` | 有可达/不可用态，缺真实地面物品卡丰富态 | loot panel、item cards、capacity badge | item card frame、rarity badge、pickup icon | pickup fly-to-bag, blocked shake |
| Inventory | M3 | `art13/final_inventory_1280x720.png` | 文本边界已改善，仍需卡片化和图标状态 | backpack panel、item card、tooltip、action buttons | item cards、slot icons、capacity bar | item select, use, drop |
| Item Tooltip | 物品资产模型 | inventory screenshot | Tooltip 已短化，缺视觉层级 | tooltip panel、icon、effect badge | tooltip frame、effect icons | appear/disappear |
| 物品确认 | M3 | current_screenshot_missing | 拾取/丢弃/替换/使用确认缺截图 | modal, item comparison, confirm buttons | confirm modal, replace arrows | confirm, cancel, replace |
| 背包满 / 重量不足提示 | M3 | ground_loot screenshot | 当前只有短提示，缺阻塞动效 | warning toast、capacity bar、shake target | warning badge、capacity bar red state | blocked shake |
| 撤离确认 | 局内流程 / 结算案 | current_screenshot_missing | 缺当前截图 | modal、reward preview、risk list | extraction modal、summary icons | confirm transition |
| 失败 / 放弃确认 | 局内流程 / 结算案 | current_screenshot_missing | 缺当前截图 | modal、loss preview、salvage preview | failure modal、loss icons | warning dim、confirm |
| 本局结算报告 | 结算历史案 | current_screenshot_missing | 结算页未形成正式截图 | result banner、resource rows、item sections、next buttons | success/failure banners、count-up assets | count-up、item kept/lost、report reveal |
| 历史战绩列表 | 结算历史案 | current_screenshot_missing | 缺当前截图 | list、filters、thumbnail、result badge | history row, result icons | filter switch |
| 历史战绩详情 | 结算历史案 | current_screenshot_missing | 缺当前截图 | detail panel、map summary、event list | history detail frame, mini map thumbnail | detail open |
| 设置 | 主菜单策划案 | current_screenshot_missing | 缺当前截图 | settings sections、slider/toggle、reduce motion | setting panel, toggle, slider | toggle/slider feedback |
| 暂停菜单 | 局内流程 | historical accidental pause screenshots | 有可见暂停风险，需正式化 | pause overlay、button stack、confirm modal | pause panel, resume/settings/abandon buttons | pause dim |
| 通用弹窗 | UI修改案 | multiple screenshots | 通用弹窗风格需统一 | modal overlay、panel、button layer | modal panel nine-slice, buttons | modal dim, open/close |
| toast / notice / warning | UI修改案 | art13 feedback | 文案已降噪，需视觉状态化 | toast stack、badge、duration | toast panel states, warning icon | toast, warning flash |
| 红点 / 角标 | 主菜单 / 长期系统 | current_screenshot_missing | 缺统一红点素材和规则 | badge layer、red dot、new marker | red dot, new badge, warning badge | red dot ping |
| Debug UI dev-only | UI修改案 | ART11R2 warnings | 仍需继续隔离，不能混入玩家界面 | debug_dev_only layer only | no player runtime asset | dev gate only |

## 3. 当前结论

- P0 最大差距：局内地图 / 房间对象 / M3 物品循环 / 结算报告的资产和动效规格。
- P1 最大差距：长期系统子页面、战斗 / 事件房表现、商人/回收终端。
- P2 / 暂缓：抽奖、收藏外观、完整角色换装、最终发布级 polish。

## 4. 截图结论的代码 / 图片校正

历史截图只能说明视觉表现，不等于素材真实缺失。结合当前代码和 runtime 图片后，差距应按以下方式校正：

| screenshot gap | code / image fact | corrected decision |
| --- | --- | --- |
| 主菜单仍需要更强基地门厅语义 | 主菜单 shell 已有背景层和 `ui.main_menu.background.no_text` runtime asset | ART-15 先做入口按钮 / 角色展示 / 公告板状态，不优先重导整屏背景 |
| 出发探索按钮和卡片仍显模板化 | deploy button/icon/panel 已导入但未完全接线 | 先处理接线、slot state、ready/blocked/warning 变体，再考虑重画 |
| 长期系统像卡片模板 | 代码已有长期模块框架，但缺专用卡面素材 | 需要 long-term card/badge/thumbnail，不是新页面结构 |
| HUD 信息和反馈仍有产品化缺口 | HUD panel、room background、key prompt 已有；ART13/11R2 已修部分文案 | 重点补 feedback visual、room object state、event/combat affordance |
| MapOverlay 仍偏暗 / 状态少 | minimap 基础图标已存在，MapOverlay 代码已存在 | 补 selected / danger / unresolved / polluted state 和 detail frame |
| Inventory/GroundLoot 有图标但视觉弱 | item icons 已存在，面板代码存在 | 补 item card、tooltip、capacity feedback，而不是重复 item icon |
| Settlement / History 缺截图 | result panel 代码和 scene 已存在 | 需要结算报告专用视觉和截图验证，属于 P0 |

因此 ART-14 不是单纯输出“美术需求清单”，而是把需求拆成：
- `existing_runtime_asset`：已有、可复用或待接线。
- `candidate_pending_import`：Base Art / Draw 候选，需 ART-15 审核。
- `state_variant_needed`：已有基础图但缺状态变体。
- `new_art_needed`：当前代码和图片都没有覆盖。
- `forbidden_reference_only`：只能参考，不能导入。
