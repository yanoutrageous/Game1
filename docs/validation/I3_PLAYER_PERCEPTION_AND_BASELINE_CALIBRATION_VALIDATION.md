# I3 玩家感知与 Base 基线校准验证记录

文档状态：`CLOSED / PASS_WITH_NOTES`（仅在提交后 exact-head full 与同一 HEAD push 均通过时生效）
最后更新：2026-07-23
阶段：I3 Player Perception and Baseline Calibration（I3.0–I3.7 为同一阶段的内部切片）

## 中文摘要

I3 是对 I2 已交付能力进行玩家感知校准、真实生产旅程补证和来源基线治理的必要修正阶段；它不推翻 I2，也不改变项目已经进入“增量开发与既有内容修改并行”的判断。阶段以当前 Godot 代码和真实运行结果为实现事实，以 UE/Lua/原始策划案为只读比较或来源证据，不把原型表现直接复制为生产实现。

本阶段完成了局内地图、搜索与世界反馈、HUD/物品/输入/角色表现边界、战斗与特殊房/结算、主菜单/出发探索/长期系统/设置、Base 原始策划案与美术来源治理，以及由生产 `main.tscn` 和真实输入驱动的完整旅程验证。最终 full/worktree 为 75/75 PASS，Base 内容可由仓库独立复核，生产证据共 47 张 1280×720 截图，性能使用同一 60 Hz 工作负载进行五轮对照。

结论仍是 `PASS_WITH_NOTES`：已验证的是本记录明确列出的行为、结构、来源完整性和测量边界；最终审美、音频、完整动画手感、目标 GPU/FPS、长局与设备矩阵、真实天赋规则、批量出售规则及 Base 运行时准入均未被暗示为完成。本文不能预写包含自身的最终 commit。提交后必须对 exact HEAD 再跑 full，并把同一 HEAD 推送到远端；任一失败时，本阶段只能称为 closeout candidate，`CLOSED` 立即失效。

## 1. 身份与权威边界

```text
active_repo: 由 git rev-parse --show-toplevel 解析
branch: codex/i3-player-experience-calibration
i3_entry_head: 09aaafe283aa2e4c2f30708c5f88b89ebf7753eb
i3_entry_tree: a077da34237dce5e4a6081d833efd939098b4641
godot_project: <active_repo>/Godot/GraytailGodot
engine: E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
engine_version: 4.6.3.stable.official.7d41c59c4
ue_reference: E:\UE\Game @ de4ece1163505d9fe08e31cd0dbe10477909f963
```

- 当前 Godot 工程是唯一实现与运行时权威；仓库必须从 Git 根目录解析，不能以盘符猜测活动仓库。
- UE 仅用于只读比较信息层级、空间反馈与交互原因，不是代码、性能、许可或资产准入权威；未修改 UE 工作区已有的用户文件。
- `sources/base/` 是来源保存基线，不是运行时资源目录。Lua、旧 Godot、UE 和历史文档均不能覆盖当前代码与真实运行结果。
- 用户反馈处置矩阵的实质分类为 44 项 `IMPLEMENTED_AND_VERIFIED`、6 项 `REJECTED_WITH_EVIDENCE`、13 项 `BLOCKED_WITH_OWNER_AND_GATE`；其中综合关闭仍受 exact-head/full 与 push/remote-SHA 两项外部交付门约束。阻塞项没有被伪装成完成项。

## 2. 阶段裁决与切片结果

