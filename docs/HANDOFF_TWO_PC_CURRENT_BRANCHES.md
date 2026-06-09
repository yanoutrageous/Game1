# HANDOFF_TWO_PC_CURRENT_BRANCHES

## Updated

`2026-06-09`

## Current Branch Map

| Branch | Commit | Purpose | Recommendation |
|---|---|---|---|
| `main` | unchanged in G5 | remote bootstrap branch | Do not use for G5 |
| `lua-prototype-main` | `d53d117af8c786014292c2981b7edfdaf11182ea` | Lua prototype baseline | Read-only reference only |
| `godot/lua-parity-p0` | `688f3bc72be6a0f521956001eeb9657fa4c43e26` | G4/P0 playable Godot baseline | G5 base branch |
| `godot/g5-asset-ui-presentation` | local stage branch | G5 asset/UI/presentation work | Current implementation branch |

## Safety

- Push only after explicit user authorization.
- Never push to `https://github.com/yanoutrageous/Game.git`.
- Never force push.
- Do not merge Godot work into `main` without separate approval.
