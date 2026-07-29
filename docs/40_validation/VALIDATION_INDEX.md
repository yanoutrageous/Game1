# Validation Index

文档状态：I4 活动验证入口；I3R 保持被 I4 接管前的历史机器证据。
最后更新：2026-07-30

## I4 活动入口

- 总契约：`docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md`
- 执行台账：`docs/00_governance/I4_EXECUTION_LEDGER.md`
- 需求矩阵：`docs/00_governance/I4_REQUIREMENT_MATRIX.md`
- 运行手册：`docs/30_engineering/godot/I4_REPRODUCIBLE_PRODUCTION_VALIDATION_RUNBOOK.md`
- 工具入口：`tools/i4/README.md`
- entry commit：`4127bd27a05b75cb5e3071cf6dc87d9287f679a9`
- entry tree：`e1455ffd8c7a754c63eb2141a47e41f8fe5cdf3a`

I4 当前处于计划审计和入口治理。未在 I4 台账登记的 I3R 报告不得作为 I4 PASS。
当前已完成的定向证据仅有：

| 门 | 当前结果 | 证据与边界 |
| --- | --- | --- |
| I4 Base overlay Windows 换行复现 | TARGETED PASS | 入口 exact-head 首次执行复现三份 CSV 仅 CRLF/LF 不同；验证器现只归一化行尾，真实字段变化仍 `OVERLAY_DRIFT`；`tools/i3r/tests/test_base_governance_overlay.py` 新增正反测试。完整 exact-head 尚未执行。 |
| I4 入口 Git/dirty 审计 | PASS | 本地/远端入口均为 `4127bd2`，ahead/behind 0/0；Godot 生成 metadata 保存至命名 stash，未并入 I4。 |

## I3R 历史入口

- 总契约：docs/20_product/I3R_PLAYER_EXPERIENCE_REWORK_CONTRACT.md
- 执行台账：docs/00_governance/I3R_EXECUTION_LEDGER.md
- 需求矩阵：docs/00_governance/I3R_REQUIREMENT_MATRIX.md
- I3 历史关闭对象：`09aaafe283aa2e4c2f30708c5f88b89ebf7753eb` /
  tree `a077da34237dce5e4a6081d833efd939098b4641`
- I3R entry/base：`35189aaf524157761d1ab9cdddc39e76baa0d7ca` /
  tree `82f100059add24ecb2c12e7fca0bfb17f3a95c50`

下方 I3R 证据保持历史原义。用户后续生产反馈没有接受字体、遮挡、信息语义、数量
操作和任务链体验；这些开放项由 I4 接管。不得使用下方 I3R 机器/静态证据宣称 I4
或动态玩家体验已经通过。

## I3R 当前证据