| 切片 | 结果 | 已验证范围 |
| --- | --- | --- |
| I3.0 | ACCEPTED | 阶段契约、代码优先、UE 只读比较、反馈处置与单阶段闭合规则 |
| I3.1 | ACCEPTED | 5×5 玩家中心小地图、展开地图语义、选择/确认分离及完整关闭路径 |
| I3.2 | ACCEPTED | 搜索→揭示→稳定展示→显式拾取；已开箱重访；焦点滞回与真实开箱素材 |
| I3.3 | ACCEPTED | HUD 主动作与周围雷险、共享物品描述、滚动背包、单一输入路径、角色外观/动画集合边界 |
| I3.4 | ACCEPTED | 战斗阶段反馈、显式撤离、特殊房玩家信息、结果解释与幂等保存重试 |
| I3.5 | ACCEPTED | 主菜单空间转场、Deploy 同页双栏、真实设置事务、M7 研究前置树的诚实呈现 |
| I3.6 | ACCEPTED | 原始策划案完整保留、美术内容寻址去重、来源/许可/审核/消费者准入状态 |
| I3.7 | PASS_WITH_NOTES | 生产真实输入旅程、截图/CSV/JSON 证据、人工静态检查、性能对照与 full/worktree |

阶段没有采纳“区域→难度”的分步页回退。地图仍是出发探索同一页的一部分，左侧选择与右侧详细信息共同完成当前决策。

## 3. 核心运行时证明

以下是本阶段定向 runner 的精确结论摘要：

```text
I3_MAP_LOCAL_CONTEXT_INTERACTION=PASS sizes=7,10,13 minimap=5x5 semantics=monster,mine selection=separate confirmation=explicit known_map=sealed input=focus,accept,outside_click
I3_SEARCH_WORLD_FEEDBACK=PASS sequence=search,reveal,stable,pickup chest=open_asset proximity=automatic focus=hysteresis,lock loads=preloaded authority=preserved
I3_HUD_ITEM_INPUT_CHARACTER=PASS hud=primary_action,mine_risk actions=7,context_order items=shared_descriptor,scroll input=single_path,gamepad_propagated character=appearance,animation_set reduced_motion=preserved
I3_RUNTIME_MODAL_LAYOUT_MODEL=PASS cases=5 owner=RuntimeModalLayoutModel run_scene_helpers_removed=2
I3_COMBAT_SPECIAL_RESULT_RUNTIME=PASS phases=arrival,anticipation,impact,recovery,hit,death special=public_only exit=benefit,left_behind,objective flee=single_charge result=reason,consequence,persistence save_retry=idempotent reduced_motion=static
I3_LONG_TERM_PLAYER_CONTRACT=PASS source=m7_research_prerequisite talent_rules=0 tree_nodes=3 player_copy=clean
I2_SETTINGS_TRANSACTION=PASS
I2_SETTINGS_SHELL_WIRING=PASS owner=default_then_injected panel=production rollback=complete user_files=clean
I2_ACCESSIBILITY_RUNTIME=PASS
```

### 3.1 地图、世界反馈与物品

- 小地图固定为玩家中心 5×5 局部上下文；7/10/13 三种地图尺寸保持可读。Monster、Mine 和已知地图语义来自共享 presentation mapping，`KnownMap` 保持封闭。
- 展开地图的移动选择只更新大字号详情；旗帜/快速返程只有单独确认才各发出一次命令。Esc、M、Q、右键、面板外点击和焦点恢复均有覆盖。
- 箱子首次打开直接显示权威物品，重访已开箱直接展示内容；地面物靠近自动展示，但搜索、拾取、满包替换仍要求显式意图，展示层不写 ledger。
- 真实开箱图来自 `sources.zip` 成员 `sources/draw/30_game_ready/props/00_baoxiang_kai.png`，成员与运行时文件 SHA256 均为 `3A4D3445312B5611B7F9FA9066FBE7FB666C48A074579BE7D303003CC9C0180A`。运行时路径为 `res://assets/props/art07/00_baoxiang_kai.png`。
- 快捷背包、完整背包、GroundLoot、世界展示、替换与结果页共享 `RunUIViewModel` 物品描述；不绘制伪“空位”，列表可滚动，负重位于底部居中。

### 3.2 输入、角色、战斗和结果

