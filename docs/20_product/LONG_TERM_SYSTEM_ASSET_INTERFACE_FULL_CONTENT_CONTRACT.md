# G30 Long-Term System Asset Interface Full Content Contract

Status: G30-R2 implementation contract.

Primary read-only planning source:

- `D:\AGAME1\Base Docs\长期系统整合与资产接口规则策划案.md`

Supplemental read-only planning sources:

- `D:\AGAME1\Base Docs\长期系统内容补全策划案.md`
- `D:\AGAME1\Base Docs\物品资产模型与内容映射规则策划案.md`
- `D:\AGAME1\Base Docs\本局结算报告与历史战绩系统.md`
- `D:\AGAME1\Base Docs\出发探索界面与出勤准备规则策划修正案.md`
- `D:\AGAME1\Base Docs\未来规划策划案.txt`

G30 implements the LongTerm product/content contract and a Godot display-only consumer layer. It does not implement a real LongTerm backend, persistence, reward delivery, gacha roll/result delivery, objective progress, asset writes, SaveManager, AssetLedger mutation, or CommandBus mutation.

## Positioning

LongTerm answers: the player is pursuing what, has recorded what, has unlocked what, and can display what.

LongTerm does not own:

- DeployPrep run configuration
- warehouse management
- settlement execution
- RunScene gameplay
- reward delivery
- gacha execution
- persistence

All new G30 data must remain:

```text
preview_only
display_only
read_only
no_persistence
no_asset_write
no_reward_grant
```

## Six Primary Modules

The LongTerm primary information architecture is fixed to six modules:

| Module | Secondary groups | Responsibility | Explicit boundary |
| --- | --- | --- | --- |
| 目标 | 任务 / 成就 / 委托记录 | Long-term behavior goals, reward state preview, commission history references | Does not select current-run commissions or write objective progress |
| 图鉴 | 地图 / 怪物 / 藏品 / 装备 / 消耗品 / 事件 / 规则 / 世界观 | Discovery/archive display and source references | Does not unlock entries or provide abilities |
| 研究 | 功能解锁接口 / 研究入口 preview | Research-line and unlock-interface reservation | Does not spend resources or unlock features |
| 个人资历 | 资历等级 / 历史战绩 / 数据统计 / 里程碑 / 称号 / 徽章 | Profile identity, historical result display, milestones, title/badge preview | Does not upgrade profile or write history |
| 抽奖 | 奖池 / 消耗 / 结果入口 preview | Pool descriptor, cost descriptor, result ownership preview | Does not calculate odds, consume currency, roll, or deliver results |
| 收藏 / 外观 | 唯一展示 / 外观配置 / 展示内容 / 徽章称号 / 结算展示 | Display ownership, cosmetic/config intent, unique collectible presentation | Does not apply cosmetics or mutate collection state |

Historical records remain inside 个人资历. Warehouse remains independent and is only a jump/reference target.

## Module Display Fields

Each module preview should expose:

```text
module_id
display_name
module_icon_key
module_banner_key
tab_icon_key
description_key
localization_key
ui_group_key
preview_state
secondary_groups
cards
detail_preview
cross_links_preview
event_slots_preview
event_flow_preview
art_slots_preview
asset_interface_preview
reward_bundle_preview
red_dot_policy
jump_targets
current_landable_scope
deferred_scope
future_data_ref
data_source_ref
preview_only / display_only / read_only
```

Cards may show status chips, asset refs, reward summary, red dot policy, and jump targets, but must not expose true action execution.

## Objective Contract

Objective entries cover tasks, achievements, commission records, and high-risk commission record interfaces.

Required preview fields:

```text
objective_id
objective_type
display_name
description
condition_id
progress_state_preview
completion_state_preview
reward_bundle_preview
visibility_state
claim_state_preview
lifecycle_policy
failure_policy
source_system
red_dot_policy
jump_targets
```

Allowed in G30:

- show task/achievement/commission groups
- show progress and claim state as preview text
- show RewardBundle preview
- show red dot rules
- jump to DeployPrep objective consumer preview

Forbidden in G30:

- progress calculation
- completion judgment
- reward claim
- commission acceptance
- current-run objective writes

## Codex Contract

Codex displays discovery/archive state for maps, monsters, items, events, rules, and lore.

Allowed states:

```text
undiscovered
encountered
owned_or_obtained
completed
filled
```

