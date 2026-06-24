# G34 Route Update

Current active slice: G34-R2 Rule / Effect / Modifier & Content Delivery Common System Full Content Implementation.

- G34 uses `D:\AGAME1\Base Docs\规则、效果、Modifier 与内容投放通用系统策划案.md` as the primary read-only planning source.
- G34 adds the current product contract at `docs/20_product/RULE_EFFECT_MODIFIER_CONTENT_DELIVERY_COMMON_SYSTEM_CONTRACT.md`.
- G34 formalizes RuleDefinition, RuleTrigger, RuleCondition, RuleContextSnapshot, TargetSelector, ApplicabilityCheck, ScopePolicy, EffectDescriptor, EffectPreview, EffectResultPreview, ModifierProfile, ModifierStackPreview, ModifierConflictPolicy, ContentPool, ContentEntry, ContentSelector, ContentDeliveryContext, PoolResultPreview, FallbackPolicy, and DeliveryRollPreview.
- G34 aligns RoomRulePreview, RunFlowSnapshot, Settlement preview, RunSurface, and HUD as display-only consumers.
- G34 remains read_only / display_only / preview / no_persistence and does not implement complete Rule engine runtime, script language, AI Director, real reward grant, real drops, objective progress, map mutation runtime, persistence, AssetLedger / RunAssetLedger long-term writes, CommandBus mutation, gameplay runtime PASS, or manual playtest PASS.
- Unified G34-R3 audit / release gate should validate parser smoke and branch state before any main merge.
- Any remaining G33 or older route wording below this update is historical / superseded unless explicitly reopened.

# G33 Route Update

Current active slice: G33-R2 Room Type / Tag / Encounter Common Rule Full Content Implementation.

- G33 uses `D:\AGAME1\Base Docs\房间类型、标签与遭遇通用规则策划案.md` as the primary read-only planning source.
- G33 adds the current product contract at `docs/20_product/ROOM_TYPE_TAG_ENCOUNTER_COMMON_RULE_CONTRACT.md`.
- G33 formalizes RoomType, RoomTag, RoomPolicy, RoomState, RoomContentSlot, EncounterEntry, EncounterPreview, RoomRulePreview, RoomCondition, RoomResolutionPreview, RoomResultPreview, GroundLoot, and RoomLootContainer semantic previews.
- G33 aligns TruthMap, EncounterResolver, RunFlowSnapshot, Settlement preview, RunSurface, and HUD as display-only public snapshot consumers.
- G33 does not implement battle runtime, event-chain runtime, RoomLoot/GroundLoot runtime, Rule/Modifier engine, objective progress, reward grant, settlement warehouse write, SaveManager, AssetLedger / RunAssetLedger mutation, CommandBus mutation, gameplay runtime PASS, or manual playtest PASS.
- Unified G33-R3 audit / release gate should validate parser smoke and branch state before any main merge.
- Any remaining G32 or older route wording below this update is historical / superseded unless explicitly reopened.

# G32 Route Update

Current active slice: G32-R2 Run Flow & State Transition Full Content Implementation.

- G32 uses `D:\AGAME1\Base Docs\局内流程与状态流转规则策划案.md` as the primary read-only planning source.
- G32 adds the current product contract at `docs/20_product/RUN_FLOW_STATE_TRANSITION_FULL_CONTENT_CONTRACT.md`.
- G32 formalizes RunLifecycle, RunState, RunFlowSnapshot, RoomTransition, RoomActionResult, RunIntent, SettlementTriggerPreview, RunOutcomePreview, and RunResult draft.
- G32 aligns DeployPrep start intent to a bounded existing run route bridge; no full RunBootstrapper or deploy-config legality runtime is implemented.
- G32 aligns RunSurface / HUD / Settlement as display-only public snapshot consumers.
- G32 does not implement SaveManager, active-run persistence, real continue recovery, real abandon settlement, warehouse writes, reward grants, objective progress, RoomLoot runtime, CommandBus command-list changes, gameplay runtime PASS, or manual playtest PASS.
- Unified G32-R3 audit / release gate should validate parser smoke and branch state before any main merge.
- Any remaining G31 or older route wording below this update is historical / superseded unless explicitly reopened.