- 七类上下文 HUD 操作按可执行性排序，首个可执行项为主动作；禁用项不进入焦点。协议 5 的正式名称“正常作业”保留，但重复工程展示已删除；“周围雷险”保留为玩家信息。
- 键盘和手柄进入同一移动路径，移除了首帧额外位移；角色使用 `appearance_id` 与 `animation_set_id`，只使用已登记 ART24 帧，reduced-motion 使用静态表现。未宣称骨骼帧自动生成或时装资产管线已完成。
- 敌人覆盖入场、预备、命中、恢复、受击、死亡；战斗房触碰离开不发命令，取消不收费，显式确认只收费/离开一次。
- Event、Mine、Monster、Exit 只呈现公开玩家信息。结果模型分别解释成功、失败、放弃、原因、可带走、损失和保存状态；保存失败重试复用同一快照并保持幂等。
- `RunScene` 的纯 modal/safe/center/debug 几何移入只读 `RuntimeModalLayoutModel`，净减少 41 行和 2 个 helper；modal 栈、焦点、命令和路由仍由 `RunScene` 持有，没有迁移领域写权限。

### 3.3 主菜单、出发、长期与设置

- 主菜单空间锚点为门厅、洞口、基地下层。进入洞口使用登记的四帧 `walk_dungeon`，角色实际朝洞口移动、缩放至 0.58 并淡出；取消恢复位置、缩放、透明度、纹理和朝向。下沉转场移动所有非 overlay 根节点 180 px，播放结束后才提交导航。
- Deploy 使用同页左右分栏；八个既有地图 ID 未改变，地图与难度不拆成回退式两页。金币常驻，仓库和申领使用真实操作，摘要页签为“速览/携带/本局/目标”。
- 长期页面显示来自 M7 的三节点研究前置关系，明确标注 `talent_rules=0`；它是“研究解锁树”的当前事实，不伪称真实天赋点、成本、效果或重置规则已存在。
- 设置 schema v2 的主音量范围为 0–100，包含 v1 迁移、Master bus mute/dB 应用、apply/cancel/rollback/restart 事务；未虚构音乐/音效拆分、UI 缩放、震动或色盲模式。

## 4. 生产旅程与视觉证据

生产 runner 从 `main.tscn` 启动并通过 `Input.parse_input_event` 驱动。直接 fixture 仅限固定 seed 和隔离的保存 adapter/path；没有私开 UI/场景、写坐标/RunContext/result、构造伪 ViewModel 或绕过领域命令。

```text
I3_PRODUCTION_INPUT_JOURNEY=PASS seed=13 checkpoints=19 screenshots=0 inputs=124 result=Extracted save_retry=real return=main
I3_PRODUCTION_INPUT_JOURNEY=PASS seed=13 checkpoints=19 screenshots=19 inputs=126 result=Extracted save_retry=real return=main
I3_PRODUCTION_FULL_BAG_REPLACEMENT=PASS seed=13 searched_rooms=8 capacity=10 replacement=real_input screenshots=0 inputs=192
I3_PRODUCTION_FULL_BAG_REPLACEMENT=PASS seed=13 searched_rooms=8 capacity=10 replacement=real_input screenshots=13 inputs=190
I3_PRODUCTION_TERMINAL_BRANCHES=PASS seed=13 outcomes=Abandoned,Failed confirmations=cancel_then_confirm,salvage return=main screenshots=0 inputs=67
I3_PRODUCTION_TERMINAL_BRANCHES=PASS seed=13 outcomes=Abandoned,Failed confirmations=cancel_then_confirm,salvage return=main screenshots=15 inputs=69
```

生产证据位于 `E:\AGAME1\.tmp\i3_evidence\i3_7_headless_*` 与 `i3_7_rendered_*` 六个目录：每次各有 JSON/CSV，共 47 张 1280×720 PNG，记录失败数为 0。相同上级目录中的 `i3_7_cleanup_probe` 是独立生命周期诊断，不属于六次生产旅程。旅程覆盖主菜单→Deploy→局内、移动、地图外点击/Esc、箱子首次与重访、显式拾取、丢弃后 GroundLoot 自动展示、满包替换、Event、战斗撤离取消/确认、Mine、Exit 取消/确认、Extracted、真实保存失败两次重试、Abandoned、自然 `runtime_combat_melee` Failed、返回主菜单以及下沉进入长期系统。

