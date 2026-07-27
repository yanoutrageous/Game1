# Current State

文档状态：I3R 活动返工事实；I3 保持关闭历史。
最后更新：2026-07-27

## 当前身份

    active_repo: git rev-parse --show-toplevel
    observed_branch: codex/i3r-player-experience-rework
    i3_historical_head: 09aaafe283aa2e4c2f30708c5f88b89ebf7753eb
    i3_historical_tree: a077da34237dce5e4a6081d833efd939098b4641
    i3r_entry_head: 35189aaf524157761d1ab9cdddc39e76baa0d7ca
    i3r_entry_tree: 82f100059add24ecb2c12e7fca0bfb17f3a95c50
    current_stage: I3R / ACTIVE / EXTERNAL_ACCEPTANCE_PENDING
    latest_closed_non_art_baseline: I2 / CLOSED / PASS_WITH_NOTES
    latest_closed_art_stage: ART21
    later_scoped_page_ui_evidence: ART23
    successor_authorization: USER_AUTHORIZED_I3R
    godot_project: <active_repo>/Godot/GraytailGodot
    local_godot_observation: E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe

## I3R 当前目标

- 以 I3 的条件式 closeout 历史作为返工入口，不改写其原始证据，也不把它提升为
  已生效的闭合基线。
- 修复战斗输入、命中几何、视觉碰撞和局内玩家体验。
- 建立字体、边框材料、九切、安全区和长文本验收。
- 教程作为出发探索地图 catalog 中的特定模式，不新增独立生产入口。
- 完成局内、局外、Base、治理、快速预览和全链路玩家验收。

路径和 Godot 工程位置必须动态解析。本机盘符只记录关闭时观测，不是跨机器权威。

## I3 条件式 closeout 事实

- I3.0–I3.7 是同一阶段。其前审计、实现、定向验收、完成审计和反馈处置分别由总契约、
  切片台账、validation、handoff 与反馈矩阵保存。
- 地图形成 5×5 玩家中心局部小地图与共享公开语义，展开图支持选择/确认分离以及
  Esc、右键和外点关闭，同时保持 KnownMap 防泄漏。
- 箱子形成搜索、揭示、稳定查看与拾取闭环；已开箱再次靠近直接展示；地面物靠近自动
  显示但拾取仍走显式权威命令。
- HUD、背包、世界物品、替换和结果面复用共享物品描述；输入走单一路径，角色表现支持
  appearance/animation-set 替换，减弱动态保留静态可读姿态。
- 战斗补入场、预备、命中、恢复和死亡表现；战斗房离开必须显式确认；特殊房、撤离和
  成功/失败/放弃结果改为玩家可解释信息，保存失败重试保持幂等。
- 主菜单角色真实走入洞口，长期系统转场整体下移；Deploy 地图仍是同页双栏；Settings
  schema v4 的主/效果音量真实应用 AudioServer，并保存震动、减少动态和 UI 缩放；
  长期系统投影真实三分支天赋目录。
- RunScene 的模态、调试、结果和路由职责已迁入边界控制器；冻结树为
  2974 行/161 函数，低于 2980/176 预算；这不是全面解耦声明。

## 生产与 Base 证据

- 局内三条 production runner 与局外、教程生产旅程都从真实 `main.tscn` 开始并使用
  公开/解析输入；标准 20 张、满包 13 张、终局 15 张、局外 22 张以及教程首通/重播
  均有当前机器证据，覆盖成功、失败、放弃、满包替换、保存重试和空间转场。
- 最终生产预览 132 张、长期系统 125 张、状态画廊 12 张，共 269/269 张静态图已按
  原始分辨率完成 Codex 复核，未见阻断性裁切、模态偏心、对象/弹窗重叠或结果原因
  缺失。该检查不等于最终审美、动画/音频手感、真实设备或用户动态试玩签收。
- 25 份原始策划以原 basename、原字节和原 SHA 进入 sources/base/原始策划案。
- 1407 个 art/draw member 按 SHA-256 保存为 1012 个对象与 395 个 alias，折叠
  79,256,439 bytes；Base 本体不因分类自动准入。唯一显式 promotion 具备生产消费者、
  manifest、独立 runner 与 rollback 证据。

## I3 验证与性能（冻结历史）

    I3_BASE_IMPORT_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
    I3_BASE_COMMITTED_VERIFY=PASS files=1041 planning=25 art_members=1407 art_unique=1012 aliases=395
    I3_PRODUCTION_INPUT_JOURNEY=PASS headless_and_rendered
    I3_PRODUCTION_FULL_BAG_REPLACEMENT=PASS headless_and_rendered
    I3_PRODUCTION_TERMINAL_BRANCHES=PASS headless_and_rendered
    I3_FULL_WORKTREE=PASS_75_OF_75
    I3_FULL_WORKTREE_REPORT_SHA256=5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D
    I3_STAGE=CLOSED_PASS_WITH_NOTES

