# Validation Index

文档状态：I1 worktree 验收通过、committed HEAD 待验证的当前入口。
最后更新：2026-07-20

## I1 统一入口

静态完整性：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\validate_static.ps1 `
  -RepoRoot (git rev-parse --show-toplevel) `
  -GitRepoRoot (git rev-parse --show-toplevel) `
  -SourceMode worktree
```

日常/最终自动化：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 `
  -Profile quick `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

将 `quick` 替换为 `preflight`、`core`、`ui` 或 `full`。提交后的最终对象使用 `-Profile full -SourceMode head`。

生产预览：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 -All `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

本机路径不是跨机器权威；解析与身份复验规则见 I1 runbook。

## 当前状态

| 验证 | 结果 | 边界 |
| --- | --- | --- |
| I1 static final | PASS / 39 blocking / 46 inventory / 13 exclusions | 705 checks / 0 failures |
| I1 preflight worktree | PASS / 120,233 ms | 较旧观测下降 69,172 ms / 36.5%；安全门不减弱 |
| I1 quick worktree | PASS / 21 of 21 | 短跨层回归 |
| I1 core worktree | PASS / 24 of 24 | 程序权威、保存、结算；combat p95 519 μs |
| I1 ui worktree | PASS / 23 of 23 | UI/布局/动画自动契约 |
| I1 full worktree | PASS / 39 of 39 | current pre-commit candidate；pollution PASS；combat p95 321 μs；duration 400,736 ms |
| I1 production preview | PASS_WITH_VISUAL_REVIEW_REQUIRED / 27 of 27 generated / PASS_STATIC_REVIEW | machine visual acceptance NOT_RUN；人工仅覆盖布局、层级、文字、无遮挡与无裁切 |
| I1 full committed HEAD | PENDING | 精确提交快照 |
| I1 GitHub Actions quick | CONFIGURED_UNPROVEN | 需要远端实际成功 run |

详细证据、报告路径、SHA-256、cleanup 分类和排除项见 `docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`。

16:05 candidate 的 38/39 FAIL 与 M5 固定 seed 测试夹具修复保留在详细 validation 中；不得只保留最终绿色结果而删除失败链。当前 15:46 preview 的人工静态证据继续适用，但 wrapper 仍不是自动视觉 PASS。

## 已登记的性能边界

`I1_COMBAT_REFRESH` 是 I1 唯一 blocking 性能微基准，验证 production main 场景的 combat p95 和 full refresh 对照。完整运行性能、长局、内存、设备矩阵、导出和发布性能明确为 `EXCLUDED_NON_SLICE` / not claimed。

## 历史与回归证据

| 证据 | 当前用法 |
| --- | --- |
| I0 validation | 上一闭合非美术基线；冻结历史，不覆盖 I1 |
| ART21 closeout/validation | 项目级上一闭合美术阶段 |
| ART23 validation | 较晚页面/UI 验收证据切片；不提升项目级 stage authority |
| ART24R2 final Computer Use | 失败封存，24/61 PASS；不得改写 |
| G41/M6/M7 runners | I1 core/full 的行为回归来源 |
| M2/M3/M3H/M3R/M5 | 历史 characterization；当前语义以较新 runtime 和 I1 runner 为准 |

历史阶段的独立 wrapper/static validator 不再是 I1 当前入口。2026-07-20 诊断中，G35 validator 仍要求已经迁移的 DeployPrep/RunBootstrapper 预览边界，G36 validator 仍要求 terminal commit authority 位于迁移前位置；M3/M3H/M3R/M5 validator 会一刀切拒绝任何 `project.godot` 变化，M3/M3H 还包含已被新语义和 `ItemCommandHandler` 取代的结构断言。这些失败只说明旧门与当前架构漂移，不能标成当前 PASS，也不能覆盖 I1 acceptance。

I1 对应处理是：行为回归由 manifest 中已校准的 runner 承担；`project.godot` 的 4.6 feature、autoload 与 ownership 由 `I1_PROJECT_METADATA` 专门 gate 承担。若未来要恢复旧 wrapper 的复用价值，应单独校准其契约，不能为了让旧静态文本通过而回退当前权威。

## 声明规则

- 精确 PASS marker、exit code 和无 blocking diagnostic 才构成单 runner PASS。
- cleanup diagnostic 必须保留分类，不能假装不存在。
- worktree PASS 不代替提交后的 head PASS。
- screenshot/capture、静态、headless、manual、performance、CI 和 release 分开声明。
- 历史 stage validator 的失败或旧 PASS 都不替代 I1 manifest + 专门 gate 的当前结果。
