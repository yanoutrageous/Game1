# Branch Inventory

## R3d1 Scope

本文件是 G20-R3d1 的分支库存。它只登记分支、远端 heads、已知风险与建议动作，不删除、不移动、不重命名、不 prune、不自动对齐任何分支。

- 采集时间：2026-06-16。
- 仓库：`D:\AGAME1\_repo_cache\Game1_work`。
- 当前 G20 分支采集时 HEAD：`10a2dd3ea2d71879b66f5d1c20177fb7bed2a6f1`。
- `git branch -r` 不是 live remote；live remote 以 `git ls-remote --heads origin` 为准。
- `merged_candidate` 只表示以后可被单独审计的候选状态，不等于 `authorized_to_delete`。
- 远端分支删除必须由后续单独授权；G20-R3d1 不授权删除本地或远端分支。
- 保护性 stash 是 do-not-touch 项，必须保留。

## Inventory

| branch | local_head | remote_tracking_head | live_remote_head | status | merged_candidate | risk | recommended_action | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `main` | `ef362dc01bb4303408e86c2441cf9ae8b4379e1d` | `origin/main @ ef362dc01bb4303408e86c2441cf9ae8b4379e1d` | `ef362dc01bb4303408e86c2441cf9ae8b4379e1d` | protected mainline | no | high | do not push main; do not merge main in G20-R3d1 | Live remote main matches required fact source. |
| `godot/g20-project-knowledge-governance` | `10a2dd3ea2d71879b66f5d1c20177fb7bed2a6f1` | `origin/godot/g20-project-knowledge-governance @ 10a2dd3ea2d71879b66f5d1c20177fb7bed2a6f1` | `10a2dd3ea2d71879b66f5d1c20177fb7bed2a6f1` | active G20 docs-only branch | no | medium | continue only authorized G20 docs governance work | R3a/R3b/R3c complete; R3d1 document commit will advance this branch after this inventory snapshot. |
| `godot/g19-long-term-shell-foundation` | `04e14865f4d5eff7b16398d5730054273ccd0823` | `origin/godot/g19-long-term-shell-foundation @ 04e14865f4d5eff7b16398d5730054273ccd0823` | `04e14865f4d5eff7b16398d5730054273ccd0823` | historical / merged to main | possible-after-separate-review | medium | retain; no delete or prune in G20 | G19 is fast-forward merged to main; remote branch still exists. |
| `godot/g18-deploy-prep-foundation` | `285695cda0141322b0672d65998f3d3f9aa32654` | `origin/godot/g18-deploy-prep-foundation @ 285695cda0141322b0672d65998f3d3f9aa32654` | `285695cda0141322b0672d65998f3d3f9aa32654` | historical / merged to main | possible-after-separate-review | medium | retain; no delete or prune in G20 | G18 is fast-forward merged to main; remote branch still exists. |
| `godot/g17-app-shell-main-menu` | `baa57fa41167c86ad226b5b8be4d540ff114269f` | none recorded by `git branch -vv` | `baa57fa41167c86ad226b5b8be4d540ff114269f` | historical / merged to main / local no-upstream | possible-after-separate-review | medium | retain; do not auto-set upstream or delete in G20 | Live remote exists and matches local head. |
| `godot/g16-combat-encounter-foundation` | `4637e8fa0eeec6859df4eab26d5a961868e4c071` | `origin/godot/g16-combat-encounter-foundation @ 4637e8fa0eeec6859df4eab26d5a961868e4c071` | `4637e8fa0eeec6859df4eab26d5a961868e4c071` | historical / merged to main | possible-after-separate-review | medium | retain; no delete or prune in G20 | Parser blocker fix is part of this branch head. |
| `godot/g15-encounter-contract-foundation` | `e72d3a5dc4a57122d42f881f391f2b47389fcdad` | `origin/godot/g15-encounter-contract-foundation @ e72d3a5dc4a57122d42f881f391f2b47389fcdad` | `e72d3a5dc4a57122d42f881f391f2b47389fcdad` | historical / merged to main | possible-after-separate-review | medium | retain; no delete or prune in G20 | G15 Encounter Contract foundation closeout branch. |
| `godot/g10-progress-art-smoke-foundation` | `aa19db2f1989c6ebfc22676d84b83da5c6977f64` | `origin/godot/g10-progress-art-smoke-foundation @ aa19db2f1989c6ebfc22676d84b83da5c6977f64` | `aa19db2f1989c6ebfc22676d84b83da5c6977f64` | historical / merged to main | possible-after-separate-review | medium | retain; no delete or prune in G20 | G10 closeout branch remains as historical evidence. |
| `godot/g9-ui-final-integration` | `eb9f5d6` | `origin/godot/g9-ui-final-integration @ ad1aeae279594f253ab9e62931ae20fb1cfb1bf5` | `ad1aeae279594f253ab9e62931ae20fb1cfb1bf5` | historical / needs review | no | high | do not auto-align, do not push, do not reset, do not delete | Required record: local `godot/g9-ui-final-integration` points to `eb9f5d6`; remote branch is `ad1aeae`; local is ahead 1 relative to tracking. |
| `godot/g9-ui-presentation-layering-revision` | `aa5a93ed68a9a755293b97e65d4b9ffa4881054e` | `origin/godot/g9-ui-presentation-layering-revision @ aa5a93ed68a9a755293b97e65d4b9ffa4881054e` | `aa5a93ed68a9a755293b97e65d4b9ffa4881054e` | historical | possible-after-separate-review | medium | retain; no delete or prune in G20 | G9 presentation layering contracts branch. |
| `godot/g8-2-runtime-parse-hotfix` | `a1afb14cae45285b8fb42aa76c2722e96036e264` | `origin/godot/g8-2-runtime-parse-hotfix @ a1afb14cae45285b8fb42aa76c2722e96036e264` | `a1afb14cae45285b8fb42aa76c2722e96036e264` | historical | possible-after-separate-review | medium | retain; no delete or prune in G20 | G8.2 runtime parser type warning hotfix branch. |
| `godot/g8-2-kernel-protocol-hardening` | `63e5db834fe98e11a3f11d52932f852bd4c4b79f` | `origin/godot/g8-2-kernel-protocol-hardening @ 63e5db834fe98e11a3f11d52932f852bd4c4b79f` | `63e5db834fe98e11a3f11d52932f852bd4c4b79f` | historical | possible-after-separate-review | medium | retain; no delete or prune in G20 | G8.2 kernel protocol hardening branch. |
| `godot/g8-1-architecture-hardening` | `f544a29e1758952497234016f4c4d554753c2e1b` | `origin/godot/g8-1-architecture-hardening @ f544a29e1758952497234016f4c4d554753c2e1b` | `f544a29e1758952497234016f4c4d554753c2e1b` | historical | possible-after-separate-review | medium | retain; no delete or prune in G20 | G8.1 architecture hardening branch. |
| `godot/g8-rules-asset-ledger-core` | `717728087eea2bdabd3a9c031b0f2698cdb5737e` | `origin/godot/g8-rules-asset-ledger-core @ 717728087eea2bdabd3a9c031b0f2698cdb5737e` | `717728087eea2bdabd3a9c031b0f2698cdb5737e` | historical | possible-after-separate-review | medium | retain; no delete or prune in G20 | G8 asset ledger rules core branch. |
| `godot/g7-lua-ux-flow-parity-p2` | `cf35225071a9975dd1eb3ab0e3c2788cb838db96` | `origin/godot/g7-lua-ux-flow-parity-p2 @ cf35225071a9975dd1eb3ab0e3c2788cb838db96` | `cf35225071a9975dd1eb3ab0e3c2788cb838db96` | historical | possible-after-separate-review | medium | retain; no delete or prune in G20 | G7 Lua UX flow parity branch. |
| `godot/g6-lua-playable-parity-p1-core` | none | `origin/godot/g6-lua-playable-parity-p1-core @ ee43cfa272d247c57fceda1ff4a43e39e44f7ae1` | `ee43cfa272d247c57fceda1ff4a43e39e44f7ae1` | historical / remote-only | possible-after-separate-review | medium | retain; do not create/delete/align in G20 | Remote branch exists; no local branch was listed. |
| `godot/g5-asset-ui-presentation` | none | `origin/godot/g5-asset-ui-presentation @ 95a14b0d6905d0fadd5ad56cd399cd52f7b02721` | `95a14b0d6905d0fadd5ad56cd399cd52f7b02721` | historical / remote-only | possible-after-separate-review | medium | retain; do not create/delete/align in G20 | Remote branch exists; no local branch was listed. |
| `godot/lua-parity-p0` | `688f3bc72be6a0f521956001eeb9657fa4c43e26` | `origin/godot/lua-parity-p0 @ 688f3bc72be6a0f521956001eeb9657fa4c43e26` | `688f3bc72be6a0f521956001eeb9657fa4c43e26` | historical | possible-after-separate-review | medium | retain; no delete or prune in G20 | Godot Lua parity P0 history. |
| `godot/pre-g10-project-baseline-consolidation` | `a13a6fae3208850ae43e4b511511e008eb311a3e` | `origin/godot/pre-g10-project-baseline-consolidation @ a13a6fae3208850ae43e4b511511e008eb311a3e` | `a13a6fae3208850ae43e4b511511e008eb311a3e` | historical | possible-after-separate-review | medium | retain; no delete or prune in G20 | Pre-G10 project baseline consolidation branch. |
| `godot/prototype-foundation` | `43501afd5e9ae27338051a119bcbce67b956a713` | none recorded by `git branch -vv` | `43501afd5e9ae27338051a119bcbce67b956a713` | historical / local no-upstream | possible-after-separate-review | medium | retain; do not auto-set upstream or delete in G20 | Live remote exists and matches local head. |
| `lua-prototype-main` | none | `origin/lua-prototype-main @ d53d117af8c786014292c2981b7edfdaf11182ea` | `d53d117af8c786014292c2981b7edfdaf11182ea` | historical remote branch / do-not-touch | no | high | do not modify, overwrite, delete, or align in G20 | Required historical prototype branch inventory item. |
| `stash@{0}` | `a608462` | not applicable | not applicable | protective stash / do-not-touch | no | high | do not apply, do not pop, do not drop, do not delete | Exact stash message: `On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`. |

## Safety Notes

- G20-R3d1 does not turn any `merged_candidate` into deletion approval.
- G20-R3d1 does not resolve the G9 local/remote mismatch.
- G20-R3d1 does not delete local branches, delete remote branches, prune remote refs, or align branch heads.
- If a later cleanup is desired, it must be planned as a separate authorized task with fresh live remote evidence.
