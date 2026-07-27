# G29 Deploy Prep Revision Full Content Contract

Document status: G29-R2 implementation contract
Primary registered original: `sources/base/原始策划案/出发探索界面与出勤准备规则策划修正案.md`
Boundary: repository summary only; the registered original remains byte-exact and is not copied into repo docs.

## 1. Stage Position

G29 implements the current supportable UI/model/content layer for the Deploy Prep revision v0.2. The revision source takes precedence over older Deploy Prep preview wording when the two conflict.

G29 is not a release gate and does not approve a full gameplay runtime. It only moves DeployPrep from the older preview layout toward the revision's complete visible page structure, content model, state summary, and interaction boundary.

## 2. Current Primary Tabs

DeployPrep uses five visible primary tabs:

1. 地图
2. 仓库
3. 申领
4. 目标
5. 出勤配置

The former 作业许可 primary tab is no longer a current visible player configuration page. 作业许可 is downgraded to a later interface / locked state for insurance, consignment, special access, Boss reconnaissance, and high-risk protocols.

## 3. Page Responsibilities

地图:
- Shows map mode, difficulty, region, unlock state, fuzzy risk / reward tendency, topology notes, and config suitability.
- Keeps `seed_policy = defer_until_run_start`.
- Does not reveal real map layout, Boss, extraction point, room distribution, monster room, chest room, event room, or true random result.

仓库:
- Is ownership-first: "what the player already owns".
- Uses only four main item categories: 装备 / 消耗品 / 藏品 / 特殊物.
- Shows 可出勤 / 可出售 / 已配置 / 锁定 / 新获得 / 未判断 state as tags.
- Sell, equip, add-to-attendance, and remove-from-attendance are preview / in-memory intent only in G29.

申领:
- Is catalog-first: "what the logistics catalog currently offers".
- Shows 可购买 / 可领取 / 可回收 / 未解锁预览 / 推荐内容.
- Purchase / claim / recycle / purchase-and-add-to-attendance are preview intents only.
- Purchase or claim is modeled as long-term warehouse intake in the rule contract; G29 does not perform real cost, reward, or asset writes.

目标:
- Replaces the old 作业许可 visible position.
- Shows run objective / commission candidates, map and difficulty matching, requirements, completion conditions, failure conditions, and reward type summary.
- Selection is local DeployPrep draft / preview only; no runtime progress, long-term objective write, or reward grant.

出勤配置:
- Summarizes map, difficulty, target, equipment, consumables, special items, 背包容量, legality, risk, and start / continue / abandon intent.
- Does not expand full selectors; edit affordances point back to the relevant tab.
- Start / continue / abandon are button state, copy, strong-confirmation, and intent boundary only.

## 4. Vocabulary Corrections

- 修正案 v0.2 overrides older preview wording.
- 仓库 is ownership-first.
- 申领 is catalog-first.
- 容量 wording is unified as 背包容量; no new 补给容量 concept.
- 情报 and 服务 are not independent current systems; their effects are shown as consumable tags, special item effects, or later interface notes.
- 作业许可 is a future interface / locked state, not a current enabled permission page.

## 5. Current Implementation Boundary

G29 may fully land:

- page/tab structure
- local draft content
- display-only cards
- right-side summary groups: 摘要 / 配置 / 效果 / 风险
- local target selection preview
- local capacity and validity preview
- start / continue / abandon intent boundary
- G27/G28 asset content display sources

G29 must remain:

- `preview`
- `display_only`
- `read_only`
- `no_persistence`

## 6. Deferred Content

G29 does not implement:

- real warehouse persistence
- real asset writes
- real purchase cost
- real claim or reward delivery
- real sale
- real equip / unequip mutation
- real carry item write and lock into RunStartConfig
- real RunBootstrapper
- real active run persistence
- real continue recovery
- real abandon settlement
- complete Run Map generation
- complete RunFlow state machine
- complete objective / reward / pool system
- insurance / consignment / work-permit system
- SaveManager
- AssetLedger / RunAssetLedger mutation
- CommandBus mutation
- FileAccess / user:// persistence
- art/resource import

## 7. Internal G29 Slices

G29 is one implementation stage with internal slices:

1. docs alignment
2. model / state / content
3. UI display / interaction / validation

The unified G29 release gate must wait until this main content is complete.

## 8. Validation Language

Godot headless project-load / parser smoke may be recorded only as parser/project-load evidence. It is not gameplay runtime PASS and not manual playtest PASS.
