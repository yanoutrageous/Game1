# I2 Pre-execution Scope and Risk Audit

文档状态：I2 启动审计；`I2 ACTIVE / implementation not yet claimed`。
最后更新：2026-07-22

## 1. 审计结论

```text
Stage: I2 Player-experience Refactor and Incremental Baseline
Scope: valid_stage
Risk: high
Action: split into gated slices; audit each slice before execution
Current slice: I2.0 documentation and governance startup
Current-slice scope: valid_slice
Current-slice action: document only; no runtime, asset, project-setting, validation or handoff claim
```

I2 是用户明确授权的跨程序、美术、产品和治理集成阶段。目标不是再次证明项目拥有最小玩法闭环，而是把 I1 的快速反馈与权威边界用于一次面向玩家体验的完整重构。I2 作为单一阶段执行和最终综合验收，内部必须按小切片实施；任何切片通过都不能提前宣称 I2 完成。

“由核心开发转为增量开发与修改并行”的判断在 I1 关闭事实下成立，但有条件：仓库已有可运行闭环和统一 runner，仍有跨进程恢复、完整经济、最终视觉/音频、真实长局性能、设备输入、导出和发布缺口。因此当前不是维护期，也不是功能冻结期。

## 2. 审计锚点

| 项目 | 当前事实 |
| --- | --- |
| 活动仓库 | 由 `git rev-parse --show-toplevel` 解析；本次观察为 `E:\AGAME1\.tmp\worktrees\i2` |
| 活动分支 | `codex/i2-player-experience-refactor` |
| I2 起点 HEAD | `b77132b9de655b36f71c930a35a191c383b55522` |
| I2 起点 tree | `1d26f1415851755f1a8cc57f4804dfb12d9cea4d` |
| 实现目标 | `<active_repo>/Godot/GraytailGodot`，Godot 4.6 feature target |
| UE 参考 | `E:\UE\Game\UE\Graytail`；只读概念/交互/视觉参考，不是实现或架构权威 |
| 最新闭合非美术基线 | I1 / `CLOSED / PASS_WITH_NOTES` |
| 最新闭合项目级美术阶段 | ART21；ART23 仅为较晚页面/UI 证据 |
| I2 起点自动化 | exact HEAD `b77132b`，`full/head` 39/39 PASS |
| I2 运行实现 | 尚未开始、尚未声明 |

I2 起点报告为本地未版本化证据：

```text
E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T193513816Z_48329748\report.json
SHA-256: 2072F1DBD067C607E82220F06DEFE15F410ED68807BFAA4EF36B5202007167E8
profile/source_mode: full/head
runners: 39/39 PASS
plain PASS: 17
PASS_WITH_CLEANUP_DIAGNOSTIC: 22
blocking diagnostics: 0
duration: 254980 ms
```

报告及其临时 mirror 保持在 `.tmp`，不进入仓库。该结果证明 I2 起点提交通过既有 I1 full 门，不证明 I2 的视觉、交互、真实工作负载性能或实现完成。

最新生产预览基线同样只作规划证据：`E:\AGAME1\.tmp\i1\20260721T181135224Z_4a0a6ca0\preview_report.json`，SHA-256 `575113D718A4E1D399FA0EB4EA6C1BE0C0E38B881348C134450E6FF43E77F9FF`，27/27 PNG，机器状态 `PASS_WITH_VISUAL_REVIEW_REQUIRED`、`visual_acceptance=NOT_RUN`。它可用于前后对照，不是视觉验收 PASS。

## 3. 范围

### 纳入 I2

- 主菜单的文字与场景关系、角色与环境动效、空间化转场和真实设置。
- 出发探索中心信息架构、地图同页选择、仓库/申领/委托/出勤配置和右侧摘要。
- 长期系统的共享导航、信息密度、模块布局、任务档案/天赋树职责和角色档案。
- 局内 HUD、地图、背包、箱子、地面物品、协议、模态、结算、战斗房与特殊房反馈。
- 保持 I1 权威/保存/结算不变量的程序解耦、状态转换和真实工作负载性能测量。
- 来源/许可/import gate、快速生产预览、自动化、人工操作说明与综合验收。

### 当前 I2.0 仅纳入

- 启动审计、产品契约、起点评估、反馈追踪矩阵、目标架构、验证计划和切片门账。
- 更新当前阶段入口，使 I2 明确为 `ACTIVE / implementation not yet claimed`。

