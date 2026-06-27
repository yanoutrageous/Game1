# ART-12 Runtime Import Candidate Plan

文档状态：ART-12 validation evidence
生成时间：2026-06-27

## 0. 定位

本文档是下一批 runtime import candidate plan。ART-12 不导入 Godot、不复制图片到 Godot、不修改 `asset_manifest.csv`。

## 1. Candidate Plan

| candidate source path | proposed Godot target path | proposed asset_id | proposed visual_key | expected runtime role | required processing | manifest impact | priority | blocker | recommended ART-13 action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\main_menu\main_menu_bg_no_text.png` | `res://assets/ui/main_menu/main_menu_bg_base_hall_v1.png` | `ui.main_menu.background.base_hall.v1` | `bg.main_menu.base_hall` | main menu layered background candidate | crop / scale review, brightness mask, not full mockup | append 1 manifest row if accepted | P0 | Must confirm it is not used as full confirmed mockup replacement | ART-13: import as background layer candidate only |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\ui_panel\ui_panel_terminal_main.png` | `res://assets/ui/common/panels/terminal_main_v1.png` | `ui.panel.terminal_main.v1` | `panel.common.terminal_main` | reusable panel skin | nine-slice guide required | append or map existing if duplicate | P0 | Need slice margins | ART-13: evaluate nine-slice and manifest row |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\ui_deploy_panel\ui_panel_deploy_main_blank.png` | `res://assets/ui/deploy/panels/deploy_main_blank_v2.png` | `ui.deploy.panel.main_blank.v2` | `panel.deploy.main_blank` | deploy prep card / panel | compare with existing manifest asset | append only if distinct from current | P0 | Existing `ui.deploy.panel.deploy_main_blank` may already cover it | ART-13: dedupe against manifest |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\ui_deploy_panel\ui_panel_deploy_summary_blank.png` | `res://assets/ui/deploy/panels/deploy_summary_blank_v2.png` | `ui.deploy.panel.summary_blank.v2` | `panel.deploy.summary_blank` | deploy summary panel | compare with existing manifest asset | append only if distinct from current | P0 | Existing manifest entry may already cover it | ART-13: dedupe and decide replace / keep |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\ui_deploy_panel\ui_frame_highlight.png` | `res://assets/ui/common/frames/frame_highlight_v1.png` | `ui.frame.highlight.v1` | `frame.selected.highlight` | selected glow / focus frame | alpha / scale review | append 1 manifest row if accepted | P0 | Need selected state spec | ART-13: import as common state frame |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\ui_key_prompt\ui_key_e.png` | existing `res://assets/ui/key_prompt/ui_key_e.png` | existing `ui.key_prompt.e` | `keycap.global.e` | keycap | no new import if existing hash matches | no append expected | P0 | Need global keycap set expansion | ART-13: audit existing and add missing keys only |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\ui_key_prompt\ui_key_esc.png` | existing `res://assets/ui/key_prompt/ui_key_esc.png` | existing `ui.key_prompt.esc` | `keycap.global.esc` | keycap | no new import if existing hash matches | no append expected | P0 | Need global keycap set expansion | ART-13: audit existing and add missing keys only |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\props\08_saomiaoyi.png` | existing `res://assets/props/art07/08_saomiaoyi.png` | existing `prop.art07.08_saomiaoyi` | `prop.hud.scanner_device` | scanner / HUD prop | no new import if existing usable | no append expected | P1 | Need UI placement decision | ART-13: wire as optional prop visual |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\props\07_lingjian_dui.png` | existing `res://assets/props/art07/07_lingjian_dui.png` | existing `prop.art07.07_lingjian_dui` | `prop.loot.parts_pile` | loot / reward prop | no new import if existing usable | no append expected | P1 | Need loot UI spec | ART-13: map to reward state if needed |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch\item_consumable\item_consumable_medkit.png` | existing `res://assets/items/consumable/item_consumable_medkit.png` | existing `item.consumable.medkit` | `item.consumable.medkit` | inventory / deploy consumable icon | no new import if existing usable | no append expected | P1 | Need inventory visual contract | ART-13: connect to inventory / deploy slot if missing |
| `D:\AGAME1\Base Art\06_animation_sources\art07_character_candidates\huanxiong\frames\00_front_idle.png` | `res://assets/characters/huanxiong/idle_front.png` | `character.huanxiong.idle.front.v1` | `character.huanxiong.idle.front` | hero / character candidate | crop, alpha, frame spec, naming | append only after role confirmation | P1 | Character strategy not finalized | ART-13 or later: single-frame hero trial only |
| `D:\AGAME1\Base Art\07_sprite_sheets\art07_character_candidates\huanxiong\huanxiong_sheet.png` | `res://assets/characters/huanxiong/huanxiong_sheet.png` | `character.huanxiong.sheet.v1` | `character.huanxiong.sheet` | sprite sheet candidate | frame grid / animation_key spec | append only after animation spec | P2 | Full animation not in ART-12 | Later stage: animation import gate |
| `D:\AGAME1\Draw\30_game_ready\rooms\fangjian_jichu_1024.png` | `res://assets/rooms/room_base_v2.png` | `room.background.base.v2` | `bg.room.base` | room background candidate | crop / readability / duplicate review | append if improves current room backgrounds | P1 | Direct Draw import not allowed; must first stage through Base Art | ART-13: require Base Art staging before import |

## 2. Manifest Impact Summary

- Most P0 UI key prompt / deploy panel / prop assets already have manifest-backed records from earlier stages.
- Next batch should prefer dedupe / mapping before appending new rows.
- New manifest rows should be small and limited to UI background / panel / frame candidates that are not already represented.
- `asset_manifest.csv` is not modified in ART-12.

## 3. ART-13 Recommended Order

1. Dedupe existing manifest entries against Base Art candidates.
2. Confirm visual_key and proposed asset_id naming.
3. Confirm size, alpha, nine-slice, crop policy.
4. Import a small batch only after review.
5. Wire through presentation / UI mapping, not direct external paths.

## 4. 自检

- 本文档 is plan-only。
- No Godot import performed.
- No manifest modification performed.
- Direct Draw candidate is explicitly blocked until Base Art staging.
