# ART-15 Slice 1 Source Candidate Dedup Review

## 0. 定位

本文档记录 ART-15 Slice 1 的源素材去重审查。它只读扫描 Base Art、Draw、旧 GameJam Draw 和当前 runtime assets，不清理、不移动、不重命名、不删除任何源文件。

## 1. Source scan summary

| source | visual files scanned | matched current runtime by SHA | debug / forbidden files | use in ART-15 |
| --- | ---: | ---: | ---: | --- |
| `D:\AGAME1\Base Art` | 188 | 86 | 0 | staging / reference；很多 ART07/08 已重复进入 runtime |
| `D:\AGAME1\Draw\30_game_ready` | 147 | 58 | 8 | legacy source_candidate；不得修改 |
| `D:\A GAME\26.5.30 GameJam\Draw` | 969 | 99 | 21 | historical mirror；不得解压 Art.zip，不作为默认执行目标 |
| `Godot/GraytailGodot/assets` | 74 | 74 | 0 | runtime truth for already imported PNG |

## 2. High-confidence duplicates already in runtime

| source category | source path pattern | runtime asset_id | decision |
| --- | --- | --- | --- |
| item consumables | `item_consumable_medkit.png`, `item_consumable_syringe.png` | `item.consumable.medkit`, `item.consumable.syringe` | `existing_runtime`; do not recopy |
| item equipment | `item_equipment_flashlight.png`, `item_equipment_goggles.png` | `item.equipment.flashlight`, `item.equipment.goggles` | `existing_runtime`; do not recopy |
| recovered item | `item_recovered_ore.png` | `item.recovered.ore` | `existing_runtime`; do not recopy |
| main menu background | `main_menu_bg_no_text.png` / old `Main.png` | `ui.main_menu.background.no_text` | `existing_runtime`; do not recopy |
| minimap 32 icons | Draw `icons\32\*.png` | `icon.minimap.*`, `icon.room.*`, `icon.minimap.number.1/2/3` | `existing_runtime`; do not recopy |
| props | Draw/Base Art `props\00..11*.png` | `prop.chest.closed`, `prop.mine.trap`, `prop.gold.pile`, `prop.art07.*` | `existing_runtime`; semantic review first |
| deploy buttons | `ui_deploy_button\*.png` | `ui.deploy.button.*` | `existing_runtime`; wiring first |
| deploy icons | `ui_deploy_icon\*.png` | `ui.deploy.icon.*` | `existing_runtime`; wiring first |
| deploy panels | `ui_deploy_panel\*.png` | `ui.deploy.panel.*` | `existing_runtime`; wiring first |
| key prompts | `ui_key_prompt\*.png` | `ui.key_prompt.*` | `existing_runtime`; wiring first |
| terminal panel | `ui_panel_terminal_main.png` | `ui.panel.terminal_main` | `existing_runtime`; needs semantic review |
| player idle | old GameJam processed `Huanxionggai` idle directions | `sprite.player.*` | `existing_runtime`; do not recopy idle |

## 3. Candidate assets not yet runtime-matched

| candidate | source | size | suggested handling | rationale |
| --- | --- | --- | --- | --- |
| `ui_summary_bar\ui_bar_blank_dark.png` | Draw / old GameJam | 418x71 | `copy_to_runtime_candidate` | Useful as compact HUD / toast / capacity bar panel |
| `ui_summary_bar\ui_bar_blank_red.png` | old GameJam | 418x71 | `copy_to_runtime_candidate` | Warning / danger feedback variant |
| `ui_summary_bar\ui_bar_event_prompt.png` | old GameJam | 454x162 | `copy_to_runtime_candidate` | Event/search feedback panel candidate |
| `ui_title_plate\ui_title_extract_confirm.png` | Draw / old GameJam | 243x150 | `copy_to_runtime_candidate` | Result/extract confirm title plate |
| `ui_title_plate\ui_title_extraction_success.png` | Draw / old GameJam | 260x147 | `copy_to_runtime_candidate` | Settlement success title plate |
| `ui_title_plate\ui_title_signal_lost.png` | Draw / old GameJam | 240x150 | `copy_to_runtime_candidate` | Fail / signal lost title plate |
| `ui_scrollbar\ui_scrollbar_vertical.png` | Draw / old GameJam | 29x340 | `defer` | Useful later for long lists; not visual-impact P0 |
| character walk frames | Draw `characters\*\frames\04..11*.png` | 128x128 | `crop_required` / `defer` | Requires animation spec and sprite mapping; not Slice 2 low-risk import |
| character sheets | Draw `characters\*\*_sheet.png` | 512x384 | `crop_required` / `defer` | Candidate for animation import, but needs frame mapping |
| raw character sheets | old GameJam `00_raw` / `10_working` | 1448x1086 | `reference_only` | Not runtime-ready; source/working image |
| old room `Fangjian.png` / processed room | old GameJam | 1254x1254 | `reference_only` / `defer` | Current runtime already has six room backgrounds |

## 4. Reference-only sources

| source | reason |
| --- | --- |
| `Base Art\Base\主菜单确定.png`、`出发探索确定.png`、`长期系统确定.png` | Whole-screen confirmed art; layout / visual semantic reference only |
| `Base Art\Base\*示例.png` / `6.17问题*.png` | Review / issue screenshots, not runtime slices |
| `Base Art\ART-13\*.png` | In-run reference screenshots, not asset source |
| `Base Art\M1\*.png` and `Lua demo.mp4` | HUD and interaction rhythm reference only |
| old GameJam root `1.png`..`6.png`, `Zuhe*.png`, `Zujian*.png` | Whole images or historical composites; require review before any crop |
| any `debug_detected_boxes.png` | Debug detection output; forbidden import |
| `Art.zip` | Archive; do not unzip in ART-15 |

## 5. Dedup rules for later import slices

Later import slices must:
1. Compute SHA256 for every candidate before copying.
2. Stop or skip if the same SHA already exists under `Godot/GraytailGodot/assets`.
3. Stop or skip if a manifest row already points to the same `godot_path`.
4. Never overwrite an existing runtime asset unless SHA is identical and the operation is explicitly idempotent.
5. Never mark imported items as `approved`, `final`, or `runtime_ready`; use conservative statuses such as `pending_verification` / `needs_semantic_review`.
6. Keep `Draw`, `Base Art`, `Base Docs`, `Connection`, and old GameJam Draw read-only.

## 6. Slice 2 recommended minimal import batch

Given the dedup result, the lowest-risk visible import batch for Slice 2 is:
- `ui_summary_bar\ui_bar_blank_dark.png`
- `ui_summary_bar\ui_bar_blank_red.png`
- `ui_summary_bar\ui_bar_event_prompt.png`
- `ui_title_plate\ui_title_extract_confirm.png`
- `ui_title_plate\ui_title_extraction_success.png`
- `ui_title_plate\ui_title_signal_lost.png`

This batch avoids duplicating existing runtime assets and targets feedback / settlement visual gaps with direct visible impact. It should still be verified against existing runtime SHA and manifest path before copying.
