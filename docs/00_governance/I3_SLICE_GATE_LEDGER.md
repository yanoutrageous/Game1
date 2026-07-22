# I3 切片审计与执行台账

文档状态：CLOSED / PASS_WITH_NOTES
最后更新：2026-07-23
总契约：`docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md`

## 1. 台账规则

每门只允许按 `PRE_AUDIT → APPROVED → IMPLEMENTED → POST_AUDIT → ACCEPTED`
前进。`ACCEPTED` 只表示该内部切片通过，不表示 I3 关闭。每门必须填写真实改动、
真实消费者、命令、marker、动态证据和残余风险；空白项不得解释为通过。

| Gate | Scope | Decision baseline | Status | Rollback | Required completion evidence |
| --- | --- | --- | --- | --- | --- |
| I3.0 | 身份、范围、对照、Base 导入与验收规则 | `NEW_I3` | `ACCEPTED` | I2 entry `09aaafe` | 契约、来源 hash、导入 verify、baseline quick/head 48/48、entry 五轮 perf 分布 |
| I3.1 | 地图/小地图 | UE 地图语法 + Godot KnownMap | `ACCEPTED` | I2 entry `09aaafe` | 共享语义、5×5 局部小地图、选择/确认、生产 modal、五分辨率、无泄漏 |
| I3.2 | 搜索/箱子/地面物/世界弹窗 | UE 反馈闭环 + Godot GroundLoot | `ACCEPTED` | I2 entry `09aaafe` + I3.1 patch | 搜索/揭示/查看/拾取、真实 open 素材、焦点滞回、退场反馈、预加载 |
| I3.3 | HUD/协议/物品/输入/角色表现/架构 | mixed | `ACCEPTED` | I3.2 accepted checkpoint | 玩家表面通过；模态布局计算迁出，RunScene 净减 41 行/2 函数并有独立门 |
| I3.4 | 战斗/特殊房/撤离/结果/性能 | mixed | `ACCEPTED` | I3.3 accepted checkpoint | 行为门与冻结负载五轮通过；enemy1 低基数残余回退及目标设备 GPU/FPS 如实保留 |
| I3.5 | 主菜单/出发/长期/设置 | mixed | `ACCEPTED` | I3.4 pre-audit checkpoint | 同页地图、设置、研究解锁树与真实空间转场均通过定向门；最终视觉归 I3.7 |
| I3.6 | Base 原始策划/美术与治理 | `NEW_I3` | `ACCEPTED` | 删除仅本门生成的 Base 目标 | 25 原件、hash 去重、全别名、保留理由、独立 runtime admission |
| I3.7 | 综合终验、关闭、exact-head、push | production truth | `ACCEPTED` | latest accepted checkpoint | production/渲染旅程与 full/worktree 75/75 已通过；提交后 exact-head 与 push/remote SHA 由最终交付记录证明，失败则关闭无效 |

## 2. 全阶段保护边界

- 不修改 UE 工程和 UE 已有脏文件。
- 不把 Lua/UE/旧 Godot/旧工作树当活动实现。
- `project.godot`、scene/resource、`.uid`、`.translation`、import metadata、运行时
  manifest 和新二进制运行时素材，必须在对应切片记录专门准入后才能暂存。
- 不修改掉落、伤害、经济、保存、结算、KnownMap、RunStateMachine、fixed tick 和
  容量替换规则，除非切片审计证明当前缺陷就在权威实现，并另行扩大门。
- Base 原件入库与 production 晋级分离；Base 文件不能因被 Git 跟踪而自动被 Godot 消费。

## 3. I3.0 前审计记录

### 3.1 I2 验收错位

- I2 validation 明确排除最终审美、音频、动态交互手感、完整手工路线、长局和设备矩阵。
- 39 张生产 capture 是 13 静态状态 × 3 个 16:9 分辨率。
- 最终 capture runner 使用私有调用、直接上下文写入、坐标和结果注入；可证明布局，
  不能证明玩家旅程。
- ART24R2 的真实接受曾为 24/61，说明后续静态覆盖不能自动抹去体验失败事实。

结论：I3 终验必须使用生产入口、公开输入和连续路线；静态 capture 只作补充。

### 3.2 表现架构

- I2 入口的 `run_scene.gd` 约 2680 行，仍协调搜索、物品、事件、撤离、战斗、地图、
  modal 与刷新；薄 controller 名称没有充分迁移职责。
