# G35 Current Update

Current active slice: G35-R2 Engineering Stabilization / Runtime Ownership Cleanup.

G35 status boundaries:

- Persistence safety: M1 MetaProgress loading is read-only and does not overwrite parse-failed, future-schema, or manually edited save files.
- Debug safety: Debug panel visibility and CommandBus debug-source execution are hard-gated behind debug/editor or explicit dev setting.
- Event safety: default Event room interaction returns the real EventService result.
- Runtime ownership: RunScene remains the authoritative M1 runtime owner; GameKernel is inactive/bootstrap placeholder until a later migration.
- DeployPrep start remains bounded preview/intent wording only; no real RunBootstrapper is implemented.
- G35 does not implement complete SaveManager, active-run persistence, full RunFlow, real DeployPrep start, new gameplay systems, gameplay runtime PASS, or manual playtest PASS.

Any remaining G34 or older current-state wording below this update is historical / superseded unless explicitly reopened by a future gate.

# G34 Current Update

Current active slice: G34-R2 Rule / Effect / Modifier & Content Delivery Common System Full Content Implementation.

Current G34 contract source:

- `docs/20_product/RULE_EFFECT_MODIFIER_CONTENT_DELIVERY_COMMON_SYSTEM_CONTRACT.md`

G34 uses `D:\AGAME1\Base Docs\规则、效果、Modifier 与内容投放通用系统策划案.md` as the primary read-only planning source and establishes the project-supported common preview layer for rules, effects, modifiers, and content delivery.

G34 status boundaries:

- Core outputs: RuleDefinition / RuleTrigger / RuleCondition / RuleContextSnapshot / TargetSelector / ApplicabilityCheck / ScopePolicy.
- Effect outputs: EffectDescriptor / EffectPreview / EffectResultPreview.
- Modifier outputs: ModifierProfile / ModifierStackPreview / ModifierConflictPolicy.
- Content outputs: ContentPool / ContentEntry / ContentSelector / ContentDeliveryContext / PoolResultPreview / FallbackPolicy / DeliveryRollPreview.
- Consumer alignment: RoomRulePreview, RunFlowSnapshot, Settlement preview, RunSurface, and HUD can read display-only summaries.
- G34 remains read_only / display_only / preview / no_persistence.
- G34 does not implement a complete Rule engine runtime, script language, AI Director, real rewards, real drops, real objective progress, real map mutation runtime, persistence, AssetLedger / RunAssetLedger long-term writes, CommandBus mutation, gameplay runtime PASS, or manual playtest PASS.

Any remaining G33 or older current-state wording below this update is historical / superseded unless explicitly reopened by a future gate.

# G33 Current Update

Current active slice: G33-R2 Room Type / Tag / Encounter Common Rule Full Content Implementation.

Current G33 contract source:

- `docs/20_product/ROOM_TYPE_TAG_ENCOUNTER_COMMON_RULE_CONTRACT.md`

G33 uses `D:\AGAME1\Base Docs\房间类型、标签与遭遇通用规则策划案.md` as the primary read-only planning source and establishes the project-supported room type / tag / policy / state / encounter preview carrier layer.

G33 status boundaries:

- Core outputs: RoomType / RoomTag / RoomPolicy / RoomState / RoomContentSlot / EncounterEntry / EncounterPreview / RoomRulePreview / RoomCondition / RoomResolutionPreview / RoomResultPreview.
- Room loot boundary: GroundLoot and RoomLootContainer are semantic preview only; they are not player backpack, long-term warehouse, or settlement grant runtime.
- Consumer alignment: TruthMap, EncounterResolver, RunFlowSnapshot, Settlement preview, RunSurface, and HUD read display-only room common-rule summaries.
- G33 remains read_only / display_only / preview / no_persistence.
- G33 does not implement battle runtime, monster AI, event-chain runtime, RoomLoot/GroundLoot runtime, real in-run backpack, Rule/Modifier engine, objective progress, reward grant, settlement warehouse write, SaveManager, AssetLedger / RunAssetLedger mutation, CommandBus mutation, gameplay runtime PASS, or manual playtest PASS.

