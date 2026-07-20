# I1 Incremental Development Baseline Validation

文档状态：`CLOSED_PASS_WITH_NOTES`
阶段：I1
最后更新：2026-07-21

## 1. 中文摘要

I1 的 static、preflight、quick、core、ui、full worktree、ART25 资源门和生产预览人工静态审查已经通过。最终提交态 full/head 在 `492d74fcdc94cb75e47401c203defd49dac11ae9` 上覆盖 39/39 blocking runner，污染、manifest、control、static 和 registration 守卫通过；九状态 × 三分辨率共 27 张最新生产预览已逐张检查，布局、层级、文字、无遮挡与无裁切通过。

implementation commit 与最小 newline safety fix 已推送到 `origin/codex/i1-baseline-stabilization`。GitHub Actions quick run `29760789712` 成功；该远端结果只证明 quick，本地提交态 full/head 是完整关闭权威。I1 因保留 cleanup、静态预览与人工/性能/恢复/发布排除项，关闭为 `PASS_WITH_NOTES`，且不自动授权下一阶段。

```text
worktree_acceptance: PASS_WITH_NOTES
committed_head_acceptance: PASS_39_OF_39
stage_closeout: CLOSED_PASS_WITH_NOTES
```

## 2. 验收对象

```text
active_repo: resolve with git rev-parse --show-toplevel
stage_branch_observed: codex/i1-baseline-stabilization
source_head_before_i1: 2212992337aeef7cda412dbaaa191c3ad6cbb81a
validated_worktree_base_head: 2212992337aeef7cda412dbaaa191c3ad6cbb81a
implementation_commit: 6a4f207d743583c7342655488c2d9a652b9ab05c
newline_safety_fix_commit: 492d74fcdc94cb75e47401c203defd49dac11ae9
validated_implementation_head: 492d74fcdc94cb75e47401c203defd49dac11ae9
validated_tree: 96a5272e50ff80aad400ccde3db9d313fa1456a1
godot_project: <active_repo>/Godot/GraytailGodot
engine_version: 4.6.3.stable.official.7d41c59c4
```

`SourceMode worktree` 的 mirror 包含当时 base HEAD 上的 tracked 与 untracked I1 candidate，只作为提交前证据。关闭对象由 `SourceMode head` 报告中的 HEAD 和 tree 精确标识。

## 3. Worktree 验收结果

