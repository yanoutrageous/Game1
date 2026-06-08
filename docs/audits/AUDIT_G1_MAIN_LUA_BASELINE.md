# AUDIT_G1_MAIN_LUA_BASELINE

## Time
2026-06-08 16:56:00 +08:00

## Allowed Paths
- Read: $src, $godot, $reports, D:\AGAME1\_repo_cache
- Write: $work

## Forbidden / Not Used
- Did not modify $src.
- Did not modify $godot.
- Did not modify D:\AGAME1\Base Docs.
- Did not write to D:\AGAME1_codex_reports or D:\AGAME1_repo_cache.
- Did not modify C drive, PATH, registry, global Git config, or global Godot config.

## Safety Answers
- Deleted files: no.
- Moved or renamed files: no.
- Force push: no.
- Used old Game.git remote in work repo: no.
- Copied old .git: no.
- Modified Base Docs: no.
- Copied Godot project into main: no.

## Validation Commands
`powershell
git -C D:\2026.6\GAME branch --show-current
git -C D:\2026.6\GAME log -1 --oneline
git -C D:\AGAME1\_repo_cache\Game1_work branch --show-current
git -C D:\AGAME1\_repo_cache\Game1_work remote -v
git -C D:\AGAME1\_repo_cache\Game1_work status --short
git ls-remote --heads https://github.com/yanoutrageous/Game1.git
`

## Validation Results
- Source branch: $srcBranch
- Source commit: $srcCommit
- Work branch expected: main
- Work remote expected: $remote
- Remote status: unknown; network connection to GitHub failed during ls-remote.

## Issues / Blockers
- Remote branch status could not be confirmed due network failure. Push is blocked until git ls-remote --heads origin succeeds and remote main state is known.
