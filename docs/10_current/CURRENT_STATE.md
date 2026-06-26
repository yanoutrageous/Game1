# Current State

文档状态：当前事实摘要
适用范围：G37S validation supplement 与 G37 最新工程证据摘要
最后更新：2026/06/26

本文件只汇总当前事实入口，不替代验证记录、历史 handoff、产品契约或外部策划来源。

## G38 Current Update

```text
当前执行阶段：G38-R2 Runtime Architecture Consolidation Finalization
阶段性质：runtime architecture boundary finalization
当前仓库分支观测：godot/g38-runtime-architecture-finalization
```

G38 finalizes RunScene responsibility boundaries after G35/G36/G37/G37S. It adds helper controllers for input routing, route handoff, command feedback, result/meta commit orchestration, and debug meta operations. `RunRuntimeController` / `RunStateMachine` remain runtime authority, and `GameKernel` is retained only as an inactive compatibility facade until a future project metadata gate.

G38 does not implement complete RunFlow, active-run persistence, Objective/Reward/Pool, complete settlement/economy, complete warehouse, complete Rule engine, gameplay runtime PASS, or manual playtest PASS.

G38 entries:

```text
docs/20_product/RUNTIME_ARCHITECTURE_FINALIZATION_CONTRACT.md
docs/validation/G38_RUNTIME_ARCHITECTURE_FINALIZATION_VALIDATION.md
docs/handoff/HANDOFF_G38_RUNTIME_ARCHITECTURE_FINALIZATION.md
tools/validate_g38_runtime_architecture_finalization.ps1
```

## 1. 当前工作阶段

```text
当前执行阶段：G37S-R2 Runtime Authority Validation / Handoff Supplement
阶段性质：validation / handoff supplement only
当前仓库分支观测：godot/g37-runtime-authority-validation-supplement
当前 HEAD 观测：main-derived supplement branch
```

G37S supplements validation and handoff evidence for the already completed G37 runtime authority work. It does not modify core runtime code, UI code, Base Docs, Connection, Godot scenes, resources, metadata, imports, or `project.godot`.

## 2. 最新工程证据阶段

```text
最新工程证据阶段：G37-R2 Runtime Authority / RunFlow Execution Consolidation
G37 contract：docs/20_product/RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_CONTRACT.md
G37 validation：docs/validation/G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_VALIDATION.md
G37S validation supplement：docs/validation/G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md
G37 handoff：docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION.md
G37S handoff supplement：docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md
```

G37 is a runtime-authority implementation. G37S records the validation supplement and hands unresolved runtime architecture work to G38+.

## 3. G37 边界摘要

- `RunRuntimeController` owns the active `RunContext` and `CommandBus`.
- `RunStateMachine` owns lifecycle transitions for start, extract, cancel, failure, and force-extract paths.
- `CommandBus` remains the command surface and delegates lifecycle transitions to the runtime controller.
- `RunScene` is orchestration-only for current runtime construction.
- `RunFlowStateContract` remains projection-only.
- `GameKernel` remains hard-disabled as a runtime driver.

未实现 / 未声明：complete RunFlow rewrite、active-run persistence、SaveManager ownership migration、new gameplay systems、gameplay runtime PASS、manual playtest PASS。

## 4. 历史阶段状态

| 阶段 | 当前状态 |
| --- | --- |
| G27A | closed / historical asset-domain warehouse-view contract foundation |
| G28A | closed / historical item asset content warehouse-view content contract |
| G29 | closed / historical DeployPrep revision preview/display-only content |
| G30 | closed / historical LongTerm asset interface preview/display-only content |
| G31 | closed / historical run map / room state preview/display-only content |
| G32 | closed / historical run flow / state transition preview/display-only content |
| G33 | closed / historical room type / tag / encounter common-rule preview content |
| G34 | closed / historical rule/effect/modifier/content-delivery preview content |
| G35 | closed / historical runtime safety / ownership cleanup |

## 5. 当前文档入口

```text
docs/README.md
docs/INDEX.md
docs/10_current/NEXT_ACTION.md
docs/10_current/CAPABILITY_MATRIX.yaml
docs/40_validation/VALIDATION_INDEX.md
docs/50_stages/active/STAGE_INDEX.md
docs/50_stages/closed/STAGE_INDEX.md
```

## 6. 外部来源边界

```text
Base Docs = 外部策划原件 / 用户留档，不参与仓库去重。
Base Docs_Governance = 外部治理快照区，不替代当前仓库事实源。
Connection = 外部并行交接区，不复制内容入库。
Godot/GraytailGodot/docs = 工程历史 / 环境证据，不作为当前文档治理入口。
```