覆盖边界必须同时保留：六条生产旅程仅使用 `seed=13`，未覆盖真实手柄、其他分辨率或 reduced-motion；自然 Failed 仅覆盖 `runtime_combat_melee`，未覆盖 projectile/laser；salvage 分支只验证呈现与确认路径，没有在存在可选物品时实际选择带走物；保存失败重试仅覆盖 Extracted，未覆盖 Failed/Abandoned；Event 未穷举全部选项，Mine 未覆盖多次状态变化；长期系统只覆盖下沉进入与返回，没有覆盖内部操作。组件 runner 可以补充单点契约，但不能替代这些生产旅程空白。

人工以原始分辨率检查 17 张代表图，没有发现阻塞性的裁切、偏心 modal、对象弹窗重叠或结果原因缺失。检查中发现丢弃反馈显示“未命名物资”：根因是 UI 读取命令外层结果而非 `action_result.item`；修复后共享描述读取内部权威 item，HUD 与生产主旅程重跑显示“自护螺母”。这项检查不等价于最终审美、动态动画、音频或完整玩家手感验收。

空间测量记录：进入洞口总移动 111.5168 px、其中向上 94 px、最小缩放 0.58、出现 3 个可区分帧且只提交一次；下沉移动 180 px、持续 1338 ms，表现完成后只提交一次。

## 5. Base 原始来源基线

源压缩包 SHA256 为 `A1035F69C412680016E6FB1C4FB181E77E75A517FDB252D6EBBC76D7F7957E71`，共 1,626 个成员、314,060,767 bytes。仓库中 `sources/base/` 的物理内容为 1,042 个文件、179,095,285 bytes；其中 importer payload 为 1,041 个文件、179,092,608 bytes。最大 blob 为 38,064,205 bytes，低于 GitHub 单文件 100 MiB 限制。

| 类别 | 结果 |
| --- | ---: |
| 原始策划案 | 25 个 / 728,214 bytes |
| art + draw 来源成员 | 1,407 个 / 256,510,309 bytes |
| 美术唯一内容对象 | 1,012 个 / 177,253,870 bytes |
| 别名路径 | 395 个 |
| 内容去重节省 | 79,256,439 bytes |

- 25 份文件明确位于 `sources/base/原始策划案/`，保持来源 basename、完整正文、源字节和 SHA；“原始策划案”名称不得更改，也不得摘要替换或减少信息。格式统一只有在证明信息等价时才允许，本次默认保持源字节。
- 美术按内容 SHA256 唯一保存；每个 canonical/alias 都保留来源路径与保留理由。去重不删除来源身份，395 条 alias 均登记在 manifest。
- 内嵌 `sources/draw/Art.zip` 的 23 张重复图片、`docs_governance` 的 192 份复制型治理快照和外层 `sources.zip` 不重复保存正文/字节，但 1,626 个 archive 身份及排除理由全部保留。
- 所有 Base 美术仍为 `pending_verification` / `pending_review` / `not_admitted`，consumer 为 none。目录名含 `selected` 或 `game_ready` 不构成许可、审核或运行时准入。

```text
I3_BASE_IMPORT_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
I3_BASE_COMMITTED_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
```

`I3_BASE_COMMITTED_VERIFY` 表示不依赖外部 archive、从仓库内容重新计算并验证，不表示相关内容已经完成 Git commit、push、许可审核或运行时接入。

## 6. 性能对照

入口基线与 I3 使用相同 60 Hz workload、300 次 warmup、3,600 次采样、五轮运行。所有场景均为 `cache_loads_after_warmup=0`、`fixed_step_max=1`、`saturated=0`。下表是五轮中位数，单位为微秒；括号内为 I3 相对入口变化。