# G31 Route Update

Current active slice: G31-R2 Run Map Domain / Room State Foundation Full Content Implementation.

- G31 uses `D:\AGAME1\Base Docs\局内地图本体与生成规则策划案.md` as the primary read-only planning source.
- G31 adds the current product contract at `docs/20_product/RUN_MAP_DOMAIN_ROOM_STATE_FOUNDATION_CONTRACT.md`.
- G31 formalizes TruthMap / KnownMap / ScanLayer / MarkMap / RunMapState / InfoReliabilityLayer.
- G31 lands MapGenProfile, MapGenerationLog, FinalMapSnapshot, RunMapSnapshot, MapResult, RoomState, RoomPolicy, RoomTag, return_eligibility, and fast_return preview.
- G31 aligns minimap / run surface / HUD as display-only public snapshot consumers and reserves Settlement / Objective / Modifier / RoomLoot / RunResult context fields.
- G31 does not implement complete RunFlow, persistence, battle runtime, event chains, RoomLoot runtime, objective progress, reward grant, settlement warehouse write, SaveManager, AssetLedger / RunAssetLedger mutation, CommandBus mutation, gameplay runtime PASS, or manual playtest PASS.
- Unified G31-R3 audit / release gate should validate parser smoke and branch state before any main merge.
- Any remaining G30 or older route wording below this update is historical / superseded unless explicitly reopened.

# G30 Route Update

Current active slice: G30-R2 Long-Term System Integration & Asset Interface Full Content Implementation.

- G30 uses `D:\AGAME1\Base Docs\长期系统整合与资产接口规则策划案.md` as the primary read-only planning source.
- G30 adds the current product contract at `docs/20_product/LONG_TERM_SYSTEM_ASSET_INTERFACE_FULL_CONTENT_CONTRACT.md`.
- G30 aligns LongTerm six modules, secondary groups, cards, status chips, asset references, RewardBundle preview, ResourceEvent / ItemEvent / UnlockEvent / HistoryRecordEvent / ObjectiveEvent preview, red_dot_policy, and jump_target preview.
- G30 aligns DeployPrep and Settlement as display-only consumers of the same preview interface.
- G30 does not implement real objective progress, reward claim/grant, gacha odds/roll/results, red dot clearing, asset writes, SaveManager, AssetLedger mutation, CommandBus mutation, gameplay runtime PASS, or manual playtest PASS.
- Unified G30-R3 audit / release gate should validate parser smoke and branch state before any main merge.
- Any remaining G29 or older route wording below this update is historical / superseded unless explicitly reopened.

# G29 Route Update

Current active slice: G29-R2 Deploy Prep Revision Full Content Implementation.

- G29 uses `D:\AGAME1\Base Docs\出发探索界面与出勤准备规则策划修正案.md` as read-only planning source.
- G29 advances DeployPrep to revision v0.2 page/content/state/interaction boundaries.
- Current visible tabs: 地图 / 仓库 / 申领 / 目标 / 出勤配置.
- 目标 replaces the old 作业许可 visible position; 作业许可 is a future interface / locked state.
- Warehouse is ownership-first; Claim is catalog-first; capacity wording is 背包容量.
- G29 remains preview / display-only / read-only and does not implement real warehouse, asset writes, purchase, sale, claim reward, settlement, RunBootstrapper, persistence, or full RunFlow.
- Unified G29 release gate must wait for this main implementation content to complete.
- Any remaining G28A or older route wording below this update is historical / superseded unless explicitly reopened.

# G28A Route Update

Current active slice: G28A Item Asset Content / Warehouse View Content Contract - docs-only.

