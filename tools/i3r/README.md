# I3R 快速验证入口

I3R 以 I3 的不可变 Base 和 I1 的镜像执行器为底座。不要直接在生产 Godot 目录运行
编辑器导入来代替本入口；直接运行会产生 `.import`、`.translation` 等工作树污染。
I3R 当前状态为 `ACTIVE / EXTERNAL_ACCEPTANCE_PENDING`，本说明中的
机器 PASS 不得解释为阶段关闭。

当前口径：

- 搜索/掉落、地图、背包、特殊房、撤离、结果、教程和 UI-only 缩放均已有生产消费者
  与定向门，状态为 `IMPLEMENTED_PRODUCTION`；
- 固定 seed 13 的当前标准生产旅程已通过 20 个 checkpoint/截图；最终生产状态画廊
  12/12、生产预览 132/132、长期系统 125/125 已生成，269/269 张静态图完成 Codex 复核；
- 教程仍从 Deploy 可见目录选择 `tutorial_5x5` 并沿 `standard_run` 启动；真实
  `main.tscn` 首通/重播自动旅程已证明 completion-only、零金币/物品/salvage 污染
  和正确返回路由；I3R.6 合并套件还覆盖四类事件差异、地图直接操作、可关闭非阻塞
  提示及 1280×720/1920×1080 × UI 100/125/150 响应门；
- I3R.5 局外生产旅程已在真实 `main.tscn` 完成 22/22 checkpoint/PNG 和 36 次解析
  输入；I3R.7 已完成 Base 真实消费者证明与当前长期系统治理；
- 当前长期系统为 6 模块、25 页面、58 个运行资产，gacha 运行资产为 0，天赋使用
  独立 furniture；历史 ART23 6×27/58 原样保留，但不是当前生产门；
- seed 13 战斗自动旅程已通过真实 `main.tscn` 与解析 D/Space 输入，覆盖可见祭坛
  同源阻挡、近战确定性绕障、held 封锁门单次拒绝/零 transition dispatch、敌预警、
  攻击期朝向锁定后释放、遮挡视觉裁剪/未命中、无遮挡命中、战斗结算和正常离房；
- 角色移动/外观定向门已证明 InputMap 连续位移、拒绝移动无回弹、局内 Sprite2D
  消费审计安全 `field_coat` 色型基线、未拥有/未知 catalog fail closed，以及受击
  色与 profile 组合后精确恢复；这只证明局内替换管线，不是独立真实时装素材，也
  没有生产获取/选择 UI 或跨局外场景一致；
- 门的房型/方向贴图、裁切、轴点、几何、近距提示和过门判定已同源；`RunScene` 的
  弹层协调已提取到 `RunSceneModalController` 并接入生产 `main.tscn`；底层
  `_focus_stack` 为私有且 RunScene 无 raw alias；冻结树架构门以 2974 行 / 161 函数
  通过，低于 2980 / 176 预算；
- Deploy 放弃/批售 stale 与 wrong-top 调用无副作用；CommandBus 拒绝未确认放弃；
  真实顶层确认后结果层可见、取得焦点且不会误启动新局；
- 最终 worktree full `20260726T171400780Z_6f66cb6f` 为 96/96 PASS；
  53 plain、43 cleanup-diagnostic、0 hard failure；
- exact-head/full 与 Git 远端一致性由最终交付结果提供；其他终局分支、真实设备/
  控制器/音频、目标 GPU 长局和动态人工玩家/视觉验收仍是 pending；
- 当前空间归档、V2 恢复、38/38 镜像事务裁剪与物理复量均 PASS；
  `E:\AGAME1` 为 9.1937 GiB / 56331 files；
- 任一局部 runner 或 PNG 生成成功都不能把上述待验收项改写成全阶段 PASS。

下方 `E:\Godot` 与 `E:\UE\Game` 只是当前机器实例。Godot 仓库权威必须由
`git rev-parse --show-toplevel` 解析；`-UERoot` 也必须指向能够由
`git -C <path> rev-parse --show-toplevel` 解析、且与解析结果完全一致的 UE Git 根。
`E:\UE\Game` 不是跨机器权威或默认值。

