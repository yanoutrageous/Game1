# I2 Slice Gate Ledger

文档状态：I2 当前门账；阶段 `ACTIVE`，所有运行时切片均未开始。
最后更新：2026-07-22

## 1. 状态定义

| 状态 | 含义 |
| --- | --- |
| `NOT_STARTED` | 未获切片执行授权；不得改运行时/资产 |
| `AUDIT_REQUIRED` | 候选范围已知，但缺 scope/risk/paths/evidence 门 |
| `READY` | 切片审计通过，allowed/protected paths 与验证已冻结 |
| `IN_PROGRESS` | 正在 allowed scope 内实施 |
| `READY_FOR_REVIEW` | 变更与约定证据已产生，尚未被切片审计接受 |
| `ACCEPTED_WITH_NOTES` | 切片证据接受但有登记债务；不等于 I2 关闭 |
| `BLOCKED` | 有 blocking regression、未知 dirty、缺决策或缺证据 |

只有一份最终 I2 综合 validation/handoff；切片状态用于执行控制，不构成独立阶段关闭。

## 2. 当前总览

```text
I2 stage: ACTIVE
I2 runtime implementation: NOT_STARTED / NOT_CLAIMED
I2 capability promotion: NONE
I2 final validation/handoff: NOT_CREATED
entry HEAD: b77132b9de655b36f71c930a35a191c383b55522
entry full/head: 39/39 PASS
```

| Slice | 范围 | 依赖 | 当前状态 | 当前证据/下一门 |
| --- | --- | --- | --- | --- |
| I2.0 | 启动审计、契约、评估、矩阵、架构、验证计划、门账、入口 | I1 closed + exact entry baseline | `ACCEPTED_WITH_NOTES` | 独立复核修正 I1/I2 报告字段后，16/16 allowed paths、43/43 IDs、refs/UTF-8/YAML basic/diff/static 与 quick 21/21 PASS；无 runtime claim |
| I2.1 | 共享导航/转场、设置、focus/modal、character presentation、style/layer seam | I2.0；设置字段与动画技术决策 | `AUDIT_REQUIRED` | 冻结 characterization、allowed paths、feature gates、reduced motion 与 persistence |
| I2.2 | 主菜单文字/场景/锚点/动效/空间转场 | I2.1 最小 seam | `NOT_STARTED` | 需四入口动态标准、素材复用清单、回退到现有 fade |
| I2.3 | Deploy 双栏、地图同页、仓库/申领/委托/摘要 | I2.1；经济/taxonomy/loadout 决策 | `NOT_STARTED` | 需八地图 ID no-regression、真实命令与批量售卖门 |
| I2.4 | 长期模块重排、任务档案迁移、天赋、角色档案 | I2.1；taxonomy 与天赋数据权威 | `NOT_STARTED` | 先证明任务/成就/红点/领取不丢失，再改 Goal 入口 |
| I2.5 | 局内 HUD、地图、背包、箱/门/掉落、协议、Esc/modal | I2.1；对象/ledger/map characterization | `NOT_STARTED` | 需 RUN-01..12 中相关条目、input/focus/proximity gate |
| I2.6 | 战斗/特殊房、结算解释、真实工作负载性能 | I2.5 基础；性能 baseline/阈值 | `NOT_STARTED` | 需 deterministic、结算幂等、1/3/5 敌人 PERF 与失败路径 |
| I2.7 | 跨页面整合、操作说明、全量回归、综合验收 | I2.1–I2.6 accepted/deferred with owner | `NOT_STARTED` | full/worktree→commit→full/head；matrix 逐项；创建唯一 validation/handoff |

## 3. 全局进入门

任一 I2.1–I2.6 切片从 `AUDIT_REQUIRED/NOT_STARTED` 进入 `READY` 前必须登记：

```text
Goal and non-goals
User-feedback IDs
Current code/runtime characterization
Product decisions and unresolved decisions
Allowed paths
Protected/forbidden paths
Expected authority/state changes
Asset/source/import status
Baseline commands and fingerprints
Targeted + regression validation
Dynamic/input/accessibility/failure review
Performance workload if claimed
Rollback point
Stop conditions
```

没有精确 allowed paths 的 scene/resource/project/metadata/asset 切片保持 `BLOCKED`。不能用“同一 I2 阶段”扩大当前切片权限。

## 4. 不可变全局门

### 4.1 权威门

- Godot 是实现目标；UE 只读参考。
- `RunStateMachine`、`RunAssetLedger`、terminal settlement、保存安全和幂等边界不得回归。
- UI/动画/计时器不拥有领域提交。
- Deploy 地图始终为同一页 split view，不增加 region→difficulty page flow。

### 4.2 反馈门

切片必须列出其处理的 `MAIN-*`、`DEP-*`、`LONG-*`、`RUN-*`、`ROOM-*`、`CROSS-*`。用户观察需要运行证据确认；不采纳的方案必须给仓库证据和替代方案，不得静默删除。

### 4.3 资产门

```text
reuse registered Godot asset
  -> use audited-but-unwired Godot asset
  -> audit/import selected external asset
  -> generate only after confirmed gap and approval
```

每个新增/改绑资源必须有 source、license、SHA-256、usage、target、runtime key、replacement 状态和确定性结论。禁止直接迁入 `.uasset`、UE 烤字布局、过程帧或未知许可素材。

