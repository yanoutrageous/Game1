# I2 Validation, Preview and Manual Review Plan

文档状态：I2 执行计划；不是 validation 结果，未运行项不得写成 PASS。
最后更新：2026-07-22

## 1. 目标

I2 的反馈环必须同时回答四个不同问题：

1. 程序权威和既有玩法是否回归；
2. 生产页面是否能快速生成可对比的静态效果；
3. 动画、转场、输入、焦点和玩家理解是否在动态操作中成立；
4. 战斗房等性能是否在真实工作负载下改善。

自动 runner、截图、人工操作、性能、来源许可、CI 和发布是不同证据。任何一类通过都不能替代另一类。

## 2. I2 进入基线

```text
head: b77132b9de655b36f71c930a35a191c383b55522
tree: 1d26f1415851755f1a8cc57f4804dfb12d9cea4d
full/head: 39/39 PASS
report: E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T193513816Z_48329748\report.json
report sha256: 2072F1DBD067C607E82220F06DEFE15F410ED68807BFAA4EF36B5202007167E8
duration: 254980 ms
plain pass / cleanup-classified: 17 / 22
blocking diagnostics: 0
```

这是 exact HEAD entry baseline，不是 I2 验收。报告保持 `.tmp` 未版本化。

生产截图对照基线：

```text
preview: E:\AGAME1\.tmp\i1\20260721T181135224Z_4a0a6ca0\preview_report.json
sha256: 575113D718A4E1D399FA0EB4EA6C1BE0C0E38B881348C134450E6FF43E77F9FF
head: b77132b9de655b36f71c930a35a191c383b55522
images: 27/27
machine status: PASS_WITH_VISUAL_REVIEW_REQUIRED
visual acceptance: NOT_RUN
```

基线图仅证明捕获成功和可用于前后对照，不证明动态手感或视觉通过。

## 3. 环境与安全预检

所有命令从当前 I2 Git worktree 根执行：

```powershell
$i2Repo = git rev-parse --show-toplevel
Set-Location $i2Repo
git branch --show-current
git rev-parse HEAD
git status --short
git diff --check
```

本机 I1 报告已验证的 Godot 示例为：

```text
E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
4.6.3.stable.official.7d41c59c4
```

实际执行仍由 `-GodotExe`、I1 环境变量和 PATH 解析并复验 identity；绝对路径不是跨机器权威。`E:\UE` 只作为 UE 参考环境，不能拿其 UnrealEditor 当 Godot runner。

启动任何会触及 Godot 工程的切片前：

- 核对 allowed/protected paths 与 `I2_SLICE_GATE_LEDGER.md`；
- 核对另一个主工作树的受保护 `project.godot` 和七个 `.translation` 状态未被吸收；
- 资源切片先核对 source/license/hash/manifest/runtime key；
- 不直接在活动工程打开编辑器来生成 import/translation 变化作为测试手段；使用隔离 mirror。

## 4. 当前可执行的最短循环

I2 目前复用 I1 已验证 harness；尚不存在的 I2 runner 不能写进操作说明假装可用。

### 4.1 静态检查

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\validate_static.ps1 `
  -RepoRoot (git rev-parse --show-toplevel) `
  -GitRepoRoot (git rev-parse --show-toplevel) `
  -SourceMode worktree
```

### 4.2 日常 quick

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 `
  -Profile quick `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

成功标记必须包含 `I1_TEST_STATUS=PASS` 和报告绝对路径。cleanup diagnostic 需分类保留；blocking diagnostic 不能被 marker PASS 覆盖。

### 4.3 定向生产预览

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 `
  -Scene main_menu,deploy,long_term `
  -Resolution 1280x720 `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

局内示例：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 `
  -Scene run,combat,inventory,map,result_success,result_failure `
  -Resolution 1280x720 `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

