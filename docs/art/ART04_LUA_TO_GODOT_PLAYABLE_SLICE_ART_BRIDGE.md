# ART-04 Lua 原型到 Godot 可玩竖切美术桥接包

## 0. 文档定位

本文档是 R4 美术生产前置桥接包，用于把 Lua / UrhoX 原型素材经验、当前 Godot 可接入接口、首批图片需求候选和后续 R5 准入条件整理到同一份美术侧工作文档中。

本文档不是执行授权，不是导入计划，不是 manifest 修改，不是 Godot 资源变更，也不是图片入库指令。本文档不授权复制 Lua 素材、不授权写入 Base Art registry、不授权修改 Godot runtime assets、不授权修改 `asset_manifest.csv`、AssetCatalog、ContentDB、PresentationMapping、scripts 或 scenes。

## 1. 前置结论摘要

- R3 程序交接已确认 manifest-backed `asset_id`、AssetCatalog、ContentDB、PresentationMapping、ViewModel-snapshot 的基础存在。
- A 类接口优先服务可玩竖切：RunScene / Room、Minimap / MapOverlay、Room prop、Player sprite。
- B 类接口适合小批候选补足：HUD / common UI、Item / Inventory / Reward 局部。
- C 类内容仍以 preview / future contract 为主：MainMenu、DeployPrep、Settlement、History、LongTerm 多数界面。
- ART-04 的重点不是导入资产，而是明确 Lua 原型素材如何进入候选池、哪些接口值得优先补图、哪些内容应暂缓生产。

## 2. 当前可接入图矩阵

| 模块 | 当前接口 | 接入方式 | 是否 manifest-backed | 是否运行时消费 | fallback 状态 | 等级 | 程序侧需补内容 | 美术侧建议 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MainMenu / AppShell | App shell / preview UI 合同 | 后续通过 key / resolver 映射 | 待确认 | 低 | 需要通用 fallback | C | 明确最终主菜单视觉槽位、背景 key、转场 key | 暂缓最终大背景，先保留风格参考 |
| DeployPrep | 出发准备 UI 合同 | 后续通过 visual_key / panel key 接入 | 待确认 | 中 | 需要 panel / icon fallback | C | 明确五页签结构、状态枚举、缺图策略 | 暂缓完整 UI，只准备通用 icon 候选 |
| RunScene / Room | Room 背景、prop、角色 sprite 槽位 | A 类小批 runtime candidate，经 manifest-backed 流程 | 是，后续必须登记 | 高 | 需要 room / prop / player fallback | A | 明确 room state、prop role、sprite 朝向和尺寸约束 | 首批优先补 room background、room prop、player idle / 朝向 |
| Minimap / MapOverlay | map icon、number、grid 视觉槽 | A 类小图标候选，经 manifest-backed 流程 | 是，后续必须登记 | 高 | 需要 icon / unknown cell fallback | A | 明确 tile state、marker type、number style | 首批优先生产小图标、数字、格子视觉 |
| Item / Inventory / Reward | item icon、resource icon、reward icon 槽 | 局部 B 类候选，经 manifest-backed 流程 | 是，后续必须登记 | 中 | 需要 placeholder / unknown item fallback | B | 明确 item category、rarity、slot state | 先做通用 item / resource icon，不做完整 reward VFX |
| Settlement | settlement panel / result visual 合同 | preview / future contract | 待确认 | 低 | 需要 result panel fallback | C | 明确结算数据结构和缩略图使用边界 | 暂缓最终缩略图和复杂结果图 |
| History | history entry / snapshot visual 合同 | preview / future contract | 待确认 | 低 | 需要 generic history fallback | C | 明确 snapshot 来源、缩略图生命周期 | 暂缓最终历史缩略图 |
| LongTerm | long-term system UI 合同 | future contract | 待确认 | 低 | 需要 generic panel / icon fallback | C | 明确长期系统 visual key 范围 | 暂缓完整 UI，保留接口讨论 |
| HUD / common UI | frame、panel、button、common icon 槽 | B 类通用 UI 候选，经 manifest-backed 流程 | 是，后续必须登记 | 中 | 需要 default UI fallback | B | 明确 button state、panel size、icon taxonomy | 先做通用 UI icon / resource icon，小批验证风格 |

等级说明：

- A：可玩竖切首批可服务接口。
- B：可作为局部体验补足接口。
- C：以 preview / future contract 为主，暂不做完整资产生产。
- D：不建议在 R4 / R5 前置阶段接入。