| 门 | 当前结果 | 证据与边界 |
| --- | --- | --- |
| I3R.7 Base / SFX 治理 | PASS | 25 原始策划案与 1012 个唯一 Base 对象；178 行 crosswalk / 175 条 runtime 路径 / 149 个 runtime SHA；消费者证明为 47 direct-token + 108 dynamic-contract + 0 scene-resource + 6 staging-no-consumer + 17 no-production-consumer；1 个 promotion 具备真实生产链；2 个跨语义 alias 债务组保持开放；9 个登记 SFX |
| 当前 I3R.6 教程路由、交互与生产旅程 | PASS_WITH_EXTERNAL_BOUNDARY | 当前合并套件：`tutorial_5x5` 仍从 Deploy 可见目录进入 `standard_run`，无独立教程接口；真实 `main.tscn` 首通/重播、completion-only、零金币/物品/salvage 污染和正确返回路由 PASS；事件真实生产顺序 `trap→dice→altar→trader`；地图鼠标/`ui_accept` 同源且一次执行、非阻塞提示可主动关闭；1280×720/1920×1080 × 100/125/150% 布局及 1280×720@150% 范围化视觉复核 PASS；证据 `.tmp/i3r6_final_combined_20260726` 与 `.tmp/i3r6_popup_fix/visual/capture.png`；真实设备与动态玩家签收 pending |
| 角色移动与外观替换 | TARGETED PASS | `I3R_PLAYER_MOVEMENT_APPEARANCE`：InputMap 连续位移、拒绝无回弹、局内 Sprite2D 消费审计安全 `field_coat` 色型、未拥有/未知 catalog fail closed、受击色与 profile 组合后精确恢复；生产获取/选择 UI、跨局外场景一致、真实时装资产与交易、动态手感 pending |
| 战斗障碍生产旅程 | TARGETED PASS | `I3R_PRODUCTION_COMBAT_OBSTACLE_JOURNEY`：seed 13、真实 `main.tscn`、64 次解析输入；移动阻挡及拒绝后恢复、近战自然绕障、held 门单次拒绝/零 transition dispatch、敌预警、攻击期朝向锁定后释放、早按拒绝不耗回合、后段缓冲、遮挡视觉裁剪/blocked/no-hit、无遮挡 one-hit、结算和正常离房 PASS；真实设备/GPU/玩家签收 pending |
| 输入、弹层与破坏性确认 | TARGETED PASS | `I3R_INPUT_MODAL_AUTHORITY` + `I1_TERMINAL_AUTHORITY`：RunScene 无 raw stack；Deploy 放弃/批售 stale 与 wrong-top fail closed；CommandBus 拒绝未确认放弃；真实 Deploy 确认后结果层/焦点/返回一致且不误开新局；物理手柄与玩家签收 pending |
| 门呈现与交互同源 | TARGETED PASS | `I3R_WORLD_OBJECT_PRESENTATION_CONTRACT`：房型/方向贴图、裁切、轴点、显示尺寸、`body_rect`、近距提示、过门对齐及入口落点同源；动态玩家观感 pending |
| `RunScene` 架构边界 | TARGETED PASS | `I3R_RUN_SCENE_ARCHITECTURE_BOUNDARY`：`RunSceneModalController` 以私有 `_focus_stack` 接入生产 `main.tscn`，RunScene 不暴露 raw stack；冻结树 2974 行 / 161 函数，预算 2980 / 176；相邻回归 PASS；仍是大型协调器，继续提取不是本次关闭硬要求 |
| I3R.7 当前长期系统治理与缩放反自证 | PASS_WITH_EXTERNAL_BOUNDARY | `I3R_LONG_TERM_CURRENT_GOVERNANCE=PASS`：6 模块/25 页面/58 runtime 资产、`gacha_runtime=0`、独立 talent furniture、历史 ART23 保持冻结；最终 25 页×5 分辨率矩阵 125/125，100/125/150% 真实字号/布局变化和截图 SHA 互异门 PASS；`.tmp/i1/20260726T173939443Z_6d8ac659/i3r_long_term_matrix/matrix_manifest.json`，SHA-256 `BE3535EB0CDBA9A181C5A5A2DD61890D290145019CD02E37F86A7CFE15B545F6`；Codex 静态复核完成，动态玩家签收 pending |
| I3R 当前 UI 定向截图迁移 | PASS | `docs/40_validation/i3r_ui_current/`：将原先只存在于当前线程缓存的 FusionPixel/弹层安全区与箱子悬浮窗截图按原字节和 SHA 迁入仓库，线程缓存清理后不再依赖本机绝对路径；仅为定向静态证据 |
| 当前 I3R.5 局外生产旅程 | PASS_WITH_EXTERNAL_BOUNDARY | `I3R_OUT_OF_RUN_PRODUCTION_JOURNEY`：真实 `main.tscn`，22 checkpoint/22 PNG/36 次解析输入；设置安全应用/取消/危险显示回退、Deploy 五页、批售取消后确认、长期任务/天赋/档案与三级 Esc 全部通过；`.tmp/i3r5_out_of_run_rendered_20260726` 已完成范围化 Codex 视觉复核，并据此修正显示确认框、Deploy 图层安全区/藏品等级、长期信息层级/图标/档案控件；不替代真实设备、动态玩家或用户签收 |
| Worktree quick | 67/67 PASS | `.tmp/i1/20260724T081049594Z_48c9c715/report.json`；43 plain、24 cleanup runner、48 cleanup diagnostic、0 blocking；报告仅覆盖 I1 镜像/runner，治理 marker 单独绑定 |
| 标准生产旅程 | PASS | seed 13；20 checkpoint/20 screenshot/137 inputs；`.tmp/i3r4_final_standard_rendered_20260726`；主菜单→洞口→Deploy→Run→撤离→真实保存重试→主菜单 |
| 历史生产状态画廊 | 11/11 generated | `.tmp/i1/20260724T081913076Z_117ed89a/i3r_production_state_gallery/manifest.json`；`PASS_WITH_VISUAL_REVIEW_REQUIRED`；早于当前门/角色等修改 |
| 最终生产状态画廊 | 12/12 generated | `.tmp/i1/20260726T174413001Z_03839547/i3r_production_state_gallery/wrapper_report.json`；wrapper SHA-256 `5854567A235971BAF0B4689BF3B925A7E3E3229E157E9276FBAEABBB1CB7A7D2`；manifest SHA-256 `3D5003B9C19161C8D79A75DAB017C9ABAA2BE8C5F7FD564DA26E62432F7C277D` |
| 当前 I3R.4 渲染玩家旅程 | PASS | 满包 `.tmp/i3r4_final_full_bag_rendered_20260726`：13 screenshot/222 inputs；终局 `.tmp/i3r4_final_terminal_all_rendered_20260726`：15 screenshot/129 inputs/outcomes=Abandoned,Failed/natural reason=`runtime_combat_projectile` |
| 最终生产预览矩阵 | 132/132 generated | `.tmp/i1/20260726T171343894Z_6892a1f1/i3r_preview_matrix/matrix_manifest.json`；11 场景 × 4 分辨率 × 3 UI 缩放；预检/捕获污染与镜像一致性 PASS；SHA-256 `DCB8DA67E8D19B496024585447987CEF1F77916A20325573F13E5D0EB72D7494` |
| 最终 Codex 静态视觉复核 | 269/269 PASS_WITH_EXTERNAL_BOUNDARY | 132 生产预览 + 125 长期系统 + 12 状态画廊逐图复核完成，未发现阻断项；不替代动态玩家、真实设备或用户签收 |
| 较早 canonical implementation full | SUPERSEDED 89/89 PASS | `.tmp/i1/20260724T133447862Z_f32e4b02/report.json`；52 plain、37 cleanup runner、74 cleanup diagnostic、0 blocking；report `AB793F0920D88CB4BBE530A5BEFF30748E9D5ABCCF2C25959560CA061715C0EC` |
| 最新 raw worktree full 检查点 | SUPERSEDED 89/89 PASS | `.tmp/i1/20260725T153926647Z_13de92f4/report.json`；52 plain、37 cleanup runner、74 cleanup diagnostic、0 blocking、931537 ms；manifest `FF9B6516D6D651C0C272D7613C5D6ACB55D4E3063EE47C94AF3BEA27465D6304`，report `EC2C009F8EA81802447DA4D55BFE93D8099FD9BB18F37EB754AB47B0ABA6CB94`，2306 files / fingerprint `44D1E829AB13CB2ED0C612A57B275538EDDB7AF215BBFD9361B0F2AA0D6D2358`；仍早于当前生产与控制面修改 |
| 历史空间治理检查点 | PASS / SUPERSEDED AS CURRENT SIZE | 旧事务 81 snapshots、6129-object/715273262-byte CAS、四 namespace V2 restore、index SHA-256 `64BEC2C6E7188D00DBD17C4B5515DB68FA5FBAB9170EC53465DA963B4F24D54A`、final proof SHA-256 `C04B76302003C0DA3C6120DDCA8A1F7E1E606F67CE9D80379510C0FD2AC13903` 与 `7.4064 GiB / 51163 files` 只绑定当时时点，不证明当前物理收口 |
| 最终 worktree full | 96/96 PASS | `.tmp/i1/20260726T171400780Z_6f66cb6f/report.json`；53 plain、43 cleanup-diagnostic、0 hard failure、1053141 ms；static/registration/pollution PASS；manifest `11B32B377A244B9DDF98637020CC9F263ABCDEB488472FA624F11F5A0A575406`；report `3CDF02791EC61CD580B78489A4C5B2581EF7E974AADEEA897AF06FEBD1494BC4`；业务指纹 `E7ACAA39576A6DFEEB8B22EA18C41B0914A008F84F33348637183B1541C25A1F` |
| 当前物理空间重收口 | PASS | 123 snapshots（I3R 60）、543197 snapshot files、6489 CAS objects/735449033 bytes；index `16974A206B007F737CB4CC45163720F3D10AF1170A657EC1DD477B26DE61AEAE`；final-full V2 restore proof `ACE86F8E3614CBA2BB8E0A52EC82B1E3A320609422CF20FD17AC274F1D483195`；final verifier proof `A9B1286576B9E877642F9B2D0FACC7FE90F22C06D40C14856A1C7C7D97A377C4`；本轮 38/38 镜像事务裁剪，worktree/tombstone 0；当前 `E:\AGAME1` `9.1937 GiB / 56331 files` |
| Exact-head / push | FINAL_DELIVERY_RECORD | 用户已授权候选提交验证与 main 快进交付；实际提交和远端 SHA 由最终交付结果提供 |
| Device / GPU / player | PENDING | 仍需真实设备、目标 GPU 长局和动态玩家签收 |