完整三分辨率矩阵：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 -All `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

输出在 `.tmp/i1/<run-id>/`；`PASS_WITH_VISUAL_REVIEW_REQUIRED` 仍需人工检查。I2 后续新增状态必须先登记到可复现 capture/runner，再加入完成门。

## 5. 按切片最低自动门

| 改动 | 开发中最低门 | 切片审计门 |
| --- | --- | --- |
| 文档/矩阵/门账 | static + 文档链接/UTF-8/diff check | quick；无 runtime claim |
| shared navigation/settings/focus/animation | quick + ui + 定向 runner | full/worktree + dynamic/input/failure |
| 主菜单/Deploy/长期 UI | ui + 定向 preview | full/worktree + 三分辨率 CAP + DYN/INPUT/TEXT |
| 库存/交易/RunStartConfig/天赋效果 | core + 定向行为 runner | full/worktree + save/idempotency/failure |
| 局内地图/箱子/掉落/模态 | core + ui + 状态 runner | full/worktree + production dynamic path |
| 战斗/结算/性能 | core + deterministic runner | full/worktree + PERF + result/save failure |
| scene/resource/project/metadata | project metadata + source/import gate | full/worktree；精确暂存清单 |
| I2 综合关闭 | 全部切片证据 | full/worktree；提交后 full/head；单一综合 review |

## 6. 快速人工阅览流程

每个 UI 切片提供一个不超过 10 分钟的 smoke，并记录 build/head、存档夹具、分辨率、输入设备、步骤、预期、实际、截图/视频路径和问题 ID。

### 6.1 主菜单

1. 启动 production `main.tscn` 到主菜单，等待可交互。
2. 用鼠标、键盘和手柄逐个聚焦四个入口，观察文字、旗帜、选中框和角色状态是否同一锚点。
3. 进入 Deploy：确认角色进入洞口表现、路由只提交一次、快速连按不会双导航。
4. 返回后进入 Long：确认画面下移语义、返回焦点恢复。
5. 打开/取消/应用设置，重启后核对持久化；模拟写入失败时不得显示成功。
6. 开启 reduced motion 重复步骤 2–4，确认仍有清晰静态反馈且不跳过路由状态。

### 6.2 Deploy

1. 地图页同屏查看左选择/右难度详情，依次验证 8 个现有 ID；不得出现独立区域页。
2. 改变地图/难度，确认右摘要和最终 RunStartConfig 一致。
3. 仓库以空/少/满/不同品质测试拥有、使用/出勤与详情；只执行已接真实命令的动作。
4. 若批量售卖获批，测试选择、取消、确认、余额、失败和重启幂等；未获批时 UI 不显示可用假按钮。
5. 申领测试可领、余额不足、条件不足、重复申领和满库存。
6. 四个摘要二级页签只显示概览/具体配置/本局效果/本局目标；开始、继续、禁用、错误 CTA 可区分。

### 6.3 长期系统

1. 逐一进入任务档案、天赋、图鉴、研究、资历、收藏和角色模块（仅限切片已实现模块）。
2. 验证列表、详情、条件、奖励、状态、空态、锁定态、分页/滚动和档案栏收起/恢复。
3. 迁移期核对原任务/成就/委托记录、红点、领取和存档无丢失，再检查 Goal 标签变化。
4. 用长中文、英文伪本地化和无头像/缺图 fallback 检查布局。

### 6.4 局内与结果

1. 普通房移动，核对角色表现位置不偏离碰撞/可交互范围。
2. 未开箱→首次打开→查看物品→离开→回到已开箱，确认只提交一次奖励。
3. 靠近地面多物品，确认自动显示但不自动拾取；测试满包替换、滚动、离开关闭。
4. 打开 quick inventory/full inventory/map，检查品质冗余、负重、tooltip、邻雷数、fog、标记、外点关闭和焦点恢复。
5. Esc 测试继续、设置、放弃二次确认、取消、嵌套模态和快速连按。
6. 战斗房验证怪物入场、攻击/受击、边缘接触不直接离开、明确逃跑操作和代价。
7. 雷房/事件房/撤离点逐一验证发现、提示、意图、结果和离开；reduced motion 重复高刺激反馈。
8. 分别触发成功、失败、放弃、失败保全与保存失败，确认原因、获得、保全/待选、损失、去向和下一步清楚且结算幂等。

## 7. 视觉与可访问性矩阵

最低分辨率仍覆盖 `1280x720`、`1600x900`、`1920x1080`。I2 最终还需根据目标平台明确是否加入非 16:9、窗口实时缩放和系统 DPI；在未执行前标记 `NOT_RUN`。

每个玩家页面检查：

- 字体、对比、遮挡、裁切、锚点、layer、safe area；
- normal/hover/focus/pressed/disabled/error/loading/empty/overflow；
- 键鼠、手柄、焦点归还、点击穿透、连点和失焦恢复；
- reduced motion、闪烁安全、颜色+文字/图标/边框冗余；
- 长中文、伪英文、本地化占位、数字极值和缺图 fallback；
- 页面进入/退出、存档/加载失败、目标内容刷新后 selected ID 消失。

静态截图能验构图，不能验 hitbox、焦点、动画节奏或 input ownership。动态视频能验表现，不能替代领域 runner。

## 8. 真实工作负载性能

### 8.1 固定条件

- 同一机器、Godot build、分辨率、渲染设置、VSync 状态、存档、seed 和内容版本；
- Debug/diagnostic 开销必须记录，前后配置一致；
- 冷启动与热启动分开；至少记录样本数量和预热策略。

### 8.2 场景

| 场景 | 最低时长/次数 | 指标 |
| --- | --- | --- |
| 主菜单/Deploy/Long 静置 | 各 60 秒 | frame、CPU、节点、分配、隐藏页 process、内存 |
| 页面往返 | 20 次 | 可交互时间、内存漂移、节点/资源增长、焦点 |
| 战斗 1/3/5 敌人 | 各 ≥60 秒 | frame P50/P95/P99/max、fixed-step、snapshot、presentation、追赶步数 |
| 峰值攻击/FX | 可重复固定脚本 | 加载次数、尖峰、分配、掉帧、reduced motion |
| 地图/背包/多掉落 | 空/少/满/滚动 | rebuild、layout、资源加载、input latency |
| 保存/设置/结算 | 成功与拒绝写入 | 磁盘延迟、帧尖峰、反馈、恢复 |

阈值在第一次同条件 baseline 后由性能切片 gate 冻结。没有前后同条件数据时，不声明“性能优化”；combat refresh p95 只能保留为分项历史指标。

### 8.3 I2.6A 真实战斗工作负载 runner

`Godot/GraytailGodot/tests/i2_combat_frame_baseline_runner.gd` 使用 production `main.tscn -> RunScene -> G41InRunRuntime -> G41CombatSimulation -> G41RoomRuntimeView -> G41RuntimeActorView` 路径。runner 不修改 production 脚本；为得到分项时间，它关闭 `RunScene._process`、`PlayerController._process` 与全部 `G41RuntimeActorView._process` 的自动外层调度，再按生产顺序显式以 60Hz 驱动 simulation、domain event、snapshot、player projection、room presentation、PlayerController 和 ActorView，随后等待真实 SceneTree process frame。这样动画换帧和纹理应用属于 `presentation_sync`，不会消费 headless 未限速产生的微小 SceneTree delta。

默认冻结 `workload_schema=v2`：

- 每个场景预热 300 帧，采样至少 3600 帧，即 5 秒预热和 60 秒固定步模拟；
- `enemy_1`：1 slime；
- `enemy_3`：slime + bat + drone；
- `enemy_5`：slime + 2 bat + 2 drone；
- `projectile_peak`：1 drone，并用生产弹丸结构持续维持 15 枚弹丸；15 来自 5 bat × 3-shot spread 的容量预算；
- 固定 1280×720、60Hz combat 与 visual step、seed、输入轨迹和 1,000,000 durable HP；headless 设 `Engine.max_fps=0`，visible 设 `Engine.max_fps=60` 且启用 VSync，结束后恢复原值；每帧结束前断言所有受控 PlayerController/ActorView 均未保留自动 process。
- 该 workload 在 production 容器内注入固定敌人 roster，并在峰值场景维护弹丸数量；其 JSON 明示 `fixture_injected=true`、`production_encounter_bootstrap_covered=false`。四个场景同进程但每场景重置 simulation、view、HP、domain events、run event log 与 transaction log，故只能用于场景内增长门，不能把四场景数据当作严格的跨场景相对内存基准。

记录内容包括 frame total、同步工作总量、simulation、domain event、snapshot、presentation sync、engine process、process-frame interval、fixed steps/catch-up/12-step saturation、accumulator backlog，PlayerController/ActorView 固定推进次数与自动 process 违规数，敌人/弹丸/激光计数，RuntimeTextureCache 请求/加载/命中/失败，以及 Performance/OS static memory、peak、Node、Resource、orphan 数。ActorView 自身固定 `_process` 已计入 `presentation_sync`；`engine_process` 仍只代表其余 SceneTree 工作，二者都不能单独冒充完整呈现成本。

headless 正式结构门为：四个场景和采样数准确；1/3/5 敌人数不漂移；弹幕场景每帧恰好 15 枚弹丸；steady schedule 每帧恰好 1 fixed step、无 catch-up、无 12-step saturation、无 accumulator backlog；PlayerController 每个固定帧恰好推进一次、每个活动 ActorView 每帧恰好推进一次且自动 process 违规为零；cache failure 为零且最后十秒加载数进入平台；前十秒与后十秒 static memory 中位数增长不超过 2 MiB；Node 中位数漂移容差 64、Resource 中位数增长容差 8、orphan 恒为零；首次销毁后 Node 回到启动基线 +4 内，并且从 runtime-loaded 平台至少释放 64 个 Resource。随后必须再执行一次 build→Run→teardown，第二次 Node/orphan 不高于第一次稳定平台，第二次 Resource 不得高于第一次 after +8；这证明重复生命周期不持续增长，不声称 Godot Resource 缓存回到进程启动计数。以上是结构/生命周期门，不是冻结后的性能改善门槛。

I2.6B 将 combat actor cache 完成门收紧到生产资源准入后的绝对零迟加载：`Art24RuntimeAnimationCatalog` 声明 36 张玩家动态帧，`Art24EnemyVisualCatalog` 声明 35 张去重后的生产敌人动态帧；`RunScene._run_start_asset_admission()` 在权威启动命令 dispatch 前通过 `RuntimeTextureCache.prewarm()` 组合并核对 71 张，失败时不得提交 active run；命令成功后 `_show_run_screen()` 再做 load-idempotent 复核。正式 runner 实例化 `main.tscn` 前清理一次测试 cache，随后不得逐场景清理或私自加载。准入报告必须满足 `ok=true`、`declared=cached=71` 且 `missing=failures=rejected=0`，show-time 报告必须 `already_cached=71/loaded=0`；每个场景从 setup、warmup 到 sample 的 `loads_delta/failures_delta/entries_delta` 均必须为 0。生产 route 集成 runner 另行锁定 `_start_run_from_route()` 已传入 admission Callable，避免测试手工顺序掩盖真实接线遗漏。当前主场景初始化先消费 2 张隐藏玩家 idle 纹理，本结论因此只覆盖 Run 准入后的迟加载，不声称应用启动后零加载；也不覆盖程序绘制 projectile/laser、房间背景或物品 UI。

在主审把 runner 登记到 I1 manifest 后，正式执行优先使用 harness 的 per-case `APPDATA`/`USERPROFILE` 隔离。登记前定向执行必须显式隔离 `user://`：