- 多个生产 UI 仍以 `.new()`、`add_child()` 和固定 rect 即时拼装，编辑器预览、复用、
  动效与跨分辨率调节成本高。
- 旧 HUD、声明但未成为生产消费者的 panel 和 placeholder 仍存在，治理检查更多证明
  “已登记/可加载”，没有证明唯一生产消费者。

结论：I3 以真实消费者和职责减少验收，不以新增类名、目录或注册项验收。

### 3.3 已确认语义缺陷

- 开箱状态仍绑定关闭箱贴图并用变形伪装。
- 展开地图把 Monster 与 Mine 映射为同一语义；小地图缺少 Monster 独立映射。
- 世界焦点逐帧按最近距离重选，缺少滞回、驻留和目标锁定。
- 地面物动画在热路径重复 `load()`；拾取实体可能先消失再请求反馈。
- HUD 固定列出不可用操作并可能强调第一个禁用项；多个物品表面各自格式化品质与详情。

上述是 I3.1–I3.3 的前审计事实，不因旧测试断言当前行为而降级。

### 3.4 来源包前审计

```text
archive_sha256=A1035F69C412680016E6FB1C4FB181E77E75A517FDB252D6EBBC76D7F7957E71
member_count=1626
uncompressed_bytes≈314 MiB
planning_originals=25
exact_duplicate_groups=205
redundant_copies=424
redundant_bytes≈94.4 MiB
```

- `sources/docs/` 的 25 份策划均需作为“原始策划案”保留原名与完整正文。
- `docs_governance` 是复制型快照；旧仓库 docs 镜像中既有重复也有漂移，不作为原件再次导入。
- `sources/draw/Art.zip` 的 23 张图在外层均有相同内容；不再次导入嵌套压缩副本。
- `art/03_selected` 与 `art/05_export_runtime_candidates` 52/52 内容相同；目录名不构成晋级。
- art registry 仍是全量 pending；不能把文件夹名称写成许可或审核通过。

I3.0/I3.6 必须用内容 hash 形成唯一对象，并为每个原路径保留 alias 和保留/排除说明。

## 4. 切片完成记录模板

每门完成时追加：

```text
gate:
pre_audit:
decision: UE_PARITY | KEEP_GODOT | NEW_I3
allowed_paths:
protected_paths:
implementation:
real_consumers:
targeted_tests:
production_journey:
visual_evidence:
accessibility_and_focus:
performance:
post_audit:
residual_risks:
status:
```

禁止只写“测试通过”而不列出命令、marker、状态数量和未覆盖边界。

## 5. I3.0 实施与完成审计

```text
gate: I3.0
decision: NEW_I3
implementation: stage contract + active/current/audit entrypoints + Base importer + exact Base outputs
status: ACCEPTED
```

### 允许与保护路径

允许写入 `docs` 中的 I3 契约/入口/来源登记、`tools/i3/import_base_sources.py`、
`.gitignore`、`.gitattributes` 和 `sources/base/`。不允许把 `sources.zip`、
`docs_governance` 正文或内嵌 `Art.zip` 暂存；不允许 Base blob 被 Godot 自动消费。

### 已完成证据

- I2 exact entry：commit `09aaafe283aa2e4c2f30708c5f88b89ebf7753eb`，tree
  `a077da34237dce5e4a6081d833efd939098b4641`。
- entry quick/head：`PASS / 48 of 48`；report SHA256
  `0048A8F0BCFBB6CD93F2B16059A662CB866D17A69214F4A3DB412C6EDFB71876`。
- source archive SHA、1626 member 与 314060767 bytes 已验证。
- `I3_BASE_IMPORT_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395`。
- 原始策划目录 25 文件，保持 source basename 和源 SHA；没有正文摘要替换。
- Base art 1407 member 折叠为 1012 blob，395 alias 与 79256439 去重 bytes 均可追溯。
- importer 拒绝 archive identity drift、缺失、字节不匹配和生成区 unexpected file。

### 完成审计

- Base 位于 `sources/base` 而非 `repo/docs` 或 Godot runtime；位置规则成立。
- 目录名未被当成审核状态；所有 Base art 初始仍为 pending/not_admitted。
- 192 个 governance snapshot 与 nested Art.zip 均保留 inventory 行和排除理由，没有
  以“清理”为名删除来源身份。