| Gate | Result | Evidence | Boundary |
| --- | --- | --- | --- |
| I1 static inventory | PASS / 39 blocking / 46 inventory / 13 exclusions / 705 checks / 0 failures | `E:\AGAME1\.tmp\i1\20260720T161528162Z_4c36eeef\artifacts\static_validation.json`; SHA256 `BDED76696261E2478B831E3298AE9355E778747DE173CA4BEEA3A408162BD141` | registration and exclusion completeness |
| preflight worktree | PASS / 0 runner / 120,233 ms / pollution PASS | `E:\AGAME1\.tmp\i1\20260720T121125570Z_19409ad4\report.json`; SHA256 `C6896085B5A6004C039E78C1FAA2026C4A72085FDAB19E6AD8815FBA03420CF9` | mirror, locked engine, import and isolation |
| quick worktree | PASS / 21 of 21 / pollution PASS | `E:\AGAME1\.tmp\i1\20260720T092146483Z_e7b30fa7\report.json`; SHA256 `DD3B80EDFCC9363DBC654E0B3D5DC574ED0A2C38FA088DF57FDFF94621A8F370` | short cross-layer regression |
| core worktree | PASS / 24 of 24 / pollution PASS | `E:\AGAME1\.tmp\i1\20260720T093606696Z_e192e1a0\report.json`; SHA256 `7268CBA2F76D55FB3DE8C36BFE58830D16A366DE26EB3FA0DBCC8F19CF167166` | program invariants and combat microbenchmark |
| ui worktree | PASS / 23 of 23 / pollution PASS | `E:\AGAME1\.tmp\i1\20260720T100420457Z_fe521560\report.json`; SHA256 `B4B4C19E85038F4615284F995B84A981FC9D8434C3D692E0A420D0166063B600` | automated UI/layout/animation contracts |
| full worktree | PASS / 39 of 39 / 400,736 ms / pollution PASS | `E:\AGAME1\.tmp\i1\20260720T161528162Z_4c36eeef\report.json`; SHA256 `5A29A7FB2CA72326839479BB3B4354DE16934F579A7CC5870CBF1ED02F0F0E5B` | pre-commit evidence; mirror/manifest/control/static/registration/pollution PASS; fatal null |
| production preview generation | PASS_WITH_VISUAL_REVIEW_REQUIRED / 27 of 27 GENERATED_REVIEW_REQUIRED / complete set / pollution PASS | `E:\AGAME1\.tmp\i1\20260720T154608674Z_b8f19552\preview_report.json`; SHA256 `9600FC4E19CB2BDBDA9E29DDC162F4D3848BE6625D193F0A7764C0E35934972C` | PNG/hash/marker/exact-cleanup/manifest/control/mirror-fidelity generation gates; `visual_acceptance=NOT_RUN` |
| production preview human static review | PASS / 9 states × 3 resolutions | same latest 27 PNG files; reviewer inspection on 2026-07-20 | layout, hierarchy, text, no occlusion and no cropping only |
| ART25 source/license/content validator | PASS / 107 assets | `python tools/validate_art25_content_and_ui.py` | deploy 0.721 MiB; long-term 0.993 MiB; maps 8; commissions 6; shop 10; items 42 |
| ART25 deterministic generation | PASS | before/after fingerprint `CE8A6BFFA8AF81125956ECDA943E86A20B2DF53809C689C499029088D1BA061C` | generator output byte identity |
| project metadata gate | PASS in quick/core/full | `I1_PROJECT_METADATA=PASS` | Godot 4.6 feature, ContentDB/SettingsManager autoload and runtime ownership |
| document encoding/references/YAML/diff | PASS | encoding: 1,080 inventory / 474 text / 606 binary / 5 exact historical exceptions / 0 errors; references: 27 changed Markdown/YAML files / 196 literal repo-path references / 0 missing; capability YAML simple-subset: 98 lines / 93 keys / 0 errors; `git diff --check`: PASS | docs quality only |
| implementation/fix scope | PASS | implementation commit `6a4f207d743583c7342655488c2d9a652b9ab05c` = 110 files; fix commit `492d74fcdc94cb75e47401c203defd49dac11ae9` = one-file follow-up inside the same cumulative 110-path set | audited Git scope; no unauthorized generated metadata |
| first full committed HEAD | FAIL / 38 of 39 | `E:\AGAME1\.tmp\i1\20260720T162935175Z_b12b72eb\report.json`; SHA256 `60F1CEFB3918D4165DC7C48335AA3CA7AB3A425912CA6B87BCC45FFBBCF1BCF9` | only `I1_RUNTIME_SAFETY`; CRLF checkout versus LF-only test literal |
| final full committed HEAD | PASS / 39 of 39 / 291,203 ms | `E:\AGAME1\.tmp\i1\20260720T163703897Z_ba791ba4\report.json`; SHA256 `AF6F7C5A4B74B6E8E17FA89443E0DD77BCC25E6F0E2752E07DE707439B1E2851` | exact head `492d74f...`; tree `96a5272...`; 17 PASS + 22 cleanup; fatal null |
| implementation commit / push checkpoint | PASS | checkpoint `492d74fcdc94cb75e47401c203defd49dac11ae9`; closing audit verified local/upstream/remote equality by `ls-remote` at that checkpoint | pushed to `origin/codex/i1-baseline-stabilization` before the documentation-only closeout commit |
| GitHub Actions quick | PASS_QUICK_ONLY | run `29760789712`; job `88414602442`; <https://github.com/yanoutrageous/Game1/actions/runs/29760789712> | event push / head `492d74f...`; all quick steps success; does not prove full/export/release |

### 3.1 当前候选替换与失败证据

12:14 的 `E:\AGAME1\.tmp\i1\20260720T121452851Z_74d12c3d\report.json` 只保留为先前 worktree PASS 历史证据；其 fingerprint、duration 和性能数值不代表最终提交态关闭对象。

