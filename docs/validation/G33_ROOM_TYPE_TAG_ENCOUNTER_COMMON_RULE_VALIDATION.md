# G33 Room Type / Tag / Encounter Common Rule Validation

## 中文结论摘要（DOC-GOV-001）

G33 记录房间类型、标签与遭遇通用规则的 preview / display-only 内容。它说明 RoomType、RoomTag、RoomPolicy、RoomState、EncounterEntry、RoomRulePreview、RoomResultPreview、GroundLoot 和 RoomLootContainer 的语义预览边界；不实现 battle runtime、monster AI、事件链 runtime、真实掉落/背包、规则引擎、奖励发放、结算仓库写入、SaveManager、CommandBus mutation、gameplay runtime PASS 或 manual playtest PASS。

本验证摘要只概括原 validation 的验证对象、边界和未声明项。具体 PASS/命令以原 validation 正文为准；不得把 parser/headless smoke 写成 gameplay runtime PASS 或 manual playtest PASS。


Stage: G33-R2 Room Type / Tag / Encounter Common Rule Full Content Implementation.

Branch: `godot/g33-room-type-tag-encounter-common-rule`

## Scope

G33 validates:

- RoomType / RoomTag / RoomPolicy / RoomState
- EncounterEntry / EncounterPreview
- RoomContentSlot / RoomRulePreview / RoomCondition / RoomResolutionPreview
- RoomResultPreview / GroundLoot / RoomLootContainer semantic boundaries
- RunFlow / Settlement / RunSurface / HUD display-only consumer alignment

## Static Validation

Commands:

```powershell
git diff --name-only
git diff --stat
git diff --check
git diff --cached --name-only
git status --short --branch
git ls-files --others --exclude-standard
```

Expected dirty files are limited to the G33 allowlist. Forbidden dirty files include project metadata, scenes/resources, UID/translation/import metadata, `core/command`, Base Docs, and Connection.

## Negative Grep

```powershell
rg "FileAccess|user://|SaveManager|AssetLedger|RunAssetLedger|CommandBus|grant_reward|claim_reward|persist|save|load|dispatch|emit_signal|ResourceLoader|PackedScene|add_child" Godot/GraytailGodot/scripts/core/map Godot/GraytailGodot/scripts/core/run Godot/GraytailGodot/scripts/core/settlement Godot/GraytailGodot/scripts/ui/run_surface Godot/GraytailGodot/scripts/ui/hud
```

Safe hits may include existing runtime, static preload, existing UI construction, display text, or preview/no_persistence fields. G33 must not add real persistence, reward, objective, RoomLoot runtime, scene/resource loading, or CommandBus mutation.

## Positive Grep

```powershell
rg "RoomType|RoomTag|RoomPolicy|RoomState|RoomContentSlot|EncounterEntry|EncounterPreview|RoomRulePreview|RoomCondition|RoomResolutionPreview|RoomResult|GroundLoot|RoomLootContainer|preview|display_only|read_only|no_persistence" Godot/GraytailGodot/scripts/core/map Godot/GraytailGodot/scripts/core/run Godot/GraytailGodot/scripts/core/settlement Godot/GraytailGodot/scripts/ui/run_surface Godot/GraytailGodot/scripts/ui/hud docs/20_product docs/validation docs/handoff
```

## Godot Smoke

Run project-load/parser only:

```powershell
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
```

Only this may be declared:

```text
Godot headless project-load/parser smoke PASS / FAIL
```

## Non-Claims

G33 does not claim gameplay runtime PASS or manual playtest PASS.

## Execution Record

- Static validation: PASS.
- `git diff --check`: PASS, with LF/CRLF conversion warnings only and no whitespace errors.
- Negative grep review: PASS. Hits were existing runtime/preload/UI construction code, existing run systems outside the G33 delta, display text, and preview/no_persistence fields.
- Positive grep evidence: PASS for RoomType, RoomTag, RoomPolicy, RoomState, RoomContentSlot, EncounterEntry, EncounterPreview, RoomRulePreview, RoomCondition, RoomResolutionPreview, RoomResultPreview, GroundLoot, RoomLootContainer, preview, display_only, read_only, and no_persistence.
- Godot headless project-load/parser smoke: PASS.
- Godot smoke produced no new metadata dirty side effects.
- No project/scene/resource/uid/translation/import metadata changes were included.