- I3.0 已完成同机 frozen workload 的五轮进入分布。该分布只冻结 I2 entry 对照，I3
  候选的五轮比较仍属于 I3.4/I3.7，不把 baseline 本身写成性能改善。

## 6. I3.1 地图/小地图完成记录

```text
gate: I3.1
pre_audit: full-map shrink, Monster/Mine collapse, click-immediately-executes, sparse ordering risk
decision: UE_PARITY for readable grammar and selection hierarchy; KEEP_GODOT for KnownMap/focus/modal
status: ACCEPTED (stage-wide production journey remains I3.7)
```

### 精确改动

- `scripts/presentation/presentation_mapping.gd`
- `scripts/presentation/art24/art24_map_overlay_layout.gd`
- `scripts/ui/minimap/minimap_view_model.gd`
- `scripts/ui/minimap/minimap_panel.gd`
- `scripts/ui/map_overlay/map_overlay_panel.gd`
- `tests/i3_map_local_context_interaction_runner.gd`
- `tests/i2_map_public_information_input_runner.gd`（行为回归；无最终注入声明）
- `tests/i2_runtime_modal_priority_runner.gd`
- `tests/art24_map_overlay_scene_probe.gd`

未修改 RunScene、RunSurface、scene/resource/project/import/translation 或二进制素材；Monster
复用已有已登记 `icon.room.monster`。

### 实现与消费者

- MiniMapPanel 以玩家为中心显示 5×5 局部上下文；7×7、10×10、13×13 地图不再
  把 HUD 单元压到不可读尺寸。
- 小地图与展开图共同消费 `PresentationMapping.map_marker_state()`；Monster/Mine、
  Chest/Event/Exit/Flag/Player 语义分离，未知内容仍净化为 Unknown。
- 展开图按坐标补全公开格，不信任数组顺序；选择/焦点只更新大字号详情，独立确认
  才发出一次 toggle flag 或 fast return。
- Esc、M/Q、右键、面板外点击、嵌套 modal 与焦点恢复沿用生产输入栈。

### 定向验收

```text
I3_MAP_LOCAL_CONTEXT_INTERACTION=PASS
I2_MAP_PUBLIC_INFORMATION_INPUT=PASS
ART24_MAP_OVERLAY_SCENE=PASS resolutions=5
I1_UI_INTERACTION=PASS resolutions=3
I2_RUNTIME_MODAL_PRIORITY=PASS toggle_flag=1 fast_return=1 modal/focus/input=preserved
```

完成审计确认 KnownMap 未迁入 UI、选择阶段零领域命令、执行阶段恰好一次。5×5 是 I3
可读性基线，最终人工游玩可调整尺寸但不得退回“完整地图缩小”。生产 UI 仍由脚本
创建的技术债进入 I3.3/I3.7，不阻断本切片语义修复。

## 7. I3.2 搜索/箱子/地面物完成记录

```text
gate: I3.2
pre_audit: closed texture used as open, no stable reveal sequence, focus jitter, entity removed before feedback, process-time load
decision: UE_PARITY for feedback sequence/open-state truth; KEEP_GODOT for explicit pickup/GroundLoot/capacity authority
status: ACCEPTED (stage-wide production journey remains I3.7)
```

### 精确改动

- `data/assets/asset_manifest.csv`（本门专门 runtime asset gate）
- `scripts/gameplay/interactables/g41_chest_interactable.gd`
- `scripts/gameplay/loot/g41_ground_loot_entity.gd`
- `scripts/gameplay/runtime/g41_room_runtime_view.gd`
- `scripts/presentation/art24/art24_in_run_asset_contract.gd`
- `tests/i2_world_interaction_runtime_runner.gd`

未修改 scene/resource/project/translation/import metadata；未新增二进制。首次测试产生的
`.translation` 自动污染已按 HEAD 精确恢复并核对，未进入最终差异。

### 开箱状态素材专门准入

```text
archive=sources.zip
archive_sha256=A1035F69C412680016E6FB1C4FB181E77E75A517FDB252D6EBBC76D7F7957E71
member=sources/draw/30_game_ready/props/00_baoxiang_kai.png
member_sha256=3A4D3445312B5611B7F9FA9066FBE7FB666C48A074579BE7D303003CC9C0180A
runtime=res://assets/props/art07/00_baoxiang_kai.png
runtime_sha256=3A4D3445312B5611B7F9FA9066FBE7FB666C48A074579BE7D303003CC9C0180A
consumer=scripts/gameplay/interactables/g41_chest_interactable.gd
runtime_key=visual.art24.prop.chest_open_state
binary_import=none; exact existing runtime file revalidated
```

