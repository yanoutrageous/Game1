# Next Action

文档状态：G41 关闭后的下一步边界；最后更新 2026-07-19。

## 当前状态

G41“局内基础玩法运行时与交互接口补全”已完成正式执行审计、问题修正和回归，关闭证据为：

- `docs/20_product/G41_IN_RUN_CORE_GAMEPLAY_RUNTIME_CONTRACT.md`
- `docs/validation/G41_IN_RUN_CORE_GAMEPLAY_RUNTIME_VALIDATION.md`
- `docs/handoff/HANDOFF_G41_IN_RUN_CORE_GAMEPLAY_RUNTIME.md`
- `Godot/GraytailGodot/tools/validate_g41_in_run_core_gameplay_runtime.ps1`

当前没有自动授权的后继阶段。下一阶段仍需先与用户确认计划；计划确认后，审计、执行、修正、提交与上传可按用户最新授权直接完成，无需逐门等待批准。

## 后继计划必须继承

- 基线以 ART23 `7f2e0b304e2cd7959411bfe6422d3d0b3337462f` 加 G41 最终提交为准，不回退到 main 推断状态。
- 用户已明确排除 ART24：不得把 `art/art24-in-run-final-ui` 作为程序基线或未经重新规划直接接入。
- `RunAssetLedger` 继续作为物品位置唯一权威；活跃战斗只由 `G41CombatSimulation` 写入；持久局内结果继续经 CommandBus → Rule/Effect 提交。
- 美术接入只替换 `VisualRoot` 下视觉内容并使用稳定状态、锚点和 `visual_key`；不得用纹理尺寸决定碰撞。
- 映射/manifest 整合必须指定单一提交所有者，不覆盖并行美术内容。

## G41 未声明完成

- 最终美术、动画、特效、音频与跨分支美术整合。
- Boss、精英、技能、完整被动、完整事件、最终数值平衡与跨进程局内保存。
- 完整人工长时间游玩、性能认证、CI、导出和发布。
- G8.1/G8.2 对既有 `save_adapter.gd` 和 CommandBus 历史直写路径的基线限制。