| 场景 | 入口 p50 / p95 / p99 / max | I3 p50 / p95 / p99 / max |
| --- | --- | --- |
| enemy1 | 319 / 778 / 1157 / 2335 | 355 / 877 / 1279 / 2782（+11.3% / +12.7% / +10.5% / +19.1%） |
| enemy3 | 477 / 1261 / 1888 / 5651 | 497 / 1311 / 1898 / 5014（+4.2% / +4.0% / +0.5% / -11.3%） |
| enemy5 | 601 / 1635 / 2415 / 6830 | 586 / 1531 / 2238 / 5221（-2.5% / -6.4% / -7.3% / -23.6%） |
| projectile15 | 645 / 1724 / 2616 / 4857 | 665 / 1776 / 2741 / 4703（+3.1% / +3.0% / +4.8% / -3.2%） |

可支持的结论仅是：projectile15 关键分位变化控制在 5% 内，enemy5 改善，缓存热身后无新加载；enemy1 仍有 0.036/0.099/0.122/0.447 ms 的绝对回退，不能声称“无回退”或“全面优化”。Headless CPU 测量不能替代目标 GPU/FPS、长局、设备矩阵或玩家可感知掉帧验收。

## 7. 回归失败与修正时间线

### 7.1 首轮 quick：FAIL → 修正 → PASS

首轮 quick/worktree `20260722T202653529Z_02a1c388` 为 FAIL：53 个 runner 中 3 个失败，耗时 415,709 ms；报告 SHA256 为 `C3A422BEB16483C1FF39CF5804C3F91F1017524E91EBA6EF12E5757495223C15`。

- `I1_ANIMATION_RUNTIME`：hurt 的最短可见阈值误设为 0.14 秒，runner 的两次 delta 合计 0.13 秒因此仍停留在 hurt。恢复既有 0.12 秒释放契约；没有修改原本已正确的 pending-state 逻辑，也没有削弱测试。
- `I2_WORLD_INTERACTION_RUNTIME`：生产与 runner 已输出 `asset=open_png_revalidated`，manifest 仍要求旧的 `asset=open_png_blocked`。更新资产门和 marker 契约，没有改变运行时行为。
- `I2_ACCESSIBILITY_RUNTIME`：旧断言未包含已批准的 `master_volume`，并把“音量”全局禁用。更新为精确六字段、0–100/步长 5/默认 80、玩家文案与回滚断言；仍禁止未实现的音乐/音效拆分、UI 缩放、震动、高对比和色盲设置。

修正后 quick/worktree `20260722T204036470Z_9624c50d` 为 PASS 53/53（33 plain + 20 cleanup），40 条精确 cleanup、blocking 0、耗时 403,410 ms、pollution PASS；报告 SHA256 为 `ACB78574948879F9724BF0F216DFB01AFE93C40BC55F44A8DCE0006FF5AE0FD6`。

### 7.2 首轮 full：73/75 FAIL → 修正 → 75/75 PASS

首轮 full/worktree `20260722T204814719Z_fb3bc472` 为 FAIL：40 plain PASS + 33 cleanup PASS + 2 FAIL，耗时 782,561 ms，pollution PASS；manifest SHA256 为 `8DB83675FB3251D88EC54EF0E259A7761198A6A3067C0FC5D68FC25E34B1B058`，报告 SHA256 为 `EAAB37EA9679D1B52569D4D7C3C5798A26C4BF7F078CB020660807C5080AE157`。

- `ART24_INVENTORY_PANEL_LAYOUT`：旧探针仍要求把“藏品”类型写入 tooltip；I3 的共享描述契约已把它放在 `item_presentation.type_label`。探针改为验证共享类型字段，同时继续要求“珍贵”“收藏等级：4”并禁止 raw tag 泄漏，没有降低玩家信息要求。
- `ART24_MAP_OVERLAY_SCENE`：探针已验证并输出 `detail=visible` 的大字号随选项详情，manifest 仍要求旧 marker。只同步精确 marker 与新详情契约，没有绕过布局或交互检查。

修正后执行最终 full/worktree，结果见下一节。

## 8. 最终 full/worktree