当前 worktree 命令：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r.ps1 `
  -Profile full `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe' `
  -UERoot 'E:\UE\Game'
```

## I3 收口证据

- 历史关闭对象：`09aaafe283aa2e4c2f30708c5f88b89ebf7753eb` /
  tree `a077da34237dce5e4a6081d833efd939098b4641`
- 总契约：docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md
- 切片台账：docs/00_governance/I3_SLICE_GATE_LEDGER.md
- 用户反馈：docs/00_governance/I3_USER_FEEDBACK_DISPOSITION_MATRIX.md
- validation：docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md
- handoff：docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md
- Base 审计：docs/00_governance/I3_BASE_RETENTION_AND_DEDUP_AUDIT.md

最终 worktree full 为 75/75 PASS：42 个 runner 为纯 PASS，33 个为
PASS_WITH_CLEANUP_DIAGNOSTIC，blocking 为 0，时长 785952 ms。

    report: .tmp/i1/20260722T210300990Z_ed330093/report.json
    report_sha256: 5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D
    source_mode: worktree
    profile: full

首次 quick/full 失败、真实原因、补救与复验链只在 I3 validation 原文展开。

## 分类证据

| 范围 | 当前结果 | 解释边界 |
| --- | --- | --- |
| I3 定向 runner | PASS | 地图、搜索、HUD/输入、长期、战斗/结果与模态模型 |
| Production 公开输入 | 6/6 PASS | 三条 runner 各 headless/rendered；47 PNG、6 JSON/CSV |
| Base | PASS | 1041 files；25 planning；1407 members；1012 unique；395 aliases |
| 同机冻结 CPU workload | PASS_WITH_NOTES | enemy1 低基数残余保留；不等于设备 GPU/FPS |
| 人工可见检查 | PASS_WITH_NOTES | 17 张代表图无阻断问题；不等于最终审美/手感 |
| Cleanup | PASS_WITH_NOTES | 全量 33 个 runner 按 manifest 分类；六次 production 的 18-resource 子集仍可复现 |
| Worktree full | 75/75 PASS | 不替代 exact-head/full |
| Exact-head 与 push | 外部交付门 | 由最终交付记录写入真实 SHA；本文不预写 |

## I3R 外部交付命令

获得提交授权并形成候选提交后，最终对象使用：

    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
      -File .\tools\i3r\invoke_i3r.ps1 `
      -Profile full `
      -SourceMode head `
      -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe' `
      -UERoot 'E:\UE\Game'

