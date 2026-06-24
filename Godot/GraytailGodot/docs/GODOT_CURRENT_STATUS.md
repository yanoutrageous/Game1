# G34 Rule Effect Modifier Content Delivery Status

G34-R2 is the current implementation slice on branch `godot/g34-rule-effect-modifier-content-delivery`.

- Scope: Rule / Effect / Modifier & Content Delivery Common System.
- Product contract: `docs/20_product/RULE_EFFECT_MODIFIER_CONTENT_DELIVERY_COMMON_SYSTEM_CONTRACT.md`.
- Godot scope: `RuleEffectModifierSchema`, `ContentDeliverySchema`, `RunRulePipeline` preview summaries, `RunRuleService` result previews, `ContentDefRegistry` pool previews, `RunQueryFacade` public snapshot output, RunFlow / Settlement preview handoff, RunSurface / HUD display-only consumers.
- Boundary: read_only / display_only / preview / no_persistence.
- Not implemented: complete Rule engine runtime, script language, AI Director, real rewards, real drops, objective progress, map mutation runtime, persistence, AssetLedger / RunAssetLedger long-term writes, CommandBus mutation, gameplay runtime, manual playtest.
- G34-R2 static validation PASS.
- G34-R2 Godot headless project-load/parser smoke PASS.
- Godot smoke produced no new metadata dirty side effects.
- Parser smoke is project-load/parser only and not gameplay runtime PASS or manual playtest PASS.

# G33 Room Type Tag Encounter Common Rule Status

G33-R2 is the current implementation slice on branch `godot/g33-room-type-tag-encounter-common-rule`.

- Scope: Room Type / Tag / Encounter Common Rule Full Content.
- Product contract: `docs/20_product/ROOM_TYPE_TAG_ENCOUNTER_COMMON_RULE_CONTRACT.md`.
- Godot scope: RoomEncounterCommonRuleSchema, TruthMap room common-rule snapshots, EncounterResolver preview fields, RunFlow room resolution handoff, Settlement / RunSurface / HUD display-only consumers.
- Boundary: read_only / display_only / preview / no_persistence.
- Not implemented: battle runtime, monster AI, event-chain runtime, RoomLoot/GroundLoot runtime, real in-run backpack, Rule/Modifier engine, objective progress, reward grant, settlement warehouse write, SaveManager, AssetLedger / RunAssetLedger mutation, CommandBus mutation, gameplay runtime, manual playtest.
- G33-R2 static validation PASS.
- G33-R2 Godot headless project-load/parser smoke PASS.
- Godot smoke produced no new metadata dirty side effects.
- This is project-load/parser only and not gameplay runtime PASS or manual playtest PASS.

# G32 Run Flow State Transition Status

G32-R2 is the current implementation slice on branch `godot/g32-run-flow-state-transition-full-content`.

- Scope: Run Flow & State Transition Full Content.
- Product contract: `docs/20_product/RUN_FLOW_STATE_TRANSITION_FULL_CONTENT_CONTRACT.md`.
- Godot scope: `RunFlowStateContract`, `RunQueryFacade` run-flow snapshot output, DeployPrep bounded route bridge, AppShell handoff, RunSurface / HUD display-only snapshot consumers, Settlement trigger/outcome/result draft preview.
- Boundary: read_only / display_only / preview / no_persistence.
- Not implemented: SaveManager, active-run persistence, real continue recovery, real abandon settlement, warehouse write, reward grant, objective progress, complete Rule / Modifier engine, RoomLoot runtime, CommandBus command-list change, gameplay runtime, manual playtest.
- G32-R2 static validation PASS.
- G32-R2 Godot headless project-load/parser smoke PASS.
- Godot smoke produced no new metadata dirty side effects.
- This is project-load/parser only and not gameplay runtime PASS or manual playtest PASS.

# G31 Run Map Room State Status

G31-R2 is the current implementation slice on branch `godot/g31-run-map-room-state-foundation`.

- Scope: Run Map Domain / Room State Foundation.
- Product contract: `docs/20_product/RUN_MAP_DOMAIN_ROOM_STATE_FOUNDATION_CONTRACT.md`.
- Godot scope: TruthMap / IntelMap / RunQueryFacade map snapshot output, settlement map-facing preview, minimap / run surface / HUD display-only snapshot consumers.
- Boundary: read_only / display_only / preview / no_persistence.
- Not implemented: complete RunFlow, persistence, battle runtime, event chains, RoomLoot runtime, objective progress, reward grant, settlement warehouse write, SaveManager, AssetLedger / RunAssetLedger mutation, CommandBus mutation, gameplay runtime, manual playtest.
- G31-R2 static validation PASS.
- G31-R2 Godot headless project-load/parser smoke PASS after a local `IntelMap.build_public_cell` explicit `Dictionary` type hotfix.
- Godot smoke produced no new metadata dirty side effects.
- This is project-load/parser only and not gameplay runtime PASS or manual playtest PASS.

# G30 LongTerm Asset Interface Status

G30-R2 is the current implementation slice on branch `godot/g30-long-term-asset-interface-full-content`.

