# G18-align Deploy Prep Asset Attendance View Validation

## R4B Closeout

- G18-align-R2 commit: `55a048e7419a890cc899bdbd7fae4db4431ddacf`.
- G18-align-R3 acceptance: passed.
- Godot headless project-load/parser smoke PASS.
- Working tree stayed clean after Godot smoke, with no dirty side effects.
- This stage only completed consistency alignment for deploy prep asset attendance view, right-side summary, and start / continue / abandon strong-confirmation preview.
- This stage did not implement complete deploy prep, complete warehouse, real asset writes, event bus, reward grant, persistence, or real RunScene start / continue / abandon logic.
- This stage did not declare gameplay runtime PASS.
- This stage did not declare manual playtest PASS.
- G22 has not started.

## Stage

G18-align-R2 aligns the existing DeployPrep foundation with the Base Docs deploy-prep design direction.

Scope is intentionally small:

- asset attendance view for deploy prep
- secondary labels under the five primary tabs
- card list and card detail preview
- right-side summary / config / effect / risk wording
- start / continue / abandon strong-confirmation preview
- read-only connection to G21 `AssetProjectionSchema` for deploy prep projection shape

## Fixed Primary Tabs

The DeployPrep shell must keep exactly five primary areas:

- 地图
- 仓库
- 申领
- 出勤配置
- 作业许可

Secondary labels are filters inside these areas. They are not replacement top-level systems.

## Boundary

G18-align is still deploy-prep alignment, not a complete expedition module.

It does not implement:

- complete warehouse
- real inventory writes
- real asset event writes
- event bus
- reward grant or reward claim
- persistence
- gacha
- settlement or history
- red dot
- real run start
- real continue
- real abandon
- full RunScene changes
- G22

G21 remains a contract/projection foundation only. This branch consumes the display-only deploy prep projection shape and does not turn it into a real asset system.

## Files Expected To Change

Code:

- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_tab_model.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd`

Docs:

- `docs/validation/G18_ALIGN_DEPLOY_PREP_ASSET_VIEW_VALIDATION.md`
- `docs/handoff/HANDOFF_G18_ALIGN_DEPLOY_PREP_ASSET_VIEW.md`
- current status, route, index, milestone, and manual-playtest documents

## Static Validation Commands

Run from repository root:

```bat
git diff --stat
git diff --check
git status --short
git diff --name-only

rg -n "CommandBus\.dispatch|command_bus\.dispatch|RunScene|RunContext|Encounter|Combat|Ledger|TruthMap|FileAccess|user://|persist|save|write_|grant_reward|claim_reward|clear_red_dot|roll_gacha|gacha_roll|RunAssetLedger|AssetCatalog" Godot/GraytailGodot/scripts/ui/deploy_prep Godot/GraytailGodot/scripts/ui/app_shell

rg -n "地图|仓库|申领|出勤配置|作业许可|二级|卡片|详情|摘要|配置|效果|风险|开始|继续|放弃|出勤|AssetProjectionSchema|deploy_prep_projection|asset_attendance" Godot/GraytailGodot/scripts/ui/deploy_prep docs Godot/GraytailGodot/docs

git diff --name-only | rg -n "project.godot|\.tscn|\.uid|\.translation|\.import|Base Docs|Godot/GraytailGodot/scripts/core/run|Godot/GraytailGodot/scripts/core/command|Godot/GraytailGodot/scripts/core/content/asset_catalog|Godot/GraytailGodot/scripts/ui/long_term"
```

Expected result:

- diff contains only the approved deploy_prep GDScript files and documentation
- no project, scene, resource, import, uid, or translation changes
- no Base Docs changes
- no forbidden run/core/long_term changes
- no direct run command dispatch
- no private run-state reads

## Godot Smoke

G18-align-R2 does not run Godot. Because it changes GDScript, a later acceptance round should run headless project-load/parser smoke only:

```bat
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
```

That future result, if passed, may only be recorded as `Godot headless project-load/parser smoke PASS`. It must not be recorded as complete gameplay runtime PASS or manual playtest PASS.
