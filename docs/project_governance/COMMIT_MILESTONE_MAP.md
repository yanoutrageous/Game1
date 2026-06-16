# Commit Milestone Map

## R3d1 Scope

本文件是 G20-R3d1 的提交到阶段映射。它根据 `git show`, `git log`, 当前状态文档、handoff 与 validation 文档整理 G10-G20 的关键提交，不改写历史，不新增最终 R3d1 hash。

- `merged_to_main` 表示该提交或阶段在当前事实源中是否已经进入 mainline；它不是分支删除授权。
- G20 已通过 fast-forward 合并 main；first main merge baseline 为 `ae689b7464fd6ea81a763110cd89813abcfb6665`。
- G20-R3d1、G20-R3d2、G20-R4A blocker fix 和 G20-R4B closeout 的已知提交 hash 已在本文件记录；post-merge docs commit hash 保留 pending until commit，不得补猜。
- 不足或不确定项必须写 `unknown` 或 `not recorded in this map yet`，不得补猜。

## Map

| stage | commit | short_hash | subject | role | branch | merged_to_main | evidence_source | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| G10 | `cf6e73d16574f6b900d18217471522aa18a6ab10` | `cf6e73d` | `feat(godot): add G10 progress and art smoke foundation` | implementation | `godot/g10-progress-art-smoke-foundation` | yes | `git show`; `docs/stage_summaries/G10_SUMMARY.md` | G10 foundation implementation. |
| G10 | `aa19db2f1989c6ebfc22676d84b83da5c6977f64` | `aa19db2` | `chore(godot): close G10 progress art smoke` | branch closeout | `godot/g10-progress-art-smoke-foundation` | yes | `git show`; `docs/MILESTONES.md` | Required G10 closeout commit. |
| G10 | `53a4e122376998d2f6d0a2a617b753a3d382b2f0` | `53a4e12` | `docs: calibrate G10 closeout facts after merge` | post-merge docs calibration | `main` | yes | `git show`; `docs/stage_summaries/G10_SUMMARY.md` | G10 closeout fact calibration after merge. |
| G11 | `e261ac7d8671b59e7e72750122e6581af6ea6644` | `e261ac7` | `fix(godot): improve G11 mainline UX readability` | implementation | `main` | yes | `git show`; `docs/MILESTONES.md` | G11 mainline readability repair. |
| G11 | `4be0010dd68abe1b0e74966775db64f736d78e15` | `4be0010` | `docs: close G11 mainline UX readability pass` | closeout | `main` | yes | `git show`; `docs/MILESTONES.md` | G11 docs closeout. |
| G12 | `2855ca9889e394fb79d22c468b1355cd3871fd39` | `2855ca9` | `fix(godot): align G12 core loop readability with legacy demo` | implementation | `main` | yes | `git show`; `docs/MILESTONES.md` | G12 legacy Demo readability alignment. |
| G12 | `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f` | `e90bd27` | `docs: close G12 legacy demo parity pass` | closeout | `main` | yes | `git show`; `docs/MILESTONES.md` | G12 closeout and G13 baseline. |
| G13 | `5afdb05fefe65031da1486507b0b39bdd2f1cea7` | `5afdb05` | `feat(godot): add fixed resolution layout support` | implementation | `main` | yes | `git show`; `docs/MILESTONES.md` | G13 fixed 16:9 resolution support. |
| G13 | `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf` | `8878bd3` | `docs: close G13 resolution layout adaptation pass` | closeout | `main` | yes | `git show`; `docs/MILESTONES.md` | G13 closeout and G14 baseline. |
| G14 | `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5` | `1d33c89` | `feat(godot): add legacy demo run surface shell` | implementation | `main` | yes | `git show`; `docs/MILESTONES.md` | G14 run surface shell. |
| G14 | `39b51f165b548cc28fef072675f846413513f2ed` | `39b51f1` | `docs: record G14 run surface acceptance follow-up` | acceptance follow-up | `main` | yes | `git show`; `docs/MILESTONES.md` | G14 acceptance follow-up. |
| G14 | `cc652e5a616359d7d6857c87da5f76c6aca25c28` | `cc652e5` | `feat(godot): refine legacy demo run surface presentation` | implementation follow-up | `main` | yes | `git show`; `docs/MILESTONES.md` | G14 display refinement. |
| G14 | `fc2b86b6b6b2af9a6c249230621482617b594775` | `fc2b86b` | `fix(godot): resolve RunSurface parser type inference` | parser hotfix | `main` | yes | `git show`; `docs/MILESTONES.md` | Parser compatibility hotfix only. |
| G14 | `d6c03c6ff8ca9884f992a61e27728bdddf3a637a` | `d6c03c6` | `docs: close G14 legacy demo UI surface pass` | closeout | `main` | yes | `git show`; `docs/MILESTONES.md` | G14 docs closeout. |
| G15 | `aca5b958a588879a16da97616484424da795da7f` | `aca5b95` | `feat(godot): add encounter contract foundation` | implementation | `godot/g15-encounter-contract-foundation` | yes | `git show`; `docs/stage_summaries/G15_SUMMARY.md` | G15 rules-layer encounter contract. |
| G15 | `1887385af81624ebcd84342ca765d75e6fbf20eb` | `1887385` | `feat(godot): add encounter slot surface adapter` | UI adapter | `godot/g15-encounter-contract-foundation` | yes | `git show`; `docs/stage_summaries/G15_SUMMARY.md` | G15 EncounterSlot adapter. |
| G15 | `e72d3a5dc4a57122d42f881f391f2b47389fcdad` | `e72d3a5` | `docs: close G15 encounter framework foundation` | branch closeout | `godot/g15-encounter-contract-foundation` | yes | `git show`; `docs/MILESTONES.md` | G15 branch closeout. |
| G15 | `a28ae4c0c96f0b964602fd6fe7b88fa254354763` | `a28ae4c` | `docs: mark G15 merged to main` | post-merge docs calibration | `main` | yes | `git show`; `docs/stage_summaries/G15_SUMMARY.md` | G15 mainline merge status. |
| G16 | `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a` | `fb18aa0` | `feat(godot): add combat encounter foundation` | implementation | `godot/g16-combat-encounter-foundation` | yes | `git show`; `docs/stage_summaries/G16_SUMMARY.md` | G16 Monster/combat foundation. |
| G16 | `8a0e0c3e718a30c1f0afd210b46ecfa564d16468` | `8a0e0c3` | `docs: close G16 combat encounter foundation` | closeout | `godot/g16-combat-encounter-foundation` | yes | `git show`; `docs/MILESTONES.md` | G16 docs closeout. |
| G16 | `4637e8fa0eeec6859df4eab26d5a961868e4c071` | `4637e8f` | `fix(godot): expose encounter parser classes` | parser blocker fix | `godot/g16-combat-encounter-foundation` | yes | `git show`; `docs/stage_summaries/G16_SUMMARY.md` | Parser fix before main integration. |
| G16 | `9af74aeefd3a28b6b417fa0667532737cddc916b` | `9af74ae` | `docs: mark G16 merged to main` | post-merge docs calibration | `main` | yes | `git show`; `docs/stage_summaries/G16_SUMMARY.md` | G16 mainline merge status. |
| G17 | `368a7be5c2fb919db47421a026ddf417df9c1b1c` | `368a7be` | `feat(godot): add app shell main menu foundation` | implementation | `godot/g17-app-shell-main-menu` | yes | `git show`; `docs/stage_summaries/G17_SUMMARY.md` | G17 AppShell/MainMenuShell foundation. |
| G17 | `baa57fa41167c86ad226b5b8be4d540ff114269f` | `baa57fa` | `docs: close G17 app shell main menu foundation` | branch closeout / first main merge baseline | `godot/g17-app-shell-main-menu` | yes | `git show`; `docs/MILESTONES.md` | G17 closeout and mainline baseline. |
| G17 | `eeffe5800864c05f8b000e406609fa7ca3323cb5` | `eeffe58` | `docs: mark G17 merged to main` | post-merge docs calibration | `main` | yes | `git show`; `docs/stage_summaries/G17_SUMMARY.md` | G17 merge status; G18 baseline. |
| G18 | `59ea57caf1baa977e727da2697cac014cbd7429e` | `59ea57c` | `feat(godot): add deploy prep shell foundation` | implementation | `godot/g18-deploy-prep-foundation` | yes | `git show`; `docs/stage_summaries/G18_SUMMARY.md` | G18 DeployPrepShell foundation. |
| G18 | `285695cda0141322b0672d65998f3d3f9aa32654` | `285695c` | `docs: close G18 deploy prep foundation` | branch closeout / first main merge baseline | `godot/g18-deploy-prep-foundation` | yes | `git show`; `docs/MILESTONES.md` | G18 closeout and mainline baseline. |
| G18 | `0e44c261f399a197d6e6eec277eb51ce72e1ba8c` | `0e44c26` | `docs: mark G18 merged to main` | post-merge docs calibration | `main` | yes | `git show`; `docs/stage_summaries/G18_SUMMARY.md` | G18 merge status; G19 baseline. |
| G19 | `4eeb345daef5f8263b325db2ab5607e6c78f6d36` | `4eeb345` | `feat(godot): add long term shell foundation` | implementation | `godot/g19-long-term-shell-foundation` | yes | `git show`; `docs/stage_summaries/G19_SUMMARY.md` | G19 LongTermShell foundation. |
| G19 | `04e14865f4d5eff7b16398d5730054273ccd0823` | `04e1486` | `docs: close G19 long term shell foundation` | branch closeout / first main merge baseline | `godot/g19-long-term-shell-foundation` | yes | `git show`; `docs/MILESTONES.md` | G19 closeout and mainline baseline. |
| G19 | `ef362dc01bb4303408e86c2441cf9ae8b4379e1d` | `ef362dc` | `docs: mark G19 merged to main` | post-merge docs calibration | `main` | yes | `git show`; precheck `origin/main` | Current main / origin/main fact source. |
| G20-R3a | `caaf3c5eb0559a395b9940dacd05dc5810bcd1d7` | `caaf3c5` | `docs: import design sources for G20 governance` | design source text import | `godot/g20-project-knowledge-governance` | yes | `git show`; `docs/NEXT_HANDOFF.md` | Base Docs Markdown / TXT copies imported under `docs/design_sources/`; originals not modified. |
| G20-R3b | `81513bdbf10cf4f774a9bda5c3ce3e2d3b1302dc` | `81513bd` | `docs: add project governance maps` | governance maps and indexes | `godot/g20-project-knowledge-governance` | yes | `git show`; `docs/ENGINEERING_STATUS.md` | Project governance and design source index structure. |
| G20-R3c | `10a2dd3ea2d71879b66f5d1c20177fb7bed2a6f1` | `10a2dd3` | `docs: add G10-G19 stage summaries and route analysis` | stage summaries and route analysis | `godot/g20-project-knowledge-governance` | yes | `git show`; precheck G20 HEAD | Stage summaries and route analysis. |
| G20-R3d1 | `493a5649ea114609abbf28bc07d3e25582fca7ae` | `493a564` | `docs: add branch commit and validation governance matrices` | branch / commit / validation governance matrices | `godot/g20-project-knowledge-governance` | yes | G20-R3d1 commit | Final hash filled after commit existed. |
| G20-R3d2 | `ef30741902f0cf9e9984e20de3ceef696b30523a` | `ef307419` | `docs: add decision glossary and deprecated inventories` | decision log / glossary / temporary deprecated inventory | `godot/g20-project-knowledge-governance` | yes | G20-R3d2 commit | Docs-only R3d2 governance inventory batch. |
| G20-R4A | `82e2b1c6bec8311a144b42dd69950e4bfd500d9c` | `82e2b1c` | `docs: fix G20 R3d2 validation status` | read-only acceptance blocker fix | `godot/g20-project-knowledge-governance` | yes | `git show`; G20 validation | R4A blocker fix; docs-only. |
| G20-R4B | `ae689b7464fd6ea81a763110cd89813abcfb6665` | `ae689b7` | `docs: close G20 project knowledge governance` | branch closeout / first main merge baseline | `godot/g20-project-knowledge-governance` | yes | `git show`; first main merge precheck | G20 docs-only closeout; no Godot run. |
| G20-final-post-merge | pending until commit | pending | `docs: mark G20 merged to main` | post-merge docs calibration | `main` | yes after final merge | this execution | G20 final post-merge docs commit hash pending until commit. |

## Explicit Non-Claims

- G20 is merged to main.
- G20 final post-merge docs commit hash is pending until commit.
- G21 is not started.
- R3d1 does not create or fill R3d2 files.
- Parser smoke, manual playtest, and full gameplay runtime status are tracked separately in `docs/project_governance/VALIDATION_STATUS_MATRIX.md`.