- Scope: LongTerm system integration and asset interface full content.
- Product contract: `docs/20_product/LONG_TERM_SYSTEM_ASSET_INTERFACE_FULL_CONTENT_CONTRACT.md`.
- Godot scope: LongTerm preview model/schema/UI, asset-domain RewardBundle/event/red-dot/jump helpers, Settlement and DeployPrep display-only consumer alignment.
- Boundary: preview_only / display_only / read_only / no_persistence.
- Not implemented: real LongTerm backend, objective progress, reward claim/grant, gacha odds/roll/result, red dot clearing, asset write, SaveManager, AssetLedger mutation, CommandBus mutation, gameplay runtime, manual playtest.
- G30-R2 Godot headless project-load/parser smoke PASS was recorded for project-load/parser only; this is not gameplay runtime PASS or manual playtest PASS.

# G26 Engineering Architecture Structure Readiness

Current G26 direction is Engineering Architecture Structure Readiness Foundation.

- G25 final `main` / `origin/main`: `17f8406dcf745f81c829e78478663bec6cbd4e68`.
- G25 UI Structure Stabilization & Playable Route Recovery is complete.
- G26-R1 audit result: PASS with preconditions.
- G26-R2A changes documentation only and prepares a reviewable architecture workspace.
- Objective / Reward / Pool Contract Foundation is deferred to G27 or a later functional stage.
- The Godot line prepares formal system skeletons, public contracts, interfaces, content boundaries, and validation seams.
- The Lua line remains responsible for gameplay hypothesis validation.
- G26 does not add Godot scripts, scenes, resources, imports, runtime wiring, SaveManager, AssetLedger behavior, CommandBus behavior, objectives, rewards, pools, gacha, warehouse, or playable prototype v1.
- `project.godot`, `asset_manifest.*.translation`, first-real bundle files, and independent governance files remain protected and unabsorbed.
- No Godot run was performed for G26-R2A. No gameplay runtime PASS or manual playtest PASS is claimed.

# G25 Final Main Merge Status

G25 UI Structure Stabilization & Playable Route Recovery has been fast-forward merged to `main`.

- G25 branch: `godot/g25-ui-structure-playable-route`.
- G25 implementation commit: `ae6f2ab6abd50b51c6f8f600cb8f5cda1cda7462`.
- G25 closeout docs commit: `022d3f74e9982fffae62e174df04b8f8f55a8958`.
- First `main` commit containing G25: `022d3f74e9982fffae62e174df04b8f8f55a8958`.
- `main` now contains the G25 implementation and closeout docs.
- G25-R3b static validation PASS.
- G25-R3b Godot headless project-load/parser smoke PASS.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.

G25 remains UI structure / route semantics work only. It does not implement real warehouse, rewards, settlement, gacha, objectives, red dots, SaveManager, asset writes, real LongTerm backend, real settings, or art import. Its historical next-step wording is superseded by the G26-R1 audit and current G26 architecture-readiness direction.

# G25-R3b Closeout Status

G25 UI Structure Stabilization & Playable Route Recovery is complete on branch `godot/g25-ui-structure-playable-route`.

- G25 implementation commit: `ae6f2ab6abd50b51c6f8f600cb8f5cda1cda7462`.
- Static validation PASS.
- Godot headless project-load/parser smoke PASS.
- Godot smoke produced no new dirty side effects.
- `D:\AGAME1\Connection\Program\G25_UI_Structure_Stabilization_Notice.md` exists outside the repository and is not committed.

G25 adds the main-menu `快速开始 / Demo Run` current playable route entry through existing AppShell / NavigationIntent / PageRouter run route. DeployPrep remains preview-only, LongTerm avoids raw Dictionary / JSON main output, and Settings remains a reduced placeholder. G25 does not implement real warehouse, rewards, settlement, gacha, objectives, red dots, SaveManager, asset writes, real LongTerm backend, real settings, or art import. No gameplay runtime PASS or manual playtest PASS is claimed.

# G24 Final Main Merge Status

G24 LongTerm Content Framework Foundation has been fast-forward merged to `main`.

- G24 branch: `godot/g24-long-term-content-framework-foundation`.
- G24 implementation commit: `02c2e577787a49ce4cbed173482a7acc31fa2bc9`.
- G24 closeout docs commit: `8502c2dee4b0a9736f7f9be51a4ea19bc77330cd`.
- First `main` commit containing G24: `8502c2dee4b0a9736f7f9be51a4ea19bc77330cd`.
- G24-R3 static validation PASS.
- G24-R3 Godot headless project-load/parser smoke PASS.
- `D:\AGAME1\Connection\Program\G24_LongTerm_Content_Framework_Art_Request.md` was written as an external program-to-art request and was not committed.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.

G24 remains preview-only / display-only / read-only foundation. It is not complete LongTerm, real tasks, real rewards, real gacha, real red dots, real SaveManager, real asset writing, complete Warehouse, or complete Gacha.

# G24-R3 Closeout Status

G24 LongTerm Content Framework Foundation is complete on branch `godot/g24-long-term-content-framework-foundation`.

- G24 implementation commit: `02c2e577787a49ce4cbed173482a7acc31fa2bc9`.
- G24-R3 static validation PASS.
- G24-R3 Godot headless project-load/parser smoke PASS.
- `git diff --check` had no whitespace error; LF/CRLF warnings only.
- Godot smoke produced no new dirty side effects.
- `D:\AGAME1\Connection\Program\G24_LongTerm_Content_Framework_Art_Request.md` was written as an external program-to-art request and was not committed.

