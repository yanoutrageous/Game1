# M4 Branch Governance Ledger

文档状态补充：本文件是 M4 / M4S 时间点分支证据。其旧仓库路径和旧 refs 不改写；I1 当前分支事实见 `docs/10_current/CURRENT_STATE.md` 和 `docs/50_stages/active/STAGE_INDEX.md`。

文档状态：M4 / M4S 仓库同步 / 分支治理台账
适用范围：当前本地与 origin 分支的审计、合并候选判断、清理建议
最后更新：2026/06/30

本文件只记录分支事实和治理建议，不删除分支，不授权 push main，不替代 release gate。

## 1. 状态冻结

```text
repo: D:\AGAME1\_repo_cache\Game1_work
fetch: git fetch --prune 已执行
main: 786c898388896eb6654e3a3a96fe4aef5cdb32fe
origin/main: 786c898388896eb6654e3a3a96fe4aef5cdb32fe
M4S working branch: godot/m4s-metadata-branch-clean-checkout-finalization
protective stash: stash@{0} exists / read-only observed / untouched
```

## 2. 分类规则

| 分类 | 含义 |
| --- | --- |
| current-main | 当前 main / origin/main 或等价主线引用 |
| active-merge-candidate | 当前有新内容、拓扑上可进入 release gate 的候选 |
| already-merged-keep | 已被 main 包含，保留分支证据即可 |
| archive-candidate | 历史分支，未来可由独立治理阶段判断归档 |
| needs-human-decision | 含 main 未含内容或语义冲突，需要人工决策 |
| stale-experiment | workflow / smoke / prototype 类实验分支 |
| blocked | 当前验证失败或存在路径污染，暂不可合并 |

## 3. 重点分支结论

| 分支 | hash | main...branch | merged into main | 分类 | 结论 |
| --- | --- | --- | --- | --- | --- |
| `main` / `origin/main` | `786c898` | `0 / 0` | yes | current-main | M4 完成后的当前主线；包含 G39、ART15/17、M4 repository sync governance。 |
| `godot/g39-navigation-boundary-route-closure` | `e9c17cb` | included in main history | yes | already-merged-keep | 已被 M4 main 包含，保留分支证据。 |
| `godot/art15-art17-visual-ui-cleanup` | `7d405cc` | included in main history | yes | already-merged-keep | ART15/17 已进入 M4 main；保留分支证据，不再作为待合入阻塞。 |
| `godot/latest-verifiable-state` | `786c898` | `0 / 0` | yes | superseded-by-main | 临时最新可验证整合分支，内容已等价于 M4 main，可保留至后续归档阶段。 |
| `godot/m4-repository-sync-metadata-validation` | `195f29b` | content cherry-picked into M4 main as `786c898` | yes | superseded-by-main | M4 docs/tools 治理内容已进入 M4 main；原分支保留历史证据。 |
| `godot/m4s-metadata-branch-clean-checkout-finalization` | pending | ahead of M4 main | no | active-governance-finalization | M4S 当前执行分支，只允许 metadata policy、branch governance、validator、ignore/attributes 与 clean checkout 证据。 |
| `docs/doc-gov-001` | `634ffa6` | `20 / 0` | yes | already-merged-keep | 已包含于 main，保留历史分支。 |
| `docs/doc-gov-002` | `909a71a` | `10 / 1` | no | needs-human-decision | 含 ART-12 文档治理 backlog，需人工决定是否仍有未合入价值。 |
| `godot/g9-ui-final-integration` | local `eb9f5d6`, origin `ad1aeae` | local ahead origin | yes to main lineage | needs-human-decision | 本地与远端不同步，且历史 UI 分支已被后续 main 覆盖；不得自动删除或 force push。 |
| `godot/m2-latest-planning-minimum-gameplay-meta-loop` | `e4aee9b` | `10 / 1` | no | needs-human-decision | 存在 main 未含内容，但后续 M2/M3/M3H 分支已进入 main；需人工判断是否为旧分叉残留。 |
| `godot/g27-asset-domain-warehouse-view-contract` | `4432333` | `36 / 1` | no | needs-human-decision | 含 ART-05 Lua asset candidate registry；需与 G27A/G28 后续证据比对。 |
| `workflow-smoke/*` | pruned remote removed | n/a | n/a | stale-experiment | 本轮 fetch 已删除一个远端 workflow-smoke 引用；不执行远端分支删除。 |
| `origin/lua-prototype-main` | `d53d117` | `132 / 0` | yes | already-merged-keep | 只作历史 Lua prototype 证据，不作为当前 Godot release candidate。 |

