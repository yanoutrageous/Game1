# Audit Scope

文档状态：I2 当前审计范围；阶段 active，运行时实现尚未声明。
最后更新：2026-07-22

## 已纳入

- 由 `git rev-parse --show-toplevel` 解析的 I2 活动 worktree、Godot 工程、分支/HEAD/origin/index/stash/worktree/dirty/staged/untracked。
- I2 起点 `b77132b9de655b36f71c930a35a191c383b55522` 的 exact full/head 39/39 报告及其污染/diagnostic 边界。
- I1 关闭契约、权威/保存/结算不变量、runner 和生产预览作为 I2 继承基线。
- 主菜单、Deploy、长期、局内 12 项、特殊房 4 项和补充跨域判断的逐项 U/R/UE/D/A 追踪。
- 程序耦合、模块职责、状态转换、UI/动效/交互、真实工作负载性能、资源/许可/import 和文档治理计划。
- production `main.tscn` 的当前 9 状态 × 3 分辨率预览基线；其机器状态仍要求视觉复核。
- `E:\UE\Game\UE\Graytail` 的只读语义/交互/视觉参考边界；不把 UE 设为实现或性能权威。
- I2 每切片的 allowed/protected paths、产品决策、characterization、回退、自动/可见/人工/输入/性能/失败/来源证据门。

## I2.0 当前写入范围

I2.0 只写启动审计、契约、评估、追踪矩阵、架构计划、验证计划、切片门账和必要当前入口。Godot 脚本、场景、资源、项目设置、tools、validation、handoff 和历史关闭记录不在当前写入范围。

I2.0 的有效结论仅为：

```text
I2 = ACTIVE
implementation = not yet claimed
runtime capability delta = none claimed
next execution = gated per slice
```

## 证据优先级

1. 当前可复现代码、数据、运行和 exact fingerprint；
2. 当前自动化、生产截图、动态人工、输入、性能、失败与资产审计各自证据；
3. 当前产品/架构契约；
4. UE/历史文档/历史截图等有边界的参考；
5. 对话观察和偏好。

用户观察必须保留并验证，但不能覆盖仓库事实。UE 参考不能覆盖 Godot 产品约束；尤其禁止把 Deploy 地图改为 region→difficulty 分步页面。

## protected dirty / asset 范围

隔离 I2 worktree 启动时干净。另一个主工作树 `E:\AGAME1` 已观察到 `Godot/GraytailGodot/project.godot` 和七个 `data/assets/asset_manifest.*.translation` 文件的受保护状态；它们不属于 I2.0。不得清理、覆盖、复制或暂存。

Godot scene/resource/`.uid`/`.translation`/import metadata/`project.godot` 只有在对应实现切片给出精确路径和专门 gate 后才可变更。UE `.uasset`、烤字固定布局、过程帧和未知许可素材不在可导入范围。

## 当前明确未声称完成

- MAIN-01..05、DEP-01..10、LONG-01..04、RUN-01..12、ROOM-01..04 的任何运行时改善。
- 真实设置、角色骨骼/烘焙动画、时装替换、仓库批售、任务 taxonomy、天赋树或长期模块迁移。
- 战斗房整帧性能、通用性能、设备/输入矩阵、人工长局、最终视觉或音频。
- 跨进程 active-run 恢复、完整经济/内容、导出、发布或 release gate。
- I2 validation/handoff、能力提升、提交、推送或合并。

## 当前证据口径

- I1 是最新闭合非美术基线，ART21 是项目级最新闭合美术阶段；ART23 仍只是较晚页面/UI 证据。
- I2 起点 full/head 报告为 39/39 PASS，SHA-256 `2072F1DBD067C607E82220F06DEFE15F410ED68807BFAA4EF36B5202007167E8`；它证明 entry regression，不证明 I2。
- 最新 27/27 production capture 为 `PASS_WITH_VISUAL_REVIEW_REQUIRED / visual_acceptance=NOT_RUN`；静态图不能证明动态、输入或手感。
- combat refresh 历史指标仅是微基准，不能当作 FPS 或真实战斗房性能。
- I2 切片通过也不关闭 I2；最终必须逐条处置追踪矩阵并运行 full/worktree、提交后 exact full/head 及综合证据审计。