## 治理快速检查

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r.ps1 `
  -GovernanceOnly
```

成功时正式入口最后输出 `I3R_VALIDATION=PASS scope=governance`。不要绕过该入口单独运行
底层 Python 脚本来声明治理 PASS。

依次验证：

1. 25 份“原始策划案”的原名、字节和 SHA；
2. 1407 条 Base source alias、1012 个唯一对象和 395 个精确重复；
3. 1012 行语义对象目录；
4. Base/runtime 精确交叉账：178 行、175 个 runtime 路径和 149 个 runtime SHA；
5. 75 项逐 SHA 视觉复核裁决及零遗留待复核项；
6. 1 条显式 runtime promotion 的来源、输出、key、consumer 和 rollback；
7. 真实消费者证明：direct 47、dynamic 108、staging 6、无生产 consumer 17；
8. 2 组共享 alias 的显式替换债；
9. 当前长期系统 6 模块/25 页面/58 资产、gacha runtime 0、独立 talent furniture，
   并确认历史 ART23 6×27/58 证据仍被冻结且不作为当前门。

`sources/base/原始策划案` 的 25 份文件是不可变原始策划案：保留原名、完整字节、
信息量和 SHA，不做摘要替换。素材只按内容 SHA 精确去重，所有来源 alias 继续保留；
Base 不被运行时直接扫描，只有登记了许可、真实 consumer 和 rollback 的 promotion
才能进入生产路径。

## 当前长期系统治理门

正式 `invoke_i3r.ps1` 入口会对所有 profile 先运行当前长期系统治理门。该门读取
`docs/40_validation/i3r_long_term_current/`，固定核对当前生产 6 个一级模块、25 个
二级页面和 58 个运行资产，要求 gacha 运行资产为 0、天赋具有独立 furniture，同时
确认历史 ART23 的 6×27 页面/58 资产证据、历史 gacha 来源和 validator 原样保留但
不参与当前生产判定。正式入口在源工作树只执行这部分静态治理，不把 `GodotExe`
转发给会直接打开项目的 runner；动态 `ART23_LONG_TERM_MAIN_ROUTE`/`RUNTIME`
由后续 I1 隔离镜像执行，其中 `full` 同时覆盖两项，避免验证本身重写
`project.godot` 或 `.translation`。成功 marker 为：

```text
I3R_LONG_TERM_CURRENT_GOVERNANCE=PASS modules=6 pages=25 runtime_assets=58 gacha_runtime=0 talent_furniture=dedicated historical_art23=preserved
```

## I3R 效果音来源门

治理入口会固定校验
`docs/00_governance/I3R_UE_GENERATED_SFX_IMPORT_REGISTRY.csv` 与 Godot 运行时中
9 个项目内部程序化 WAV 的数量、路径、字节数和 SHA。默认只做 registry/runtime
校验；提供 UE 仓库时还会核验历史提交、Git LFS OID、已还原源文件和运行时文件：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r.ps1 `
  -GovernanceOnly `
  -UERoot E:\UE\Game
```

示例中的 `E:\UE\Game` 只代表本机当前 UE Git 根；不要传入其父目录 `E:\UE`，也不要
在其他机器沿用该盘符。省略 `-UERoot` 时只验证 registry/runtime；提供可解析的 UE
Git 根时才追加历史提交、LFS OID 与源文件交叉验证。

该门只准入登记的 9 个效果音；来源或许可未确认的 Hero Immortal BGM 不在登记表中，
也不会被复制或加载。

## Base 运行时视觉复核联系表

```powershell
python .\tools\i3r\build_base_visual_review_gallery.py `
  --repo-root . `
  --output .tmp\i3r\base_visual_review
