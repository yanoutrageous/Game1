# REPO_POLICY

## Repository Remote

- The only authorized push/pull remote for this repository is `https://github.com/yanoutrageous/Game1.git`.
- The old repository `https://github.com/yanoutrageous/Game.git` is read-only reference only and must not receive pushes.
- Every push must be preceded by `git remote -v`, `git branch --show-current`, `git status --short`, and `git ls-remote --heads origin`.

## Current Branch Policy After G2.5

- Remote `main` exists at `8f7e3cb67642708e6a5245d19f722bbfdb357ebe` and was not overwritten in G2.5.
- Lua prototype baseline is preserved on `lua-prototype-main` at `d53d117af8c786014292c2981b7edfdaf11182ea`.
- Current Godot S1/S2 foundation is preserved on `godot/prototype-foundation`; before the G2.5 repair commit it was at `2f2f4918f9715e711dcaaac3dea76732c8b62643`.
- Future Godot Lua parity work must start from `godot/prototype-foundation` and use a separate branch such as `godot/lua-parity-p0`.

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
- two-PC handoff update or supplement
