# G31 Run Map Domain / Room State Foundation Validation

## 中文结论摘要（DOC-GOV-001）

G31 记录局内地图与房间状态 foundation 的 preview / display-only 内容。它说明 TruthMap、KnownMap、扫描层、标记层、RunMapState、房间状态和地图结果快照的边界；不实现完整 RunFlow、真实持久化、战斗 runtime、事件链、RoomLoot runtime、奖励发放、仓库写入、SaveManager、AssetLedger / RunAssetLedger mutation、gameplay runtime PASS 或 manual playtest PASS。

本验证摘要只概括原 validation 的验证对象、边界和未声明项。具体 PASS/命令以原 validation 正文为准；不得把 parser/headless smoke 写成 gameplay runtime PASS 或 manual playtest PASS。


Stage: G31-R2 Run Map Domain / Room State Foundation Full Content Implementation.

Branch: `godot/g31-run-map-room-state-foundation`

## Execution Record

- Static validation: PASS.
- `git diff --check`: PASS; only LF/CRLF working-copy warnings were reported.
- Negative grep review: PASS. Safe hits were existing runtime/preload/UI construction code, existing `core/run` runtime systems outside the G31 delta, display text, and preview/no_persistence fields.
- Positive grep evidence: PASS for RunMap, TruthMap, KnownMap, ScanLayer, MarkMap, RunMapState, InfoReliabilityLayer, MapGenProfile, MapGenerationLog, FinalMapSnapshot, RunMapSnapshot, MapResult, RoomState, RoomPolicy, RoomTag, return_eligibility, fast_return, preview, display_only, read_only, and no_persistence.
- First parser smoke exposed a local G31 type-inference blocker in `IntelMap.build_public_cell`; the fix was limited to an explicit `Dictionary` type for the existing `previous` public-cell value.
- Godot headless project-load/parser smoke: PASS after the local parser hotfix.
- Godot smoke produced no new metadata dirty side effects.

## Scope

G31 implements foundation content for:

- `RunMap`
- `TruthMap`
- `KnownMap`
- `ScanLayer`
- `MarkMap`
- `RunMapState`
- `InfoReliabilityLayer`
- `MapGenProfile`
- `MapGenerationLog`
- `FinalMapSnapshot`
- `RunMapSnapshot`
- `MapResult`
- `RoomState`
- `RoomPolicy`
- `RoomTag`
- `return_eligibility`
- `fast_return`

## Validation Commands

Static validation:

```powershell
git diff --name-only
git diff --stat
git diff --check
git diff --cached --name-only
git status --short --branch
git ls-files --others --exclude-standard
```

Negative grep:

```powershell
rg "FileAccess|user://|SaveManager|AssetLedger|RunAssetLedger|CommandBus|grant_reward|claim_reward|persist|save|load|dispatch|emit_signal|add_child|PackedScene|ResourceLoader" Godot/GraytailGodot/scripts/core/map Godot/GraytailGodot/scripts/core/intel Godot/GraytailGodot/scripts/core/run Godot/GraytailGodot/scripts/core/settlement Godot/GraytailGodot/scripts/ui/minimap Godot/GraytailGodot/scripts/ui/map_overlay Godot/GraytailGodot/scripts/ui/run_surface Godot/GraytailGodot/scripts/ui/hud
```

Expected safe hits:

- static `preload`
- existing UI node construction such as `add_child`
- existing run fields or comments
- display text and preview guard fields

Failure condition:

- real persistence
- real SaveManager / AssetLedger / CommandBus integration
- real reward grant
- real command dispatch
- real dynamic scene/resource loading

Positive grep:

```powershell
rg "RunMap|TruthMap|KnownMap|ScanLayer|MarkMap|RunMapState|InfoReliabilityLayer|MapGenProfile|MapGenerationLog|FinalMapSnapshot|RunMapSnapshot|MapResult|RoomState|RoomPolicy|RoomTag|return_eligibility|fast_return|preview|display_only|read_only|no_persistence" Godot/GraytailGodot/scripts/core/map Godot/GraytailGodot/scripts/core/intel Godot/GraytailGodot/scripts/core/run Godot/GraytailGodot/scripts/ui/minimap Godot/GraytailGodot/scripts/ui/map_overlay Godot/GraytailGodot/scripts/ui/run_surface docs/20_product docs/validation docs/handoff
```

## Godot Smoke

Run only project-load/parser smoke:

```powershell
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
```

Only this may be declared:

```text
Godot headless project-load/parser smoke PASS / FAIL
```

## Non-Claims

G31 does not claim:

- gameplay runtime PASS
- manual playtest PASS
- complete RunFlow
- complete combat runtime
- complete event runtime
- RoomLoot runtime
- objective progress runtime
- reward grant
- settlement warehouse write
- persistence

## Expected Dirty Boundaries

Allowed changed files are limited to G31 docs/status files and allowed Godot `.gd` files under:

- `scripts/core/map`
- `scripts/core/intel`
- `scripts/core/run`
- `scripts/core/settlement`
- `scripts/ui/minimap`
- `scripts/ui/map_overlay`
- `scripts/ui/run_surface`
- `scripts/ui/hud`

Forbidden dirty files:

- `project.godot`
- scenes/resources
- `.uid`
- `.translation`
- `.import`
- `core/command`
- Base Docs
- Connection

## Follow-Up

Recommended next gate: unified G31-R3 audit / release confirmation before any main merge.
