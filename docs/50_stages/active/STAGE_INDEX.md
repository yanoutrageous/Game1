# Active Stage Index

文档状态：阶段索引
适用范围：当前活动阶段
最后更新：2026/06/26

## 活动阶段

| stage | lane | status | evidence | boundary |
| --- | --- | --- | --- | --- |
| DOC-GOV-001 | documentation governance | active / docs-only | `docs/00_governance/DOC_PLACEMENT_STANDARD.md`、`docs/00_governance/DUPLICATE_DOC_LEDGER.md` | 不改 Base Docs / Base Docs_Governance / Connection；不改工程代码；不运行 Godot；不 commit / push |
| G36 follow-up | engineering gate | pending separate gate | `docs/validation/G36_RUNTIME_ARCHITECTURE_SAVE_PROFILE_VALIDATION.md`、`docs/handoff/HANDOFF_G36_RUNTIME_ARCHITECTURE_SAVE_PROFILE.md` | 需另行审计 / release gate；DOC-GOV-001 不自动执行 |

## 非活动但需保留的阶段名

| stage | status | note |
| --- | --- | --- |
| G27A-G35 | closed / historical | 作为历史证据保留，不作为当前入口 |
| P2 / G20 governance | historical | 旧治理材料保留；当前治理入口在 `docs/00_governance/` |