```

该命令只读取 Base/runtime 交叉账与运行时 PNG，在临时目录生成带 `asset_id`、原始
来源名、尺寸、consumer、SHA 和人工裁决的 5 页联系表。裁决来源为
`docs/00_governance/I3R_BASE_VISUAL_REVIEW_REGISTRY.csv`；当前 75 项中只有 14 项
确认适用于既有真实消费者，35 项保留为未准入暂存参考，25 项因烘焙文字/键位受到
限制，另有 1 项语义错配被隔离。生成成功不等于新素材自动获准。

## 生产对象、特殊房与战斗状态画廊

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r_state_gallery.ps1 `
  -SourceMode worktree `
  -Width 1280 `
  -Height 720 `
  -GodotExe E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

该入口先通过 I1 preflight 建立隔离镜像，再只实例化一次生产 `main.tscn`，固定
seed 13，生成箱子关闭/开启内容、事件、地面掉落、普通门、雷区武装/触发/离开后
失效、撤离摘要、战斗锁门、敌人预警和玩家攻击判定几何共 12 个状态。每项都有 PNG、metadata 和
覆盖两者的 SHA256 sidecar，总清单状态仍为
`PASS_WITH_VISUAL_REVIEW_REQUIRED`。控制台输出
`I3R_STATE_GALLERY_REPORT=<绝对路径>`。

需要人工操作同一生产战斗房时追加 `-InteractiveCombat`。该模式不会自动超时，
由操作者通过真实 InputMap 操作并关闭窗口；它是可见调试入口，不是自动玩家签收。
状态画廊中为构造可重复画面而直接设置权威字段的条目，会在 metadata 中明确记录
`fixture_method`、`authority_fields_mutated` 和 `player_journey=false`，不得冒充
完整玩家旅程。

当前正式证据：

```text
manifest=.tmp/i1/20260726T174413001Z_03839547/i3r_production_state_gallery/manifest.json
wrapper_report=.tmp/i1/20260726T174413001Z_03839547/i3r_production_state_gallery/wrapper_report.json
status=PASS_WITH_VISUAL_REVIEW_REQUIRED
generated=12/12
manifest_sha256=3D5003B9C19161C8D79A75DAB017C9ABAA2BE8C5F7FD564DA26E62432F7C277D
wrapper_report_sha256=5854567A235971BAF0B4689BF3B925A7E3E3229E157E9276FBAEABBB1CB7A7D2
visual_acceptance=CODEX_STATIC_REVIEW_COMPLETE / DEVICE_AND_PLAYER_SIGNOFF_PENDING
```

## 程序快速回归

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r.ps1 `
  -Profile quick `
  -SourceMode worktree `
  -GodotExe E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

正式入口先完成 Base、治理 overlay 与效果音门，再委托 I1 隔离镜像；成功时最后输出
`I3R_VALIDATION=PASS scope=<profile> source_mode=<mode>`。直接调用局部 runner 或绕过
`invoke_i3r.ps1` 不能形成 I3R 阶段证据。

I1 在 `.tmp/i1/<run_id>/worktree` 镜像中导入并运行 Godot，报告写入同一 run 目录的
`report.json`。`overall_status=PASS` 才表示本次静止快照通过；单个 runner marker
不能覆盖污染、注册或清理门。

较早的 quick 支撑证据：

```text
report=.tmp/i1/20260724T081049594Z_48c9c715/report.json
status=PASS
runners=67/67
plain=43
cleanup=24 runners / 48 diagnostics
blocking=0
pollution=PASS
```

较早的 canonical implementation full：

```text
report=.tmp/i1/20260724T133447862Z_f32e4b02/report.json
status=PASS
profile=full
source_mode=worktree
source_head=35189aaf524157761d1ab9cdddc39e76baa0d7ca
runners=89/89
plain=52
cleanup=37 runners / 74 diagnostics
blocking=0
static=PASS
registration=PASS
pollution=PASS
manifest_sha256=8D7DE29F024C7EDD23A7C851D1A1DEA35ED0292E257712D97127D8CCFB264811
business_fingerprint=B85932E120CFD1EEF785ABD7408B753EFA6BF5BEF16C4F41EAC38525D908A60B
report_sha256=AB793F0920D88CB4BBE530A5BEFF30748E9D5ABCCF2C25959560CA061715C0EC
```