该单项准入只批准真实“已打开箱子”稳定状态，不批量升级 ART07 或 Base art。

### 实现与验收

- 新地面物播放 reveal 后稳定展示；权威拾取删除后以 disabled departure entity 完成退场。
- 已打开箱子首次和再次靠近均直接显示剩余内容；不开第二份 GroundLoot 账本。
- 靠近自动显示，拾取仍需显式输入；焦点使用驻留、距离优势、离开 grace 与目标锁定。
- 光柱 8 帧使用 preload 数组，热路径不再调用 `load()`。

```text
I2_WORLD_INTERACTION_RUNTIME=PASS chest=single_projection command=before_animation proximity=display_only doors=public_snapshot asset=open_png_revalidated
I3_SEARCH_WORLD_FEEDBACK=PASS sequence=search,reveal,stable,pickup chest=open_asset proximity=automatic focus=hysteresis,lock loads=preloaded authority=preserved
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS fixed_hz=60 outer_schedules=30,60,144,hitch monsters=slime,slimeling,bat,drone visual_contract=v1
git diff --check=PASS
```

完成审计确认 UI/动画不发命令、GroundLoot/CommandBus/容量替换未变、拾取反馈不再因
投影刷新消失。并行阶段曾观察到 runtime modal 的临时 NUL/级联失败；I3.1 完成后已以
稳定共享工作树复跑 `I2_RUNTIME_MODAL_PRIORITY=PASS`，因此不保留为当前缺陷。

## 8. I3.3 HUD/物品/输入/角色表现完成记录

```text
gate: I3.3
pre_audit: disabled-first HUD, raw engineering fields, duplicated item copy, first-key extra movement, fixed animation identity
decision: UE_PARITY for player-first hierarchy; KEEP_GODOT for authoritative protocol/GroundLoot/input actions; NEW_I3 for replaceable animation-set boundary
status: ACCEPTED (player surfaces and measured RunScene presentation-responsibility reduction pass)
```

### 实现与边界

- HUD 的七项操作按公共快照中的可执行上下文排序；第一个可执行项获得主强调，
  disabled 项退出焦点链。`run_id/mode/phase/outcome` 和英文 combat state 不再作为玩家文案。
- “周围雷险”继续来自权威快照。协议 5 的正式名称“正常作业”仍是策划/领域语义，
  只删除左侧重复呈现，没有篡改协议定义。
- 快捷包、背包、GroundLoot、世界弹窗、替换候选和结果项统一消费
  `RunUIViewModel` 的只读品质/名称/重量/说明描述；快捷包没有伪“空位”，支持真实滚动，
  hover/focus 只展示详情，负重位于底部居中。
- 键盘首帧预览不再与逐帧移动叠加；连续方向统一由 `Input.get_vector` 读取，D-pad、
  LB/B 与键盘动作保持同一生产输入路径。
- PlayerController 接受 `appearance_id + animation_set_id`，默认只使用已登记 ART24 帧；
  reduced-motion 选择清晰静态姿态。未把 Base/UE `huanxiong` 候选冒充已准入素材，
  也未声称实现缺少骨骼源的骨骼生成。
- 完成审计发现 `run_scene.gd` 原为 2687 行、161 个函数，因此没有把最初的玩家表面
  通过冒充架构完成。补救后，模态、安全边距、居中和 debug panel 几何计算迁入纯只读
  `RuntimeModalLayoutModel`；`RunScene` 只把返回的 Rect2 应用到节点并继续拥有 modal
  stack、焦点、命令和路由。`run_scene.gd` 降为 2646 行、159 个函数，净减 41 行/2 函数。

### 精确改动与验收

生产改动限定于 `g41_world_context_popup.gd`、`player_controller.gd`、
`art24_runtime_animation_catalog.gd`、`ground_loot_panel.gd`、`hud_view_model.gd`、
`inventory_panel.gd`、`run_surface.gd`、`run_surface_model.gd` 和
`run_ui_view_model.gd`，并更新 `i1_ui_interaction_runner.gd`、新增
`i3_hud_item_input_character_runner.gd`。完成审计补救另新增
`runtime_modal_layout_model.gd` 和 `i3_runtime_modal_layout_model_runner.gd`。