G24 adds LongTerm six-module content framework, secondary groups, preview cards, Objective / Reward / Gacha / Collection preview slots, and UI / art / data key reservation. It remains preview-only / display-only / read-only and does not implement real task systems, achievements, commissions, reward claiming, claim, red dot clearing, gacha probability / pity / cost / result grant, cosmetic configuration, unique collectible acquisition, codex unlock, research unlock, profile progression, history writes, SaveManager, event bus, asset writes, complete LongTerm, complete Warehouse, or complete Gacha. Gameplay runtime and manual playtest were not run and are not claimed as PASS.

# G23 Final Main Merge Status

G23 Settlement / History Snapshot Foundation has been fast-forward merged to `main`.

- G23 branch: `godot/g23-settlement-history-snapshot-foundation`.
- G23 implementation commit: `f20ddf60513f17ef72afe8e5c99a4e1a22fccd0e`.
- G23 closeout docs commit: `85bf697d09147c7d92268dee4d4b6f51643155a7`.
- First `main` commit containing G23: `85bf697d09147c7d92268dee4d4b6f51643155a7`.
- G23-R3 static validation PASS.
- G23-R3 Godot headless project-load/parser smoke PASS.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.

G23 remains foundation-only. It does not implement real settlement, history persistence, reward grant, asset write, event bus, SaveManager, RunScene ending flow, complete LongTerm, complete Warehouse, or complete Gacha.

# G23-R3 Closeout Status

G23 Settlement / History Snapshot Foundation is complete on branch `godot/g23-settlement-history-snapshot-foundation`.

- G23 implementation commit: `f20ddf60513f17ef72afe8e5c99a4e1a22fccd0e`.
- G23-R3 static validation PASS.
- G23-R3 Godot headless project-load/parser smoke PASS.
- `git diff --check` had no whitespace error; LF/CRLF warnings only.
- Godot smoke produced no new dirty side effects.

G23 adds settlement/history snapshot schemas and LongTerm personal profile / history display-only preview consumption. It does not implement real settlement report UI, reward grant, asset return/loss/conversion, gold or black coin economy, consumable clearing, history persistence, profile progression, red dots, event bus, SaveManager, RunScene ending flow, complete LongTerm, complete Warehouse, or complete Gacha. Gameplay runtime and manual playtest were not run and are not claimed as PASS.

# G22 Final Main Merge Status

G22 Deploy Prep Full Module Content Preview has been fast-forward merged to `main`.

- G22 branch: `godot/g22-deploy-prep-full-module-content-preview`.
- G22 implementation commit: `bd1ce6373c4332d04d7262474ed6055a24698096`.
- G22 closeout docs commit: `a4fb21e618d348161aa46e2099fa5a1c0f95da4f`.
- First `main` commit containing G22: `a4fb21e618d348161aa46e2099fa5a1c0f95da4f`.
- G22-R3 static validation PASS.
- G22-R3 Godot headless project-load/parser smoke PASS.
- Final merge did not run a new Godot smoke; it keeps the G22-R3 smoke record.
- Gameplay runtime was not run, and no gameplay runtime PASS is claimed.
- Manual playtest was not run, and no manual playtest PASS is claimed.

G22 remains preview-only / display-only / read-only. It does not implement real asset writes, real warehouse, real claim purchase, real RunScene start / continue / abandon, real map generation, real settlement, real persistence, real reward grant, real gacha, or a complete long-term system.

# G22-R4B Branch Closeout

G22 Deploy Prep Full Module Content Preview is complete on branch `godot/g22-deploy-prep-full-module-content-preview`.

- G22-R2 implementation commit: `bd1ce6373c4332d04d7262474ed6055a24698096`.
- G22-R3 static validation PASS.
- G22-R3 Godot headless project-load/parser smoke PASS.
- `git diff --check` had no whitespace error; LF/CRLF warnings only.
- Smoke produced no new dirty side effects.
- R4B did not run a new Godot smoke.
- R4B did not merge main and did not push.

This is not gameplay runtime PASS and not manual playtest PASS. G22 remains preview-only / display-only / read-only and does not implement real asset writes, real warehouse, real claim purchase, real RunScene start / continue / abandon, real map generation, real settlement, real persistence, real reward grant, real gacha, or a complete long-term system.

# GODOT_CURRENT_STATUS

## G18-align-R4B Closeout

G18-align-R2 commit: `55a048e7419a890cc899bdbd7fae4db4431ddacf`.

G18-align-R3 acceptance passed with Godot headless project-load/parser smoke PASS. The smoke run left the working tree clean with no dirty side effects.

Historical G18-align closeout record: this stage only aligned DeployPrep asset attendance view, right-side summary, and start / continue / abandon strong-confirmation preview. At that time G22 had not started; this status is superseded by the later G22 completion record.

## Historical G18-align-R2 Batch (Superseded)

Branch: `godot/g18-align-deploy-prep-asset-view`.

G18-align-R2 updates only the DeployPrep foundation UI/model/config layer. It adds asset attendance view wording, secondary labels, card list/detail preview, right-side summary/config/effect/risk preview, start/continue/abandon strong-confirmation preview, and read-only deploy prep projection shape from G21.

This is not complete deploy prep, not complete warehouse, not real asset writes, not event bus, not reward grant, not persistence, not real exploration start/continue/abandon, and not G22. Godot is not run in R2; parser smoke is deferred to acceptance.

## Updated

`2026-06-16`

## Branch

Current G21 branch: `godot/g21-asset-item-flow-contract`.

G21-R3 baseline main HEAD: `4bb4594fc23b846da9c15003a86c71cf08003830`.

G21-R3 commit: `29a68e7b093ae653be212e32eb97042c0a7c0a4c`.

