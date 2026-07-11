# Current Execution Environment

文档状态：I0 当前执行环境契约
最后更新：2026-07-11

`docs/project_governance/EXECUTION_ENVIRONMENT.md` 是 G20 历史证据；当前执行边界以本文件为准。

## 路径

```text
workspace_root: D:\AGAME1
active_repo: D:\AGAME1\active\Game1_work
godot_project: D:\AGAME1\active\Game1_work\Godot\GraytailGodot
godot_runtime: D:\AGAME1\tools\runtimes\godot\4.6.3
i0_temp: D:\AGAME1\tools\runtimes\.tmp\i0
i0_reports: D:\AGAME1\reports\i0
i0_freeze: D:\AGAME1\_i0_freeze
```

## 文件系统边界

- 允许读取和写入的最高根是 `D:\AGAME1`。
- 不修改、删除、移动或清理 `D:\AGAME1` 外任何文件。
- 写入前必须规范化绝对路径并拒绝逃逸、重解析点和旧活动仓库路径。
- 历史报告、freeze、refs、stash 和用户原始脏状态不得作为清理目标。
- 递归移动或删除需要独立审计；I0.5 只使用同卷原子 `Directory.Move`，未使用 copy-delete fallback。

## Godot 执行边界

- 当前唯一获准执行源是工具链锁确认的项目本地 Godot 4.6.3。
- Godot 必须通过 I0 harness 使用隔离 APPDATA、LOCALAPPDATA、TEMP 和 `user://`。
- I0.7 证明仅使用项目内二进制 / self-contained editor data 仍不足以隔离游戏日志；直接可见启动曾写入范围外 AppData logs，属于记录的安全不符合项。
- 在独立启动门实证编辑器与游戏日志均留在 `D:\AGAME1` 前，只授权 I0 headless harness，不授权新的直接可见 Godot 启动。
- 系统 PATH、历史工具或 `D:\Godot` 不得作为当前执行源。
- 历史 G37 与 I0.7 可见启动事件均记录在 I0 validation；不得用删除外部日志来掩盖事件。

## Git 边界

- 允许：只读检查、精确暂存 I0 文件、本地提交。
- 禁止：`reset --hard`、`clean`、stash apply/pop/drop/clear、历史重写、force push、未经授权的 push / merge / branch deletion。
- 保护性 stash `a608462968d7913a5bf63c376c186fe1df89d2db` 必须保持不变。
- 原始 12 项 status 必须在每个高风险门前后精确核对；I0 新增变更单独分类。

## 当前验证入口

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/i0/invoke_i0_tests.ps1 -Profile remediated
```
