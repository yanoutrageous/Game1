# Game1 Active Repository

这是 Game1 / GraytailGodot 当前活动工程。

```text
repository: D:\AGAME1\active\Game1_work
godot_project: D:\AGAME1\active\Game1_work\Godot\GraytailGodot
current_stage: none authorized; I0 closed with recorded safety nonconformance and limitations
branch: i0/project-baseline-refactor
```

## 当前入口

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/10_current/CURRENT_STATE.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/10_current/NEXT_ACTION.md`

详细审计与进度判断：`docs/10_current/I0_BASELINE_ASSESSMENT.md`。

## 当前验证

从仓库根执行项目本地、隔离的 I0 套件：

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/i0/invoke_i0_tests.ps1 -Profile remediated
```

Godot 自动化只允许使用 `D:\AGAME1\tools\runtimes\godot\4.6.3` 中被锁定的二进制和 I0 隔离 harness。历史工具、系统 PATH 或 `D:\Godot` 不得作为当前执行源。I0.7 证明直接可见启动仍可能写入范围外 AppData logs；在独立日志隔离门通过前，不授权新的可见 Godot 启动。

## 边界

- 只操作 `D:\AGAME1` 内的文件。
- 不把历史 validation / handoff / ART 报告改写成当前事实。
- 不把 preview、display-only 或 schema foundation 声称为完整玩法。
- 不把 headless / runner PASS 声称为未执行的人工游玩、最终视觉或发布 PASS。
- 不清理、丢弃或自动提交原有 12 项脏状态和保护性 stash。
- I0 已关闭但不是无条件 PASS；最终 validation / handoff 中的安全不符合与有限人工覆盖必须保留。
- 外部来源位于 `D:\AGAME1\sources`、`D:\AGAME1\handoff` 和 `D:\AGAME1\external`；默认只登记，不复制正文。