G21-R4B closeout commit / first main commit containing G21: `fdadd78ccdf1d61378ac93a74cfe26449e47c411`.

G21-R3 adds Asset & Item Flow Contract Foundation under `Godot/GraytailGodot/scripts/core/asset/`: `AssetContract`, `ItemSchema`, `AssetEventSchema`, and `AssetProjectionSchema`. It is schema, constants, default helpers, normalize helpers, validate helpers, and read-only projection schema only.

G21 does not implement real asset systems, warehouse, inventory, event bus, reward grant, persistence, gacha, settlement/history, red dot state, or Policy / Tag rule engine. It does not modify DeployPrepShell, DeployConfig, LongTermShell, LongTermSnapshot, RunAssetLedger, AssetCatalog, run_scene, CommandBus, project.godot, scenes, resources, `.uid`, `.translation`, or Base Docs.

Historical G21 closeout record: G21-R4 acceptance passed with parser smoke PASS and G21 was merged. At that time G22 had not started; this status is superseded by the later G22 completion record.

Historical G21-R5 route record: the next recommended step was G18-align before G22. That route was subsequently executed; current route authority is the G26 section at the top of this document.

Historical stage record (superseded): G20 Project Knowledge Governance was docs-only and merged at `ae689b7464fd6ea81a763110cd89813abcfb6665`. Current stage authority is the G26 section at the top of this document.

G18 DeployPrepShell / DeployConfig / RunStartConfig foundation has R4 acceptance, Godot headless project-load/parser smoke PASS, docs-only closeout, fast-forward main merge, and post-merge docs calibration complete. Scope remains deploy prep placeholder tabs, right-side summary, public config preview, and AppShell deploy route integration; it does not start RunScene or write persistence. G17 AppShell / NavigationIntent / PageRouter / MainMenuShell foundation is complete, parser-smoke checked, and fast-forward merged to `main`.

Main HEAD at start of Post-G16 architecture direction import: `9af74aeefd3a28b6b417fa0667532737cddc916b docs: mark G16 merged to main`.

Current main HEAD after G17 fast-forward and before this post-merge status commit: `baa57fa41167c86ad226b5b8be4d540ff114269f`.

G18-R3 baseline main HEAD: `eeffe5800864c05f8b000e406609fa7ca3323cb5 docs: mark G17 merged to main`.

G18-R3 implementation commit: `59ea57caf1baa977e727da2697cac014cbd7429e feat(godot): add deploy prep shell foundation`.

G18 closeout / merge baseline: `285695cda0141322b0672d65998f3d3f9aa32654 docs: close G18 deploy prep foundation`.

G18 merged to main: yes, by fast-forward.

G19 branch: `godot/g19-long-term-shell-foundation`.

G19 baseline main HEAD: `0e44c261f399a197d6e6eec277eb51ce72e1ba8c docs: mark G18 merged to main`.

G19-R3 commit: `4eeb345daef5f8263b325db2ab5607e6c78f6d36 feat(godot): add long term shell foundation`.

G19-R4B status: self-check PASS, Godot headless project-load/parser smoke PASS, docs-only closeout complete on branch.

G19 merged to main: yes, by fast-forward. First main merge baseline: `04e14865f4d5eff7b16398d5730054273ccd0823`.

G20 docs-only governance branch: `godot/g20-project-knowledge-governance`. R3a imported authorized text design source copies under `docs/design_sources/`; Base Docs originals were not modified; PNG files were not imported and remain `external_reference` / `pending_user_authorization`; R3b adds project governance maps and design source indexes; R3c adds G10-G19 stage summaries, route analysis, system boundary map, and stage dependency map; R3d1 adds branch, commit, and validation governance matrices under `docs/project_governance/`; R3d2 adds decision log, glossary, and temporary / deprecated inventory under `docs/project_governance/`; R4A read-only acceptance passed; R4B docs-only closeout is complete. G20 is fast-forward merged to main, G20 final has executed, G21 completed separately and is now merged to main, and no Godot project, scene, resource, font, import product, `.uid`, or `.translation` change is part of G20 R3a/R3b/R3c/R3d1/R3d2/R4A/R4B/final.

G20-R4B closeout commit / first main merge baseline: `ae689b7464fd6ea81a763110cd89813abcfb6665`. G20 final post-merge docs commit: pending until commit.

G20-R3a/R3b/R3c/R3d1/R3d2/R4A/R4B/final Godot run status: not run. No Godot headless project-load/parser smoke PASS, gameplay runtime PASS, or manual playtest PASS is claimed for these docs-only batches.

G19 modules: 目标、图鉴、研究、个人资历、抽奖、收藏 / 外观.

G17-R2 commit: `368a7be5c2fb919db47421a026ddf417df9c1b1c feat(godot): add app shell main menu foundation`.

G17-R3 closeout commit: `baa57fa41167c86ad226b5b8be4d540ff114269f docs: close G17 app shell main menu foundation`.

G17 merged to main: yes, by fast-forward.

G16 baseline main HEAD before R3: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`.

G16-R3 branch: `godot/g16-combat-encounter-foundation`.

G16-R3 commit: `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a feat(godot): add combat encounter foundation`.

G16-R4 status: accepted.

G16-R5 status: docs-only branch closeout.

G16 parser blocker fix commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071 fix(godot): expose encounter parser classes`.

G16 merged to main: yes, by fast-forward.

