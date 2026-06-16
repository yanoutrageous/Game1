# G19 LongTermShell Foundation Validation

## Scope

G19-R3 implements only `LongTermShell foundation + 6 module placeholder + interface preview only`.

G19-R4B closeout records execution-frame self-check, Godot headless project-load/parser smoke PASS, and docs-only closeout on branch `godot/g19-long-term-shell-foundation`. G19 was fast-forward merged to `main`; the first main merge baseline is `04e14865f4d5eff7b16398d5730054273ccd0823`. G20 has not started, and Base Docs were not modified.

The six top-level modules are fixed:

- `goals` / 目标
- `codex` / 图鉴
- `research` / 研究
- `profile` / 个人资历
- `gacha` / 抽奖
- `collection_appearance` / 收藏 / 外观

G19 is not a complete long-term system, not MetaProgress, not a real asset system, not a real item model, not real AssetEvent / RewardBundle / Policy / Tag work, not real gacha, not history storage, not real codex data, not real research unlock, not collection / appearance equipment logic, not persistence, not reward claiming, and not red-dot clearing.

## R3 Static Validation Commands

Run from repository root:

```bat
cd /d D:\AGAME1\_repo_cache\Game1_work
git diff --stat
git diff --check
git status --short
git diff --name-only

rg -n "CommandBus\\.dispatch|command_bus\\.dispatch|RunContext|Encounter|Combat|Ledger|TruthMap|FileAccess|user://|MetaProgress|save|persist|write_profile|write_unlock|write_history|grant_reward|claim_reward|clear_red_dot|gacha_roll|roll_gacha|equip|create_item|ItemDefinition|ItemInstance|ItemStack|ResourceEvent|ItemEvent|UnlockEvent|HistoryRecordEvent|RewardBundle|Policy|Tag" Godot/GraytailGodot/scripts/ui/long_term Godot/GraytailGodot/scripts/ui/app_shell

rg -n "LongTermShell|LongTermModel|LongTermTabModel|LongTermSnapshot|目标|个人资历|收藏 / 外观|asset_projection_preview|event_flow_preview|reward_preview|red_dot_preview|inventory_link_preview|codex_link_preview|history_link_preview" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs

rg -n "project.godot|\\.tscn|\\.uid|\\.translation" .
```

The negative grep is intentionally code-only. Documentation may mention forbidden future-system terms in non-goal and boundary sections.

## Acceptance Boundary

- `LongTermSnapshot` is a public Dictionary helper only.
- `LongTermSnapshot` does not inherit `Node`, does not use `Resource`, does not use `FileAccess`, does not use `user://`, and does not persist data.
- `LongTermModel` builds static overview, module, placeholder, disabled reason, next-stage note, and display-only snapshot preview data.
- `LongTermShell` displays module tabs, overview, placeholder panels, child preview groups, and display-only interface previews.
- `AppShell` replaces the old long-term placeholder page with `LongTermShell`.
- `PageRouter` adds `PAGE_LONG_TERM` while keeping the old placeholder alias compatible.
- `NavigationIntent` adds `make_long_term()` without changing existing target semantics.

## Godot Smoke

G19-R3 did not run Godot, editor, import, or project-load/parser smoke. G19-R4B ran Godot headless project-load/parser smoke using:

```text
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
```

Result: Godot headless project-load/parser smoke PASS.

Smoke before/after `git status --short` remained clean. No `project.godot`, `.tscn`, resource, font, import product, `.uid`, or `.translation` dirty was produced.

This is not complete gameplay runtime PASS and not manual playtest PASS. G19 still does not implement real goals, codex data, research, profile progression, history storage, gacha, collection / appearance equipment, warehouse, asset systems, item models, ResourceEvent / ItemEvent / UnlockEvent / HistoryRecordEvent, RewardBundle / Policy / Tag, red-dot state machine, inventory projection, gacha result, profile/unlock/history persistence, RunScene startup, CommandBus dispatch, or RunContext / Encounter / Combat / Ledger / TruthMap reads.

PATCH_MODE remains `AGAME1_ROOT`; future `apply_patch` paths must use the `_repo_cache/Game1_work/` prefix.

## Post-Merge Calibration

- G19-R3 implementation commit: `4eeb345daef5f8263b325db2ab5607e6c78f6d36 feat(godot): add long term shell foundation`.
- G19-R4B closeout commit and first main merge baseline: `04e14865f4d5eff7b16398d5730054273ccd0823 docs: close G19 long term shell foundation`.
- G19 merged to main: yes, by fast-forward.
- G20 started: no.
