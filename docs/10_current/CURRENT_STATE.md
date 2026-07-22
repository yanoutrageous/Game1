# Current State

文档状态：I2 关闭后的当前仓库事实；I2 为最新闭合非美术基线，状态 `CLOSED / PASS_WITH_NOTES`。
最后更新：2026-07-22

## 当前身份

```text
active_repo: git rev-parse --show-toplevel
observed_branch: codex/i2-player-experience-refactor
source_head_before_i1: 2212992337aeef7cda412dbaaa191c3ad6cbb81a
implementation_commit: 6a4f207d743583c7342655488c2d9a652b9ab05c
closure_fix_commit: 492d74fcdc94cb75e47401c203defd49dac11ae9
i1_closure_commit: b77132b9de655b36f71c930a35a191c383b55522
i2_entry_validated_head: b77132b9de655b36f71c930a35a191c383b55522
i2_entry_validated_tree: 1d26f1415851755f1a8cc57f4804dfb12d9cea4d
i2_implementation_commit: c500bdb8b931fada26f4f617a3feaad643281b4c
i2_implementation_tree: 7b04e81882961f65a516e192c33093ec98162667
observed_base_ref: origin/main at b77132b9de655b36f71c930a35a191c383b55522
current_stage: no active successor stage; I2 CLOSED / PASS_WITH_NOTES
latest_closed_non_art_baseline: I2
latest_closed_art_stage: ART21
later_accepted_page_ui_evidence: ART23
latest_failed_art_attempt: ART24R2 archived at 24/61 PASS
godot_project: <active_repo>/Godot/GraytailGodot
local_godot_observation: E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

仓库路径和 Godot 工程位置必须动态解析。本机 Godot 路径只是观测/示例；I1 runner 仍按显式参数、环境变量、PATH 顺序解析并对照 lock 验证。

## I2 关闭事实

- I2 是用户授权的跨程序、美术、产品和治理集成阶段；I2.0–I2.7 是内部门，不是独立阶段。I2 已以 `CLOSED / PASS_WITH_NOTES` 收口，后续阶段未自动授权。
- 已验证的获批范围包括：真实设置与 focus/modal 基础；主菜单文字/锚点安全回退；Deploy 同页双栏、八地图投影、真实单件交易与摘要；长期任务档案/模块工作区/角色表现端口；局内对象、公开地图、品质/背包、modal；战斗显式撤离、特殊房公开旅程；以及结果原因、物品分类、保存失败重试和两次放弃确认。
- 这些结论来自 I2 的定向 runner、生产 capture、I1/G41 回归、结算/保存失败路径与独立复核；只覆盖获批范围，不等同于最终美术、完整玩家手感、通用性能、长时人工游玩、导出或发布。
- Godot 是唯一实现目标；`E:\UE\Game\UE\Graytail` 只作只读语义/交互/视觉参考，不是架构、代码、性能或素材许可权威。
- Deploy 地图固定为同一页面的双栏信息架构：左侧地图名称与比例/规模，右侧难度与详情；现有 8 个地图 ID 保持不变，不引入“区域 → 难度”分步页。
- I1 的 `RunStateMachine`、`RunAssetLedger`、terminal settlement、`SaveAdapter`、结算幂等和失败保全确认边界全部继承。
- I2 已验证的是玩家体验与解释层的受控增量，未改变 I1 的领域/保存/结算权威；能力矩阵中的玩法与持久化基线仍以 I1/G41/M6/M7 的事实为基础。

## 已有运行能力

- 主菜单、出发整备、长期页、局内和结果页由生产 `main.tscn` 路由。
- G41 提供连续房间移动、距离交互、宝箱/地面掉落、拾取/替换/丢弃、固定步长战斗、怪物、逃跑和生命周期清理。
- M6 提供真实仓库实例、手动出勤、局内获取/使用、成功/失败/放弃结算、手动失败保全、幂等局外写回和最多 50 条历史。
- M7 提供八档地图、难度、委托、任务、成就、研究、图鉴、资历、收藏和红点的首轮真实内容。
- 当前进程内可继续相同 `run_id`；退出 Godot 进程后的 active-run 检查点恢复未实现。
- 消耗品终局清除；失败保全在玩家确认后提交；UI 不应拥有结算或持久化权威。

## I1 继承实现事实

### 程序与可靠性

- 普通 restart 强制确认；debug restart 使用独立动作和 debug gate，standard/demo 启动配置身份保持。
- `RunStateMachine` 集中 phase 写入；`RunContext` 兼容入口委托状态机。
- `RunRuntimeController` 在 UI 之前监听结果并协调 terminal settlement 的单次提交；pending failure salvage 不提交。
- `SaveAdapter` 使用临时写入、flush、解析、backup、替换后复验和 backup 恢复，并阻止当前 schema 覆盖未来 schema。
- 物品命令细节进入 `ItemCommandHandler`；CommandBus 保留接收、归一化、信号和跨服务协调。
- `ContentDBAccess` 为可复用脚本提供运行时内容访问边界，消除对 autoload symbol 的编译期耦合；`ContentDB` 仍是 production 内容权威。
- `GameKernel` 不再作为 autoload；当前项目保留 `ContentDB` 与 `SettingsManager`，feature target 为 Godot 4.6。

### 刷新与性能

- combat damage 发出最小 `scope=combat` 快照；生产 RunSurface 走轻量 HP/威胁/压力/消息刷新，不重建地图、背包或完整页面。
- AppShell 只刷新可见页面，隐藏页面缓存 revision，显示时追到最新一次。
- `I1_COMBAT_REFRESH` 在最终提交态 full/head 中得到 combat p50/p95/p99/max = 110/222/310/356 μs，full refresh p95 = 151,070 μs；180/40 samples，满足 combat p95 ≤ 8 ms 且低于 full p95。
- 上述是战斗刷新微基准，不是通用性能、长局、内存或设备验收。

### UI、动画与资源

- 生产交互契约覆盖 1280×720、1600×900、1920×1080；共享按钮可聚焦、可见字号不低于 13 px，命令反馈和禁用原因必须可见。
- run/combat 底部双行状态框已修正边框内距与行高，deploy 摘要已收敛为单行；`I1_UI_INTERACTION` 三分辨率与 ART22 34 状态定向 runner 均 PASS，并由最新 full 覆盖。
- 运行时贴图缓存和动画 catalog 覆盖 idle/move/attack/hurt/dead 状态、受击最短可见时间与 reduced motion；玩家独立 death bitmap 和最终 motion feel 未完成。
- ART25 来源/许可/content validator 已以 107 assets 通过，确定性生成前后 fingerprint 一致；production 字体使用 Noto Sans CJK。
- 最新生产预览已生成主菜单、出发、长期、局内、战斗、背包、地图、成功/失败结果 × 三分辨率 27/27 PNG，并完成人工静态布局、层级、文字、无遮挡与无裁切检查。机器状态仍要求视觉复核；鼠标/手柄手感、动态动画观感和音频仍排除。
- 15:46 preview 早于后续 `game_kernel` diagnostic 校准、M5 固定 seed 测试夹具与 newline safety 修复；这些变化都不改变 UI 可见执行路径，因此静态图证据仍适用于关闭对象，且不升级为自动视觉 PASS。

### 验证与治理

- `tools/i1/invoke_i1.ps1` 提供 preflight/quick/core/ui/full 和 worktree/head 两种 source mode，使用隔离 mirror、锁定 Godot、JSON 报告、超时、marker、diagnostic 分类和污染守卫。
- preflight 以单次剪枝源检查和复制后完整目标检查替代 7 次包含 `.tmp` 历史 mirror 的全树扫描；最新耗时 120,233 ms，较旧观测下降 69,172 ms / 36.5%，安全门未减少。
- 16:05 worktree full 曾因 M5 旧夹具未固定地图 seed 而 38/39 FAIL；fixture 固定 `seed_value=1001` 后独立进程连续 3 次 PASS，随后 16:15 worktree full 39/39 PASS。production 的 M7 无 seed 时间随机规则未改变。
- `tools/i1/invoke_i1_preview.ps1` 提供生产场景快速阅览；其 runner 明确登记为 `EXCLUDED_NON_SLICE`。
- 最终提交态 full/head 在 `492d74fcdc94cb75e47401c203defd49dac11ae9` 上 39/39 PASS；17 个 runner 为纯 PASS，22 个带已分类 cleanup diagnostic，blocking 为 0，business file 2,121 个且污染/manifest/control/静态/注册守卫均 PASS。
- `.github/workflows/i1-quick.yml` 已由 GitHub Actions run `29760789712` / job `88414602442` 成功证明 quick；本地 full/head 仍是完整关闭权威，远端结果不证明 full、导出或 release。
- 当前入口、来源、Godot docs hash、重复台账和 I1 文档链已统一到关闭状态；历史原文不删除。

## 阶段判断

I1 的提交态验收与 Git 交付已经支持：将项目从“核心能力集中开发”切换为“新增能力与存量修改并行”是正确的。I2 已在这一判断下完成受控的玩家体验重构，并保留 I1 的权威/保存/结算边界。后续主要风险仍是权威漂移、局部修改回归、热路径成本、界面新增状态、审美/手感未验收项和历史文档冲突；现有 runner 与 preview 为这些风险提供快速反馈。

这不表示项目进入维护期。跨进程恢复、完整经济、更深内容、最终视觉/音频、人工长局、通用性能、设备/输入、远端 full、导出和发布仍需要独立增量。I2 的关闭也不自动包含这些排除项；后续工作必须取得新的范围授权与独立门。

## 当前验证状态

```text
I1_STATIC_FINAL=PASS_39_BLOCKING_46_INVENTORY_13_EXCLUSIONS_705_CHECKS
I1_PREFLIGHT_WORKTREE=PASS
I1_QUICK_WORKTREE=PASS_21_OF_21
I1_CORE_WORKTREE=PASS_24_OF_24
I1_UI_WORKTREE=PASS_23_OF_23
I1_FULL_WORKTREE=PASS_39_OF_39_PRECOMMIT_EVIDENCE
I1_PRODUCTION_PREVIEW_REVIEW=PASS_STATIC_LAYOUT_27_OF_27
I1_FULL_HEAD=PASS_39_OF_39_HEAD_492D74F
I1_CI_QUICK=PASS_RUN_29760789712
I1_STAGE=CLOSED_PASS_WITH_NOTES
I2_ENTRY_FULL_HEAD=PASS_39_OF_39_HEAD_B77132B
I2_ENTRY_REPORT_SHA256=2072F1DBD067C607E82220F06DEFE15F410ED68807BFAA4EF36B5202007167E8
I2_QUICK_WORKTREE=PASS_48_OF_48
I2_UI_WORKTREE=PASS_49_OF_49
I2_FULL_WORKTREE=PASS_67_OF_67
I2_FULL_WORKTREE_REPORT_SHA256=A6F7978C038EFC6F5FFCA9FA058A0DA161AA28B12DD0B589F87354E126FABCAB
I2_STAGE=CLOSED_PASS_WITH_NOTES
I2_RUNTIME_CAPABILITY_DELTA=SCOPED_PLAYER_EXPERIENCE_AND_EXPLANATION_ONLY
```

I1 的 validation/handoff 仍是 I1 的历史关闭权威。`b77132b` 的 39/39 full/head 是 I2 进入基线，不改写历史 I1 证据；worktree、preview 和 Actions quick 各自只证明其覆盖范围。I2 的关闭原文将单独登记 validation/handoff，不能用本摘要替代。

## 明确未完成

- `RunScene` 仍是大型协调器；I1 不宣称全面解耦。
- active-run 跨进程检查点与迁移未实现。
- 完整仓库整理/堆叠/扩容/保险/寄售/批量出售和更深经济未完成。
- 装备强化、耐久、随机词条、完整被动、最终数值平衡未完成。
- Boss、精英、更深事件与内容量、抽奖、唯一物真实获取和实际外观未完成。
- 22 个 full runner 的已分类 cleanup diagnostic、完整人工长局、最终美术/音频、通用性能、导出和发布未关闭。
- I2 的九项明确延期仍需独立门：最终角色动画/时装替换、空间叙事转场、批量出售、真实天赋树、最终角色移动手感、跨页最终视觉风格、战斗房绝对性能、整合键鼠/手柄 UX 与长时人工体验。