较新的 raw worktree full 检查点：

```text
report=.tmp/i1/20260725T153926647Z_13de92f4/report.json
status=PASS
profile=full
source_mode=worktree
source_head=35189aaf524157761d1ab9cdddc39e76baa0d7ca
runners=89/89
plain=52
cleanup=37 runners / 74 diagnostics
blocking=0
static=PASS
registration=PASS
pollution=PASS
manifest_sha256=FF9B6516D6D651C0C272D7613C5D6ACB55D4E3063EE47C94AF3BEA27465D6304
business_fingerprint=44D1E829AB13CB2ED0C612A57B275538EDDB7AF215BBFD9361B0F2AA0D6D2358
report_sha256=EC2C009F8EA81802447DA4D55BFE93D8099FD9BB18F37EB754AB47B0ABA6CB94
```

两个报告都只证明各自历史实现检查点。当前最终 worktree full 为：

```text
report=.tmp/i1/20260726T171400780Z_6f66cb6f/report.json
status=PASS
profile=full
source_mode=worktree
runners=96/96
plain=53
cleanup_diagnostic=43 runners
hard_failures=0
static=PASS
registration=PASS
pollution=PASS
manifest_sha256=11B32B377A244B9DDF98637020CC9F263ABCDEB488472FA624F11F5A0A575406
business_fingerprint=E7ACAA39576A6DFEEB8B22EA18C41B0914A008F84F33348637183B1541C25A1F
report_sha256=3CDF02791EC61CD580B78489A4C5B2581EF7E974AADEEA897AF06FEBD1494BC4
```

其后仅回写治理文档与空间终态；进入同一候选提交的 exact-head 门前仍需获得提交授权。

## 生产输入旅程

标准生产输入旅程是 `full` profile 中登记的
`I3_PRODUCTION_INPUT_JOURNEY`，必须通过镜像入口运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r.ps1 `
  -Profile full `
  -SourceMode worktree `
  -GodotExe E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

当前固定 seed 13 渲染证据覆盖主菜单 → 洞口转场 → Deploy → Run → 多房探索/地图
→ 撤离 → 真实保存失败重试 → 返回主菜单，共 20 个 checkpoint/截图，位于
`.tmp/i3r4_final_standard_rendered_20260726`。这是标准旅程，不覆盖教程完成/
重播、其他成功/失败/放弃终局分支、真实物理手柄或目标设备。

`I3R_OUT_OF_RUN_PRODUCTION_JOURNEY` 已登记在 `ui`/`full` profile，不进入
`quick`/`core`。它从真实 `res://scenes/main/main.tscn` 启动，以解析后的键鼠事件
和可点击生产 Control 覆盖：

- 主菜单设置的安全应用、未应用编辑取消，以及危险显示变更的显式回滚；
- 主菜单转场到 Deploy，同页地图/难度、仓库批售取消后确认、申领、本局委托、
  携带清单和四页出发摘要；
- 返回主菜单后进入长期系统，访问任务、天赋树和角色历史档案，并用三级 Esc 将
  焦点从档案记录退回二级页签、一级模块和主菜单；
- 仓库与设置的全部测试变更只写 evidence 目录内的隔离权威存档，不改玩家正式档案。

仅做开发期直达诊断时，可运行无截图版本：

```powershell
& E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe `
  --headless `
  --path .\Godot\GraytailGodot `
  --script res://tests/i3r_out_of_run_production_journey_runner.gd `
  -- --evidence-dir=user://tests/i3r5_out_of_run