### 当前 I2.0 不纳入

- Godot 脚本、场景、资源、`.uid`、`.translation`、import metadata 或 `project.godot` 修改。
- UE 工程修改、UE 代码移植、UE 素材复制或外部消息/交付。
- 新素材生成、资产导入、提交、推送、合并、validation 或 handoff。
- 任何“已改善 UI/动画/性能/交互”的运行时声明。

## 4. 不可绕过的边界

1. 当前代码和运行证据优先于文档与用户偏好；用户意见进入追踪矩阵，不自动变为已确认实现方案。
2. Godot 是唯一实现目标。UE 只可提供语义、交互和视觉概念；不得复制其架构、烤字固定布局、Debug 玩法权威或未知许可素材。
3. 出发探索的地图选择永远留在同一 Deploy 页签：左侧地图名称和比例/规模，右侧难度与详情；不得改成“区域 → 难度”的分步页面。
4. `RunAssetLedger`、`RunStateMachine`、`RunRuntimeController`/meta adapter、`SaveAdapter`、结算幂等和失败保全确认边界继承 I1。
5. UI 只呈现和发出意图，不拥有结算、库存、任务、地图 truth 或保存权威。
6. 每个高风险切片必须先登记 allowed paths、protected paths、回归集、可见验收、停止条件和回退点。

## 5. 主要风险与前置处理

| 风险 | 级别 | 前置处理/停止条件 |
| --- | --- | --- |
| 大范围 UI 重排同时改变领域规则 | high | 布局切片与规则切片分开；先 characterization，领域规则变化另设产品门 |
| 主菜单空间转场破坏路由、焦点或 reduced motion | high | 转场协调器只在路由提交前后工作；失败可回退；静态替代路径必须存在 |
| “骨骼帧生成”被误解为运行时魔法能力 | high | 只评估离线 rig-assisted/baked pixel workflow；先做可替换角色 proof，不承诺运行时生成 |
| 仓库快捷售卖改变经济与不可逆资产 | high | UI 架构可先做；批量选择、价格、确认、撤销/失败语义必须单独产品与持久化门 |
| 将长期“目标”直接改名为天赋树导致真实任务/成就丢位 | high | 先定义任务档案迁移与天赋权威；不可只改标签或隐藏现有数据 |
| 战斗房优化只看 refresh 微基准 | high | 以真实 1/3/5 敌人、峰值效果和长时帧数据分解模拟/快照/表现；无测量不得声称 FPS 改善 |
| 资源复用扩大未登记或未知许可绑定 | high | 先查 manifest/hash/license/runtime key；未审计素材隔离；确认不足后才走批准的生成/替换门 |
| 自动预览被当成人工交互验收 | high | capture、人工动态、输入/焦点、性能、保存失败各自留证，不互相替代 |
| 历史/外部 dirty 被吸收到 I2 | high | 精确路径保护；若状态变化或无法解释，立即停止切片并回到审计 |

## 6. 受保护 dirty 与资产门

本次隔离 I2 worktree 启动时干净。另一个主工作树 `E:\AGAME1` 已观察到以下用户/编辑器状态，不属于 I2.0，不得清理、覆盖、复制或暂存：

```text
Godot/GraytailGodot/project.godot
Godot/GraytailGodot/data/assets/asset_manifest.category.translation
Godot/GraytailGodot/data/assets/asset_manifest.import.translation
Godot/GraytailGodot/data/assets/asset_manifest.license.translation
Godot/GraytailGodot/data/assets/asset_manifest.linked.translation
Godot/GraytailGodot/data/assets/asset_manifest.note.translation
Godot/GraytailGodot/data/assets/asset_manifest.replacement.translation
Godot/GraytailGodot/data/assets/asset_manifest.usage.translation
```

其中 `project.godot` 的变化包含语义项，不能假设为无害生成物。任何未来切片触及上述类型，必须在隔离 worktree 中重新解析精确 preimage、说明业务必要性，并通过 project metadata/asset import 专门 gate；没有 gate 时禁止暂存。

## 7. 启动判定

I2 可以进入受控实施准备，但只有 I2.0 文档/治理切片已获执行授权。后续任一程序、美术、资源、场景或项目配置切片在 `I2_SLICE_GATE_LEDGER.md` 中从 `NOT_STARTED` 变为可执行前，必须完成自己的范围与风险复核。当前结论不得写成 I2 validation、handoff、capability promotion 或运行时 PASS。