Codex can reference warehouse ownership, history origin, collection display, or research requirements through jump targets. Codex cannot run research, unlock entries, or mutate ownership.

## Research Contract

Research is a functional unlock interface reservation. It may show research lines:

```text
level_research
collectible_research
currency_research
codex_research
sample_special_research
function_research
future_hook_research
```

G30 only displays line, requirement, and unlock-target preview. It does not spend resources, consume items, unlock features, or write research state.

## Profile / History Contract

个人资历 contains profile level, history records, statistics, milestones, titles, badges, and profile reward preview.

History records consume settlement/history snapshot preview. They preserve the run result snapshot and do not depend on current warehouse state.

Profile reward preview may expose RewardBundle and red_dot_policy, but no profile upgrade or reward claim is executed.

## Gacha Contract

Gacha remains an independent LongTerm module. It may show:

```text
pool descriptor
cost descriptor
result ownership preview
RewardBundle preview
jump targets to warehouse / collection / codex
```

G30 does not implement probability, pity, currency cost, roll execution, result generation, or reward delivery.

## Collection / Appearance Contract

Collection / appearance displays owned presentation content and cosmetic config intent.

Unique remains a collectible, not a new item primary type. Appearance is an unlock/display concept and is not a warehouse item.

G30 may show unique display, appearance config intent, display slots, badges/titles, and settlement display references. It does not apply appearance, write collection state, or mutate assets.

## Asset Interface

LongTerm reads asset references from the asset domain and warehouse view contracts:

```text
AssetRef
AssetDescriptor
OwnedAssetSnapshot
WarehouseViewSnapshot
AssetEventPreview
AssetSourceContext
HistoryAssetReference
```

LongTerm may reference warehouse, codex, history, collection, and DeployPrep by jump target, but it does not own or write warehouse state.

## Event And Reward Flow

G30 reserves preview schemas for:

```text
RewardBundle
ResourceEvent
ItemEvent
UnlockEvent
HistoryRecordEvent
ObjectiveEvent
```

Correct future flow:

```text
module condition
-> ObjectiveEvent / other source event
-> RewardBundle
-> ResourceEvent / ItemEvent / UnlockEvent / HistoryRecordEvent
-> warehouse / codex / collection / profile read changes
-> red_dot_policy display
```

G30 only describes this flow. It does not dispatch events, grant rewards, or persist changes.

## Red Dot Policy

Allowed red dot reasons:

- objective ready or reward state preview
- task/achievement complete
- codex new entry
- research available/completed
- profile reward preview
- unread history record
- unread gacha result
- collection/appearance newly obtained
- warehouse new asset reference

Not recommended:

- currency sufficient only
- can roll gacha only
- shop refresh only
- hidden objective incomplete
- already viewed content

Clear policies are preview only:

```text
open_module
view_entry
reward_state_preview
manual_clear_preview
```

No real red dot clearing or persistence is implemented.

## Jump Targets

Allowed jump target preview examples:

- 目标 -> DeployPrep
- 目标 -> warehouse
- 图鉴 -> warehouse
- 图鉴 -> profile/history
- 研究 -> codex
- 研究 -> DeployPrep future unlock consumer
- 个人资历 -> history record
- 个人资历 -> collection / appearance
- 抽奖 -> collection / appearance
- 抽奖 -> warehouse
- 收藏 / 外观 -> codex
- 唯一展示 -> warehouse reference

Jump targets are locator intent only. They do not execute actions or cross system boundaries.

## Relations With Other Systems

DeployPrep:

- reads objective and asset interface preview
- does not accept LongTerm objective state writes
- does not start true run configuration from LongTerm

Settlement:

- produces settlement/history snapshot preview
- may expose RewardBundle/event preview
- does not write warehouse/history in G30

History:

- consumes snapshot references inside 个人资历
- does not depend on current warehouse state

Warehouse:

- remains independent
- accepts future events from backend systems, not from LongTerm UI

## Current Landable Scope

G30 lands:

- product contract documentation
- current status and capability matrix update
- LongTerm module preview data enrichment
- RewardBundle/event/red-dot/jump-target preview schemas
- display-only UI summary for the new interface fields
- validation and handoff docs

## Deferred Scope

Deferred:

- real LongTerm backend
- real objective progress
- real reward claim/grant
- real gacha roll/odds/result
- real red dot state
- real profile progression
- real collection/cosmetic application
- real asset writes
- real persistence
- full gameplay loop
