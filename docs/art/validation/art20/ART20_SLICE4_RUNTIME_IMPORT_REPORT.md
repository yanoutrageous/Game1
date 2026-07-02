# ART-20 Slice 4 Runtime Import and visual_key Integration Report

## 0. Document Role

This report records ART-20 Slice 4 runtime import and manifest-backed `visual_key` integration.

This slice only imports a conservative subset approved by Slice 3 audit. It does not replace core screens, does not run Godot, does not commit, and does not push.

## 1. Import Eligibility Rules

- Import only rows marked `cut_ready_for_review`.
- Import only rows resolved to one `asset_id` and one `visual_key`.
- Defer all `cut_governance_review` rows.
- Defer all rows with `nine_slice_margin=manual_review_required`.
- Defer all rows with `A|B|C` multi-candidate fields.
- Defer 32px `run_bottom_key_bar_button` crops until page-level visual review.
- Keep the 5 Slice 3 blocked rows excluded.

## 2. Import Summary

- Runtime PNG imports: 15
- New ART-20 manifest rows: 15
- Deferred / excluded rows: 39
- Manual nine-slice deferred rows: 29
- Runtime target directory: `Godot/GraytailGodot/assets/ui/art20/**`

## 3. Imported Rows

| cut_id | asset_id | visual_key | godot_path | size | hash status |
| --- | --- | --- | --- | --- | --- |
| `art20_cut_007` | `ui.art20.keycap.e.normal` | `shared.keycap.e.normal` | `res://assets/ui/art20/shared/keycaps/ui_shared_keycap_e_normal.png` | 40x40 | ok |
| `art20_cut_008` | `ui.art20.keycap.esc.normal` | `shared.keycap.esc.normal` | `res://assets/ui/art20/shared/keycaps/ui_shared_keycap_esc_normal.png` | 40x40 | ok |
| `art20_cut_009` | `ui.art20.keycap.f.normal` | `shared.keycap.f.normal` | `res://assets/ui/art20/shared/keycaps/ui_shared_keycap_f_normal.png` | 40x40 | ok |
| `art20_cut_010` | `ui.art20.keycap.m.normal` | `shared.keycap.m.normal` | `res://assets/ui/art20/shared/keycaps/ui_shared_keycap_m_normal.png` | 40x40 | ok |
| `art20_cut_011` | `ui.art20.keycap.q.normal` | `shared.keycap.q.normal` | `res://assets/ui/art20/shared/keycaps/ui_shared_keycap_q_normal.png` | 40x40 | ok |
| `art20_cut_012` | `ui.art20.keycap.t.normal` | `shared.keycap.t.normal` | `res://assets/ui/art20/shared/keycaps/ui_shared_keycap_t_normal.png` | 40x40 | ok |
| `art20_cut_013` | `ui.art20.main_menu.background.base_hall` | `main_menu.background.base_hall` | `res://assets/ui/art20/main_menu/backgrounds/ui_main_menu_background_base_hall.png` | 1672x941 | ok |
| `art20_cut_023` | `ui.art20.deploy.icon.consumable.medkit` | `deploy.icon.medkit` | `res://assets/ui/art20/deploy/icons/deploy_equipment_slot_item_consumable_medkit.png` | 72x72 | ok |
| `art20_cut_024` | `ui.art20.deploy.icon.consumable.syringe` | `deploy.icon.syringe` | `res://assets/ui/art20/deploy/icons/deploy_equipment_slot_item_consumable_syringe.png` | 72x72 | ok |
| `art20_cut_025` | `ui.art20.deploy.icon.equipment.flashlight` | `deploy.icon.flashlight` | `res://assets/ui/art20/deploy/icons/deploy_equipment_slot_item_equipment_flashlight.png` | 72x72 | ok |
| `art20_cut_026` | `ui.art20.deploy.icon.equipment.goggles` | `deploy.icon.goggles` | `res://assets/ui/art20/deploy/icons/deploy_equipment_slot_item_equipment_goggles.png` | 72x72 | ok |
| `art20_cut_027` | `ui.art20.deploy.icon.armor` | `deploy.icon.armor` | `res://assets/ui/art20/deploy/icons/deploy_equipment_slot_ui_icon_armor.png` | 72x72 | ok |
| `art20_cut_028` | `ui.art20.deploy.icon.backpack` | `deploy.icon.backpack` | `res://assets/ui/art20/deploy/icons/deploy_equipment_slot_ui_icon_backpack.png` | 72x72 | ok |
| `art20_cut_029` | `ui.art20.deploy.icon.bandage` | `deploy.icon.bandage` | `res://assets/ui/art20/deploy/icons/deploy_equipment_slot_ui_icon_bandage.png` | 72x72 | ok |
| `art20_cut_030` | `ui.art20.deploy.icon.compass` | `deploy.icon.compass` | `res://assets/ui/art20/deploy/icons/deploy_equipment_slot_ui_icon_compass.png` | 72x72 | ok |

## 4. Deferred Rule Summary

| reason | count |
| --- | ---: |
| `cut_governance_review` | 11 |
| `manual_9slice_margin_required` | 29 |
| `multi_candidate_needs_resolution` | 26 |
| `keybar_button_crop_semantic_review` | 7 |

## 5. visual_key Integration Surface

- `Art09ManifestAssetMapping.art20_component_ref(visual_key)` exposes ART20 manifest-backed component lookup.
- `Art09ManifestAssetMapping.art20_keycap_ref(action_id)` exposes keycap lookup.
- `Art09ManifestAssetMapping.art20_main_menu_background_ref()` exposes the main menu background candidate.
- `Art09ManifestAssetMapping.art20_deploy_icon_ref(kind)` exposes deploy icon candidates.
- `PresentationMapping` only forwards those helpers. Page consumption remains deferred to later Slice work.

## 6. Self-check Result

- Runtime file hashes match cut output hashes.
- Manifest has no duplicate `asset_id`.
- Imported rows do not contain multi-candidate `asset_id` or `visual_key`.
- Blocked rows were not imported.
- Godot was not run.
- No commit / push was performed.