```text
I3_HUD_ITEM_INPUT_CHARACTER=PASS
I1_UI_INTERACTION=PASS resolutions=3
I2_RUN_INFORMATION_SURFACE=PASS
I2_INVENTORY_HOVER_FOCUS=PASS
I2_ITEM_RARITY_PRESENTATION=PASS
I2_PLAYER_MOTION_PROJECTION=PASS
I2_RUNTIME_INPUT_PROFILE=PASS
I2_CHARACTER_PRESENTATION_SWAP=PASS
I2_ASSET_BINDING=PASS
I2_RUNTIME_MODAL_PRIORITY=PASS
I3_RUNTIME_MODAL_LAYOUT_MODEL=PASS cases=5 owner=RuntimeModalLayoutModel run_scene_helpers_removed=2
```

完成审计确认 UI descriptor 为只读，未创建第二物品权威；没有修改场景、资源、项目、
UID、翻译或 import metadata。残余风险是 HUD 的房间级可用性与
`G41RoomRuntimeView.focused_interaction_id` 的近距离焦点仍是两层投影；I3.7 生产旅程
必须验证远处地面物存在时不会给出可误解的主操作。

## 9. I3.4 战斗、特殊房、撤离、结果与性能完成记录

```text
gate: I3.4
pre_audit: abrupt enemy presentation, touch-to-leave ambiguity, engineering special-room copy, weak terminal consequence summary, combat-room frame concern
decision: UE_PARITY for readable anticipation/exit summary; KEEP_GODOT for authority/fixed-step/result settlement; NEW_I3 for read-only presentation models and projectile sync path
status: ACCEPTED (headless behavior and frozen CPU workload pass; target-device GPU/FPS remains an explicit residual gate)
```

### 实现与权威边界

- 敌人显示增加 arrival→anticipation→impact→recovery、受击与死亡阶段；reduced-motion
  使用清晰静态姿态。所有阶段只消费公开战斗快照，不写生命、伤害或房间状态。
- 战斗房触碰出口保持零命令；只有玩家显式操作并确认后才离开，取消零命令、确认只扣一次。
- Event、Mine、Monster 与 Exit 的工程字段由只读特殊房展示模型转为玩家目标、收益、
  遗留和后果文案；Exit 首次发现及靠近摘要不绕过 KnownMap、距离与命令权威。
- 结果面以只读展示模型区分成功、失败、放弃、失败原因、带回、损失和保存状态；
  保存失败重试复用同一结算快照，未把 UI 变成第二个持久化写入者。
- actor 节点、纹理选择和能力查询在热路径缓存。15 个多边形弹体不再逐帧误走敌人
  动画目录与签名格式化，改用保持位置/公开状态等价的 projectile 专用同步路径。

### 定向与恢复验收

```text
I3_COMBAT_SPECIAL_RESULT_RUNTIME=PASS phases=arrival,anticipation,impact,recovery,hit,death special=public_only exit=benefit,left_behind,objective flee=single_charge result=reason,consequence,persistence save_retry=idempotent reduced_motion=static
I2_SPECIAL_ROOM_PLAYER_EXPERIENCE=PASS
I2_COMBAT_ROOM_EXPERIENCE=PASS
I2_RUNTIME_MODAL_PRIORITY=PASS
I2_TERMINAL_RESULT_AUTHORITY=PASS
I2_TERMINAL_COMMIT_RECOVERY=PASS
ART24_RESULT_PANEL_SCENE=PASS
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS
```

冻结负载与入口完全一致：60 Hz、300 warmup、3600 sample，五轮全部 PASS，且每轮
`cache_loads_after_warmup=0`、`fixed_step_max=1`、`saturated=0`。五轮 `frame_work`
中位数如下（p50/p95/p99/max，μs）：

| 场景 | I2 入口五轮中位 | I3 五轮中位 | 相对变化 |
| --- | --- | --- | --- |
| enemy1 | 319/778/1157/2335 | 355/877/1279/2782 | +11.3%/+12.7%/+10.5%/+19.1% |
| enemy3 | 477/1261/1888/5651 | 497/1311/1898/5014 | +4.2%/+4.0%/+0.5%/−11.3% |
| enemy5 | 601/1635/2415/6830 | 586/1531/2238/5221 | −2.5%/−6.4%/−7.3%/−23.6% |
| projectile15 | 645/1724/2616/4857 | 665/1776/2741/4703 | +3.1%/+3.0%/+4.8%/−3.2% |