## 4. 已合入主线的工程分支

以下分支均被当前 `main` 包含，建议保留为历史证据，不进入合并队列：

```text
godot/m3r-item-usability-completion
godot/m3h-item-loop-hardening-metadata-hygiene
godot/m3-minimum-item-drop-loop
godot/m2-lua-ue-effect-first-playable-loop
godot/g38-runtime-architecture-finalization
godot/g37-runtime-authority-validation-supplement
godot/g37-runtime-authority-runflow
godot/g36-runtime-architecture-save-profile
godot/g35-runtime-safety-ownership-cleanup
godot/m1-playable-prototype-loop
godot/g34-rule-effect-modifier-content-delivery
godot/g33-room-type-tag-encounter-common-rule
godot/g32-run-flow-state-transition-full-content
godot/g31-run-map-room-state-foundation
godot/g30-long-term-asset-interface-full-content
godot/g29-deploy-prep-revision-full-content
godot/g28-item-asset-content-warehouse-view-foundation
godot/g27a-asset-domain-warehouse-view-contract
godot/g26-integrated-structure-docs-firstreal-closeout
godot/g26-engineering-architecture-structure-readiness
godot/g25-ui-structure-playable-route
godot/g24-long-term-content-framework-foundation
godot/g23-settlement-history-snapshot-foundation
godot/g22-deploy-prep-full-module-content-preview
godot/g21-asset-item-flow-contract
godot/g20-project-knowledge-governance
godot/g19-long-term-shell-foundation
godot/g18-deploy-prep-foundation
godot/g18-align-deploy-prep-asset-view
godot/g17-app-shell-main-menu
godot/g16-combat-encounter-foundation
godot/g15-encounter-contract-foundation
godot/g10-progress-art-smoke-foundation
godot/pre-g10-project-baseline-consolidation
godot/g9-ui-presentation-layering-revision
godot/g8-2-runtime-parse-hotfix
godot/g8-2-kernel-protocol-hardening
godot/g8-1-architecture-hardening
godot/g8-rules-asset-ledger-core
godot/g7-lua-ux-flow-parity-p2
godot/prototype-foundation
godot/lua-parity-p0
```

## 5. ART15/17 / latest-verifiable-state / M4S 判断

```text
M4 main final hash = 786c898388896eb6654e3a3a96fe4aef5cdb32fe
ART15/17 final branch hash = 7d405ccc9f0ad656a62cadcf9c9e27096a4d5434
latest-verifiable-state = 786c898388896eb6654e3a3a96fe4aef5cdb32fe
M4 repository sync governance source branch = 195f29b8844e96d83d3fb6645f64f96c2455bfb9
```

结论：

```text
ART15/17 已进入 M4 main，不再是待合入 blocker。
latest-verifiable-state 与 M4 main 等价，可视为临时验证分支，后续可由独立分支治理阶段归档。
M4S 不修改 gameplay / ART UI content / G39 route logic，只补齐 metadata policy、ignore/attributes、validator portability 与 clean checkout 验证。
```

当前症状解释：

```text
历史症状已解释为：G39 main 曾先行包含调用关系，而 ART15/17 完整实现尚未进入当时 main。
M4 main 786c898 已收敛该问题；M4S 继续处理生成 metadata 和 clean checkout 验证。
```

## 6. 不执行项

```text
未删除本地或远端分支。
未 force push。
未 push main。
未触碰 stash。
未把 needs-human-decision 分支自动归档。
```