G15 post-merge status commit: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`.

Current G15 branch HEAD before R5 closeout: `1887385af81624ebcd84342ca765d75e6fbf20eb`.

G15 branch closeout commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad docs: close G15 encounter framework foundation`.

Main HEAD after G15 fast-forward and before post-merge status commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad`.

G15-R3 commit: `aca5b95 feat(godot): add encounter contract foundation`.

G15-R4 commit: `1887385 feat(godot): add encounter slot surface adapter`.

G15 branch merged to main: yes, by fast-forward.

G14-R3 baseline before implementation: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`.

Closed G10 branch: `godot/g10-progress-art-smoke-foundation` at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.

G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.

G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`.

G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`.

G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`.

G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`.

G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`.

G13 baseline commit: `e90bd27 docs: close G12 legacy demo parity pass`.

G13-R3 commit: `5afdb05 feat(godot): add fixed resolution layout support`.

G13 closeout commit: `8878bd3 docs: close G13 resolution layout adaptation pass`.

G14-R3 commit: `1d33c89 feat(godot): add legacy demo run surface shell`.

G14-R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`.

G14-R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`.

G14 parser hotfix commit: `fc2b86b fix(godot): resolve RunSurface parser type inference`.

G14 closeout commit: `d6c03c6 docs: close G14 legacy demo UI surface pass`.

Current fact source: `docs/PROJECT_BASELINE.md`.

Next-chat entry: `docs/NEXT_HANDOFF.md`.

Docs index: `docs/DOCS_INDEX.md`.

Milestone map: `docs/MILESTONES.md`.

G20-R3d1 governance matrices: `docs/project_governance/BRANCH_INVENTORY.md`, `docs/project_governance/COMMIT_MILESTONE_MAP.md`, and `docs/project_governance/VALIDATION_STATUS_MATRIX.md`.

G20-R3d2 governance documents: `docs/project_governance/DECISION_LOG.md`, `docs/project_governance/GLOSSARY.md`, and `docs/project_governance/TEMP_AND_DEPRECATED_INVENTORY.md`.

G20-R4B closeout documents: `docs/validation/G20_PROJECT_KNOWLEDGE_GOVERNANCE_VALIDATION.md` and `docs/handoff/HANDOFF_G20_PROJECT_KNOWLEDGE_GOVERNANCE.md`.

Planning source originals still live under `D:\AGAME1\Base Docs`; `docs/可行性判断.md` and `docs/难度判断.md` were moved there by the user and their repository deletions are authorized docs relocation deletions. G20-R3a imported authorized Markdown / TXT copies into `docs/design_sources/`; external Base Docs originals and PNG references were not modified by R3b.

G9 UI final integration branch: `godot/g9-ui-final-integration`.

G8.2 hardening branch: `godot/g8-2-kernel-protocol-hardening`.

G8.1 hardening branch: `godot/g8-1-architecture-hardening`.

G8 rules branch: `godot/g8-rules-asset-ledger-core`.

Base branch: `main`.

G8.2 base main commit: `91ddf591b04923520834e72eab99a8b6d8702aa4`.

Implementation baseline commit before documentation closure: `f2dd365cca153793883960caa3ba26f5b959ba9b`.

G8 documentation closure commit: `717728087eea2bdabd3a9c031b0f2698cdb5737e`.

## Current Capability

- Tutorial P0 mode remains a 5x5 fixed Lua-derived map.
- Standard P0 mode remains a 10x10 generated map.
- TruthMap stores real map state.
- IntelMap stores player-known public state only.
- CommandBus remains the only player and Debug UI command entry.
- HUD, MiniMap, MapOverlay, TutorialPopup, and ResultPanel consume snapshots/ViewModels.
- AssetCatalog and ContentDB load assets through `data/assets/asset_manifest.csv`.
- PresentationMapping and PresentationTheme isolate asset ids, labels, hints, colors, and visual roles from core rules.
- G5 migrated a first audited asset batch for minimap icons, HUD panels, player idle sprites, room backgrounds, and room props.
- G6 separates map room coordinates from room-local player coordinates.
- G7 adds the main menu shell, read-only deploy shell foundation, run layout, event option panel, loot result panel, and extraction confirmation panel.
- G8 adds a run-scoped `RunAssetLedger` and `RunRuleService` for asset rules.
- `black_coin` and `gold_coin` are available through ledger currency definitions and snapshot outputs.
- Item instances carry `location_state`, `room_pos`, rarity, weight, value state, and source data.
- Ground loot is tracked per room through `room_floor_items`.
- Pickup/drop commands are exposed through CommandBus.
- Pickup checks backpack capacity and returns `blocked_capacity` when full.
- Equipment, consumable, Buff/Debuff, rarity, and `unique` hooks are reserved in the rules layer.
- Success settlement converts black coin to gold coin and routes eligible inventory/equipped items to Warehouse Lite.
- Failure settlement loses black coin, keeps gold coin, sends eligible inventory/equipped items through salvage, and loses room floor items by default.
- G7 compatibility mirrors remain available through `pending_gold`, `safe_gold`, `parts`, and `carried_items`.
- G8.1 adds `RunQueryFacade` as the status/result snapshot boundary.
- G8.1 routes asset-related effects through `RunAssetEffectHandler`; `RunAssetLedger` remains the single asset state owner.
- G8.1 normalizes `RunRuleService` results as `RuleResult` dictionaries with `EffectSpec` entries.
- G8.1 normalizes CommandBus command envelopes with `command_id`, `actor_id`, `source`, `payload`, and `sequence`.
- G8.1 adds `RunRuleContent` as the minimal content-definition fallback for rule rewards.
- G8.1 reserves `SaveAdapter` and `MetaProgressAdapter` as contract-only boundaries without storage writes.
- G8.2 makes `CommandBus.dispatch` the formal UI/debug command entry.
- G8.2 adds `CommandResult` for accepted/rejected command output and blocked reason propagation.
- G8.2 adds `RunEventLog` for fact-only domain events.
- G8.2 adds `RunTransactionLog` for asset transaction audit records.
- G8.2 standardizes EffectSpec correlation fields: `effect_id`, `command_id`, and `rule_request_id`.
- G8.2 reserves `RunRulePipeline` and `RunModifierSpec` for deterministic rule modification.
- G8.2 reserves `ContentDefRegistry` for CurrencyDef, ItemDef, EncounterDef, EffectDef, ModifierDef, and LootTableDef.
- G8.2 exposes event log, transaction log, and ContentDef snapshots through `RunQueryFacade`.
- G9 UI presentation layering revision reserves a fixed base background plus independent Presentation Overlay layers.
- G9 keeps map theme, character outfit, scene props, foreground effects, and panel skins outside the baked base background.
- `PresentationLayerContracts` provides contract-only schemas and placeholder examples for ThemeProfile, PresentationLayerEntry, CharacterPresentationConfig, OutfitPresentationDef, PanelState, UIVisibilityPolicy, NavigationEntry, ShortcutEntry, ExpeditionSummaryViewModel, and LongTermSummaryViewModel.
- G9 final integration adds a playable three-page UI shell.
- The main page exposes `出发探索`, `长期系统`, and `设置`.
- The expedition page exposes map, warehouse, claim, loadout, talent, character/outfit placeholders, tutorial, standard, and confirm deploy entries.
- The long-term page exposes the G19 six-module shell: 目标、图鉴、研究、个人资历、抽奖、收藏 / 外观. It is placeholder / preview / disabled only and uses display-only interface preview fields.
- InventoryPanel and GroundLootPanel provide formal player pickup/drop flow.
- ResultPanel explains success/failure settlement with EventLog and TransactionLog summaries.
- G10 adds ResultPanel return actions, a run pause/settings overlay, MiniMapPanel click-to-map, MapOverlay action feedback, blocked-reason pulse feedback, dev-only diagnostics gating, manifest/fallback art smoke, and `UILayoutProfile` responsive reservation.
- G11-R3 improves mainline testability and UX readability through manual playtest coverage, clearer MapOverlay feedback, inventory/ground-loot hints, result return tooltips, and Pause/Settings wording. G11-R4 is docs-only closeout and does not continue UI repair.
- G12-R3 aligned the current UI with legacy Demo core-loop feel through Chinese readability, scan/map feedback, protocol/pressure text, loot/settlement wording, and local typography/readability tweaks on existing UI only.
- G13-R3 completed fixed 16:9 resolution tiers, runtime-only display selection, manual apply/reset, resize locking, fixed-tier `UILayoutProfile` fields, and bounded layout adaptation.
- G14 is complete, committed, pushed, and closed by R5. G14-R3 adds `RunSurfaceModel` and `RunSurface` for the first low-fidelity legacy Demo-style run surface while preserving existing panel, routing, and CommandBus paths.
- G14-R4 refines the display surface only: scanner legend/detail, right-side protocol/danger/status lines, bottom action hints, button visual states, legacy-style modal chrome, event / loot / extract display text, and feedback hierarchy.
- G14 parser hotfix `fc2b86b` resolves a `run_surface.gd` GDScript type inference parser error without changing UI behavior or rules.
- G15-R3 adds a rules-layer Encounter contract foundation: `EncounterContract`, `EncounterResolver`, public `encounter_view_model`, public `encounter_result_summary`, and additive `select_encounter_option` for search/chest/event only.
- G15-R4 adds a UI EncounterSlot surface adapter: `RunSurfaceModel` consumes only public encounter snapshot fields, `RunSurface` displays options and emits public option signals, and `run_scene.gd` performs minimal CommandBus wiring for `select_encounter_option`.
- G16-R3 adds the first combat encounter foundation: Monster rooms expose `monster_basic` / `combat_basic` public encounter data, `attack_basic` option data, monster summary, risk/reward preview, and combat result summary. `attack_basic` routes through `select_encounter_option` into the existing deterministic `fight_current_enemy` chain.
- G16-R5 closes branch docs/status; parser blocker fix `4637e8f` makes encounter helper references parser-safe.
- Post-G16 architecture direction baseline records that current architecture has not lost control, G15/G16 Encounter / Combat foundations should be retained, and G17 should focus on `AppShell / NavigationIntent / PageRouter / MainMenuShell` rather than plain main-menu implementation.

Current `main` includes G10 Progress & Art Smoke Foundation, the completed G11 mainline UX readability pass, G11 closeout, the completed G12 lightweight legacy Demo readability/typography pass, G13 fixed resolution layout support and closeout, completed G14 run surface work, G15 Encounter Contract Foundation, G16 Combat Encounter Foundation, G17 AppShell / MainMenuShell foundation, G18 DeployPrepShell / DeployConfig / RunStartConfig foundation, G19 LongTermShell foundation, G20 Project Knowledge Governance docs-only artifacts, and G21 Asset & Item Flow Contract Foundation. G21 is not Warehouse, not gameplay implementation, not gameplay runtime PASS, and not manual playtest PASS.

Design alignment note: old long-term seven-module wording, old "天赋" tab wording, and old G21/G22 ordering are historical references. Current long-term modules are 目标 / 图鉴 / 研究 / 个人资历 / 抽奖 / 收藏外观. Current 出发探索 tab vocabulary is 地图 / 仓库 / 申领 / 出勤配置 / 作业许可.

Post-G17 next structural work requires separate authorization. Main menu should only navigate and present atmosphere/light hints; it must not directly start or continue RunScene. Expedition prep should later output `RunStartConfig / DeployConfig`; long-term systems should later output `PlayerProfileSnapshot / LongTermSnapshot / UnlockSnapshot`; settlement should later return through `RunResultSummary / SettlementAdapter`.

G17 establishes the first AppShell / NavigationIntent / PageRouter / MainMenuShell slice and is fast-forward merged to main. The formal main menu exposes only `出发探索`, `长期系统`, `设置`, and `退出游戏`; expedition, long-term, and settings are placeholder routes in this slice, and exit uses a confirm layer. G17-R3 acceptance and Godot headless project-load/parser smoke PASS are complete. G17 does not implement formal expedition prep, long-term systems, warehouse, codex, lottery, MetaProgress, Deploy persistence, full settings, complete gameplay runtime PASS, or manual playtest PASS.

G18 is fast-forward merged to main. It adds `DeployPrepShell`, `DeployConfig`, and `RunStartConfig` preview support only. The deploy page has five placeholder tabs, right-side summary/config/effect/risk sections, AppShell deploy route integration, and preview-only start intent. Godot headless project-load/parser smoke PASS is recorded, but this is not complete gameplay runtime PASS or manual playtest PASS. G18 does not start or continue RunScene, dispatch run CommandBus, generate real maps, implement warehouse/requisition/work permit rules, settlement reports/history, long-term systems, lottery, MetaProgress, or Deploy persistence.

G19 is fast-forward merged to main and replaces the old long-term placeholder route with `LongTermShell`. It does not implement real goals, task progress, achievement checks, commission acceptance, codex data, research, profile progression, history storage, gacha, collection / appearance equipment, warehouse, asset events, item models, RewardBundle, Policy / Tag rules, red-dot clearing, reward claiming, persistence, MetaProgress, RunScene startup, CommandBus dispatch, or private RunContext / Encounter / Combat / Ledger / TruthMap reads.

G19-R4B smoke produced no `project.godot`, `.tscn`, resource, font, import product, `.uid`, or `.translation` dirty and did not modify Base Docs.

G10 was a bounded stabilization and smoke-foundation stage. It is complete, merged to main, and closed. It does not represent complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.

## UI Boundary

Future UI work should consume:

- `RunContext.get_status_snapshot()`
- result snapshots
- HUD/ViewModel fields
- CommandBus commands
- `CommandResult.reason_code` / `message_key`
- Event and transaction snapshots when audit/debug panels need them
- G9 presentation contract fields for visual layer resolution
- semantic ids such as `theme_id`, `character_id`, `outfit_id`, `risk_level`, and `tracked_objective_id`
- InventoryPanel and GroundLootPanel snapshots
- ResultPanel EventLog and TransactionLog summaries

G14 UI work consumes ViewModel/snapshot data, `MiniMapViewModel`, latest command result data, and existing `UILayoutProfile` data. It must not directly read or write `RunAssetLedger`, `TruthMap`, `RunRuleService`, Ledger private state, or private run-rule state. G14 does not start G15 or any new gameplay/system branch.

If future UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. The rules line must not directly modify UI surface code, and the UI line must not directly read rules private state. High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.

G15 UI boundary: R4 consumes `encounter_view_model` and `encounter_result_summary` through `RunSurfaceModel` display-only data. `RunSurface` only displays EncounterSlot state and emits public option signals; `run_scene.gd` uses minimal CommandBus wiring. UI must not read `TruthMap`, `RunRuleService`, Ledger, `AssetLedger`, `RunAssetLedger`, `RunContext`, or any private rule state, and must not bypass CommandBus.

Presentation work should map semantic ids into ThemeProfile, PresentationLayerEntry, CharacterPresentationConfig, panel skins, and fallback asset ids. Core gameplay should not directly build image paths.

Rules work should extend `RunRulePipeline`, `RunModifierSpec`, and `RunAssetEffectHandler`. Content work should register declarative ContentDef entries. Later persistence work should attach through `SaveAdapter` and `MetaProgressAdapter`.

## Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_architecture_hardening_g8_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_kernel_protocol_g8_2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_ui_presentation_layering_g9.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_ui_final_g9.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_baseline_docs_pre_g10.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_g10_progress_art_smoke.ps1
```