Any remaining G32 or older current-state wording below this update is historical / superseded unless explicitly reopened by a future gate.

# G32 Current Update

Current active slice: G32-R2 Run Flow & State Transition Full Content Implementation.

Current G32 contract source:

- `docs/20_product/RUN_FLOW_STATE_TRANSITION_FULL_CONTENT_CONTRACT.md`

G32 uses `D:\AGAME1\Base Docs\局内流程与状态流转规则策划案.md` as the primary read-only planning source and establishes the project-supported run lifecycle / state transition public snapshot layer.

G32 status boundaries:

- Core outputs: RunLifecycle / RunState / RunFlowSnapshot / RoomTransition / RoomActionResult / RunIntent / SettlementTriggerPreview / RunOutcomePreview / RunResult draft.
- Route handoff: DeployPrep emits a bounded start bridge to the existing run route; no real deploy-config bootstrapper is created.
- UI consumers: RunSurface / HUD read lifecycle, transition, and settlement trigger preview fields.
- Settlement receives trigger/outcome/result draft preview only and does not write warehouse state.
- G32 remains read_only / display_only / preview / no_persistence.
- G32 does not implement complete SaveManager, active run persistence, real continue recovery, real abandon settlement, real warehouse write, real reward grant, objective progress, complete Rule / Modifier engine, RoomLoot runtime, CommandBus command-list changes, gameplay runtime PASS, or manual playtest PASS.

Any remaining G31 or older current-state wording below this update is historical / superseded unless explicitly reopened by a future gate.

# G31 Current Update

Current active slice: G31-R2 Run Map Domain / Room State Foundation Full Content Implementation.

Current G31 contract source:

- `docs/20_product/RUN_MAP_DOMAIN_ROOM_STATE_FOUNDATION_CONTRACT.md`

G31 uses `D:\AGAME1\Base Docs\局内地图本体与生成规则策划案.md` as the primary read-only planning source and establishes the run-local map / room-state fact source.

G31 status boundaries:

- Core layers: TruthMap / KnownMap / ScanLayer / MarkMap / RunMapState / InfoReliabilityLayer.
- Current map type: classic rectangular minesweeper map.
- Current outputs: FinalMapSnapshot, RunMapSnapshot, MapResult, RoomState, RoomPolicy, RoomTag, return_eligibility / fast_return preview.
- UI consumers: minimap / run surface / HUD read display-only public snapshots.
- Settlement receives map-facing summary preview fields only.
- G31 remains read_only / display_only / preview / no_persistence.
- G31 does not implement complete RunFlow, persistence, battle runtime, event chains, RoomLoot runtime, objective progress, reward grant, settlement warehouse write, SaveManager, AssetLedger / RunAssetLedger mutation, CommandBus mutation, gameplay runtime PASS, or manual playtest PASS.

Any remaining G30 or older current-state wording below this update is historical / superseded unless explicitly reopened by a future gate.

# G30 Current Update

Current active slice: G30-R2 Long-Term System Integration & Asset Interface Full Content Implementation.

Current G30 contract source:

- `docs/20_product/LONG_TERM_SYSTEM_ASSET_INTERFACE_FULL_CONTENT_CONTRACT.md`

G30 uses `D:\AGAME1\Base Docs\长期系统整合与资产接口规则策划案.md` as the primary read-only planning source and aligns the six-module LongTerm structure with asset interface, RewardBundle, event flow, red_dot_policy, and jump_target preview data.

G30 status boundaries:

- LongTerm primary modules remain: 目标 / 图鉴 / 研究 / 个人资历 / 抽奖 / 收藏 / 外观.
- G30 adds display-only module scope, secondary groups, cards, status chips, asset refs, RewardBundle preview, red_dot_policy, jump_targets, and event-flow preview.
- G30 aligns DeployPrep and Settlement as display-only consumers of the same preview interface.
- G30 remains preview_only / display_only / read_only / no_persistence.
- G30 does not implement real LongTerm backend, real objective progress, reward claim/grant, real gacha odds/roll/result, real red dot clearing, real asset writes, SaveManager, AssetLedger mutation, CommandBus mutation, gameplay runtime PASS, or manual playtest PASS.

