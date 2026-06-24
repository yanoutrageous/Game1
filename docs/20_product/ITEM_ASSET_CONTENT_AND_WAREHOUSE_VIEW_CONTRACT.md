# Item Asset Content And Warehouse View Contract

Document status: G28A docs-only content contract foundation.
Last updated: 2026-06-24.

G28A defines the product contract for item asset content and warehouse-view content. It builds on the G27 `AssetDescriptor` and `WarehouseViewSnapshot` boundary and does not redefine the asset domain.

G28A is documentation only. It does not implement Godot schema, UI consumers, real warehouse behavior, real asset flow, run map generation, room loot runtime, ground loot runtime, RunFlow state machines, reward delivery, gacha execution, settlement warehouse writes, objective progress, SaveManager, AssetLedger, RunAssetLedger, CommandBus mutation, FileAccess, or `user://` persistence.

## 1. Positioning

G27 defines asset-domain and warehouse-view schema vocabulary. G28A defines the content layer that can feed those contracts later:

- item asset content categories
- display fields and policy fields
- preview fixture boundaries
- source context taxonomy
- warehouse view display content
- future consumer boundaries for DeployPrep, LongTerm, Settlement, Run Map, Run Flow, and G29 Objective / Reward / Pool work

## 2. Base Docs Source Alignment

Base Docs remain external read-only planning sources. G28A records alignment with the following source contexts without copying, importing, or modifying them:

- `物品资产模型与内容映射规则策划案.md`
- `长期系统整合与资产接口规则策划案.md`
- `长期系统内容补全策划案.md`
- `出发探索界面与出勤准备规则策划案.md`
- `出发探索界面与出勤准备规则策划修正案.md`
- `本局结算报告与历史战绩系统.md`
- `局内地图本体与生成规则策划案.md`
- `局内流程与状态流转规则策划案.md`
- `战斗房与怪物遭遇通用规则策划案.md`
- `未来规划策划案.txt`

These sources inform product vocabulary only. They do not authorize runtime implementation, Godot metadata changes, resource import, or direct content copying.

## 3. Content Categories

Item asset content categories:

- `resource`
- `equipment`
- `consumable`
- `material`
- `collectible`
- `unlock`
- `appearance`
- `special`

Category notes:

- `material` is a content category for ingredient-like or crafting-like future content. It does not imply a crafting system exists.
- `appearance` is an unlock/display category, not warehouse-owned equipment by default.
- `unlock` can reference codex, research, profile, or feature unlocks without merging those systems into the warehouse.
- `special` covers quest, commission, sample, unidentified, or unusual objects through tags and source context rather than creating new core asset types.

## 4. Required Content Fields

Minimum content fields:

- `asset_id`
- `asset_category`
- `item_main_type`
- `display_name_key`
- `description_key`
- `icon_key`
- `rarity_key`
- `source_context`
- `content_tags`
- `display_policy`
- `warehouse_view_policy`
- `deploy_policy`
- `settlement_policy`
- `history_policy`
- `reward_reference_policy`
- `run_presence_policy`
- `map_visibility_policy`
- `room_loot_policy`

All fields are contract fields. They are not a runtime catalog, ContentDB, save record, asset ledger row, inventory row, or reward command.

## 5. Source Contexts

Allowed source context labels:

- `deploy`
- `map`
- `room`
- `event`
- `combat`
- `chest`
- `objective`
- `settlement`
- `history`
- `gacha`

Source context records where a preview item would be displayed or referenced. It does not create the item, grant it, persist it, or mark ownership.

## 6. Reserved Preview Concepts

`ItemAssetContentPreview`:
Read-only content fixture for item asset display. It may contain display keys, category, tags, and policy notes.

`WarehouseViewContentSnapshot`:
Read-only grouping of item asset content previews for warehouse-like display. It is not the real warehouse.

`room_loot`:
Future room-level item appearance context. G28A only reserves policy language.

`ground_loot`:
Future ground-level pickup context. G28A does not implement pickup logic.

`run_bag_item`:
Future run-bag display context. G28A does not implement bag mutation.

`settlement_candidate`:
Future settlement display candidate. G28A does not return, lose, rescue, clear, convert, or grant assets.

`history_reference`:
Future historical display reference. It is independent from current warehouse state.

## 7. Preview Fixtures Versus Runtime Catalog

Preview fixtures:

- may be hand-authored sample rows for product review
- may use placeholder display keys
- may include incomplete balancing values
- must be labeled `read_only`, `display_only`, and `preview`
- must not be treated as runtime ownership, drop table, reward table, gacha pool, or ContentDB

Runtime catalog / ContentDB:

- requires a later implementation gate
- requires validation against engine consumers
- must not be inferred from G28A docs
- must not be generated from Base Docs without a separate approval path

## 8. Display-Only Consumer Boundaries

DeployPrep:
May display item asset content previews as candidate carry/equipment/consumable summaries. It must not equip, carry, buy, claim, or mutate assets.

LongTerm:
May display collection, appearance, codex, research, profile, history, or gacha references by content key. It must not unlock, claim, roll, grant, or update profile state.

Settlement:
May display `settlement_candidate` and `history_reference` previews. It must not write warehouse state, grant rewards, clear consumables, or persist settlement results.

## 9. Run Map And Run Flow Reserved Interfaces

Run Map and Run Flow may later consume item asset content contracts for map visibility, room loot, ground loot, run bag display, encounter context, and flow summaries.

G28A does not implement:

- map generation
- room loot runtime
- ground loot runtime
- run bag runtime mutation
- RunFlow state machine
- combat room drops
- chest contents
- pickup behavior

## 10. Relationship To G29

G29 or later Objective / Reward / Pool Contract Foundation may depend on G28A field names and source contexts.

G29 must still define its own contracts for:

- objective progress and completion
- reward bundle references
- claimable state
- red dot state
- gacha pool descriptor
- reward delivery boundaries

G28A does not pre-authorize those systems.

## 11. Explicit Non-Goals

G28A does not implement:

- real warehouse
- real asset writes
- sale
- equipment changes
- carry mutation
- reward delivery
- gacha draw or result delivery
- settlement warehouse writes
- objective progress
- SaveManager
- AssetLedger
- RunAssetLedger
- CommandBus mutation
- FileAccess / `user://` persistence
- Godot scripts, scenes, resources, UID, translation, import metadata, or project configuration changes