| 字段 | 结果 |
| --- | --- |
| run | `20260722T210300990Z_ed330093` |
| source mode | `worktree`（入口 HEAD 仍为 `09aaafe…`，候选包含 tracked/untracked 工作树内容） |
| overall | PASS 75/75 = 42 plain PASS + 33 `PASS_WITH_CLEANUP_DIAGNOSTIC` |
| diagnostics | 66 条精确 cleanup；blocking 0 |
| duration | 785,952 ms |
| pollution | PASS |
| business snapshot | 2,220 files；fingerprint `ED5E6A08A3569470C00F241E265B544E2BBA6766844924D32CC83277E3D0F545` |
| manifest | SHA256 `7A85382E1B2DBDC4B1260720369D9C8FC8448DD01E125873060F58907B6589C9` |
| report | `E:\AGAME1\.tmp\worktrees\i3\.tmp\i1\20260722T210300990Z_ed330093\report.json` |
| report SHA256 | `5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D` |

33 个 cleanup 分类 runner 各产生一条 ObjectDB warning 与一条资源残留诊断，共 66 条；资源数不是单一值，而是按 manifest 精确分类为 `7×1、10×2、16×10、18×19、21×1`：

```text
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
ERROR: <manifest-classified-count> resources still in use at exit (run with --verbose for details).
```

其中六次 I3 production 旅程均属于 18-resource 子集；该生产所有权链和其余 runner 的不同资源数都已在 manifest 中精确登记，因此不冒充 blocking failure；同样也不能把 `PASS_WITH_CLEANUP_DIAGNOSTIC` 写成 cleanup-clean。若数量、文本、runner 范围改变或出现其他诊断，门应失败并重新调查。

## 9. PASS_WITH_NOTES 与重新开启门

| 未关闭内容 | owner / 重新开启条件 |
| --- | --- |
| 跨页最终视觉、边框/StyleBox/token、下沉蓝色底层、最终审美 | UI 美术/产品 UX；批准统一视觉方向并完成人工动态复核 |
| 角色移动/动画手感、真实时装、骨骼帧生成 | 角色表现/美术管线；真实 rig/素材、替换夹具、reduced-motion、性能与人工门 |
| 批量/快捷售卖 | 经济与产品规则；价格、选择、确认、原子性、保存回滚和幂等命令契约 |
| 真实天赋树 | 成长系统产品；点数、成本、依赖、效果、重置/返还和持久化权威 |
| 新设置类别 | 产品/平台；schema、adapter、迁移、apply/cancel/rollback/restart 与玩家文案 |
| Esc 全键鼠/手柄 UX、Mine 音频/震动 | UX QA/音频；跨页面焦点、设备、reduced-motion 和动态人工验证 |
| enemy1 性能残差、目标 FPS/GPU、长局/设备矩阵 | 性能/战斗体验；同机目标设备、可见帧、长局 workload 与玩家感知门 |
| 退出清理分类（production 为 18-resource 子集） | Runtime/QA；逐 runner 定位所有权链并将 manifest 登记的 cleanup diagnostics 降为 0 |
| Base 许可、内容审核与运行时使用 | 资产治理/法务/美术；逐资产 license/review/derivative/runtime key/consumer/视觉门 |
| 导出、发布和 CI 发布矩阵 | 发布工程；独立 export/package/install/smoke/remote CI 门 |

## 10. 外部收口规则

本文只能验证“即将提交的工作树候选”，不能在自身内容中可靠预写包含自身的最终 SHA。最终交付必须依次完成并报告：

1. 提交全部获批 I3 内容并取得 exact HEAD/tree；提交后不得再改业务文件或本文。
2. 以 `-Profile full -SourceMode head` 对该 exact HEAD 运行 75/75，并记录 report 路径、report SHA、manifest SHA、business fingerprint、cleanup/blocking 和 pollution。
3. 将同一个 exact HEAD 推送到获批远端分支，以 `git ls-remote` 证明远端 SHA 与本地 HEAD 完全一致。

只有三步全部通过，本文开头的 `CLOSED / PASS_WITH_NOTES` 才生效。exact-head full 或 push 任一失败、远端 SHA 不一致，或通过后又产生文件修改时，I3 状态自动回退为 `CLOSEOUT CANDIDATE / NOT CLOSED`，不得以本 worktree 报告宣称关闭。
