# Current State

文档状态：当前事实摘要
适用范围：DOC-GOV-001 文档治理阶段与 G36 最新工程证据摘要
最后更新：2026/06/26

本文件只汇总当前事实入口，不替代验证记录、历史 handoff、产品契约或外部策划来源。

## 1. 当前工作阶段

```text
当前执行阶段：DOC-GOV-001 仓库文档体系治理与去重标准化
阶段性质：docs-only governance / documentation standardization
当前仓库分支观测：main
当前 HEAD 观测：cbf9746180c4731c6cbc65df00293430e8a83646
```

DOC-GOV-001 只修改仓库内文档，不修改 Base Docs、Base Docs_Governance、Connection、工程代码、Godot 场景、资源、metadata 或 project.godot。

## 2. 最新工程证据阶段

```text
最新工程证据阶段：G36-R2 Runtime Architecture Consolidation & Save/Profile Foundation
G36 contract：docs/20_product/RUNTIME_ARCHITECTURE_SAVE_PROFILE_FOUNDATION_CONTRACT.md
G36 validation：docs/validation/G36_RUNTIME_ARCHITECTURE_SAVE_PROFILE_VALIDATION.md
G36 handoff：docs/handoff/HANDOFF_G36_RUNTIME_ARCHITECTURE_SAVE_PROFILE.md
```

G36 已有 contract / validation / handoff 三件套。DOC-GOV-001 只登记和索引这些事实，不重新声明 G36 release 已完成。

## 3. G36 边界摘要

- Save/profile foundation 覆盖 `SaveManager`、`SaveProfileManifest`、`SaveImportStaging`、`SaveProfilePreview` 和 profile path 结构。
- MetaProgress read-only fallback 会阻断 save、settlement commit、debug meta writes、clear/reset 和 debug marker writes。
- RunScene 仍是当前 M1 runtime owner；GameKernel 仍是 inactive/bootstrap placeholder。
- DeployPrep/AppShell 使用 bounded `RunStartConfig` / `RunStartRouteAdapter` payload，并保留 unsupported config fallback。
- Debug panel 和 debug command 继续由 `DebugGate` / `CommandBus` 硬 gate。

未实现 / 未声明：complete SaveManager UI、active-run persistence、runtime profile switching、complete RunBootstrapper、新 gameplay systems、gameplay runtime PASS、manual playtest PASS。

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
