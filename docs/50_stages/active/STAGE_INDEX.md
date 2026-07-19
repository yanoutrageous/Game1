# Active Stage Index

文档状态：G41 关闭后无 active stage；最后更新 2026-07-19。

## 当前已授权阶段

无。G41 已通过正式执行审计并移入 closed index；不得在没有新计划的情况下自动扩大到后继功能或美术整合。

## 当前基线

| Item | Current fact |
| --- | --- |
| Active repo | 使用 `git rev-parse --show-toplevel` 解析，不以盘符或旧机器路径作为权威 |
| Latest closed program stage | G41 局内基础玩法运行时与交互接口补全 |
| G41 source baseline | ART23 `7f2e0b304e2cd7959411bfe6422d3d0b3337462f`；ART24 由用户明确排除 |
| G41 branch | `godot/g41-in-run-core-gameplay-runtime` |
| Godot project | `<git-worktree-root>/Godot/GraytailGodot` |
| Current-machine Godot | 用户指定的 `E:\Godot\Tools\Godot`，验证版本 4.6.3 |
| Latest accepted art baseline | ART23 long-term final UI |

## 当前解释边界

- G41 关闭仅声明程序侧局内移动、交互、宝箱、实际掉落、拾取/替换、固定步长战斗、逃跑、奖励、失败与生命周期接口完成。
- 不声明最终美术、完整人工长时间游玩、发布、CI、性能或跨进程局内保存通过。
- 后继阶段先与用户确认计划；计划确认后的后续门可自动执行。
