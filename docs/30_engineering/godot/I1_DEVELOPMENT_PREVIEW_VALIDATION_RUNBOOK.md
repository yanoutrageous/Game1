# I1 Development, Preview and Validation Runbook

文档状态：当前操作手册。
最后更新：2026-07-20

## 1. 适用范围

本手册是 I1 后所有程序、UI、资源、文档和接口修改的默认反馈入口。命令从 Git worktree 根执行；不要把历史绝对路径当作项目定位规则，也不要直接在活动工程上用编辑器生成 import / translation 状态来代替隔离验证。

## 2. 环境确认

```powershell
$repo = git rev-parse --show-toplevel
Set-Location $repo
git status --short
```

Godot 解析顺序：

1. `-GodotExe`
2. `I1_GODOT_EXE`、`GODOT4`、`GODOT_EXE`
3. manifest 登记的命令名从 `PATH` 解析

本机已观测路径：

```text
E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
4.6.3.stable.official.7d41c59c4
```

它只用于本机示例。harness 会复验主/console 可执行文件、大小、SHA-256 和版本；其他机器应显式传参或设置环境变量。

## 3. 最短开发循环

修改 manifest、runner 或 probe 后先运行静态自检：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\validate_static.ps1 `
  -RepoRoot (git rev-parse --show-toplevel) `
  -GitRepoRoot (git rev-parse --show-toplevel) `
  -SourceMode worktree
```

普通修改运行 quick：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 `
  -Profile quick `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

成功输出必须包含：

```text
I1_REPORT_JSON=<absolute-path>
I1_TEST_STATUS=PASS
```

失败时先打开 `report.json`，按 `fatal_error`、runner、`blocking_diagnostics`、marker、timeout、pollution 顺序定位。cleanup diagnostic 单独记录，不等于 blocking，也不得悄悄删除。

## 4. 按改动选择 profile

| 改动 | 最低本地门 | 合入/关闭门 |
| --- | --- | --- |
| 文档 / manifest / runner | static + quick | full |
| 命令、状态、保存、结算 | core | full |
| 战斗热路径 | core（包含 combat refresh） | full + 指标复核 |
| UI、布局、动画、路由 | ui + 相关 preview | full + 人工图片/交互复核 |
| 资源/manifest/font | ART25 专门 validator + ui | full + 来源/许可复核 |
| `project.godot` / metadata | quick 或 core 中的 project metadata gate | full；明确暂存清单 |

不要把 `validate_g35`、`validate_g36` 或 M3/M3H/M3R/M5 的历史 wrapper 当作 I1 current acceptance。它们保留旧模块位置、旧语义或“任何 `project.godot` 变化都失败”的静态断言。I1 使用 manifest 中校准的行为 runner，并由 `I1_PROJECT_METADATA` 对当前 project metadata 进行专门验证；旧 wrapper 只能作为历史/诊断材料，不能记录为当前 PASS。

可用 profile：

```text
preflight  infrastructure, mirror, locked engine, import, isolation
quick      short cross-layer smoke
core       program invariants and combat microbenchmark
ui         UI/runtime/layout/animation contracts
full       all registered blocking runners
```

worktree mirror 的源检查必须剪枝 `.git`、`.tmp`、Godot `.godot` 与 `reports`，不得递归进入历史 mirror；复制完成后仍须对目标执行完整检查，并保留 manifest/control binding、mirror fidelity、import/isolation 与污染守卫。性能优化不得通过删除这些安全门实现。

依赖地图拓扑或随机内容的 legacy characterization runner 必须在测试夹具中显式固定 seed；不得依赖 production 在缺省 seed 下的时间随机结果，也不得为修复测试而改变 production 随机规则。

## 5. 快速生产预览

预览来自 `scenes/main/main.tscn` 的隔离 mirror，不修改活动工程。

单个或少量状态：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 `
  -Scene run,combat,result_failure `
  -Resolution 1280x720 `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

完整矩阵：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 -All `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

状态：`main_menu`、`deploy`、`long_term`、`run`、`combat`、`inventory`、`map`、`result_success`、`result_failure`。

分辨率：`1280x720`、`1600x900`、`1920x1080`。

输出位于 `.tmp/i1/<run-id>/previews/`。`I1_PREVIEW_STATUS=PASS_WITH_VISUAL_REVIEW_REQUIRED` 只证明生产场景渲染并写出 PNG；仍需人工检查构图、遮挡、可读性、状态正确性和新增交互。动画节奏、鼠标/手柄手感不能从静态 PNG 得出。

## 6. 提交前与提交后

提交前：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile full -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'

git diff --check
git status --short
```

必须确认没有无授权的 `.translation`、`.uid`、`.godot`、import metadata、`.tmp` 或 `reports` 被暂存。

提交后验证确切快照：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile full -SourceMode head `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

`SourceMode head` 只读取当前提交；如果它与 worktree 结果不同，不能用 worktree PASS 代替。

## 7. 证据存放

```text
.tmp/i1/<run-id>/report.json          local machine-readable run evidence
.tmp/i1/<run-id>/logs/                isolated logs
.tmp/i1/<run-id>/previews/            local review images
.tmp/i1/<run-id>/preview_report.json  capture report
docs/validation/                      accepted stage validation summary
docs/art/validation/                  explicitly approved frozen art evidence only
```

`.tmp` 与 `reports` 默认不进入 Git。只有经过审查、具有长期价值且在 validation 中登记的证据才可复制到版本化 evidence 目录；不得提交整套临时 mirror 或运行时。

## 8. CI 边界

`.github/workflows/i1-quick.yml` 已配置 Windows quick 验证和 artifact 上传。除非 GitHub Actions 页面出现与提交关联的成功 run，否则状态始终是 `configured_unproven`。本地 YAML 存在、语法检查或 push 成功都不能替代远端运行证据。

## 9. 常见误判

- runner marker PASS 但存在 blocking engine diagnostic：整体失败。
- preview PNG 生成成功：不是视觉验收。
- combat p95 通过：不是通用性能或发布性能。
- 当前进程内 continue：不是退出程序后的 active-run 恢复。
- UI 显示结算：不代表 UI 拥有结算提交权。
- 历史 validation 中绝对路径或 PASS：不自动成为当前机器或当前提交事实。
- 历史 stage wrapper 因旧模块位置、旧语义或 blanket metadata rule 失败：先核对 I1 manifest/专门 gate，不回退当前架构迎合旧静态文本。
