# Handoff: I0 + ART21 Baseline Integration

状态：整合基线已验证，后续阶段未授权
日期：2026-07-16

## 中文摘要

接手时应把 I0 视为最新非美术工程基线，把 ART21 视为最新美术基线。
当前主菜单场景与 I0 的保存、输入、CSV、调试和自动化契约已共存。
不要退回 G40、M5、ART21R2 或 ART21R1 作为最新整体基线。

## 分支与来源

```text
integration_branch: integration/i0-art21-baseline
I0_source: 77569579a6c66d9f4350f0ba419906a7814dd502
ART21_source: 93420a8f3799c540ac8a2b46d3c264d5f3ee10f1
common_base: 3dbb843e34f16a9a10b7122a0e094c457a7057c6
```

## 接手检查

```powershell
git status --short --branch
git rev-parse HEAD
git rev-parse --path-format=absolute --git-common-dir

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\invoke_i0_tests.ps1 `
  -Profile remediated `
  -SourceMode head

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\validate_art21_main_menu_scene.ps1
```

## 必须保留

- repository-relative 当前路径权威。
- I0 工具链哈希、12 runner、污染守卫与编码例外台账。
- ART21 主菜单 152 资产契约、四入口、路由与 motion contract。
- I0 的 24 条 cleanup 类提示与历史安全不符合记录。
- 无后续 active stage 的状态。

## 禁止误读

- 不把 `D:\AGAME1` 当成当前机器配置。
- 不把 ART21 关闭解释为 ART22 已启动。
- 不把 headless PASS 解释为完整人工游玩或最终发布 PASS。
- 不清理其他 worktree 的 dirty 状态或保护性 stash。
- 不在未通过独立日志隔离门前直接启动可见 Godot。