16:05 的 `E:\AGAME1\.tmp\i1\20260720T160545888Z_3407ef1b\report.json`（SHA256 `26421DDCECAC1FAE1F984AF36512F7580A1603940B690246E2EBC817DEC4F3CD`）为 `FAIL / 38 of 39`，唯一失败项是 `M5_ITEM_DROP_LOOP_FULL_CONTENT` 未找到确定性 altar。根因是 M7 后 `RunConfig.m7_map` 在缺少 seed 时使用时间，而 M5 旧测试夹具隐含依赖特定地图拓扑；修复仅在 M5 runner fixture 固定 `seed_value=1001`，不改 production 随机规则。该 runner 随后在独立进程连续 3 次 PASS，最终由 16:15 full 39/39 再覆盖。

implementation commit `6a4f207d743583c7342655488c2d9a652b9ab05c` 的首次 full/head 为 38/39，唯一失败项 `I1_RUNTIME_SAFETY`。提交态 checkout 把目标源码物化为 CRLF，而 runner 对生产源码硬编码 LF 文本；manifest/control/pollution 与其他 38 项均通过，`fatal_error=null`。fix commit `492d74fcdc94cb75e47401c203defd49dac11ae9` 只在该测试读取后规范化 CRLF/CR 为 LF，不放宽生产路由、缩进或安全断言。最终 full/head 39/39 覆盖该修复。

## 4. Preflight 性能与安全边界

最新 preflight 从旧观测的 189,405 ms 降至 120,233 ms，减少 69,172 ms / 36.5%。本轮关键时间为：source inspection 695 ms、mirror total 8,204 ms、cold mirror business hash 36,257 ms、Godot bootstrap 39,043 ms。

根因是旧路径进行 7 次包含 `.tmp` 历史 mirror 的全树扫描。当前实现改为一次剪枝源检查，再在复制完成后执行完整目标检查；`.git`、`.tmp`、Godot `.godot` 与 `reports` 的排除、目标完整性、manifest/control binding、mirror fidelity、import/isolation 和污染守卫均继续执行，没有以减少安全门换取耗时下降。

## 5. 战斗刷新性能证据

`I1_COMBAT_REFRESH` 在 production `main.tscn` 中使用 180 个 combat sample 和 40 个 full-refresh control sample：

| Profile | Combat p50 | Combat p95 | Combat p99 | Combat max | Full p95 | Result |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| core | 198 μs | 519 μs | 630 μs | 824 μs | 267,793 μs | PASS |
| pre-commit worktree full | 205 μs | 321 μs | 409 μs | 442 μs | 333,855 μs | PASS |
| final committed HEAD full | 110 μs | 222 μs | 310 μs | 356 μs | 151,070 μs | PASS |

上述三轮 combat p95 均低于 8 ms 且低于各自 full p95。该结论只证明 I1 combat-scoped refresh 微基准，不证明整局帧时间、内存、低端设备、通用性能或发布性能。

## 6. 可见审查边界

最新 preview wrapper 的机器状态仍是 `PASS_WITH_VISUAL_REVIEW_REQUIRED`，27 个 capture 记录为 `GENERATED_REVIEW_REQUIRED`；`capture_set_complete=true`，PNG hash、marker、exact cleanup、manifest/control binding、mirror fidelity 和污染守卫通过。I1 没有篡改机器报告中的 `visual_acceptance=NOT_RUN`。

随后对 `main_menu`、`deploy`、`long_term`、`run`、`combat`、`inventory`、`map`、`result_success`、`result_failure` 在 1280×720、1600×900、1920×1080 的 27 张 PNG 逐张人工检查，静态布局、层级、文字、无遮挡与无裁切结论为 PASS。鼠标/手柄交互手感、动态动画观感、音频和打击体感仍为 `EXCLUDED_NON_SLICE`，不得从静态图推断。

该 15:46 preview 早于随后进行的 `game_kernel` diagnostic 校准、M5 测试夹具 seed 修复和 runtime-safety newline 测试修复。这些变化都没有改变 UI 可见执行路径，因此这 27 张静态视觉证据继续适用于关闭对象，无需伪造一次未运行的视觉 wrapper PASS。

## 7. 验收中修复与校准

