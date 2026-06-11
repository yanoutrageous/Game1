# REPO_POLICY

## Repository Remote

- The only authorized push/pull remote for this repository is `https://github.com/yanoutrageous/Game1.git`.
- The old repository `https://github.com/yanoutrageous/Game.git` is read-only reference only and must not receive pushes.
- Every push must be preceded by `git remote -v`, `git branch --show-current`, `git status --short`, and `git ls-remote --heads origin`.

## Current Baseline Policy

- Use `docs/PROJECT_BASELINE.md` for the current engineering fact source.
- Use `docs/NEXT_HANDOFF.md` as the minimum next-chat context entry.
- Use `docs/DOCS_INDEX.md` for document navigation and historical status.
- Use `docs/handoff/HANDOFF_TEMPLATE.md` for future handoffs.
- Lua prototype baseline is preserved on `lua-prototype-main` at `d53d117af8c786014292c2981b7edfdaf11182ea`.
- Historical G2.5, S1/S2, and Lua parity branch notes remain reference material, not the current project baseline.

## Merge Policy

- Godot must not enter `main` until it is truly playable and the user manually approves a merge.
- No automatic merges to `main`.
- No force push.
- If remote state is unknown or histories differ unexpectedly, stop and report.

## File And Asset Policy

- Do not commit `D:\Godot\Tools`.
- Do not commit `.godot`, editor data, import caches, temp caches, or local tool directories.
- Lua baseline may retain existing prototype assets unless a file exceeds GitHub limits or the user approves a cleanup/LFS pass.
- Large files, LFS needs, and asset licensing risks must be reported before changing storage strategy.
- Unknown-license assets must not be labeled commercial-ready.
- Real art/audio/font/video migration into Godot is a separate future phase.

## Stage Documentation Policy

Each stage must produce:

- branch change document under `docs/branch_changes/`
- audit document under `docs/audits/`
- engineering status update
- handoff using `docs/handoff/HANDOFF_TEMPLATE.md`
