# G19 LongTermShell Foundation Validation

## Scope

G19-R3 implements only `LongTermShell foundation + 6 module placeholder + interface preview only`.

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

G19-R3 does not run Godot, editor, import, or project-load/parser smoke. Godot headless project-load/parser smoke belongs to G19-R4 validation using:

```text
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
```

Do not record full gameplay runtime PASS or manual playtest PASS unless those validations are explicitly run later.
