# I0 本地工具链与隔离测试

本目录保存 I0 基线的锁定工具链与 headless 特征测试。当前版本不绑定
固定盘符；默认工作区是 Git worktree 与 Git common directory 的共同祖先。

## Godot 4.6.3

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\bootstrap_toolchain.ps1
```

默认落位：

```text
<workspace_root>/tools/runtimes/godot/4.6.3
<workspace_root>/reports/i0/I0.1_TOOLCHAIN_CURRENT.json
```

锁定身份：

- `4.6.3.stable.official.7d41c59c4`
- 主程序 SHA-256：
  `ef90e929ba1a6a4322860285d97f40f4aa349c90329a91b0e8b55b8df0f4cb00`
- Console SHA-256：
  `63b3b2208819714c9677fbfdd8217c5b7dee8ecf5f383502e826bc9e2227ff5a`

脚本不修改系统 PATH、注册表或证书库。下载、安装、进程环境和报告都
限制在选定工作区。

## I0.2 隔离测试

当前工作树：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\invoke_i0_tests.ps1 `
  -Profile remediated `
  -SourceMode worktree
```

已提交 HEAD：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\invoke_i0_tests.ps1 `
  -Profile remediated `
  -SourceMode head
```

如自动推导不适合当前拓扑，可显式传入：

```powershell
-RepoRoot <git-worktree-root> -WorkspaceRoot <workspace-root>
```

每次运行都会在
`<workspace_root>/tools/runtimes/.tmp/i0/<run-id>` 建立独立镜像、
引擎硬链接、进程环境、日志和导入缓存，并把报告写入
`<workspace_root>/reports/i0`。

当前整合基线验证：

- 12 个 runner。
- 17 列、388 行资产 manifest（ART22 新增 57 个受审计的出发探索运行时资产）。
- 文档严格 UTF-8 门与 5 个精确历史例外。
- 保存、InputMap、DebugGate、RunScene / ART21R2 smoke 契约。
- Git、index、refs、stash 和业务文件污染守卫。

Godot 退出时的 ObjectDB / resource 清理提示继续按精确白名单记为
`PASS_WITH_CLEANUP_DIAGNOSTIC`；其他 WARNING / ERROR / SCRIPT ERROR /
FATAL / CRASH 仍阻断。