### 4.4 证据门

- 自动化、CAP、DYN、INPUT、PERF、FAIL、ASSET、TEXT 分开记录。
- `PASS_WITH_VISUAL_REVIEW_REQUIRED` 不是视觉 PASS。
- combat refresh 微基准不是 FPS/通用性能。
- worktree PASS 不是 exact HEAD PASS。
- 未运行必须写 `NOT_RUN`。

## 5. 受保护 dirty / metadata 门

I2 隔离 worktree 启动时干净。主工作树 `E:\AGAME1` 的以下状态属于外部受保护内容：

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

规则：

1. 不清理、restore、复制、重放、stash pop 或暂存这些状态。
2. 任何 I2 切片需要同类型文件时，只在隔离 worktree 以起点 preimage 新建精确 diff。
3. `project.godot` 必须说明每个语义键；不能把 stretch/aspect 等变化归类为无害 metadata。
4. scene/resource/`.uid`/`.translation`/import metadata 需要专门 gate 与精确暂存清单。
5. 检测到 unexplained dirty、staged 或 external write，立即停止并回到风险审计。

## 6. 切片专门停止条件

| Slice | Blocking stop condition |
| --- | --- |
| I2.1 | 转场双提交/失焦；设置伪生效或保存失败冒充成功；角色 fallback 阻断玩法 |
| I2.2 | 路由依赖动画计时提交；锚点在目标分辨率漂移；reduced-motion 无可理解反馈 |
| I2.3 | 地图离开同一 Deploy 页；地图 ID/schema 漂移；UI 直接改金币/库存；批售无幂等/确认 |
| I2.4 | Goal 改名先于任务迁移；任务/成就/红点/领取丢失；天赋只有展示无真实权威却被声明完成 |
| I2.5 | proximity 自动拾取；UI 泄露地图 truth；箱/门视觉与状态不一致；模态输入穿透 |
| I2.6 | 触边自动逃跑仍存在；结算重复提交；性能数据非同条件或只测 refresh；失败路径未覆盖 |
| I2.7 | 任一矩阵项静默遗漏；未知 dirty；full/head、人工或来源门缺失；声明超过证据 |

## 7. I2.0 文档切片 allowed paths

本次 I2.0 只允许：

```text
AUDIT_ENTRYPOINT.md
docs/README.md
docs/INDEX.md
docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md
docs/00_governance/I2_PRE_EXECUTION_SCOPE_RISK_AUDIT.md
docs/00_governance/I2_SLICE_GATE_LEDGER.md
docs/10_current/AUDIT_SCOPE.md
docs/10_current/CAPABILITY_MATRIX.yaml  # 仅阶段/起点 metadata；不得提升 runtime capability
docs/10_current/CURRENT_STATE.md
docs/10_current/I2_PRE_EXECUTION_BASELINE_ASSESSMENT.md
docs/10_current/NEXT_ACTION.md
docs/20_product/I2_REFACTOR_DIRECTION_AND_INCREMENTAL_BASELINE_CONTRACT.md
docs/20_product/I2_PLAYER_FEEDBACK_TRACEABILITY_MATRIX.md
docs/30_engineering/architecture/I2_TARGET_ARCHITECTURE_AND_MIGRATION_PLAN.md
docs/30_engineering/godot/I2_VALIDATION_PREVIEW_AND_MANUAL_REVIEW_PLAN.md
docs/50_stages/active/STAGE_INDEX.md
```

I2.0 明确禁止修改 Godot、tools、assets、validation、handoff、closed stage index、历史审计和外部 source pack。

## 8. 门账更新规则

- 执行角色在切片开始、产生证据、遇到阻塞和完成 review 时更新状态与证据路径。
- `READY_FOR_REVIEW` 不能自行升级为 accepted；需要独立 scope/claim review。
- 切片接受后仍保持 I2 `ACTIVE`，直到 I2.7 综合关闭。
- I2.0 自检完成后只可记为“docs ready for review / no runtime delta”，不得创建 validation/handoff 或修改 runtime capability。

## 9. I2.0 自检记录

```text
changed paths: 16 / 16 in I2.0 allowlist
feedback IDs: 43 / 43, no missing/extra/duplicate
repository document references: 35 unique, all resolved
strict UTF-8: PASS
CAPABILITY_MATRIX YAML basic structure/required keys: PASS
git diff --check: PASS
I1 validate_static.ps1 / worktree: PASS
I1 quick/worktree: PASS 21/21; 9 PASS + 12 PASS_WITH_CLEANUP_DIAGNOSTIC
quick report: E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T200136741Z_9257b2a5\report.json
quick report SHA-256: DE0BBEA26E0A41A0F9DAFEC3E1EBC85C2059664EFC7CF61C36CBFA2162D21666
quick duration: 170878 ms
core/ui/full worktree after docs: NOT_RUN (docs-only slice; no runtime claim; entry full/head remains separately recorded)
```

Python 环境未安装 PyYAML，因此 YAML 自检使用严格的当前文件子集结构、缩进、重复键与 required-key 检查；这是已登记的工具限制，不等于完整 schema validator。独立 claim review 同时把能力矩阵中的 I1 关闭报告与 I2 entry 报告拆成独立字段，避免把不同运行的哈希和微基准混为一组。I2 entry exact full/head 39/39 仍为运行时进入基线，不被本次 docs 自检改写。