## 3. key 与 fallback policy

### key 职责

- `asset_id`：manifest-backed runtime asset 的稳定标识，只能由后续登记流程确认。
- `visual_key`：程序和 UI 消费的视觉语义 key，用于表达“这里需要什么视觉”，不直接等同文件路径。
- `art_key`：美术生产和候选管理使用的制作语义 key，可在进入 manifest 前帮助归类候选。
- `animation_key`：动画状态或帧组语义 key，例如 idle、walk、hit、open、pulse。
- `background_key`：背景类视觉槽 key，例如 room background、main menu background、dynamic layer background。
- `transition_profile_key`：转场表现配置 key，例如 fade、slide、room_enter、reward_reveal。
- `fallback_asset_id`：当目标资产缺失、未登记、加载失败或被禁用时使用的 manifest-backed fallback 资产标识。
- `fallback policy`：定义缺图、缺动画、缺背景、缺转场时的退化策略和错误可见性。

### policy 原则

- 业务层不拼 `res://` 图片路径。
- UI 不直接读取 TruthMap。
- Base Docs、Base Art、Connection 路径不得写入 runtime。
- 资源路径由 manifest、AssetCatalog、ContentDB、PresentationMapping 或后续 resolver 管理。
- `visual_key` 可以先于真实资产存在，但不得绕过 manifest-backed 资产流程。
- fallback 必须允许可玩竖切在部分资产缺失时继续运行。
- fallback 不应掩盖生产状态：缺图可以有 placeholder，但 registry / handoff 中仍需保留缺口。

## 4. Lua / UrhoX 素材复用原则

- Lua / UrhoX 素材可作为可玩竖切素材来源和风格参考来源。
- 不全量复制 Lua assets。
- 不直接导入 Godot。
- 不绕过 Base Art、registry、review、export、manifest-backed 流程。
- 优先服务 A / B 接口的小批候选，避免把未来系统的一整套大图提前生产。
- 素材进入 runtime 前必须完成来源与授权登记策略确认。
- 字体、音频、视频、复杂动画暂缓，不在 R4 桥接包中作为导入目标。
- 若 Lua 素材只适合作为结构参考，应记录为 reference，不应假定可直接复用。

## 5. Lua 素材到接口映射

| 素材类型 | 可映射模块 | 接口等级 | 是否建议复用 | 处理需求 | 风险 |
| --- | --- | --- | --- | --- | --- |
| room background | RunScene / Room | A | 建议小批候选 | 统一尺寸、透视、光照、风格；进入 Base Art 后评审 | 来源授权、画幅不匹配、风格断裂 |
| tiles / floor / wall | RunScene / Room | C | 暂缓完整复用 | 仅作为 room background 参考；不做完整 tileset | tileset 工作量大，运行时接口未必需要 |
| room prop | RunScene / Room | A | 建议小批候选 | 透明背景、尺寸规范、交互状态枚举 | 状态缺失、碰撞 / 视觉边界不一致 |
| player sprite | RunScene / Room | A | 建议小批候选 | idle、朝向、基础帧；明确像素尺寸和锚点 | 动画帧不足、风格与 UI 不一致 |
| enemy sprite | RunScene / Room | B | 谨慎候选 | 先定义 enemy role 和状态，不做大批量 | 敌人系统需求未稳定 |
| chest / loot / exit / mine / event marker | RunScene / Room、Minimap / MapOverlay | A | 建议复用或重绘小批 | 统一 marker taxonomy，提供 room 与 minimap 两种规格 | 语义混淆、图标尺寸过密 |
| minimap icon / number / grid | Minimap / MapOverlay | A | 优先候选 | 小尺寸清晰度、数字可读性、状态色规范 | 低分辨率可读性差 |
| item icon | Item / Inventory / Reward | B | 建议小批候选 | category、rarity、slot state、透明背景 | item taxonomy 未完整 |
| consumable / equipment icon | Item / Inventory / Reward | B | 建议小批候选 | 区分 consumable / equipment / resource | 类别边界变动 |
| currency / resource icon | HUD / common UI、Reward | B | 建议候选 | 通用 icon、单色 / 彩色两套可选 | 经济系统图标过早定稿 |
| UI frame / panel / button | HUD / common UI、DeployPrep | B | 仅通用件候选 | button state、panel slicing、九宫格策略 | 完整 UI 风格未锁定 |
| popup / result panel | Settlement、History、Reward | C | 暂缓 | 先定义 panel key，不做最终图 | 数据结构和展示密度未稳定 |
| font / glyph / number | HUD / common UI、Minimap | D | 暂缓 | 仅记录需求，不导入字体 | 授权、渲染、语言覆盖风险高 |
| animation frames | Player、prop、reward | B / C | 小批验证 | 只做 player idle / prop state，复杂动画后置 | 帧数、方向、状态机未稳定 |
| audio / sfx | 通用反馈 | D | 暂缓 | 不纳入 ART-04 美术桥接执行 | 授权和音频 pipeline 未纳入本阶段 |