15 弹体的关键分位回退已从补救前约 8%–12% 收敛到 5% 内，max 下降。enemy1
不能写成“无回退”：相对增加 10%–19%，但绝对仅 +0.036/+0.099/+0.122/+0.447 ms；
它记录为低基数下固定表现成本与跨批次调度波动放大的残余回退。headless CPU 分布也
不能替代目标设备的 GPU/FPS、长时帧时间和输入手感，因此该设备门进入 I3.7，而不被
本切片的 ACCEPTED 隐藏。

## 10. I3.5 主菜单、出发、长期与设置完成记录

```text
gate: I3.5
pre_audit: scene/copy mismatch, deploy summary density, long-term engineering copy, settings lacking audio effect
decision: KEEP_GODOT for same-page deploy and existing spatial transitions; NEW_I3 for player copy/audio/research tree projection
status: ACCEPTED (same-page/settings/research projection and corrected spatial transitions pass)
```

### 实现与消费者

- 主菜单文案重新锚定“门厅/洞口/基地下层”场景。完成审计先确认旧 `enter_cave` 只有
  focus/fade、旧 `descend` 仅约 48 px，因此没有用 coordinator PASS 冒充体验完成。
  补救后 `enter_cave` 消费已登记的 4 帧 `walk_dungeon`，角色真实向洞内锚点移动、缩放
  至 0.58 并分段淡出；取消精确恢复 position/scale/modulate/pivot/texture/flip。
  `descend` 将全部非 overlay 根节点同步最大下移 180 px，路由仍只在表现结束后提交。
- 出发地图保持同页双栏：左侧规模/地图选择、右侧难度与详情；8 个既有地图 ID、
  常驻金币、仓库/申领真实操作和摘要权威保持。摘要页签缩短为“速览/携带/本局/目标”，
  没有恢复“区域 → 难度”中间页。
- 长期系统保留 M7 `complete_research` 事务与三节点 prerequisite 链，将其投影为玩家
  可读的“研究解锁树”；绘制层级和父子连线并提高列表/详情密度。没有杜撰 talent
  规则、数值或存档，也没有破坏任务档案、图鉴、角色和收藏的真实数据边界。
- Settings schema 升至 v2，新增 0–100 主音量持久化与 v1 迁移；运行 adapter 真实设置
  AudioServer master bus 的 mute/volume，预览、应用、取消回滚和重启读取均走同一事务。

### 定向验收

```text
ART21_MAIN_MENU_RUNTIME=PASS
I2_MAIN_MENU_ANCHOR_TEXT=PASS
I2_MAIN_MENU_TRANSITION_COORDINATOR=PASS profiles=4 duplicate=rejected stale=ignored cancel=recovered prepare_fail=recovered commit_fail=recovered reduced_midflight=profile_only commit_once=true
ART22_DEPLOY_PREP_RUNTIME=PASS exact_maps=8 split=selection_detail
ART22_DEPLOY_PREP_MAIN_ROUTE=PASS host=main.tscn
I2_DEPLOY_MAP_PROJECTION=PASS
I2_DEPLOY_META_ACTION_TRANSACTION=PASS
I3_LONG_TERM_PLAYER_CONTRACT=PASS source=m7_research_prerequisite talent_rules=0 tree_nodes=3 player_copy=clean
I2_LONG_TERM_TASK_ARCHIVE=PASS
I2_LONG_TERM_MODULE_WORKSPACE=PASS
ART23_LONG_TERM_RUNTIME=PASS
ART23_LONG_TERM_MAIN_ROUTE=PASS host=main.tscn
I2_SETTINGS_TRANSACTION=PASS
I2_SETTINGS_SHELL_WIRING=PASS rollback=complete user_files=clean
```

完成审计确认空间转场补救没有新增二进制、scene/resource/import metadata；walk clip 的
4 帧 runtime SHA 与 asset manifest 逐项一致。最终动态视觉签收仍归 I3.7。仓库批量售卖、
多 taxonomy 出发目标与骨骼生成都没有被占位按钮伪装；
它们需要各自的产品/事务/素材门。既有 ART23 main-route 退出 cleanup warning 保持精确
登记，不把 exit leak 写成体验通过。

