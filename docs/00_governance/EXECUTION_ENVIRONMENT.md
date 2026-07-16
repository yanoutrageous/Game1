# Current Execution Environment

文档状态：I0 + ART21 整合后的当前执行环境契约
最后更新：2026-07-16

## 路径解析

```text
repo_root: git rev-parse --show-toplevel
godot_project: <repo_root>/Godot/GraytailGodot
workspace_root: common ancestor of repo_root and git rev-parse --git-common-dir
godot_runtime: <workspace_root>/tools/runtimes/godot/4.6.3
i0_temp: <workspace_root>/tools/runtimes/.tmp/i0
i0_reports: <workspace_root>/reports/i0
```

当前机器观测到的工作区根为 `D:\AGAME2`，但该盘符不是版本化权威。
`D:\AGAME1` 仅可出现在历史 I0 / G40 证据中。

## 文件系统边界

- 当前执行的写入目标必须位于已解析的 `workspace_root`。
- repo、Git common directory、运行时临时目录和报告目录必须经过规范化与
  reparse-point 检查。
- 不修改、移动或删除其他 worktree 的用户 dirty 状态。
- 递归删除、移动和清理不属于本整合基线的默认权限。

## Godot 边界

- 固定版本：`4.6.3.stable.official.7d41c59c4`。
- 主程序 SHA-256：
  `ef90e929ba1a6a4322860285d97f40f4aa349c90329a91b0e8b55b8df0f4cb00`。
- Console SHA-256：
  `63b3b2208819714c9677fbfdd8217c5b7dee8ecf5f383502e826bc9e2227ff5a`。
- 工具链由 `tools/i0/bootstrap_toolchain.ps1` 在工作区内建立并复验。
- 测试使用无 `_sc_` 的运行时硬链接、隔离 APPDATA / LOCALAPPDATA /
  TEMP / `user://` 和隔离项目镜像。
- 当前整合只授权 headless 自动化，不授权新的直接可见 Godot 启动。
- I0 历史可见启动产生范围外 AppData logs 的安全不符合记录永久保留。

## Git 边界

- 允许只读审计、任务相关提交和用户明确授权的 push。
- 禁止 `reset --hard`、`clean`、stash apply/pop/drop/clear、历史重写和
  force push。
- linked worktree 是受支持拓扑；文档编码门同时验证 worktree Git dir
  与 common dir 均位于工作区。