- I04 历史 GroundLootPanel / `seed 2+0` 契约校准到当前 world-context 入口和 `1 floor + 1 backpack` 语义；行为 runner 随后进入 39/39 full PASS。
- 三个 ART24 Node probe 改为 SceneTree runner，使其生命周期和退出码受统一 harness 管理。
- 新增 `ContentDBAccess`，消除可复用脚本在编译期对 autoload symbol 的耦合；production autoload 权威仍由 `ContentDB` 和 `I1_PROJECT_METADATA` 验证。
- 修复 run/combat 底部双行状态框的边框内距与行高，并把 deploy 摘要收敛为单行；`I1_UI_INTERACTION` 三分辨率契约与 ART22 34 状态定向 runner 均 PASS，且由最新 full 39/39 覆盖。
- M5 legacy characterization fixture 固定 `seed_value=1001`，移除对 M7 无 seed 时间随机地图恰好生成 altar 的隐式依赖；production 随机规则未改变。

这些是为恢复当前行为契约与可复用编译边界所做的校准，不把旧静态结构恢复为当前架构。

## 8. Cleanup diagnostic

最终 full/head 中 17 个 runner 为纯 `PASS`，22 个为 `PASS_WITH_CLEANUP_DIAGNOSTIC`；共有 44 条已分类 shutdown cleanup diagnostic，blocking diagnostic 和 missing expected cleanup diagnostic 均为 0。污染守卫证明测试前后 Git 状态与 2,121 个 business file 的 fingerprint `6367CCAB6D542F8B9562EA09E484FC40104E2D8843F1085A8191A18EEEF15460` 不变。

cleanup diagnostic 继续作为非阻断技术债保留。I1 没有把它写成已解决，也没有把已分类 cleanup 扩写为 blocking-free engine shutdown。

## 9. 历史 validator 漂移记录

旧阶段独立 validator 保留历史证据属性，不是 I1 acceptance 入口：

- G35 static validator 仍断言已迁移的 DeployPrep/RunBootstrapper 预览边界。
- G36 static validator 仍断言 terminal commit authority 位于迁移前模块，而 I1 已把该权威集中到 `RunRuntimeController`。
- M3/M3H/M3R/M5 wrapper 会无条件拒绝本次经过专门 gate 的 `project.godot` 变化；M3/M3H 还带有旧结算语义或 CommandBus 内联 handler 结构断言。

当前 acceptance 使用 `tools/i1` manifest 中校准后的行为 runner，并以 `I1_PROJECT_METADATA` 单独验证 project metadata。旧 wrapper 不得标成当前 PASS，也不应驱动当前代码回退。

## 10. 明确排除

- GitHub Actions full、导出与 release；远端 quick 只证明 quick profile；
- 完整人工长时间游玩；
- 鼠标、手柄、动画与打击手感的最终可见验收；
- 除 combat refresh 微基准外的通用性能；
- 退出进程后的 active-run 检查点恢复；
- 最终美术、音频、完整经济与全部内容；
- 导出和发布。

## 11. 历史美术证据边界

- 项目级最新闭合美术阶段：ART21。
- ART23：较晚、已验收的页面/UI 运行证据切片；可作回归证据，不提升项目级阶段权威。
- ART24R2：`FAIL (24/61 PASS)` 后封存的历史尝试；I1 不改写其结果。
- I1 UI/资源/动画改善：已通过 I1 范围证据，不自动生成新的 ART stage。

## 12. 关闭结果

```text
validated_implementation_head: 492d74fcdc94cb75e47401c203defd49dac11ae9
validated_tree: 96a5272e50ff80aad400ccde3db9d313fa1456a1
full_head: PASS_39_OF_39
final_implementation_scope: PASS_110_DISTINCT_PATHS_WITH_1_FILE_FOLLOWUP
commit: PASS
push: PASS_ORIGIN_CODEX_I1_BASELINE_STABILIZATION
ci_quick: PASS_RUN_29760789712
ci_full_export_release: NOT_CLAIMED
overall_worktree: PASS_WITH_NOTES
overall_stage: CLOSED_PASS_WITH_NOTES
```

I1 关闭不消除 22 个 cleanup runner，也不提升静态预览为动态视觉/交互 PASS；完整人工长局、鼠标/手柄与动画手感、音频、通用性能、跨进程恢复、导出和发布继续保留。当前无自动授权的后继阶段。