## 11. I3.6 Base 原始策划与美术治理完成记录

```text
gate: I3.6
pre_audit: folder-name classification, copied governance mirrors, nested archive, no content identity or consumer promotion gate
decision: NEW_I3
status: ACCEPTED
```

### 落地结果

- `sources/docs/` 的 25 份文件以原 basename、原字节和原 SHA 保存到
  `sources/base/原始策划案/`；目录和关系登记明确称为“原始策划案”，没有改名、删减、
  摘要替换或把工程文档覆盖原件。
- 1407 个 art/draw member 按 SHA-256 保存为 1012 个内容对象；395 个重复路径与
  79,256,439 bytes 被折叠，但每个原路径、层级、理由和 canonical SHA 都保留在 alias。
- `draw/Art.zip`、192 个 `docs_governance` 快照和 `sources.zip` 整包不重复提交；它们的
  路径、SHA、大小、处理和排除理由仍进入完整 1626-member inventory。
- 所有 Base art 统一为 `pending_verification/pending_review/not_admitted`；运行时必须另过
  source→derivative→runtime→consumer→visual validation 门。最大单 blob 38,064,205 bytes，
  没有超过 GitHub 100 MiB 单文件限制。

```text
I3_BASE_IMPORT_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
I3_BASE_COMMITTED_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
```

根因审计确认旧整理仍乱的原因不是“文件太多”，而是分类只看目录名、重复复制快照、
缺少 hash 身份、关系/消费者登记和晋级门；早期删除根本素材则来自把 working/pending
目录误当成可删除状态。I3 只折叠精确同字节对象，不按名称或主观相似删除不同内容。

## 12. I3.7 production 旅程与综合完成审计

```text
gate: I3.7
pre_audit: static capture cannot prove continuous input, transition timing, full-bag replacement, terminal branches or save recovery
decision: production main.tscn + Input.parse_input_event + fixed seed and isolated save only
status: ACCEPTED (production/rendered journeys and full/worktree pass; exact-head/push are post-commit delivery gates)
```

### 真实输入与动态证据

三个 runner 均从生产 `main.tscn` 启动，使用 `Input.parse_input_event`，只允许固定 seed 与
隔离 save adapter/path 两类直接 fixture；没有私有 UI/scene 方法开页、写玩家坐标、写
RunContext/结果或合成 ViewModel。每个 runner 各跑 headless 与有渲染一次：

```text
I3_PRODUCTION_INPUT_JOURNEY=PASS seed=13 checkpoints=19 screenshots=0 inputs=124 result=Extracted save_retry=real return=main
I3_PRODUCTION_INPUT_JOURNEY=PASS seed=13 checkpoints=19 screenshots=19 inputs=126 result=Extracted save_retry=real return=main
I3_PRODUCTION_FULL_BAG_REPLACEMENT=PASS seed=13 searched_rooms=8 capacity=10 replacement=real_input screenshots=0 inputs=192
I3_PRODUCTION_FULL_BAG_REPLACEMENT=PASS seed=13 searched_rooms=8 capacity=10 replacement=real_input screenshots=13 inputs=190
I3_PRODUCTION_TERMINAL_BRANCHES=PASS seed=13 outcomes=Abandoned,Failed confirmations=cancel_then_confirm,salvage return=main screenshots=0 inputs=67
I3_PRODUCTION_TERMINAL_BRANCHES=PASS seed=13 outcomes=Abandoned,Failed confirmations=cancel_then_confirm,salvage return=main screenshots=15 inputs=69
```

六套 production JSON/CSV 在 `E:\AGAME1\.tmp\i3_evidence\i3_7_headless_*` 与
`i3_7_rendered_*`；同级 `i3_7_cleanup_probe` 是独立生命周期诊断，不属于生产旅程。
47 张 PNG 均为 1280×720，
JSON 数量、实际文件、截图路径和步骤序列一致，`failures=0`。覆盖 main→deploy→run、
移动、展开地图与外点/Esc、胸首次/重复、显式拾取、真实丢弃后的自动 GroundLoot、满包
替换、Event、战斗显式离开取消/确认、Mine、Exit 取消/确认、Extracted、真实保存失败
两次重试、Abandoned、自然 `runtime_combat_melee` Failed、返回主菜单和 descend→长期系统。