G16 final ran Godot headless project-load/parser smoke and passed; this must not be reported as complete gameplay runtime PASS or manual playtest PASS. G16 did not submit `project.godot`, resources, import products, font files, `.uid`, `.translation`, or the existing Godot dirty whitelist. Do not use Godot/editor/game/import for broad resource import, persistence work, full font pipeline, or full art migration.

## G15 Boundary

G15 is limited to the Encounter Contract Foundation. R3 adds public/display dictionaries for encounter type, state, options, result summaries, effect summaries, and log entries. R4 adds a first UI EncounterSlot adapter that consumes the public snapshot only. The first adapters cover search/chest and existing event options only.

G15-R3/R4 do not migrate event / loot / extract decisions, do not implement full combat rooms or action combat, do not implement out-of-run progression, and do not implement lottery. `lottery` may exist only as a reserved encounter type name until progression, warehouse, codex, appearance library, and record systems exist.

G15-R3 keeps existing command semantics. `select_encounter_option` is additive and delegates to existing `search_current_room()` or `select_event_option()` paths. G15-R4 routes UI option clicks to that bridge without direct rule-state reads. Existing `request_extract` and `confirm_extract` are unchanged.

## G16 Boundary

G16-R3 is limited to the first `combat_basic` / `monster_basic` encounter foundation on top of the G15 public encounter framework. Monster rooms expose public `monster_summary`, `combat_encounter_state`, `attack_basic` option data, deterministic risk/reward preview, and combat result summary. `select_encounter_option` routes Monster `attack_basic` to existing deterministic `fight_current_enemy`.

