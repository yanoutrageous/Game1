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
