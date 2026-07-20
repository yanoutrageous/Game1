# Current State

文档状态：I1 已关闭后的当前仓库事实。
最后更新：2026-07-21

## 当前身份

```text
active_repo: git rev-parse --show-toplevel
observed_branch: codex/i1-baseline-stabilization
source_head_before_i1: 2212992337aeef7cda412dbaaa191c3ad6cbb81a
implementation_commit: 6a4f207d743583c7342655488c2d9a652b9ab05c
closure_fix_commit: 492d74fcdc94cb75e47401c203defd49dac11ae9
validated_head: 492d74fcdc94cb75e47401c203defd49dac11ae9
validated_tree: 96a5272e50ff80aad400ccde3db9d313fa1456a1
upstream: origin/codex/i1-baseline-stabilization
current_stage: none / I1 closed PASS_WITH_NOTES
latest_closed_non_art_baseline: I1
latest_closed_art_stage: ART21
later_accepted_page_ui_evidence: ART23
latest_failed_art_attempt: ART24R2 archived at 24/61 PASS
godot_project: <active_repo>/Godot/GraytailGodot
local_godot_observation: E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

仓库路径和 Godot 工程位置必须动态解析。本机 Godot 路径只是观测/示例；I1 runner 仍按显式参数、环境变量、PATH 顺序解析并对照 lock 验证。

## 已有运行能力

- 主菜单、出发整备、长期页、局内和结果页由生产 `main.tscn` 路由。
- G41 提供连续房间移动、距离交互、宝箱/地面掉落、拾取/替换/丢弃、固定步长战斗、怪物、逃跑和生命周期清理。
- M6 提供真实仓库实例、手动出勤、局内获取/使用、成功/失败/放弃结算、手动失败保全、幂等局外写回和最多 50 条历史。
- M7 提供八档地图、难度、委托、任务、成就、研究、图鉴、资历、收藏和红点的首轮真实内容。
- 当前进程内可继续相同 `run_id`；退出 Godot 进程后的 active-run 检查点恢复未实现。
- 消耗品终局清除；失败保全在玩家确认后提交；UI 不应拥有结算或持久化权威。

## I1 当前实现事实

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

I1 的提交态验收与 Git 交付已经支持：将项目从“核心能力集中开发”切换为“新增能力与存量修改并行”是正确的。项目已不再缺少最小运行闭环，后续主要风险转为权威漂移、局部修改回归、热路径成本、界面新增状态和历史文档冲突；I1 的 runner 与 preview 已为这些风险提供快速反馈。

这不表示项目进入维护期。跨进程恢复、完整经济、更深内容、最终视觉/音频、人工长局、通用性能、设备/输入、远端 full、导出和发布仍需要独立增量。当前没有自动授权的后继阶段。

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
```

关闭权威是提交态 full/head；worktree、preview 和 Actions quick 只证明各自范围。完整记录见 `docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`。

## 明确未完成

- `RunScene` 仍是大型协调器；I1 不宣称全面解耦。
- active-run 跨进程检查点与迁移未实现。
- 完整仓库整理/堆叠/扩容/保险/寄售/批量出售和更深经济未完成。
- 装备强化、耐久、随机词条、完整被动、最终数值平衡未完成。
- Boss、精英、更深事件与内容量、抽奖、唯一物真实获取和实际外观未完成。
- 22 个 full runner 的已分类 cleanup diagnostic、完整人工长局、最终美术/音频、通用性能、导出和发布未关闭。