```powershell
$i2Repo = git rev-parse --show-toplevel
$perfUser = Join-Path $i2Repo '.tmp\i2\perf-user'
New-Item -ItemType Directory -Force -Path `
  $perfUser, `
  (Join-Path $perfUser 'AppData\Roaming'), `
  (Join-Path $perfUser 'AppData\Local') | Out-Null
$env:USERPROFILE = $perfUser
$env:APPDATA = Join-Path $perfUser 'AppData\Roaming'
$env:LOCALAPPDATA = Join-Path $perfUser 'AppData\Local'
$godot = 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
& $godot --headless `
  --path (Join-Path $i2Repo 'Godot\GraytailGodot') `
  --log-file (Join-Path $i2Repo '.tmp\i2\combat-frame-formal.log') `
  --script (Join-Path $i2Repo 'Godot\GraytailGodot\tests\i2_combat_frame_baseline_runner.gd')
```

正式 headless 成功标记严格为 `I2_COMBAT_FRAME_BASELINE=PASS`。开发期可追加 `-- --i2-perf-smoke`，缩短为 30 + 120 帧；其标记是独立的 `I2_COMBAT_FRAME_BASELINE_SMOKE=PASS`，不能当正式基线。

headless display driver 没有真实 GPU 输出，`TIME_FPS` 也不能代表玩家实际 FPS。同一 runner 仅在显式 `-- --i2-perf-visible` 且非 headless 时进入 visible 模式；此模式每场景同时满足至少 3600 帧和 60 个墙钟秒，只输出 `I2_COMBAT_FRAME_VISIBLE=MEASURED_NOT_ACCEPTED workload_schema=v2`。visible 数据仍需人工核对真实窗口、掉帧和交互手感，不能由 headless PASS 替代。

## 9. 切片证据记录模板

```text
Slice:
Commit/worktree fingerprint:
Allowed/protected paths:
Baseline:
Changed:
AUTO:
CAP:
DYN:
INPUT:
PERF:
FAIL:
ASSET:
TEXT:
Diagnostics:
NOT_RUN / deferred:
Claim check:
Rollback point:
```

临时报告、视频和截图保存在 `.tmp/i2/<slice>/<run-id>/` 或 runner 自带 `.tmp/i1/<run-id>/`；未经审查不进入 Git。

## 10. I2 最终门

提交前在干净可解释 worktree 上运行 full/worktree、全量 preview、人工关键路径、输入/可访问性、真实性能和来源门。提交后再对 exact HEAD 运行：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 `
  -Profile full `
  -SourceMode head `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

最终审计必须逐条关闭反馈矩阵并分别报告 `PASS / FAIL / NOT_RUN / DEFERRED`。只有 exact HEAD 与综合证据一致时，才可创建 I2 validation/handoff 并考虑 capability promotion；本计划本身不提供这些结论。
