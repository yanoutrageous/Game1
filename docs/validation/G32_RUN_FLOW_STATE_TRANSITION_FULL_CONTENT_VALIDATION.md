# G32 Run Flow / State Transition Full Content Validation

Stage: G32-R2 Run Flow & State Transition Full Content Implementation.

Branch: `godot/g32-run-flow-state-transition-full-content`

## Scope

G32 implements foundation content for:

- `RunLifecycle`
- `RunState`
- `RunFlowSnapshot`
- `RoomTransition`
- `RoomActionResult`
- `RunIntent`
- `SettlementTriggerPreview`
- `RunOutcomePreview`
- `RunResult` draft
- DeployPrep bounded start bridge to existing run route
- Continue / abandon disabled-preview boundaries

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
rg "FileAccess|user://|SaveManager|AssetLedger|RunAssetLedger|CommandBus|grant_reward|claim_reward|roll_gacha|gacha_roll|persist|save|load|dispatch|emit_signal|ResourceLoader|PackedScene|add_child" Godot/GraytailGodot/scripts/core/run Godot/GraytailGodot/scripts/core/map Godot/GraytailGodot/scripts/core/intel Godot/GraytailGodot/scripts/core/settlement Godot/GraytailGodot/scripts/ui/run_surface Godot/GraytailGodot/scripts/ui/hud Godot/GraytailGodot/scripts/ui/deploy_prep Godot/GraytailGodot/scripts/ui/main_menu Godot/GraytailGodot/scripts/ui/app_shell
```

Expected safe hits:

- existing runtime code before G32
- static `preload`
- existing UI construction such as `add_child`
- preview guard and no_persistence fields
- display text

Failure condition:

- G32-added persistence
- real SaveManager / FileAccess / user:// usage
- reward grant
- objective progress mutation
- RoomLoot runtime expansion
- new CommandBus command-list mutation
- scene/resource dynamic loading

Positive grep:

```powershell
rg "RunLifecycle|RunState|RunFlowSnapshot|RoomTransition|RoomActionResult|RunIntent|SettlementTriggerPreview|RunOutcomePreview|RunResult|settlement_pending|confirm_extract|abandoned|disabled_reason|preview|display_only|read_only|no_persistence" Godot/GraytailGodot/scripts/core/run Godot/GraytailGodot/scripts/core/settlement Godot/GraytailGodot/scripts/ui/run_surface Godot/GraytailGodot/scripts/ui/hud Godot/GraytailGodot/scripts/ui/deploy_prep docs/20_product docs/validation docs/handoff
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

G32 does not claim:

- gameplay runtime PASS
- manual playtest PASS
- complete SaveManager / active run persistence
- real continue recovery
- real abandon settlement
- real reward grant
- real objective progress
- complete RoomLoot / GroundLoot runtime
- settlement warehouse write

## Expected Dirty Boundaries

Allowed changed files are limited to G32 docs/status files and allowed Godot `.gd` files under:

- `scripts/core/run`
- `scripts/core/map`
- `scripts/core/intel`
- `scripts/core/settlement`
- `scripts/ui/run_surface`
- `scripts/ui/hud`
- `scripts/ui/deploy_prep`
- `scripts/ui/main_menu`
- `scripts/ui/app_shell`

Forbidden dirty files:

- `project.godot`
- scenes/resources
- `.uid`
- `.translation`
- `.import`
- `core/command`
- Base Docs
- Connection

## Execution Record

- Static validation: PASS.
- `git diff --check`: PASS, with LF/CRLF conversion warnings only and no whitespace errors.
- Negative grep review: PASS. Hits were existing runtime/preload/UI construction code, existing run systems outside the G32 delta, display text, and preview/no_persistence fields.
- Positive grep evidence: PASS for RunLifecycle, RunState, RunFlowSnapshot, RoomTransition, RoomActionResult, RunIntent, SettlementTriggerPreview, RunOutcomePreview, RunResult, settlement_pending, confirm_extract, abandoned, disabled_reason, preview, display_only, read_only, and no_persistence.
- Godot headless project-load/parser smoke: PASS.
- Godot smoke produced no new metadata dirty side effects.
- No project/scene/resource/uid/translation/import metadata changes were included.

## Follow-Up

Recommended next gate: unified G32-R3 audit / release confirmation before any main merge.