```

需要 PNG 时移除 `--headless`，并追加
`--require-screenshots=true`；`--evidence-dir` 可改为绝对目录。当前可见实跑为
22/22 checkpoint/PNG、36 次语义输入，位于
`.tmp/i3r5_out_of_run_rendered_20260726`。直达命令只用于定位和截图；正式阻断证据
仍由 I1 镜像中的 `ui`/`full` profile 形成。自动 PASS 不替代动态观感、真实
键鼠/手柄、目标设备或人工玩家签收。

教程不是独立生产接口：`tutorial_5x5` 是 Deploy 地图目录中的特定模式，经普通地图
选择/确认链进入 `standard_run`。预览矩阵中的 `tutorial` 只是该生产模式的捕获别名，
不得据此新增 UE 式独立教程入口。

`I3R_TUTORIAL_PLAYER_JOURNEY` 已登记在 `ui`/`full` profile。它实例化真实
`main.tscn`，通过生产 InputMap 从 Deploy 可见目录完成首通和重播，检查：

- 两次都沿 `tutorial_5x5 -> standard_run`；
- 结果金币、物品和 salvage 为零；
- 首通只写 `tutorial_completed`，重播不再改变存档；
- 首通返回 Deploy，重播按规则返回主菜单。

当前教程定向套件还检查：

- 固定四个事件格通过生产 `CommandBus -> RoomResolver -> EventService` 按 UE 权重
  得到 `trap,dice,altar,trader`，并映射到不同房间提示；
- 地图鼠标单击与 `ui_accept` 共用一次执行路径，焦点移动只选择；未知格标记/取消，
  已探索且可回传安全格直接回传；
- 非阻塞提示可主动关闭且不抢键盘焦点；
- 1280x720/1920x1080 × UI 100/125/150 的标题、按钮、左 HUD、房间、协议卡和
  底栏安全区。当前 1280x720@150 范围化视觉证据为
  `.tmp/i3r6_popup_fix/visual/capture.png`，合并后定向日志位于
  `.tmp/i3r6_final_combined_20260726`。

该自动旅程 PASS 不替代真实键鼠/手柄输入、动态观感或人工玩家签收。

`I3R_PRODUCTION_COMBAT_OBSTACLE_JOURNEY` 已登记在 `quick`、`core`、`ui` 和
`full` profile。它使用 seed 13，实例化真实 `main.tscn` 并通过
`Input.parse_input_event` 发送 D/Space，检查：

- 玩家移动停在与攻击遮挡同源的可见祭坛前；
- 自然近战敌人先产生祭坛切向位移，再恢复无遮挡接近；
- 持续顶住战斗封锁门只呈现一次拒绝，释放前不产生 room-transition dispatch；
- 敌人预警在生产房间视图可见；
- 攻击三个阶段中反向输入不改变 simulation、扇区或角色贴图朝向，恢复后同步释放；
- 房间渲染直接消费 simulation 的裁剪点；祭坛遮挡为 visual-clipped/blocked/no-hit，
  无遮挡攻击为 one-hit；
- 最后一名敌人死亡后房间结算、解除封锁并可正常离房。

当前实跑 marker：

```text
I3R_PRODUCTION_COMBAT_OBSTACLE_JOURNEY=PASS seed=13 input=parsed movement=blocked recovery=mobile melee_navigation=progressing door_hold=single_dispatch warning=visible facing=locked_then_released cooldown=early_rejected_no_turn,late_buffered attack=occluded_visual_clipped,hit settlement=cleared leave=normal inputs=64
```

这是自动生产输入旅程，不是物理键盘/手柄、目标 GPU/FPS 长局或人工玩家签收。

## 空间治理状态

当前归档为 123 snapshots（I3R 60）和 6489 个 CAS 对象；index SHA-256 为
`16974A206B007F737CB4CC45163720F3D10AF1170A657EC1DD477B26DE61AEAE`。
最终 full 快照 V2 独立恢复与两次树校验 PASS；本轮 38/38 镜像完成事务裁剪，
worktree/tombstone 均为 0。最终 verifier proof 为
`A9B1286576B9E877642F9B2D0FACC7FE90F22C06D40C14856A1C7C7D97A377C4`。
2026-07-27 当前 `E:\AGAME1` 为 9.1937 GiB / 56331 files。

## 最终提交态（待执行）

工作树 final full 已通过；获得提交授权并形成候选提交后，在同一候选提交上运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r.ps1 `
  -Profile full `
  -SourceMode head `
  -GodotExe E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe `
  -UERoot E:\UE\Game
```