Any remaining G29 or older current-state wording below this update is historical / superseded unless explicitly reopened by a future gate.

# G29 Current Update

Current active slice: G29-R2 Deploy Prep Revision Full Content Implementation.

G29 uses `D:\AGAME1\Base Docs\出发探索界面与出勤准备规则策划修正案.md` as the read-only planning source. The revision source supersedes older DeployPrep preview wording where the two conflict.

Current G29 contract source:

- `docs/20_product/DEPLOY_PREP_REVISION_FULL_CONTENT_CONTRACT.md`

G29 status boundaries:

- DeployPrep visible primary tabs are now aligned to 地图 / 仓库 / 申领 / 目标 / 出勤配置.
- 目标 replaces the old 作业许可 visible page position.
- 作业许可 is downgraded to future interface / locked state.
- 仓库 is ownership-first; 申领 is catalog-first.
- Capacity wording is unified as 背包容量.
- G29 remains preview / display-only / read-only and does not implement real warehouse, real asset writes, real purchase, real reward grant, real settlement, real RunBootstrapper, persistence, or full RunFlow.
- G29 internal slices are docs alignment, model/state/content, and UI display/interaction/validation.
- Unified G29 release gate must wait until the main G29-R2 content is complete.

# G28A Current Update

Current active slice: G28A Item Asset Content / Warehouse View Content Contract - docs-only.

G28A only updates repository docs. It aligns the new Base Docs source context for item asset content, warehouse view content, DeployPrep, LongTerm, Settlement, Run Map, Run Flow, combat room encounters, and future planning. It does not write Base Docs, Connection, Godot files, project metadata, scenes, resources, UID, or translation files.

Current G28A contract source:

- `docs/20_product/ITEM_ASSET_CONTENT_AND_WAREHOUSE_VIEW_CONTRACT.md`

G28A status boundaries:

- G27 Asset Domain / Warehouse View Contract Foundation is completed and historical.
- G28A defines item asset content and warehouse view content fields, source contexts, and preview fixture boundaries.
- G29 or later remains the candidate for Objective / Reward / Pool Contract Foundation.
- Run Map and Run Flow are interface-reservation notes only; G28A does not merge map generation or flow state machines into this slice.
- Any remaining G27A/G27B/G27C or older route wording below this update is historical / superseded / resolved unless explicitly reopened by a future gate.

G28A non-goals:

- no Godot schema or UI consumer implementation
- no real warehouse
- no real asset write
- no sale/equipment/carry mutation
- no reward delivery
- no gacha draw or result delivery
- no settlement warehouse write
- no objective progress
- no SaveManager / AssetLedger / RunAssetLedger / CommandBus mutation
- no FileAccess / user:// persistence
- no gameplay runtime PASS
- no manual playtest PASS

# G27A Current Update

Current active slice: G27A Asset Domain / Warehouse View Contract Foundation - docs-only.

G27A only adds and calibrates repository documentation. It does not change Godot scripts, scenes, resources, import metadata, project configuration, Base Docs, Base Art, or Connection files.

Current contract source:

- `docs/20_product/ASSET_DOMAIN_AND_WAREHOUSE_VIEW_CONTRACT.md`

G27A status boundaries:

- G25 UI Structure Stabilization & Playable Route Recovery is already closed and merged.
- G26 is completed and historical; G27A does not reopen G26.
- G27A defines asset-domain and warehouse-view product vocabulary only.
- G27B may consider Godot asset / warehouse view schema foundation after a separate gate.
- G27C may consider a display-only warehouse UI consumer after a separate gate.
- Objective / Reward / Pool implementation remains deferred to G28 or later unless explicitly re-gated.
- Any remaining P2 / G26 / prior G27 wording below this update is historical / superseded / resolved unless it is explicitly named as a current G27A, future G27B, future G27C, or future G28 boundary.

G27A non-goals:

- no real warehouse
- no real asset write
- no sale/equip/carry mutation
- no reward grant
- no gacha draw or result delivery
- no settlement mutation
- no persistence
- no gameplay runtime PASS
- no manual playtest PASS

# Current State