严格空间测量：`enter_cave` 总位移 111.5168 px、向上 94 px、最小 scale 0.58、观察到
3 个不同动画帧并只提交一次；`descend` 为 180 px、渲染时长 1338 ms，表现结束后才
提交一次。旧“零角色位移/48 px 下移”无法通过这些断言。

### 人工可见检查与补救

人工以原始分辨率检查 17 张代表图，覆盖主菜单入洞、Deploy、地图、箱、GroundLoot、
Event、战斗入场/离开确认、Mine、Exit、满包替换、descend、长期系统以及成功/失败/放弃
结果。未见阻断性裁切、模态偏心、对象/弹窗重叠或结果原因缺失。检查发现丢弃反馈曾
显示“未命名物资”；根因为 UI 只读到了 CommandResult 外层状态，未读取
`action_result.item`。补救后共享描述器读取内层权威物品，I3 HUD 门及有渲染主链复跑
通过，截图现显示真实“自护螺母”。

本检查不宣称最终审美、动画/音频手感或设备矩阵已完成：descend 中途仍可见固定蓝色
underlay，跨页面边框/token 仍有历史混合感；这些是明确的视觉 polish 后续门，不影响
本轮功能与信息闭环结论。

### 非静默清理风险

六次 production 运行均出现同一已知退出诊断：

```text
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
ERROR: 18 resources still in use at exit (run with --verbose for details).
```

verbose 探针确认是 `RunContext`、map/intel、asset/event/state/transaction/rule/query、
save/meta、item command、room resolver、CommandBus、G41 runtime 与 runtime controller
共 18 个生产 RefCounted/GDScript 资源链。runner 已释放 main 并等待协程退栈，仍可复现；
没有调用私有清理掩盖。该诊断与既有 RunScene runner 基线一致，已在 manifest 精确登记，
但仍是后续生命周期 owner 的真实债务，不能写成 cleanup clean。

### 综合回归、失败后补救与关闭裁决

首次 quick/worktree 没有被隐藏。报告
`20260722T202653529Z_02a1c388`（SHA256
`C3A422BEB16483C1FF39CF5804C3F91F1017524E91EBA6EF12E5757495223C15`）
为 FAIL：敌人 hurt 保持时间违反既有释放契约；可访问性探针未登记新增的真实主音量；
世界交互清单仍匹配旧 `open_png_blocked` marker。三项分别恢复 0.12 秒 hurt
保持、扩充且不弱化设置事务断言、同步真实素材准入 marker。补救后 quick/worktree
报告 `20260722T204036470Z_9624c50d` 为 53/53 PASS，33 个普通 PASS、20 个
分类 cleanup PASS、blocking 0、pollution PASS；报告 SHA256
`ACB78574948879F9724BF0F216DFB01AFE93C40BC55F44A8DCE0006FF5AE0FD6`。

首次 full/worktree 报告 `20260722T204814719Z_fb3bc472`（SHA256
`EAAB37EA9679D1B52569D4D7C3C5798A26C4BF7F078CB020660807C5080AE157`）
为 73/75：旧库存探针把去冗余后的 lean tooltip 误判为丢失藏品分类；旧地图
manifest marker 未包含 runner 已输出的 `detail=visible`。补救保持共享 descriptor 的
`type_label=藏品`、品质和收藏等级三项断言，并同步精确地图 marker，没有通过删除语义
检查来放绿。

最终 full/worktree 报告
`E:\AGAME1\.tmp\worktrees\i3\.tmp\i1\20260722T210300990Z_ed330093\report.json`
为 75/75 PASS（42 普通、33 分类 cleanup、66 条精确 cleanup diagnostic、blocking 0），
用时 785952 ms，pollution PASS；business 为 2220 files / fingerprint
`ED5E6A08A3569470C00F241E265B544E2BBA6766844924D32CC83277E3D0F545`，
manifest SHA256 `7A85382E1B2DBDC4B1260720369D9C8FC8448DD01E125873060F58907B6589C9`，
report SHA256 `5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D`。

I3 因此按已验证能力裁决为 `CLOSED / PASS_WITH_NOTES`。仓库文档无法自指生成它的
最终 commit；提交后的 `full/head`、push 与 `git ls-remote` 一致性必须由最终交付记录
证明。任一外部门失败时不得推送或宣称 I3 已关闭，修复后必须重新提交并复验。