`SourceMode head` 要求候选变更已进入同一提交；用户已于 2026-07-27 授权 commit、
push 与 main 快进合并。该命令不替代渲染矩阵、真实手柄/音频、目标 GPU 性能长局或
人工玩家签收；这些证据属于 I3R.8。
上述 `E:\UE\Game` 仍只是本机实例；其他机器必须替换成其实际 UE Git 根。

## 生产预览矩阵

缩小矩阵可用于快速检查单个页面、分辨率和 UI 缩放组合：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r_preview_matrix.ps1 `
  -Scene settings,run,tutorial `
  -Resolution 1280x720 `
  -UIScale 100,150 `
  -SourceMode worktree `
  -GodotExe E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

完整矩阵覆盖 `main_menu/settings/deploy/long_term/run/combat/inventory/map/`
`result_success/result_failure/tutorial`、1280×720/1366×768/1600×900/
1920×1080 与 UI 100/125/150%：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r_preview_matrix.ps1 `
  -All `
  -SourceMode worktree `
  -GodotExe E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

入口先通过 I1 preflight 创建隔离镜像，再只实例化镜像中的生产
`res://scenes/main/main.tscn`。每个组合输出 `capture.png`、`metadata.json` 和
Godot 日志；标准局画面固定使用 seed `730031`，教程仍从 Deploy 地图目录经普通
确认链进入自身固定 5×5 seed。总清单为 `matrix_manifest.json`；控制台会给出
`I3R_PREVIEW_MATRIX_REPORT=<绝对路径>`。`PASS_WITH_VISUAL_REVIEW_REQUIRED`
只表示生产路由、PNG 和元数据生成成功，不表示框架重叠、文字安全区、可读性、动画
手感或交互已经通过人工视觉签收。PNG 需要真实 Windows/OpenGL 视口，逐例捕获时会
短暂出现游戏窗口。

UI 100/125/150% 只通过生产 `RunScene/AppShell` 的 Control 字号、最小尺寸、间距和
安全区接口生效；`Window.content_scale_factor` 保持生产 canvas 的 1.0，不得用它
同时放大世界和背景。旧实现正是把 UI 缩放施加到整个 Window、页面却仍使用固定字号
与偏移，才同时造成世界裁切、边框拉伸、文字压线和焦点框错位。

矩阵入口还执行缩放反自证：同一场景、同一分辨率的每个所选 UI 缩放必须产生互异
PNG SHA；100/125/150% 若捕获为相同画面则整组失败。长期系统已通过真实字号、换行、
安全区和三档截图互异的定向门。

任一 I1 隔离门失败、生产路由未到达、物理 PNG 尺寸不符、逐例元数据与 PNG SHA
不一致、捕获期间源工作树发生变化或出现未分类引擎错误，都会令总清单为 `FAIL`；
此时不得用已生成的部分图片替代完整矩阵。

当前最终完整矩阵证据：

```text
manifest=.tmp/i1/20260726T171343894Z_6892a1f1/i3r_preview_matrix/matrix_manifest.json
status=PASS_WITH_VISUAL_REVIEW_REQUIRED
generated=132/132
preflight_pollution=PASS
capture_pollution=PASS
mirror_unchanged=true
sha256=DCB8DA67E8D19B496024585447987CEF1F77916A20325573F13E5D0EB72D7494
```

该 132/132 矩阵是当前最终生产预览证据；其静态图已纳入 269/269 Codex 复核。

