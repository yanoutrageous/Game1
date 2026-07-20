# Duplicate Document Ledger

文档状态：I1 当前重复文档台账。
最后更新：2026-07-20

本台账登记权威与重复组，不单独授权删除、移动、归档或重写历史证据。

## 当前第一入口

| Document | Lifecycle | Rule |
| --- | --- | --- |
| `README.md` | current_entry | repository summary and commands |
| `AUDIT_ENTRYPOINT.md` | current_entry | audit order and claim boundary |
| `docs/README.md` | current_entry | docs directory entry |
| `docs/INDEX.md` | current_entry | current navigation only |
| `docs/10_current/CURRENT_STATE.md` | current_state | verified/implemented facts and explicit pending state |
| `docs/10_current/CAPABILITY_MATRIX.yaml` | current_state | machine-readable capability status |
| `docs/10_current/NEXT_ACTION.md` | current_state | next gate and candidate increments |
| `docs/10_current/I1_BASELINE_ASSESSMENT.md` | baseline_assessment_current | freeze only after I1 closeout |
| `docs/00_governance/DOC_PLACEMENT_STANDARD.md` | governance_current | placement authority |
| `docs/00_governance/SOURCE_REGISTRY.md` | registry_current | source ownership and path status |
| `docs/00_governance/DUPLICATE_DOC_LEDGER.md` | registry_current | duplicate decisions |

## 冻结评估与阶段原文

| Document group | Current handling |
| --- | --- |
| `docs/10_current/I0_BASELINE_ASSESSMENT.md` | frozen I0 baseline evidence; future changes must not edit it into I1 facts |
| I0 / ART21 validation and handoff | retain originals; current indexes only summarize scope |
| ART23 validation/art evidence | retain as later accepted page/UI evidence; not project-level art-stage authority |
| ART24R2 validation/handoff | retain failed acceptance exactly; never promote to PASS |
| G/M/ART historical contracts, validation, handoff and stage summaries | retain in original locations; no bulk rewrite |

## 旧入口重复组

| Document group | Current handling |
| --- | --- |
| `docs/PROJECT_BASELINE.md`, `docs/ENGINEERING_STATUS.md`, `docs/NEXT_HANDOFF.md`, `docs/project_governance/` | expanded/historical evidence; not current first-entry authority |
| `docs/DOCS_INDEX.md`, `docs/NEXT_HANDOFF.md`, root handoff variants | historical navigation; current authority is `docs/INDEX.md` and current chain |
| `docs/10_current/G40_HEALTH_ISSUE_CLOSURE_MATRIX.md` | historical G40 matrix; not current facts |
| `Godot/GraytailGodot/docs/` | read-only engineering/history evidence; registry in `docs/30_engineering/godot/GODOT_DOCS_REGISTRY.md` |
| damaged governance/product/README files recorded by I0 | preserve exact bytes and encoding-ledger identity; valid companion index carries navigation |

## 外部重复证据

G40 曾在 `D:\AGAME1\reports\g40` 记录 inventory、resolution plan、cleanup log 和 remaining decision。该路径是历史机器证据且本机可用性不作假设；它不授权删除当前 repo 或外部 source pack 内容。

## I1 消歧决策

| Conflict | Current decision |
| --- | --- |
| I0+ART21 integration 与 M6/M7/ART24R2 摘要互相作为“当前” | current chain 统一到 I1 worktree-accepted/head-pending；旧原文保留历史时间点 |
| ART21 与 ART23 都被写成 latest art | ART21 = project-level latest closed art stage；ART23 = later accepted page/UI evidence slice |
| ART24R2 代码/探针改善与最终失败结果冲突 | final 24/61 failed acceptance wins; archived historical attempt |
| `D:\AGAME1` 被写成当前来源/仓库 | 统一标记 historical; active repo 动态解析；外部 pack 本机 unavailable |
| `E:\Godot` 本机路径与跨机器执行规则 | 只作 local observation/example；I1 resolution + lock verification 为可移植规则 |
| preview/capture marker 与视觉验收 | capture 属 `EXCLUDED_NON_SLICE`; 必须另有人审 |
| workflow 文件存在与 CI 通过 | `configured_unproven`，直到远端成功 run |

## 删除与归档规则

- 重复文件在专门的 cleanup/risk audit 前不删除。
- 历史 validation、handoff 和失败证据不因当前入口变短而移动。
- 受引用阻塞的重复项先修正引用，再讨论归档。
- 外部来源只登记，不做仓库内镜像复制来“消除重复”。