- G27 is completed: asset-domain / warehouse-view contract docs and Godot schema foundation are now historical inputs.
- G28A adds `docs/20_product/ITEM_ASSET_CONTENT_AND_WAREHOUSE_VIEW_CONTRACT.md`.
- G28A aligns item asset content, warehouse view content, Base Docs source contexts, preview fixture boundaries, display policies, and future consumer boundaries.
- Objective / Reward / Pool Contract Foundation is deferred to G29 or later.
- Run Map and Run Flow are not merged into G28A; only interface-reservation language is recorded.
- G28A does not implement Godot schema, UI consumers, real warehouse, real asset writes, reward delivery, gacha, settlement warehouse writes, objective progress, runtime catalog, ContentDB, persistence, gameplay runtime, or manual playtest validation.
- Any remaining G27A/G27B/G27C or older route wording below this update is historical / superseded / resolved unless explicitly reopened by a future gate.

# G27A Route Update

Current active slice: G27A Asset Domain / Warehouse View Contract Foundation - docs-only.

- G25 is closed: UI Structure Stabilization & Playable Route Recovery is merged.
- G26 is completed and historical; it is no longer not started or a placeholder.
- G27A adds the product contract at `docs/20_product/ASSET_DOMAIN_AND_WAREHOUSE_VIEW_CONTRACT.md`.
- G27B may consider Godot asset / warehouse view schema foundation after a separate gate.
- G27C may consider a display-only warehouse UI consumer after a separate gate.
- Objective / Reward / Pool contract work remains deferred to G28 or later unless re-gated.
- G27A does not implement real warehouse, asset writes, reward grant, gacha, settlement mutation, persistence, gameplay runtime, or manual playtest validation.
- Any remaining P2 / G26 / prior G27 route rows below this update are historical / superseded / resolved unless explicitly named as the current G27A split or future G27B / G27C / G28 candidate.

# G20+ 路线建议

## G25-R3b Update

G25 UI Structure Stabilization & Playable Route Recovery is complete on branch `godot/g25-ui-structure-playable-route`.

- Final `main` / `origin/main`: `17f8406dcf745f81c829e78478663bec6cbd4e68`.
- Implementation commit: `ae6f2ab6abd50b51c6f8f600cb8f5cda1cda7462`.
- Static validation PASS.
- Godot headless project-load/parser smoke PASS.
- Scope: main-menu `快速开始 / Demo Run` current playable route, DeployPrep readability, LongTerm readability, and Settings placeholder noise reduction.
- Boundary: not real warehouse, rewards, settlement, gacha, objectives, red dots, SaveManager, asset writes, real LongTerm backend, real settings, or art import.
- No gameplay runtime PASS or manual playtest PASS is claimed.

## G26-R1 Route Reset

- G26-R1 audit result: PASS with preconditions.
- G26 is Engineering Architecture Structure Readiness Foundation.
- G26 prepares reviewable responsibility boundaries for `core`, `ui`, `preview`, `contract`, `content`, `validation`, and `docs`.
- Historical G26 boundary: G26 did not implement real objectives, rewards, pools, gacha, warehouse, asset writes, SaveManager, AssetLedger behavior, CommandBus behavior, or player-playable prototype v1.
- Prototype-Facing Objective / Reward / Pool Contract Foundation is deferred to G27 or a later independently authorized functional stage.
- Lua remains the gameplay-validation line. Godot remains the formal system-skeleton and interface-readiness line.
- Every later functional slice must declare a precise file allowlist, explicit exclusions, protected-dirty baseline, validation commands, and a separate Git gate.

## 声明

这是从 G20 延续并经后续阶段校准的路线记录。G21-G25 已分别执行并进入 `main`；当前路线从 G26 工程架构结构准备继续。历史候选名称不得覆盖后续审计确认的阶段目标。

G20 是 docs-only knowledge governance，不实现 Asset Contract、Warehouse、Settlement、Objective、Gacha 或 gameplay，不运行 Godot。