文档状态：当前入口
适用范围：G27A docs-only 当前事实摘要；P2 后仓库文档入口为 historical / superseded
最后更新：2026/06/23

本文件只汇总当前事实入口，不替代验证记录、历史 handoff 或外部策划来源。

## 1. 当前阶段

```text
当前文档治理阶段：G27A docs-only（P2 为 historical / superseded）
阶段性质：docs-only asset-domain / warehouse-view contract foundation
工程实现阶段：无新增 Godot 工程实现；G27A 仅为 docs-only
G26 状态：completed / historical；不再是未启动或占位
```

Historical / superseded P2 note: P2 已完成文档树迁移；G27A 继续只整理 allowlist docs，不改工程代码、Godot 场景、脚本、资源、导入文件或项目配置。

## 2. 最近已关闭工程阶段

G25 UI Structure Stabilization & Playable Route Recovery 已合入 `main`。

```text
G25 implementation commit：ae6f2ab6abd50b51c6f8f600cb8f5cda1cda7462
G25 closeout docs commit：022d3f74e9982fffae62e174df04b8f8f55a8958
G25 验证：static validation PASS；Godot headless project-load/parser smoke PASS
未声明：gameplay runtime PASS；manual playtest PASS
```

G25 只处理 UI 结构与当前可玩路线恢复，不实现真实仓库、奖励、结算、抽奖、目标、红点、SaveManager、资产写入、LongTerm 后端、真实设置或美术导入。

## 3. 当前能力摘要

| 模块 | 当前状态 | 证据入口 |
| --- | --- | --- |
| 主菜单 / AppShell | foundation 已建立；G25 增加当前可玩路线入口 | `docs/validation/G25_UI_STRUCTURE_PLAYABLE_ROUTE_VALIDATION.md` |
| 出发探索 / DeployPrep | foundation / preview；G22 为完整模块内容预览，不是真实出发系统 | `docs/validation/G22_DEPLOY_PREP_FULL_MODULE_CONTENT_PREVIEW_VALIDATION.md` |
| 长期系统 / LongTerm | 六模块 foundation / preview；不是完整长期系统 | `docs/validation/G24_LONG_TERM_CONTENT_FRAMEWORK_FOUNDATION_VALIDATION.md` |
| 物品 / 资产 | G21 为契约 foundation；不是真实资产系统或仓库 | `docs/validation/G21_ASSET_ITEM_FLOW_CONTRACT_VALIDATION.md` |
| 结算 / 历史 | G23 为 snapshot foundation；不是真实结算或持久历史 | `docs/validation/G23_SETTLEMENT_HISTORY_SNAPSHOT_FOUNDATION_VALIDATION.md` |
| 战斗遭遇 | G15/G16 为 encounter/combat foundation | `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`、`docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md` |
| 文档治理 | P2 已建立统一入口；2026/06/23 补充外部归档与并行交接只读边界 | `docs/00_governance/SOURCE_REGISTRY.md`、`docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md` |

## 4. 当前边界

```text
1. Godot headless project-load/parser smoke PASS 不等于 gameplay runtime PASS。
2. foundation / preview / display-only 不等于完整系统。
3. Base Docs 是仓库外当前归档后的只读策划事实来源之一；仓库历史副本不覆盖当前外部原件。
4. UI 图片不作为规则权威。
5. Historical / resolved: G26 已完成并进入历史；G27A 不由 P2 自动开启，而由当前 G27A docs-only gate 执行。
6. Connection 是仓库外并行交接区；不得进入 Git、不得作为 Godot 资源导入。
7. 旧文件名失效时，应在外部根目录内按主题、相近名称、更新时间和文档状态重新定位。
```

## 5. 扩展证据

扩展证据和历史正文仍保留：

```text
docs/PROJECT_BASELINE.md
docs/ENGINEERING_STATUS.md
docs/NEXT_HANDOFF.md
docs/DOCS_INDEX.md
Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md
```

G27A 当前第一入口仍以本文件、`docs/INDEX.md` 和 `docs/20_product/ASSET_DOMAIN_AND_WAREHOUSE_VIEW_CONTRACT.md` 为准；P2 wording is historical / superseded.
