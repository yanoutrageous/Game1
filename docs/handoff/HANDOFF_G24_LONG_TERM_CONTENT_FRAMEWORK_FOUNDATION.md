# Handoff: G24 LongTerm Content Framework Foundation

## Status

G24-R2 implementation is complete on branch `godot/g24-long-term-content-framework-foundation`.

- Implementation commit: `02c2e577787a49ce4cbed173482a7acc31fa2bc9`.
- Static validation: PASS.
- Godot headless project-load/parser smoke: PASS.
- `git diff --check`: no whitespace error; LF/CRLF warnings only.
- Godot smoke produced no new dirty side effects.
- External art request: `D:\AGAME1\Connection\Program\G24_LongTerm_Content_Framework_Art_Request.md`.

## Implemented

- Added `LongTermContentFramework`.
- Added `LongTermContentSlotModel`.
- Connected LongTerm tab/model/snapshot/shell to content framework preview data.
- Preserved the fixed six-module LongTerm structure: 目标 / 图鉴 / 研究 / 个人资历 / 抽奖 / 收藏 / 外观.
- Added preview slots for objective, reward event, claimable state, red dot, codex unlock, research unlock, gacha pool/cost/result, collection display, cosmetic, unique collectible, history record, qualification, and asset event.
- Reserved UI / art / data keys such as `module_icon_key`, `tab_icon_key`, `group_icon_key`, `card_icon_key`, `reward_icon_key`, `rarity_frame_key`, `gacha_pool_art_key`, `collection_slot_art_key`, `art_placeholder_id`, `localization_key`, `future_data_ref`, and `data_source_ref`.

## Non-Goals

G24 is not a complete LongTerm implementation. It does not implement real targets, achievements, commissions, reward claiming, red dot clearing, gacha, cosmetic application, unique collectible acquisition, codex unlock, research unlock, profile progression, history writes, SaveManager, event bus, asset writes, complete Warehouse, or complete Gacha.

Gameplay runtime was not run, and no gameplay runtime PASS is claimed.

Manual playtest was not run, and no manual playtest PASS is claimed.
