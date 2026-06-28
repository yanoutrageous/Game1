# ART-14 Runtime Import Priority

## 0. 定位

本文档只给 ART-15 之后的 runtime 导入优先级建议，不授权本阶段导入图片、不修改 `asset_manifest.csv`、不复制 Base Art / Draw 素材。

优先级判断同时参考：
- Base Docs 的玩法与 UI 位置要求。
- 当前 Godot UI 代码表面。
- 当前 Godot runtime 图片实际存在情况。
- Base Art / Draw 中的候选图片实际存在情况。
- ART-10R / ART-11 / ART-11R2 / ART-13 历史截图暴露的问题。

## 1. 当前已可用的 runtime asset

| group | existing runtime assets | actual image state | import priority impact |
| --- | --- | --- | --- |
| minimap core | `icon.minimap.*`, `icon.room.*`, `icon.minimap.number.1/2/3` | 32x32 PNG 已在 Godot assets 中存在，manifest 有登记 | ART-15 不应重复导入同名基础图；优先补状态缺口和号码扩展 |
| HUD panels | `ui.hud.panel.left`, `ui.hud.panel.protocol`, `ui.hud.bottom_bar`, `ui.hud.mine_risk_tag`, `ui.hud.bar.*` | 305-684px panel / 419x72 bar / 590x176 bottom bar 已存在 | 优先复用，后续只补 compact / warning / selected 变体 |
| room backgrounds | `room.background.normal/mine/chest/event/monster/exit` | 1254x1254 room background 已存在 | 已满足首批 room type 背景，不应作为 ART-15 P0 重复新制 |
| props | `prop.chest.closed`, `prop.mine.trap`, `prop.gold.pile`, `prop.art07.*` | 160/256px prop 已存在，部分 ART07 prop 仍需语义审核 | P0 优先补状态变体，不是补基础关闭箱子 / 雷陷阱 |
| item icons | `item.consumable.*`, `item.equipment.*`, `item.recovered.ore` | 57-94px item PNG 已存在 | P0 应补 card / rarity / capacity feedback，而非重复基础图标 |
| deploy UI | `ui.deploy.button.*`, `ui.deploy.icon.*`, `ui.deploy.panel.*` | button / icon / panel 已在 manifest，note 标为 not wired / needs review | 导入优先级低于代码接线与语义审核 |
| key prompts | `ui.key_prompt.e/esc/f/m/q/t` | 65-71px PNG 已存在，manifest note 标为 not wired | ART-15 应优先接线与统一 state，而不是重导入 |
| main menu bg | `ui.main_menu.background.no_text` | 1672x941 PNG 已存在 | 可作为主菜单背景候选，但需要语义遮罩和 16:9 适配，不是整屏确定稿直用 |
| player sprite | `sprite.player.default`, `sprite.player.idle.*` | 128x128 单帧方向图已存在 | 运行态可先用；角色展示 / walk 动画仍需后续审核导入 |

## 2. P0 import / wiring priority

| rank | target | reason | existing coverage | ART-15 action | notes |
| --- | --- | --- | --- | --- | --- |
| P0-01 | minimap / map overlay 状态补全 | 地图是核心玩法，且已有代码表面与基础图标 | 已有 unknown/scanned/explored/cleared/player/room/1-3 | 补 `number.4-8`、selected、danger、polluted、unresolved 状态；或明确 fallback | 不导入 debug_detected_boxes |
| P0-02 | search / command / warning feedback set | ART-13/11R2 已暴露交互反馈要求，玩家需要短反馈 | 主要是代码 label / panel，缺独立 feedback visual | 新建 `ui.feedback.search_state`、toast/warning badge，或复用 common panel | 禁止内部 reason code 直出 |
| P0-03 | chest / mine / extract 状态变体 | 房间可交互对象需要清楚状态 | 已有 closed chest、open chest candidate、mine trap、exit device candidate | 导入 open/empty/triggered/active 状态并登记 proposed asset_id | 优先使用 Base Art staging 候选，经 ART-15 审核 |
| P0-04 | inventory / ground loot item card and capacity feedback | M3 闭环需要可读的物品流转 UI | 物品图标存在，card/tooltip/capacity feedback 不完整 | 补 card、tooltip panel、capacity/weight blocked feedback | 不改 inventory 规则 |
| P0-05 | settlement / run end report panels | 结算报告是单局闭环关键 UI | 当前只有 result panel 代码 / scene，专用美术不足 | 新制 success/fail/abandon banner、report frame、history thumbnail frame | 与历史战绩区复用 |

## 3. P1 priority

| target | reason | existing coverage | ART-15+ action |
| --- | --- | --- | --- |
| event choice card / event object variants | 事件房需要决策和结果反馈 | event room bg、anomaly core prop 有候选 | 补 choice card、risk/reward icon、resolved state |
| monster / combat visual set | 战斗房不能只靠文字 | monster room bg 存在，monster sprite 缺失 | 首批基础怪物 idle/attack/hit/defeated |
| long-term module card set | 长期系统有代码 shell，但卡面语义仍弱 | 主要依赖 Skin Kit panel | 目标/图鉴/研究/历史/抽奖/收藏模块卡面和 badge |
| settings / pause controls | 通用 UI 必需但非美术首要瓶颈 | 代码表面不完整 | toggle/slider/segmented control 组件化 |

## 4. P2 / deferred

| target | reason |
| --- | --- |
| gacha full presentation | 长期系统玩法未完整落地，先保留入口和状态规范 |
| final character portrait / collection cosmetics | 缺最终角色立绘方向，不能用当前 Draw debug / sheet 直接代替 |
| full animated room object set | 首批应只做关键状态和少量动效，避免大规模素材导入 |
| complete event pool visuals | 需要事件池内容确认后再批量美术化 |

## 5. 禁止导入 / 禁止误用

| source | rule |
| --- | --- |
| `D:\AGAME1\Base Art\Base\*确定.png` | 只能作为构图和视觉语义参考，不得作为唯一 runtime UI 背景 |
| `D:\AGAME1\Base Art\M1\Lua demo.mp4` | 只能作为 HUD 节奏、key bar、房间结构参考 |
| `D:\AGAME1\Draw\30_game_ready\**\debug_detected_boxes.png` | 调试检测图，禁止导入 |
| `D:\AGAME1\Draw` / `D:\AGAME1\Base Art` runtime path | Godot 运行时不得直接读取 |
| 未登记 manifest 的最终图片 | 不进入 runtime |

## 6. ART-15 前置判断

ART-15 进入前建议先完成：
- 对现有 manifest 中 `not wired` / `needs_semantic_review` 项做接线或降级判断。
- 对 Base Art staging 候选按 `source_sha256 + proposed_asset_id + usage_scope` 建立导入批次。
- 为每个 P0 导入项明确 fallback：没有变体时使用哪个现有 asset_id，或回退到 Skin Kit panel。
- 先导入小批核心状态，不做全量角色 / 事件 / 长期系统素材。