## 6. 首批图片需求规格候选

| 候选项 | 优先级 | 对应模块 | 接口等级 | Lua 复用可行性 | 规格需求 | 程序依赖 | 建议阶段 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MiniMap / MapOverlay 小图标 | P0 | Minimap / MapOverlay | A | 高，可参考或重绘 | 小尺寸高对比、透明背景、marker type 枚举 | marker taxonomy、fallback icon | R5 首批候选 |
| MapOverlay 数字 / grid 视觉 | P0 | Minimap / MapOverlay | A | 中 | 数字可读、grid 状态清晰、支持 unknown / visited / current | grid state、number style | R5 首批候选 |
| Room 背景小批试点 | P0 | RunScene / Room | A | 中 | 统一画幅、可裁切、安全边界、弱化复杂动态 | room role、fallback background | R5 首批候选 |
| Room prop 小批试点 | P0 | RunScene / Room | A | 高 | 透明背景、尺寸组、状态枚举、锚点说明 | prop role、interaction state | R5 首批候选 |
| Player idle / 朝向资源 | P1 | RunScene / Room | A | 中 | idle 帧、朝向、统一锚点、基础尺寸 | player state、animation_key | R5 小批验证 |
| 通用 UI icon | P1 | HUD / common UI | B | 中 | 透明背景、单色 / 彩色策略、状态尺寸 | icon taxonomy、button state | R5 小批验证 |
| resource icon | P1 | HUD / Reward | B | 中 | currency / resource 分类、清晰轮廓 | resource key、fallback_asset_id | R5 小批验证 |
| item icon 小批 | P2 | Item / Inventory / Reward | B | 中 | category、rarity、slot 尺寸 | item taxonomy、inventory state | R5 后续候选 |

首批候选只应覆盖 A / B 接口，且应优先选择小尺寸、低耦合、容易通过 fallback 退化的资产。复杂 UI 套件、完整角色动画、最终背景和 VFX 不应挤入首批。

## 7. 暂缓生产清单

- 最终主菜单大背景：当前 MainMenu / AppShell 多数仍是 preview / future contract，过早定稿会锁死风格。
- 完整出发探索五页签 UI：DeployPrep 的结构和状态密度需要程序侧继续收敛。
- 完整长期系统 UI：LongTerm 多数仍属 future contract，不适合作为 R4 / R5 首批生产。
- 完整角色动画：方向、状态机、帧数和战斗表现未稳定，先保留 player idle / 朝向小批验证。
- 完整地图 tileset：可玩竖切更需要 room background 与关键 prop，完整 tileset 成本高且接口收益不确定。
- 复杂 reward VFX：Reward 局部可先补 icon，VFX 应等待 reward flow 和性能边界明确。
- 结算 / 历史最终缩略图：Settlement / History 仍需确认 snapshot 来源和生命周期。
- 抽奖演出：属于高表现、高耦合内容，不适合当前桥接阶段。
- 多层动态背景 / 复杂 transition：需 transition_profile_key 和性能策略先稳定。
- 字体 / 音频 / 视频导入：涉及授权、技术 pipeline 和运行时设置，暂不纳入 ART-04。

## 8. R5 进入条件

进入 R5 前必须满足：

- 当前 worktree clean，或 scoped gate 明确允许仅写入指定 R5 目标。
- Lua 素材来源与授权登记策略明确。
- Base Art registry 写入 gate 明确。
- 首批候选限制在 A / B 接口。
- 不全量复制 Lua assets。
- 不导入 Godot。
- 不修改 manifest。
- 不修改 scripts / scenes。
- 不修改 project.godot。
- 不写 `.import`、`.uid`、`.godot`。
- 程序侧确认 key / fallback policy 的最小接口口径。
- 美术侧确认首批候选的规格、透明背景、尺寸、状态枚举和 rejection policy。

