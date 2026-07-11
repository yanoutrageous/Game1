# GraytailGodot

这是《灰尾回收 / 五四三二一》的当前 Godot 4 工程入口。

```text
project_path: D:\AGAME1\active\Game1_work\Godot\GraytailGodot
engine: D:\AGAME1\tools\runtimes\godot\4.6.3
stage_baseline: I0
```

仓库当前事实入口位于：

```text
../../docs/10_current/CURRENT_STATE.md
../../docs/10_current/I0_BASELINE_ASSESSMENT.md
../../docs/40_validation/VALIDATION_INDEX.md
```

## 当前工程口径

- 本目录保存运行时脚本、场景、资源、数据、项目配置和工程历史文档。
- `docs/` 子目录保留工程历史 / 环境证据，不替代仓库当前事实链。
- I0 已修复四个确认契约缺陷，并只对 `RunScene` 做了行为快照保护下的最小职责提取；其余结构债仍需后续独立 gate。
- 当前主验证从仓库根执行 `tools/i0/invoke_i0_tests.ps1 -Profile remediated`，并使用隔离 APPDATA、TEMP 和 `user://`。
- 系统 PATH、历史工具和 `D:\Godot` 不得作为当前 Godot 执行源。

## 声明与修改边界

1. parser / headless / runner PASS 只证明其覆盖的契约。
2. 未执行的人工游玩、最终视觉、性能、导出、CI 或发布不得声称 PASS。
3. `project.godot`、`.uid`、`.translation` 和 import metadata 不是可随意清理的生成物；必须先分类并通过单独 gate。
4. 原始 12 项用户 dirty 和保护性 stash 不由 I0 自动清理或提交。
5. 后续资产、场景、脚本、配置和 metadata 变更必须继承 I0 工具链、污染守卫和安全边界。
