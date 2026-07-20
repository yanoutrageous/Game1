# Current Execution Environment

文档状态：I1 关闭后继续适用的当前执行环境契约。
最后更新：2026-07-21

## 路径解析

```text
repo_root: git rev-parse --show-toplevel
godot_project: <repo_root>/Godot/GraytailGodot
git_common_dir: git rev-parse --path-format=absolute --git-common-dir
i1_run_root: <derived-workspace-root>/.tmp/i1/<UTC-run-id>
i1_report: <i1_run_root>/report.json
i1_preview: <i1_run_root>/previews
```

当前机器观测到的 repo 是 `E:\AGAME1`，但仓库脚本和文档必须动态解析，不能用盘符匹配选择 active repo。

## 本机 Godot 观测

```text
install_root: E:\Godot\Tools\Godot
main: Godot_v4.6.3-stable_win64.exe
main_bytes: 172409864
main_sha256: EF90E929BA1A6A4322860285D97F40F4AA349C90329A91B0E8B55B8DF0F4CB00
console: Godot_v4.6.3-stable_win64_console.exe
console_bytes: 198152
console_sha256: 63B3B2208819714C9677FBFDD8217C5B7DEE8ECF5F383502E826BC9E2227FF5A
version: 4.6.3.stable.official.7d41c59c4
```

`E:\Godot` 只代表本机 2026-07-20 的权威观测/示例。跨机器解析顺序：

1. `-GodotExe`
2. `I1_GODOT_EXE`、`GODOT4`、`GODOT_EXE`
3. I1 manifest 允许的 PATH command name

解析后必须核对 companion executable、版本、大小和 SHA-256。历史工作区 runtime 或历史 `D:\Godot` 不自动成为当前执行源。

## 隔离与文件系统边界

- I1 harness 在 `.tmp/i1/<run-id>/worktree` 建立隔离 source mirror。
- APPDATA、LOCALAPPDATA、TEMP、HOME、日志和 `user://` 指向 run sandbox。
- `.tmp`、`reports` 和 `tools/runtimes` 不进入 source mirror。
- 执行前后比较完整 Git 状态与声明的 business roots；污染使 run 失败。
- 不直接在活动工程运行 editor/import 来获得自动化结论，以避免 `.translation`、`.uid` 或 import metadata 污染。
- 不移动、删除或恢复无法解释的用户 dirty；递归清理必须另行审计。

## Godot 与验证边界

- `preflight` 先验证 manifest、mirror、lock、import、`res://` / `user://` 隔离。
- runner 必须 exit success、恰有一个 full-line PASS marker、没有 FAIL marker、没有 timeout 和 blocking engine diagnostic。
- 已知 shutdown cleanup diagnostic 单独分类，不伪装成无警告。
- capture、人工可见验收和通用性能明确不由 headless PASS 替代。

## Git / CI 边界

- 允许只读审计、任务相关精确暂存/提交和用户明确授权的普通 push。
- 禁止 `reset --hard`、`clean`、stash apply/pop/drop/clear、历史重写和 force push。
- 提交前验证 worktree，提交后以 `SourceMode head` 验证确切提交。
- `.github/workflows/i1-quick.yml` 只有与提交关联的成功远端 run 才能证明 quick；I1 关闭证据为 run `29760789712` success。该结果不证明 full、导出或 release。

## 历史安全记录

I0 可见启动写入范围外 AppData logs 的安全不符合记录继续保留在 I0 validation/handoff。I1 的隔离设计不抹除该历史，也不能在没有新证据时宣称所有可见启动均已完全隔离。