worktree full 中 42 个 runner 为纯 PASS，33 个为 PASS_WITH_CLEANUP_DIAGNOSTIC，
blocking 为 0，时长 785952 ms。首次 quick/full 失败、原因、补救和复验链见 I3
validation 原文。

冻结 headless CPU 五轮中，enemy5 与弹幕峰值主要分位改善或收敛；enemy1 的
p50/p95/p99/max 仍有约 +0.036/+0.099/+0.122/+0.447 ms 的低基数残余。该结果不能替代
目标设备 GPU/FPS、长局或输入手感。

## I3 条件式 closeout 未完成项与 I3R 当前处置

- I3R 已补入像素字体主/回退链、跨页材质安全区、9 个登记效果音、批量售卖、真实
  天赋目录、战斗攻击几何、局内对象描述和教程地图模式；完整生产预览矩阵已经生成
  并完成 Codex 视觉复核，仍需动态人工玩家签收。
- 目标设备 GPU/FPS、长局、真实控制器/音频设备、完整键鼠/手柄人工体验、CI、
  导出与发布仍未完成。
- 退出时 18 个生产 RefCounted/GDScript 资源仍在使用的生命周期 owner 债务。
- 跨进程 active-run 恢复、完整深层经济和更深内容仍不在本次已完成范围。
- RunScene 仍是大型协调器；I3 只关闭已登记的职责迁移，不宣称全面解耦。

## I3R 当前验证事实

截至 2026-07-27，本工作树已有以下机器证据：

    I3R_BASE_GOVERNANCE=PASS base_objects=1012 runtime_rows=178 consumer_direct_token=47 consumer_dynamic_contract=108 consumer_staging_no_consumer=6 consumer_no_production_consumer=17 alias_debt_groups=2
    I3R_LONG_TERM_CURRENT_GOVERNANCE=PASS modules=6 pages=25 runtime_assets=58 gacha_runtime=0 talent_furniture=dedicated historical_art23=preserved
    I3R_UE_GENERATED_SFX_IMPORT=PASS files=9
    I3_PRODUCTION_INPUT_JOURNEY=PASS checkpoints=20 screenshots=20 inputs=137 result=Extracted
    I3R_PRODUCTION_FULL_BAG_REPLACEMENT=PASS screenshots=13 inputs=222
    I3R_PRODUCTION_TERMINAL_ALL=PASS screenshots=15 inputs=129 outcomes=Abandoned,Failed reason=runtime_combat_projectile
    I3R_PRODUCTION_STATE_GALLERY=PASS_WITH_VISUAL_REVIEW_REQUIRED cases=12 codex_static_review=complete
    I3R_PREVIEW_MATRIX_STATUS=PASS_WITH_VISUAL_REVIEW_REQUIRED generated=132 expected=132 codex_static_review=complete
    I3R_LONG_TERM_MATRIX_STATUS=PASS_WITH_VISUAL_REVIEW_REQUIRED generated=125 expected=125 codex_static_review=complete
    I3R_FINAL_STATIC_VISUAL_REVIEW=PASS reviewed=269 expected=269
    I3R_QUICK=PASS runners=67 plain=43 cleanup=24 blocking=0
    I2_COMBAT_FRAME_BASELINE=PASS fixed_hz=60 scenarios=enemy1,enemy3,enemy5,projectile15
    I3R_FINAL_WORKTREE_FULL=PASS runners=96 plain=53 cleanup=43 hard_failures=0
    I3R_OUT_OF_RUN_PRODUCTION_JOURNEY=PASS checkpoints=22 screenshots=22 inputs=36
    I3R_TUTORIAL_PLAYER_JOURNEY=PASS cycles=completion,replay zero_pollution=true

定向门还覆盖真实 8 邻域“周围雷险” unknown/0/1/3/8、UI 100/125/150%、终局
保存失败重试与显式放弃、元进度 128-bit request id/512 收据上限、教程
`start_standard_run + tutorial_5x5`、四类事件、地图直接操作、字体 332 个控件/26 个
tooltip、战斗扇区/投射物扫掠和敌方预警。当前长期系统是 6 模块/25 页面；历史
ART23 的 6×27 页面和扭蛋素材只保留为冻结证据，不再充当当前生产合同。

最终机器证据为：