## 建议路线

| 阶段 | 建议名称 | 建议目标 | 启动状态 |
| --- | --- | --- | --- |
| G20 | 项目知识治理与设计资料入库 | design source 文本入库、project governance、stage summaries、route analysis、system boundary/dependency maps | 已完成并 fast-forward 合并 main |
| G21 | Asset Contract Foundation | 建立资产/物品/奖励/标签/策略的最小 public contract，与现有 ledger 和 future long-term shell 对齐 | R3 complete at `29a68e7b093ae653be212e32eb97042c0a7c0a4c`; R4 Godot headless project-load/parser smoke PASS; R4B / first main commit `fdadd78ccdf1d61378ac93a74cfe26449e47c411`; merged main |
| G18-align | Deploy Prep Asset Attendance Alignment | 校准出发探索资产出勤视角、二级标签、卡片详情、深层跳转、开始/继续/放弃强确认口径 | 已完成并纳入历史基线；first main / closeout `70d3735a3ed49dec31ce5a6de73cfdf0829885eb` |
| G22 | Deploy Prep Full Module Content Preview | 建立出发探索完整模块内容预览；保持 preview-only / display-only / read-only | 已完成；first main / closeout `a4fb21e618d348161aa46e2099fa5a1c0f95da4f` |
| G23 | Settlement / History Snapshot Foundation | 建立结算结果与历史快照 foundation，连接 run result summary 与长期展示 | 已完成；first main / closeout `85bf697d09147c7d92268dee4d4b6f51643155a7` |
| G24 | LongTerm Content Framework Foundation | 建立长期系统六模块内容框架、二级分组、preview cards、Objective / Reward / Gacha / Collection preview slots 与 UI/art/data key reservation | 已完成；first main / closeout `8502c2dee4b0a9736f7f9be51a4ea19bc77330cd` |
| G25 | UI Structure Stabilization & Playable Route Recovery | 恢复当前可玩入口并稳定 MainMenu / DeployPrep / LongTerm / Settings 的 UI 结构与可读性 | 已完成；final `main` / `origin/main` 为 `17f8406dcf745f81c829e78478663bec6cbd4e68` |
| G26 | Engineering Architecture Structure Readiness Foundation | 收束 core / ui / preview / contract / content / validation / docs 职责边界，形成后续精确 allowlist 与审查基础 | completed / historical；no longer not started or placeholder |
| G27A | Asset Domain / Warehouse View Contract Foundation | docs-only asset-domain / warehouse-view contract; no real warehouse, asset write, reward, gacha, settlement, or persistence | current split slice; G27B/G27C future candidates; Objective / Reward / Pool deferred to G28 or later |

## 阶段门禁

每个后续阶段都必须独立完成：

- 审计：确认前置事实、代码边界、文档边界和安全边界。
- 计划：明确目标、非目标、文件范围、验证范围。
- 执行：只实现该阶段授权切片。
- 验收：区分 static validation、parser smoke、gameplay runtime PASS、manual playtest PASS。
- 合并：单独记录 branch/head/main/remote 状态。

## G21 执行状态

- G21-R3 已完成 Asset & Item Flow Contract Foundation，只做 schema / constants / default / normalize / validate / projection schema。
- G21-R4 已通过 Godot headless project-load/parser smoke PASS，且 smoke 后工作区 clean、无 dirty 副作用。
- G21 已 fast-forward 合并 main，main 首次包含 G21 的提交为 `fdadd78ccdf1d61378ac93a74cfe26449e47c411`。
- G21-R5 已完成设计一致性校准：Base Docs 全量一致性审计未发现 P0，但存在 P1/P2 设计口径与 foundation 完成度问题。
- 历史记录（G21-R5 当时状态）：G22 尚未启动。该状态已被后续 G22 完成记录取代。
- G21 不代表真实资产系统、仓库、事件总线、发奖、存档、抽奖、结算、历史战绩、红点或 Policy / Tag 规则引擎已实现。

