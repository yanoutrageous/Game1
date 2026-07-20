# Claim Ledger

文档状态补充：下表是 P2 时间点声明台账；当前声明权威已由 I1 的 `CURRENT_STATE.md`、`CAPABILITY_MATRIX.yaml`、assessment、contract 和 validation 链取代。旧 hash 不回写。I1 worktree acceptance 可以登记为 scoped PASS，但 committed HEAD 与 Git 交付仍 pending，阶段不得登记为 closed。

文档状态：声明台账
适用范围：P2 后当前声明、来源、哈希与确认状态
最后更新：2026/06/23

本台账使用 `content_hash`，不使用不稳定的 `source_line` 作为唯一依据。

| claim_id | source_file | source_heading | content_hash | domain | claim_type | implementation_status | evidence | decision_status | requires_user_confirmation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CL-P2-001 | `docs/validation/G25_UI_STRUCTURE_PLAYABLE_ROUTE_VALIDATION.md` | `Validation Result` | `sha256:7aeb25142764aca9cd02f02bdd7c2de238cc006202a8c7d021a8afa7f8bb1bfa` | validation | validated_status | closed_stage_evidence | `docs/validation/G25_UI_STRUCTURE_PLAYABLE_ROUTE_VALIDATION.md` | confirmed_by_validation_record | false |
| CL-P2-002 | `docs/handoff/HANDOFF_G25_UI_STRUCTURE_PLAYABLE_ROUTE.md` | `Non-Goals` | `sha256:ef3a2da6c100b2b1d88b65f1b8dfdb7ef107993d02cdffba4fecf95488b2d630` | scope_boundary | non_goal | not_implemented | `docs/handoff/HANDOFF_G25_UI_STRUCTURE_PLAYABLE_ROUTE.md` | confirmed_by_handoff_record | false |
| CL-P2-003 | `docs/INDEX.md` | `阶段边界` | `sha256:967db45dae6fbd71bdeaf2db552ac863dc4e0c5b7f8a87e29d26893801c91e52` | stage_boundary | governance_boundary | active_boundary | `docs/INDEX.md` | p2_boundary_recorded | false |
| CL-P2-004 | `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md` | `Base Docs 口径` | `sha256:63be41a90e955b34475a2d517c1ddba5338998feb999f79826821177ee09f994` | source_boundary | source_use_limit | external_live_reference | `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md` | current_governance_boundary | false |
| CL-P2-005 | `docs/70_sources/ui_reference/UI_REFERENCE_REGISTRY.md` | `UI 图片来源` | `sha256:37a1fa29d6c99486d3904b2385d6960d044a803d20be50a42d32d914b38215b0` | ui_reference | source_use_limit | reference_only | `docs/70_sources/ui_reference/UI_REFERENCE_REGISTRY.md` | requires_future_confirmation_for_rule_use | true |
| CL-P2-006 | `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md` | `Connection 口径` | `sha256:1c6ac1d8f1b1a5322267e2f784674a9d56a1b784ef0bd4e5d4959dbb302a90c4` | connection | source_use_limit | connection_external_only | `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md` | current_governance_boundary | false |
| CL-P2-007 | `docs/20_product/PRODUCT_CONTRACT.md` | `文档状态` | `sha256:045ca89000c87a1b94ff9fa26e6736b0299cf5fb1b44d33baebf3db86ddea7a2` | product_contract | draft_boundary | draft_pending_confirmation | `docs/20_product/PRODUCT_CONTRACT.md` | requires_user_confirmation | true |
| CL-P2-008 | `docs/10_current/CAPABILITY_MATRIX.yaml` | `validation_boundary` | `sha256:bd75530d9311698d18f727890fff1f9f3ba3278a327dcc518d911a327b8d9447` | validation | validation_boundary | active_boundary | `docs/10_current/CAPABILITY_MATRIX.yaml` | confirmed_by_current_matrix | false |

## 使用边界

```text
1. content_hash 是声明文本哈希，用于追踪声明内容变化。
2. evidence 指向可核对的文档证据，但不扩大证据范围。
3. requires_user_confirmation=true 的声明不得写成最终规则。
```