1366×768 在生产 `keep` 策略下严格记录 1365×768 内容与右侧 1 像素物理黑边；
schema 3 逐例复算内层尺寸和四边 padding，既不拉伸，也不放宽尺寸容差。

局内焦点、材质安全区和普通 Deploy 教程地图响应式布局均已登记在 `ui` profile；
定向复验也必须通过镜像入口运行，不得在活动 Godot 工程中直接调用 runner：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r.ps1 `
  -Profile ui `
  -SourceMode worktree `
  -GodotExe E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

profile 中的 `I3R_RUN_FOCUS_LAYOUT` 覆盖四种基准分辨率、`周围雷险`
unknown/0/1/3/8 与悬浮窗硬避让；`I3R_UI_MATERIAL_SAFE_ZONE` 检查三档 UI 缩放；
`I3R_TUTORIAL_RESPONSIVE_LAYOUT` 检查教程框、左 HUD、房间、协议卡和底栏互斥；
`I3R_TUTORIAL_MAP_MODE` 检查同页路由、四类事件与地图教学；
`I3R_TUTORIAL_PLAYER_JOURNEY` 检查首通/重播及成长隔离。`quick` 还登记
`I3R_RUN_SCENE_ARCHITECTURE_BOUNDARY`、`I3R_PLAYER_MOVEMENT_APPEARANCE` 和
`I3R_WORLD_OBJECT_PRESENTATION_CONTRACT`、`I3R_PRODUCTION_COMBAT_OBSTACLE_JOURNEY`。
这些自动门仍不替代动态玩家视觉签收。

## 当前长期系统 25×5 截图矩阵

当前长期系统的 25 个二级页面可在五个物理分辨率下通过独立入口统一捕获：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r_long_term_matrix.ps1 `
  -SourceMode worktree `
  -RepoRoot (git rev-parse --show-toplevel) `
  -GodotExe E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

入口先复用 I1 `preflight` 建立隔离镜像，再在镜像中调用
`res://tests/art23_long_term_matrix_capture_runner.gd`，依次捕获
1280×720、1366×768、1600×900、1920×1080、2560×1440。125 张 PNG、
Godot 日志和 `matrix_manifest.json` 全部写入该次 I1 `run_root` 下的
`i3r_long_term_matrix`，不写入源项目、镜像业务目录或
`docs/art/validation/art23`。入口逐张检查 PNG 签名、物理尺寸、非空内容和
SHA-256，并要求五个分辨率各有且仅有一条 `ART23_MATRIX_CAPTURE=PASS`；
捕获前后的源工作树 Git 快照与业务指纹也必须一致。成功时输出：

```text
I3R_LONG_TERM_MATRIX_REPORT=<绝对路径>
I3R_LONG_TERM_MATRIX_STATUS=PASS_WITH_VISUAL_REVIEW_REQUIRED generated=125 expected=125
```

runner 文件名中的 `art23` 是被冻结的历史来源标识，不代表本入口会重建或改写
历史 ART23 证据。本入口只读取镜像中的当前长期系统运行时 Shell；当前生产口径为
6 个模块、25 个二级页面、58 个运行时素材、0 个抽卡页面，并使用独立天赋家具。
历史 ART23 的 6×27 / 58 记录仍由其原有验证器与证据目录解释，不能用本矩阵覆盖。
`PASS_WITH_VISUAL_REVIEW_REQUIRED` 只证明隔离生成、数量、尺寸、哈希和污染门通过，
仍须人工检查层级、重叠、可读性、材质一致性与交互观感。

当前最终证据为：

```text
manifest=.tmp/i1/20260726T173939443Z_6d8ac659/i3r_long_term_matrix/matrix_manifest.json
status=PASS_WITH_VISUAL_REVIEW_REQUIRED
generated=125/125
sha256=BE3535EB0CDBA9A181C5A5A2DD61890D290145019CD02E37F86A7CFE15B545F6
visual_acceptance=CODEX_STATIC_REVIEW_COMPLETE / DEVICE_AND_PLAYER_SIGNOFF_PENDING
```