## 历史记录：G21-R5 路线校准（已被后续完成记录取代）

- 出发探索仍是 foundation，不能误称为完整模块内容。
- 结算报告 / 历史战绩仍缺快照系统。
- 主菜单存在 warehouse 快捷入口口径风险；G17 主菜单仍是 foundation / 部分符合。
- G21 AssetEvent action 口径在代码中保持最小，文档层补充后续动作词：获得、消耗、丢失、转化、出售、入仓、清空、抢救、装备、卸下、加入出勤、移出出勤、解锁、完成、记录。
- 旧长期七模块结构为历史参考，已被长期系统整合案覆盖；当前长期系统按六模块：目标 / 图鉴 / 研究 / 个人资历 / 抽奖 / 收藏外观。
- 旧“天赋”页签或旧 UI 页签表述为历史参考；出发探索当前按：地图 / 仓库 / 申领 / 出勤配置 / 作业许可。
- 旧 G21/G22 排序为历史参考；当前以 G20+ roadmap 与本一致性校准后的路线为准。
- G22 前应先做 G18-align：出发探索资产出勤视角、二级标签、卡片详情、深层跳转、开始/继续/放弃强确认口径。
- 不得直接进入完整仓库、长期系统扩展、抽奖、奖励领取、结算历史实现。

## 禁止误读

- G20 不代表 Asset Contract 已启动；G21 是后续独立分支阶段。
- G21-R4 smoke PASS 不代表 complete gameplay runtime PASS 或 manual playtest PASS。
- G18 DeployPrepShell 不代表真实 Warehouse 或 Deploy persistence。
- G18-align 不代表真实仓库、真实出发消耗、真实结算历史或 RunScene 启动。
- G19 LongTermShell 不代表真实长期系统、资产系统、MetaProgress 或 gacha。
- 任何 `Godot headless project-load/parser smoke PASS` 都不能写成 complete gameplay runtime PASS 或 manual playtest PASS。
## G18-align-R4B Closeout Update

G18-align-R2 is complete at `55a048e7419a890cc899bdbd7fae4db4431ddacf`, and G18-align-R3 acceptance passed with Godot headless project-load/parser smoke PASS. This validates only the pre-G22 deploy prep alignment slice: asset attendance view, right-side summary, and start / continue / abandon strong-confirmation preview. It does not start G22 and does not implement complete deploy prep, complete warehouse, real asset writes, event bus, reward grant, persistence, or real RunScene start / continue / abandon logic.

## G18-align-R2 Execution Update

G18-align-R2 is now the active pre-G22 implementation slice on `godot/g18-align-deploy-prep-asset-view`. It narrows the next route to Deploy Prep asset attendance view alignment: secondary labels, card details, right-side summary, and start/continue/abandon strong-confirmation preview. It does not start G22 and does not implement complete warehouse, real asset writing, event bus, reward claim, persistence, or real exploration execution.
## G18-align Final Main Merge Calibration

- G18-align has been fast-forward merged to `main`.
- First `main` commit containing G18-align: `70d3735a3ed49dec31ce5a6de73cfdf0829885eb`.
- G18-align-R2 implementation commit: `55a048e7419a890cc899bdbd7fae4db4431ddacf`.
- G18-align-R4B closeout commit: `70d3735a3ed49dec31ce5a6de73cfdf0829885eb`.
- G18-align-R3 recorded Godot headless project-load/parser smoke PASS only.
- This is not gameplay runtime PASS and not manual playtest PASS.
- Historical / superseded note: at that time G22 remained not started; later G22 records supersede this line.
- The next step remains closeout / new-conversation handoff unless a later user instruction starts a new stage.

## G22 Final Main Merge Calibration