- full：`.tmp/i1/20260726T171400780Z_6f66cb6f/report.json`，96/96 PASS，
  53 plain、43 cleanup-diagnostic、0 hard failure、1053141 ms；manifest
  `11B32B377A244B9DDF98637020CC9F263ABCDEB488472FA624F11F5A0A575406`，
  report `3CDF02791EC61CD580B78489A4C5B2581EF7E974AADEEA897AF06FEBD1494BC4`，
  业务文件 2333，指纹
  `E7ACAA39576A6DFEEB8B22EA18C41B0914A008F84F33348637183B1541C25A1F`；
- 生产预览：`.tmp/i1/20260726T171343894Z_6892a1f1/i3r_preview_matrix/`
  `matrix_manifest.json`，132/132，SHA-256
  `DCB8DA67E8D19B496024585447987CEF1F77916A20325573F13E5D0EB72D7494`；
- 长期系统：`.tmp/i1/20260726T173939443Z_6d8ac659/i3r_long_term_matrix/`
  `matrix_manifest.json`，125/125，SHA-256
  `BE3535EB0CDBA9A181C5A5A2DD61890D290145019CD02E37F86A7CFE15B545F6`；
- 状态画廊：`.tmp/i1/20260726T174413001Z_03839547/i3r_production_state_gallery/`，
  12/12；wrapper SHA-256
  `5854567A235971BAF0B4689BF3B925A7E3E3229E157E9276FBAEABBB1CB7A7D2`，
  manifest SHA-256
  `3D5003B9C19161C8D79A75DAB017C9ABAA2BE8C5F7FD564DA26E62432F7C277D`。

full 之后只回写治理文档与空间终态，未修改 Godot 或 tools 业务内容；这些文档回写
由最终静态/治理检查单独复核，不反向伪装为 full 业务指纹的一部分。

## I3R 空间治理状态

- 当前归档含 123 snapshots（I3R 60）、543197 个快照文件记录与
  81804420162 logical bytes；CAS 为 6489 objects / 735449033 bytes。
- index SHA-256 为
  `16974A206B007F737CB4CC45163720F3D10AF1170A657EC1DD477B26DE61AEAE`；
  最终 verifier proof SHA-256 为
  `A9B1286576B9E877642F9B2D0FACC7FE90F22C06D40C14856A1C7C7D97A377C4`。
- 最终 full 快照已用 V2 独立复制恢复并完成两次完整树校验；proof SHA-256 为
  `ACE86F8E3614CBA2BB8E0A52EC82B1E3A320609422CF20FD17AC274F1D483195`，
  恢复副本已移除。
- 本轮 38/38 快照工作树按事务裁剪，live worktree 与 tombstone 均为 0；76 个
  `process_env` / `engine_hardlink_view` 瞬态目标与 752427027-byte 孤立 staging
  已在精确校验后移除，事故取证回执保留。
- 2026-07-27 当前 `E:\AGAME1` 为 `9.1937 GiB / 56331 files`，E 盘可用
  `112984649728 bytes / 105.2252 GiB`；相对本轮清理前增加
  `32890380288 bytes` 可用空间。

历史快照归档是存储治理证据，不是 I3R 功能进度。原始 `sources.zip`、Base 原始
策划案、Base 素材和运行时素材属于基线或生产来源，不得当作缓存清理。阶段 Git
worktree 也不是快照缓存：I2 含修改，I3/I3-baseline 虽可重建但可能绑定历史任务，
均未删除。以后最多保留一个活动验证镜像；候选提交与 exact-head 证据形成后，必须按
archive → verify → V2 restore → transaction prune 顺序清理，禁止通配或手工删除。

## I3R 关闭门

- 真实控制器/音频设备、减少动态和动态人工玩家体验；
- 目标设备 GPU/FPS、内存与长局稳定性；
- exact-head/full 与 Git 远端一致性由本次最终交付记录提供。

## 阶段与交付判断

项目继续处于增量开发与存量修改并行阶段，不是维护期。I2 是最新已生效闭合非美术
基线；I3 保留 worktree/full 与条件式 closeout 历史，但其 exact-head/full 和
push/remote-SHA 生效门没有完成。I3R 是当前活动返工阶段；ART21 仍是项目级
latest art，ART23 仍是 scoped page/UI evidence。

I3R.7 的 Base/长期系统治理门、最终工作树 full、最终矩阵、静态视觉复核和当前物理
空间收口均已满足。I3R 当前状态为 `ACTIVE / EXTERNAL_ACCEPTANCE_PENDING`；
用户已授权 exact-head/full 与 Git 交付，但人工/设备门仍须满足后才能关闭。
真实提交 SHA 由最终交付记录提供，不在本文预写。当前没有自动授权 I4、ART22 或其他
后继阶段。