G16-R3 does not change `CombatState.fight_enemy()`, `RoomResolver.fight_current_enemy()`, or `RunRuleService.apply_combat_reward()` settlement semantics. UI changes are display-only through `RunSurfaceModel`; the later parser blocker fix only removes dependency on parser-visible global class references.

G16-R5 is docs-only branch closeout. G16 is fast-forward merged to `main` after Godot headless project-load/parser smoke PASS.

G16 does not implement Boss, elite, multi-monster combat, skills, passive systems, leave confirmation, teleport restriction, combat animation, full drop economy, codex, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, Deploy persistence, full event library, complete gameplay runtime PASS, or manual playtest PASS.

G14-R3 safety event record: execution reported that two temporary script files were mistakenly created outside the then-active Game1 worktree and were then cleaned as necessary deletion. The repository commit contains no outside-repository path. Current computer-two G15 worktree safety scope is `D:\AGAME1\_repo_cache\Game1_work`; future CodeX work must forbid outside-repository temporary files and must not scan or clean outside-repository directories unless the user provides the exact path and explicit authorization.

## G14 Boundary

G14 is limited to a visible legacy Demo-style run UI surface sprint and is complete after R5 docs-only closeout. R3 adds a minimal `RunSurface` / `RunSurfaceModel` cut and first shell: left scanner rail, center room/objective surface, right protocol/danger/status rail, bottom action bar, resource pocket, and reusable overlay/modal slots.