- G22 Deploy Prep Full Module Content Preview has been fast-forward merged to `main`.
- G22 branch: `godot/g22-deploy-prep-full-module-content-preview`.
- G22 implementation commit: `bd1ce6373c4332d04d7262474ed6055a24698096`.
- G22 closeout docs commit: `a4fb21e618d348161aa46e2099fa5a1c0f95da4f`.
- First `main` commit containing G22: `a4fb21e618d348161aa46e2099fa5a1c0f95da4f`.
- G22-R3 static validation PASS.
- G22-R3 Godot headless project-load/parser smoke PASS.
- Final merge did not run a new Godot smoke; it keeps the G22-R3 smoke record.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.

## G23 Final Main Merge Calibration

- G23 has been fast-forward merged to `main`.
- G23 branch: `godot/g23-settlement-history-snapshot-foundation`.
- G23 implementation commit: `f20ddf60513f17ef72afe8e5c99a4e1a22fccd0e`.
- G23 closeout docs commit: `85bf697d09147c7d92268dee4d4b6f51643155a7`.
- First `main` commit containing G23: `85bf697d09147c7d92268dee4d4b6f51643155a7`.
- G23-R3 static validation PASS.
- G23-R3 Godot headless project-load/parser smoke PASS.
- G23 remains settlement/history snapshot foundation only and not real settlement, history persistence, reward grant, asset write, event bus, SaveManager, RunScene ending flow, complete LongTerm, complete Warehouse, or complete Gacha.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.
- G22 remains preview-only / display-only / read-only and is not a real warehouse, real asset system, real claim purchase, real RunScene start / continue / abandon, real map generation, real settlement, real persistence, real reward grant, real gacha, or a complete long-term system.

## G23-R3 Closeout Update

- G23 Settlement / History Snapshot Foundation is complete on branch `godot/g23-settlement-history-snapshot-foundation`.
- G23 implementation commit: `f20ddf60513f17ef72afe8e5c99a4e1a22fccd0e`.
- G23-R3 static validation PASS.
- G23-R3 Godot headless project-load/parser smoke PASS.
- G23 adds settlement/history snapshot schema and LongTerm personal profile / history display-only preview consumption.
- G23 does not implement real settlement, real history persistence, reward grant, asset mutation, resource economy, event bus, SaveManager, RunScene ending flow, complete LongTerm, complete Warehouse, or complete Gacha.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.

## G24-R3 Closeout Update

- G24 LongTerm Content Framework Foundation is complete on branch `godot/g24-long-term-content-framework-foundation`.
- G24 implementation commit: `02c2e577787a49ce4cbed173482a7acc31fa2bc9`.
- G24-R3 static validation PASS.
- G24-R3 Godot headless project-load/parser smoke PASS.
- `D:\AGAME1\Connection\Program\G24_LongTerm_Content_Framework_Art_Request.md` was written as an external program-to-art request and was not committed.
- G24 remains foundation-only: six-module content framework, secondary groups, preview cards, Objective / Reward / Gacha / Collection preview slots, and UI / art / data key reservation.
- G24 is not complete LongTerm, real targets, real rewards, real gacha, real red dots, real SaveManager, real asset writes, complete Warehouse, or complete Gacha.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.

## G24 Final Main Merge Calibration

- G24 has been fast-forward merged to `main`.
- G24 branch: `godot/g24-long-term-content-framework-foundation`.
- G24 implementation commit: `02c2e577787a49ce4cbed173482a7acc31fa2bc9`.
- G24 closeout docs commit: `8502c2dee4b0a9736f7f9be51a4ea19bc77330cd`.
- First `main` commit containing G24: `8502c2dee4b0a9736f7f9be51a4ea19bc77330cd`.
- G24-R3 static validation PASS.
- G24-R3 Godot headless project-load/parser smoke PASS.
- `D:\AGAME1\Connection\Program\G24_LongTerm_Content_Framework_Art_Request.md` was written as an external program-to-art request and was not committed.
- G24 remains foundation-only and not complete LongTerm, real rewards, real gacha, real red dots, real SaveManager, real asset writes, complete Warehouse, or complete Gacha.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.
