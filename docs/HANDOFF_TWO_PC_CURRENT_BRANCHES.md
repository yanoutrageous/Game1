# HANDOFF_TWO_PC_CURRENT_BRANCHES

## Updated

`2026-06-08 17:13:12 +08:00`

## Current Remote Branch Map

| Branch | Commit | Purpose | New PC Recommendation |
|---|---|---|---|
| `main` | `8f7e3cb67642708e6a5245d19f722bbfdb357ebe` | Existing remote bootstrap branch; not confirmed as Lua baseline | Do not treat as current baseline until user decides |
| `lua-prototype-main` | `d53d117af8c786014292c2981b7edfdaf11182ea` | Safe Lua prototype baseline from `D:\2026.6\GAME` | Use for Lua baseline inspection |
| `godot/prototype-foundation` | `2f2f4918f9715e711dcaaac3dea76732c8b62643` before G2.5 repair push | Current Godot S1/S2 foundation | Use for Godot foundation work |

## Recommended Checkout Flow

```powershell
git clone https://github.com/yanoutrageous/Game1.git Game1
cd Game1
git remote -v
git ls-remote --heads origin
git checkout lua-prototype-main
# or
git checkout godot/prototype-foundation
```

Never push until `git remote -v` confirms `Game1.git`. Never force push. Do not merge Godot into `main` without separate user approval.