随后 push 并比较 `git rev-parse HEAD` 与远端分支 SHA。任一门失败都阻止 I3R
关闭；不得重新打开或篡改已冻结的 I3 历史。

## 历史与回归证据

| 证据 | 当前用法 |
| --- | --- |
| I2 validation/handoff | 前序闭合非美术基线，冻结历史 |
| I1 validation/handoff | 更早闭合非美术基线，冻结历史 |
| ART21 closeout/validation | 项目级最新闭合美术阶段 |
| ART23 validation | 较晚页面/UI 范围证据，不提升 art-stage authority |
| ART24R2 final Computer Use | 失败封存，24/61 PASS |
| G41/M6/M7 runners | 当前 full 的行为回归来源 |

## 声明规则

- 精确 PASS marker、exit code 和无 blocking diagnostic 才构成 runner PASS。
- cleanup diagnostic 必须保留分类，不能假装不存在。
- worktree PASS 不替代 exact-head PASS；head PASS 不替代 push/remote SHA。
- screenshot、headless、rendered、manual、performance、CI、export 和 release 分开声明。
- I2 是最新已生效闭合非美术基线。I3 的 worktree/full 与 closeout 文档属于条件式
  历史证据；其 exact-head/full 和 push/remote-SHA 生效门未完成，也不自动授权
  任何 successor。