G14-R4 adds low-fidelity presentation refinement for scanner legend, action hints, button states, modal chrome, event / loot / extract display text, right rail status, and feedback hierarchy. It does not move decisions into UI.

G14 keeps event, loot, extract, command decisions, and screen routing in `run_scene.gd`. It does not change rules, CommandBus semantics, snapshot schema, TruthMap, Ledger, AssetLedger, MetaProgress, Deploy persistence, resources, fonts, import products, project metadata, action combat, full event library, full talent/card systems, full art migration, G15, or runtime PASS.

`RunSurface` is UI surface composition only. `RunSurfaceModel` is display-only. They do not directly read `TruthMap`, `RunRuleService`, Ledger, or `AssetLedger` private state, and they do not dispatch CommandBus.

## G13 Boundary

G13 is limited to fixed 16:9 resolution tiers: `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`. G13-R3 added startup auto recommendation, runtime-only display selection, manual apply/reset, window resize locking, fixed-tier `UILayoutProfile` fields, and small layout adaptations for existing UI.

G13 does not include arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full platform DPI parity, complete final UI, complete settings, Deploy persistence, MetaProgress, action combat, new gameplay, new resources, full art migration, broad UI rewrite, broad architecture reshaping, or runtime PASS.

## G12 Boundary

G12 was limited to lightweight legacy Demo core-loop feel, Chinese visible text, scan/map feedback, protocol/pressure readability, reward/loot/settlement wording, local tooltip/autowrap/color/font-size/line-spacing tweaks, and validation/manual checklist updates. It is complete, pushed, and closed.

G12 did not run Godot/editor/game/import, did not add font files/resources/import products, did not modify `run_scene.gd`, and did not commit the existing Godot dirty whitelist. It does not include 1:1 legacy Demo remake, complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, new events library, new resources, downloaded/copied/source-unknown fonts, complete font system, full art migration, full UI rewrite, or G13.

## Current Unfinished Items

- No full MetaProgress.
- No full Deploy persistence.
- No full Warehouse UI.
- No drag/drop or replacement inventory UI.
- No consignment, insurance, or lottery pool implementation.
- No action combat.
- No final event economy tuning.
- No persistence-backed deploy economy.
- No real art import.
- No complete character or outfit system.
- No complete Inventory, GroundLoot, or Settlement UI.
- No final UI polish pass.
- No complete long-term backend.

## G10 Boundary

G10 was reserved for stability analysis, BUG fixes, UI readability optimization, interaction blocker triage, validation-chain trust checks, code convergence, documentation clarity, and future content planning.

G10 is now closed. It does not include complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping unless a later separately approved plan changes that boundary.
## G18-align Final Main Merge Status

G18-align is fast-forward merged to `main`. First `main` commit containing G18-align: `70d3735a3ed49dec31ce5a6de73cfdf0829885eb`. G18-align-R2 implementation: `55a048e7419a890cc899bdbd7fae4db4431ddacf`. G18-align-R4B closeout: `70d3735a3ed49dec31ce5a6de73cfdf0829885eb`.

Historical G18-align final merge record: parser smoke PASS only. At that time G22 had not started; this status is superseded by the later G22 completion record.
