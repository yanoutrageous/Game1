# ART-15R Visual Layer Problem Review

## 0. Review Position

This review is based on current ART-15 screenshots, current runtime asset registrations, and current UI code. It is not a new asset request list and it does not authorize any direct runtime reads from Base Art or Draw.

## 1. Existing Asset Correspondence

The existing asset correspondence work has been partially completed.

Runtime assets already registered in `Godot/GraytailGodot/data/assets/asset_manifest.csv`:

- Main menu background: `ui.main_menu.background.no_text`.
- Deploy buttons: `ui.deploy.button.*`.
- Deploy icons: `ui.deploy.icon.*`.
- Deploy panels: `ui.deploy.panel.*`.
- Key prompts: `ui.key_prompt.e`, `ui.key_prompt.esc`, `ui.key_prompt.f`, `ui.key_prompt.m`, `ui.key_prompt.q`, `ui.key_prompt.t`.
- HUD panels and badges: `ui.hud.panel.left`, `ui.hud.panel.protocol`, `ui.hud.bottom_bar`, `ui.hud.mine_risk_tag`, `ui.hud.bar.*`.
- Feedback and result plates: `ui.feedback.*`, `ui.result.title.*`.
- Player sprites: `sprite.player.default`, `sprite.player.idle.*`.
- Item icons: `item.consumable.*`, `item.equipment.*`, `item.recovered.*`.
- Room backgrounds and props: `room.background.*`, `prop.*`, `prop.art07.*`.

Runtime mappings already present:

- `Art09ManifestAssetMapping` resolves deploy buttons, deploy icons, deploy panels, key prompts, item icons, feedback bars, result plates, and panels.
- `PresentationMapping` routes minimap icons, room background ids, main menu background, deploy refs, inventory item icons, feedback refs, result refs, panel refs, and key prompt refs.

Current problem:

- The correspondence exists, but many pages still render large `ColorRect` placeholders or opaque panels instead of the registered sprites/textures.
- `sprite.player.*` is registered but the main menu, deploy prep, and long-term profile areas still use geometric silhouette blocks.
- HUD has room/minimap/key/feedback assets, but layout still presents as left scanner plus center room plus right column.
- Inventory and ground loot use item icon mapping in rows, but their container composition still looks like a debug overlay on top of HUD.

## 2. Main Menu Problems

Actual assets:

- Background: `ui.main_menu.background.no_text` is used through `PresentationMapping.main_menu_background_ref`.
- Button icons use deploy icon refs.
- Notice and meta panels use feedback and terminal panel refs.
- Player sprite assets are not used for the hero display.

Layer / layout problems:

- `MainMenuNarrativeFrame` and several black/green `ColorRect` layers cover too much of the full-bleed background.
- Character display is made from `CharacterCapeLayer`, `CharacterSilhouette`, and `CharacterHead` rectangles instead of a real runtime sprite.
- The central narrative/meta frame occupies the area that should visually sell the base entry / hero area.
- The page is closer to the Base mockup than earlier stages, but still reads as a UI prototype rather than a finished menu.

Copy problems:

- Some labels remain implementation-like because mojibake source text and sanitized fallback strings are mixed.

## 3. Deploy Prep Problems

Actual assets:

- Deploy panel textures are loaded by `Art09DeployMainPanel` and `Art09DeploySummaryPanel`.
- Deploy buttons and icons are available and used on tabs, cards, slots, and the start button.
- No character sprite is used in the left column.

Layer / layout problems:

- Base target is left character/readiness, large center mission area, fixed right summary, and a prominent bottom-right start button.
- Current center column is visually smaller than the Base target because it is split into card list plus a narrow detail panel.
- Left column still uses `DeployCharacterReadiness` and `DeployCharacterSilhouette` color blocks.
- Right summary is too text-heavy and contains partially internal-looking labels.
- The page has the right rough grid, but the existing assets are still treated as decorative textures under text rather than the primary layout language.

Copy problems:

- Some source strings leak internal concepts such as M3R-style config / selected equipment phrasing in the screenshot.
- Text budget is short, but truncation does not always make the content more player-readable.

## 4. Long Term Problems

Actual assets:

- Terminal/protocol panels are rendered as profile, archive, and detail textures.
- The page does not use dedicated long-term icons; it mostly relies on panel framing and button cards.
- Player/profile sprite assets are not used in the left profile area.

Layer / layout problems:

- Base target is a left archive/profile area, a visually large middle collection grid, and a right detail panel.
- Current layout has those columns, but the center grid cards are sparse and text-like.
- Left profile still uses geometric avatar blocks.
- Right detail panel is a stack of text modules, not a strong collection/detail presentation.

Copy problems:

- Some visible labels still read as technical placeholders or mojibake-derived summaries.

## 5. Run HUD Problems

Authoritative reference:

- Use the user-provided flipped HUD sketch and the audit frame interpretation.
- The target is not three columns and not a full right rail.

Target structure:

- Left fixed rail, about 18%-22% width:
  - top small map.
  - middle HP / combat power / black coin / gold.
  - bottom backpack entry.
- Center and lower-right should remain actual game room / interaction view.
- Right top only has a compact protocol / pressure / temporary state card.
- Center item interaction prompt is a small floating prompt near the object.
- Bottom has a main information strip above a separate key bar.

Actual assets:

- MiniMap panel and minimap icons are wired.
- Room backgrounds are wired through `PresentationMapping.room_visual_from_snapshot`.
- Key prompt icons are available.
- Feedback bar assets are available.
- Player sprite and room props are available through manifest.

Layer / layout problems:

- Current `RunSurface.apply_layout_profile` still reserves `right_width` for `right_backdrop` and encounter/status blocks.
- `right_backdrop`, `encounter_backdrop`, `threat_mask`, `event_mask`, and `reward_mask` form a full right rail that contradicts the flipped HUD reference.
- `left_backdrop` is a scanner rail with long map/log text instead of a compact status rail.
- `center_backdrop` and `room_text_mask` put a wide top text panel over the room.
- `room_hint_softener` and MapOverlay dimming can cover too much of the actual room.
- `command_feedback_art` is tied to the right side instead of a bottom main information strip.

Copy problems:

- HUD text remains denser than the reference.
- Left side uses scanner/log wording instead of fixed status wording.

## 6. Map Overlay Problems

Actual assets:

- Uses `MiniMapViewModel` markers and minimap icons through ContentDB.
- No new map overlay art is required for this pass.

Layer / layout problems:

- Scene `MapOverlayPanel/Dimmer` is `Color(0, 0, 0, 0.62)`, which darkens almost the whole run screen.
- The panel is centered and large; at 1280x720 it turns the room into a dark sheet.
- Target should preserve room context and present an expanded scan panel rather than a full black overlay.

Copy problems:

- Footer and detail copy are long and should be shortened for player view.

## 7. Inventory Problems

Actual assets:

- Item icon mapping is used through `PresentationMapping.inventory_item_icon_ref`.
- Inventory rows can show medkit/syringe/equipment/recovered icons when item data matches.

Layer / layout problems:

- The panel is a medium centered overlay, while the current HUD remains dominant behind it.
- It does not read as the left rail backpack expanding from the user HUD reference.
- Row buttons are narrow and text-heavy.

Copy problems:

- Summary and tooltip copy are long and still explain mechanics as documentation.

## 8. Ground Loot Problems

Actual assets:

- Uses the same item icon mapping path as inventory.

Layer / layout problems:

- Ground loot is a centered list overlay rather than a compact object-near prompt or a clear item pickup panel.
- It competes with the run HUD and room view instead of feeling attached to the current room object.

Copy problems:

- Summary and tooltip copy remain too explanatory.

## 9. Required Fix Direction

1. Keep the current asset registry and mapping approach; do not invent direct file paths.
2. Add or expose player sprite refs through presentation mapping, then use them for character/profile display.
3. Rework deploy prep and long-term into stronger left / center / right product pages using current textures and icons.
4. Rework run HUD around the flipped reference:
   - no full right rail.
   - no long scanner log.
   - larger room view.
   - compact right-top status card.
   - bottom info strip plus key bar.
5. Rework map overlay dimming and placement so the room context remains visible.
6. Rework inventory and ground loot to use item icons and smaller action containers rather than document-style overlays.

## 10. Latest User Correction To Validate

After the initial review, the user clarified the flipped sketches and the expected proportions:

- Deploy prep:
  - left column is only character display and appearance / setup affordance.
  - equipment and consumables must stay on the right column.
  - center top primary tabs belong to the center content area and must not interfere with the right column.
  - secondary filters must not wrap; if necessary they should behave like a horizontal strip.
  - right column content should move upward and avoid large empty top space.
  - continue / abandon should be above the large start button.
- Long-term:
  - same left / center / right family as deploy prep.
  - left column is character appearance display with a setup appearance button.
  - center should be archive / collection wall, not a detail page.
  - right column is fixed archive data: level, mainline, qualifications, resources, and rewards.
- Run HUD:
  - left column is about 30%.
  - the right about 70% should be actual game view except bottom operation information.
  - the right-top protocol / pressure card is only an occluding card over the game view.
  - a full right rail, dense scanner text, and large gray unused area are failures.

This latest correction is the current ART-15R validation baseline.
