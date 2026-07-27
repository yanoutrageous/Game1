# I3R 执行台账

文档状态：`ACTIVE`
总契约：`docs/20_product/I3R_PLAYER_EXPERIENCE_REWORK_CONTRACT.md`

## 台账规则

每门按 `PRECHECK → IMPLEMENTING → TARGETED_PASS → PLAYER_PASS → ACCEPTED` 前进。
`TARGETED_PASS` 不能替代动态玩家验收，单门 `ACCEPTED` 不能代表 I3R 已关闭。
表内 `IMPLEMENTED_PRODUCTION` 只说明当前生产路径和定向门存在；只要仍标记
`CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING`，就不得宣布对应玩家体验闭环。

| Gate | 状态 | 当前事实 | 剩余门 |
| --- | --- | --- | --- |
| I3R.0 | `FINAL_WORKTREE_FULL_PASS / FINAL_DELIVERY_AUTHORIZED` | I3 历史关闭对象是 `09aaafe` / tree `a077da`；I3R entry/base 是 `35189aaf` / tree `82f100`。最终工作树 full `20260726T171400780Z_6f66cb6f` 已 96/96 PASS，静态、污染和注册门均通过；其后的回写仅修改治理文档，不反向伪装为该 full 的业务指纹覆盖范围。用户已授权候选提交、exact-head/full、push 与 main 快进合并；实际 SHA 由最终交付结果提供 | 真实设备与玩家签收 |
| I3R.1 | `TARGETED_PASS` | InputMap 单一路径、ActionHintDescriptor、键盘/虚拟手柄、弹层优先级/LIFO、ESC 归属、焦点恢复与暂停阻断已通过；`RunSceneModalController` 私有持有 focus stack，RunScene 无 raw alias；Deploy stale/wrong-top 破坏性确认 fail closed，CommandBus 拒绝未确认放弃，Deploy-origin 结果层/焦点/不误开新局已通过真实生产链；标准与教程完成/重播自动旅程均通过真实生产入口 | 真实物理手柄、其他终局分支和动态玩家签收 |
| I3R.2 | `IMPLEMENTED_PRODUCTION / FINAL_MATRIX_AND_CODEX_VISUAL_REVIEW_PASS / PLAYER_SIGNOFF_PENDING` | FusionPixel 已成为玩家 UI 默认字体；UI-only 缩放由生产 Control 权威传播；最终 132/132 生产矩阵与 125/125 长期系统矩阵均完成，且同分辨率三档缩放反自证通过；Codex 已复核全部 269 张最终静态图 | 动态人工玩家观感、其余边框审美与真实设备 |
| I3R.3 | `TARGETED_PASS / FINAL_WORKTREE_FULL_PASS / PRODUCTION_COMBAT_JOURNEY_PASS / MOVEMENT_APPEARANCE_TARGETED_PASS` | 有限攻击缓冲；攻击三阶段中 simulation facing、扇区和角色贴图同源锁定并在恢复后释放；近战敌人确定性绕过可见祭坛；命中判定和扇区视觉消费同一遮挡合同；上述预警、遮挡/命中与结算离房已通过 seed 13 真实 `main.tscn` 解析输入旅程；移动仅走 InputMap 连续路径、拒绝无回弹；局内 Sprite2D 消费审计安全 `field_coat` 色型，未知 catalog fail closed，受击色与 profile 组合并恢复 | 外观获取/选择 UI、跨局外场景一致、真实时装资产与交易、真实手柄、动态手感与可见 GPU 长局 |
| I3R.4 | `TARGETED_PASS / FINAL_WORKTREE_FULL_PASS / CURRENT_PRODUCTION_JOURNEYS_PASS / FINAL_STATIC_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING` | 箱门、搜索/掉落、地图、背包、特殊房、撤离、结果、真实周围雷险及悬浮窗焦点避让均有生产消费者；20 checkpoint 标准旅程、满包替换、终局放弃/自然失败及最终 12/12 状态画廊均已按当前生产树重跑；132+125+12=269 张最终静态图完成 Codex 复核 | 真实键鼠/手柄、目标 GPU 长局、动态人工玩家签收 |
| I3R.5 | `TARGETED_PASS / FINAL_WORKTREE_FULL_PASS / PRODUCTION_PLAYER_JOURNEY_PASS / FINAL_STATIC_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING` | 主菜单场景化转场、同页 Deploy、仓库原子批售、三分支天赋、真实设置、结果归档与角色历史均有生产实现和定向门；真实 `main.tscn` 局外旅程以 22 checkpoint/22 PNG/36 次解析输入覆盖设置、Deploy 五页、批售、长期系统与三级 Esc；最终 132/132 与 125/125 矩阵均完成并经 Codex 静态复核 | 外观获取/选择 UI、跨局外场景一致与真实时装交易、真实键鼠/手柄、目标设备和动态人工玩家签收 |
| I3R.6 | `TARGETED_PASS / CURRENT_COMBINED_SUITE_PASS / UE_INTERACTION_ALIGNMENT_PASS / CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING` | 教程是 Deploy 地图目录中的 `tutorial_5x5` 模式并沿 `standard_run` 启动，不建立独立生产接口；真实 `main.tscn` 完成与重播旅程已证明 completion-only、零金币/物品/salvage 污染及正确返回路由；教程四类事件走真实生产链并按 UE 权重得到 `trap→dice→altar→trader`；地图单击/`ui_accept` 同源、非阻塞提示可主动关闭，1280×720@150% 可读性缺口已修正并完成范围化视觉复核 | 真实设备输入与动态玩家观感签收 |
| I3R.7 | `TARGETED_PASS / BASE_AND_CURRENT_LONG_TERM_GOVERNANCE_PASS / FINAL_MACHINE_GATES_PASS` | Base 保留 25 份原始策划案和 1012 个唯一对象；178 行/175 路径/149 SHA runtime crosswalk 只有 1 项明确晋升，逐消费者证明为 direct 47、dynamic 108、staging-only 6、无生产消费者 17，并登记 2 组共享别名债；当前长期系统为 6 模块/25 页面/58 资产，抽卡 runtime 为 0，天赋使用独立家具；最终 full 与矩阵通过 | 真实设备与玩家签收 |
| I3R.8 | `MACHINE_VALIDATION_AND_SPACE_RECLOSE_PASS / EXTERNAL_ACCEPTANCE_PENDING` | 最终 full 96/96、生产预览 132/132、长期系统 125/125、状态画廊 12/12 均通过；269/269 最终静态图完成 Codex 复核。归档现含 123 个快照（I3R 60），CAS 6489 对象；本轮 38/38 镜像按事务裁剪，V2 实际恢复与最终全局 verifier 通过，孤立 staging 和 76 个瞬态目标已处理；当前 `E:\AGAME1` 为 9.1937 GiB / 56331 files。用户已授权 exact-head/full 与 Git 交付 | 真实设备/GPU 长局、动态玩家签收 |

## I3R.0 基线

```text
i3_historical_commit=09aaafe283aa2e4c2f30708c5f88b89ebf7753eb
i3_historical_tree=a077da34237dce5e4a6081d833efd939098b4641
i3r_entry_commit=35189aaf524157761d1ab9cdddc39e76baa0d7ca
i3r_entry_tree=82f100059add24ecb2c12e7fca0bfb17f3a95c50
branch=codex/i3r-player-experience-rework
worktree=<repo>/.tmp/worktrees/i3r
```

`35189aaf` 是 I3R entry/base，不得写成 I3 historical entry 或 I3 关闭对象。
活动目录原有未提交修改和 `sources.zip` 不进入本工作树，也未被覆盖。

首次基线尝试：

```text
run_id=20260723T172639743Z_3d3349e3
profile=quick
runner_count=53
runner_failures=0
overall_status=FAIL
reason=pollution_guard（执行期间并行实现改变 status；Godot 生成 .import sidecar）
evidence=.tmp/i1/20260723T172639743Z_3d3349e3/report.json
disposition=不得当作 I3R.0 PASS；在实现静止点清除本轮生成侧车后重跑
```

中间静止快照补充：

```text
run_id=20260723T202345168Z_e1af747a
profile=preflight
source_mode=worktree
overall_status=PASS
evidence=.tmp/i1/20260723T202345168Z_e1af747a/report.json
boundary=该快照早于之后的工具/业务修改，仅是中间 preflight 证据；
  该历史边界已由下方当前 quick 证据取代
```

历史正式 quick：

```text
run_id=20260724T081049594Z_48c9c715
profile=quick
source_mode=worktree
overall_status=PASS
runners=67/67
plain_pass=43
pass_with_cleanup_diagnostic=24
cleanup_diagnostics=48
blocking_diagnostics=0
registration_complete=true
static_validation=PASS
pollution_guard=PASS
duration_ms=466108
manifest_sha256=8D7DE29F024C7EDD23A7C851D1A1DEA35ED0292E257712D97127D8CCFB264811
report_sha256=EFB4D1F1D7EC3172E27F29DEB45884DAD771E29A965EBE5EE7FCA78AE881DC3C
evidence=.tmp/i1/20260724T081049594Z_48c9c715/report.json
boundary=report.json 覆盖 I1 镜像/runner 门；Base 与 SFX 治理以同次控制台
  I3_BASE_COMMITTED_VERIFY、I3R_BASE_GOVERNANCE、I3R_UE_GENERATED_SFX_IMPORT marker 单独绑定；
  已由下方两个 worktree full 检查点取代为较新机器证据
```

较早的 canonical implementation full：

```text
run_id=20260724T133447862Z_f32e4b02
profile=full
source_mode=worktree
source_head=35189aaf524157761d1ab9cdddc39e76baa0d7ca
overall_status=PASS
runners=89/89
plain_pass=52
pass_with_cleanup_diagnostic=37
cleanup_diagnostics=74
blocking_diagnostics=0
registration_complete=true
static_validation=PASS
pollution_guard=PASS
duration_ms=833956
manifest_sha256=8D7DE29F024C7EDD23A7C851D1A1DEA35ED0292E257712D97127D8CCFB264811
report_sha256=AB793F0920D88CB4BBE530A5BEFF30748E9D5ABCCF2C25959560CA061715C0EC
business_file_count=2302
business_fingerprint_sha256=B85932E120CFD1EEF785ABD7408B753EFA6BF5BEF16C4F41EAC38525D908A60B
evidence=.tmp/i1/20260724T133447862Z_f32e4b02/report.json
boundary=该报告证明当时的 canonical implementation 快照；后续空间治理工具以及
  战斗扇区/地图像素材质修复已改变当前树，故不能充当 final post-governance full
```

较新的 raw worktree full 检查点：

```text
run_id=20260725T153926647Z_13de92f4
profile=full
source_mode=worktree
source_head=35189aaf524157761d1ab9cdddc39e76baa0d7ca
overall_status=PASS
runners=89/89
plain_pass=52
pass_with_cleanup_diagnostic=37
cleanup_diagnostics=74
blocking_diagnostics=0
registration_complete=true
static_validation=PASS
pollution_guard=PASS
duration_ms=931537
manifest_sha256=FF9B6516D6D651C0C272D7613C5D6ACB55D4E3063EE47C94AF3BEA27465D6304
report_sha256=EC2C009F8EA81802447DA4D55BFE93D8099FD9BB18F37EB754AB47B0ABA6CB94
business_file_count=2306
business_fingerprint_sha256=44D1E829AB13CB2ED0C612A57B275538EDDB7AF215BBFD9361B0F2AA0D6D2358
evidence=.tmp/i1/20260725T153926647Z_13de92f4/report.json
boundary=该报告是比 2026-07-24 检查点更新的 raw full，但仍早于长期系统缩放、
  教程与战斗生产旅程、角色移动/外观、门同源呈现和 RunScene 弹层提取等本轮修改；
  因而同样不得冒充当前树的 final post-governance full
```

## I3R.3 战斗定向记录

```text
implementation=0.16s 有限缓冲；攻击起点/方向冻结；敌圆与玩家扇形相交；
  敌预警/伤害同半径；弹体/激光 visual_radius 与逻辑半径同源；
  攻击期 simulation facing、attack geometry 与 PlayerController 贴图同步锁定；
  近战按确定性净空角点绕过祭坛；攻击视觉直接消费同源障碍裁剪点
targeted_tests=I3R_COMBAT_ATTACK_CONTRACT; G41_IN_RUN_CORE_GAMEPLAY_RUNTIME;
  I2_COMBAT_ROOM_EXPERIENCE; I3_COMBAT_SPECIAL_RESULT_RUNTIME;
  I2_COMBAT_FRAME_BASELINE_SMOKE; I3R_COMBAT_ARENA_CONTRACT;
  I3R_TRANSITION_ATTEMPT_GATE
production_journey=I3R_PRODUCTION_COMBAT_OBSTACLE_JOURNEY=PASS；seed 13；
  input=parsed；movement=blocked；recovery=mobile；melee_navigation=progressing；
  door_hold=single_dispatch；warning=visible；facing=locked_then_released；
  cooldown=early_rejected_no_turn,late_buffered；attack=occluded_visual_clipped,hit；
  settlement=cleared；leave=normal；inputs=64
supplemental_marker=I3R_COMBAT_ARENA_CONTRACT=PASS authority=shared movement=blocked
  melee_navigation=deterministic attack=occluded_visual_clipped projectile=blocked laser=clipped
status=TARGETED_PASS / PRODUCTION_MAIN_TSCN_JOURNEY_PASS
residuals=真实物理手柄、目标 GPU/FPS 长局、动态玩家手感与人工签收尚未验收
```

冻结生产负载补充证据：

```text
runner=I2_COMBAT_FRAME_BASELINE
workload=enemy 1/3/5 + 15 projectile peak；每组 3600 measured frames
result=PASS；纹理 71/71 预热；warmup 后运行时加载 0；orphan node 0
enemy_5=frame_work p95 1.020ms / p99 2.035ms
projectile_peak=frame_work p95 3.344ms / p99 5.996ms；frame_total p99 12.889ms
boundary=headless CPU 冻结负载，不得冒充可见 GPU/玩家长局签收
```

## I3R.1 输入与弹层定向记录

```text
implementation=InputMap-only 语义动作；ActionHintDescriptor v1；ModalFocusStack
  priority+LIFO；ESC 由顶层弹层到页面再到暂停逐级消费；关闭后恢复焦点快照
coverage=设置、仓库批量确认、地图、结果、Deploy 放弃、暂停阻断、教程语义提示
runscene_stack=RunScene 不暴露 raw stack；RunSceneModalController 私有持有 `_focus_stack`
deploy_confirmation=abandon/warehouse 只在自身 modal id 为 top 时提交；
  stale/wrong-top 不提交且不关闭其他 modal
command_gate=CommandBus abandon_run 只接受布尔 true；
  缺失、false 或非布尔值均返回 abandon_confirmation_required
deploy_result=真实顶层确认后进入可见结果层并取得焦点，不继续启动新局；
  Esc/B 返回 Deploy 且无 stale modal
targeted=I3R_INPUT_MODAL_AUTHORITY=PASS
regression=ART22_DEPLOY_PREP_RUNTIME + I3R_TUTORIAL_MAP_MODE +
  I3R_WAREHOUSE_BATCH_SALE + I2_SETTINGS_SHELL_WIRING
layout_fix=5x5/7x7/10x10/13x13 四个不重叠槽位，13x13 不再被教程尺寸挤掉
remaining=真实物理手柄、其他终局分支与动态玩家签收
status=TARGETED_PASS
```

## I3R.1 `RunScene` 架构边界记录

```text
extraction=弹层 root 注册、输入盾牌路由、焦点栈和首选焦点遍历已移入
  RunSceneModalController；底层 `_focus_stack` 为私有，RunScene 不再暴露 raw alias；
  RunScene 继续只负责节点接线与页面协调
production_wiring=生产 main.tscn -> RunScene -> RunSceneModalController
extraction_baseline=2959 lines / 174 functions
frozen_targeted=2974 lines / 161 functions；maximum 2980 / 176
targeted=I3R_RUN_SCENE_ARCHITECTURE_BOUNDARY=PASS
regression=I2_RUNTIME_MODAL_PRIORITY + I2_MODAL_FOCUS_LIFECYCLE +
  I3R_INPUT_MODAL_AUTHORITY
boundary=RunScene 仍是大型协调器；后续应继续一次提取一个有特征测试的职责，
  但继续压缩行数不是本次 I3R 关闭的独立硬要求
status=TARGETED_PASS / PRODUCTION_MAIN_WIRING_PASS / FURTHER_EXTRACTION_NON_BLOCKING
```

## I3R.3 角色运动定向记录

```text
implementation=首键仅预览接触姿态；逻辑位移只由 InputMap 连续 process 路径产生；
  加/减速采用分段积分，30/60/144 Hz 持续输入位移一致；被边界拒绝的移动保持原位置，
  不再出现先穿入再回弹
appearance=生产 main.tscn 的局内 PlayerController/Sprite2D 消费 appearance profile；
  默认 profile 保持原色；已拥有的 graytail.field_coat 使用审计安全的 Sprite modulate
  色型基线形成可观察替换；未拥有及未知 catalog 选择显式 fail closed；
  受击色与当前 profile 逐通道组合，反馈结束后精确恢复 profile
animation_strategy=当前使用已登记像素帧/动画集；动画只消费玩法状态；
  骨骼帧生成需另过来源、风格、轴点、碰撞同步、性能和玩家观感门，
  不作为通用补帧或替代玩法判定的默认方案
targeted=I3R_PLAYER_MOVEMENT_APPEARANCE=PASS；
  unowned=fail_closed；unknown_catalog=fail_closed；hurt=profile_composed
targeted=I2_PLAYER_MOTION_PROJECTION=PASS
targeted=I3_HUD_ITEM_INPUT_CHARACTER=PASS
boundary=field_coat 当前只证明局内替换管线与审计安全色型基线；不得宣称已有独立
  真实时装素材、生产获取/选择 UI、跨局外场景一致或完整换装产品闭环
remaining=外观获取/选择 UI、跨局外场景一致、真实时装资产与拥有/应用交易、
  生产玩家动态手感、真实手柄与目标设备签收
status=TARGETED_PASS / PRESENTATION_BOUNDARY_IMPLEMENTED /
  REAL_COSTUME_TRANSACTION_AND_PLAYER_ANIMATION_PASS_PENDING
```

## I3R.4 局内视觉焦点与周围雷险定向记录

```text
mine_risk=当前已扫描房间的八邻域真实雷房计数；排除当前格；unknown 隐藏；
  known zero 显示“周围雷险：0”；历史左栏副本保持不可见
footer=房间标签 / 周围雷险 / 上下文反馈 / 按键栏由 UILayerContract
  分配互不相交的矩形；房间投影在底栏上沿截止
popup=像素纹理框；优先停靠房间外围；玩家、交互对象、协议卡和底栏为硬避让区
door=房型与方向选择同一登记房间图源的裁切区域；贴图 region、pivot、display size、
  ground anchor、body_rect、近距提示、过门对齐和入口落点消费同一描述；
  不再以彩色碰撞矩形冒充门贴图
copy=局内反馈直接显示玩家结果，不再加“操作反馈：”工程前缀；
  教程不再泄漏 Tutorial popup/internal trigger id；战斗、搜索、事件与撤离旧消息统一玩家文案
targeted=I3R_RUN_FOCUS_LAYOUT=PASS;
  I3R_WORLD_OBJECT_PRESENTATION_CONTRACT=PASS
regression=I2_RUN_INFORMATION_SURFACE + I2_ASSET_BINDING +
  ART24_CONTEXT_ANCHOR_INTEGRATION + I2_WORLD_INTERACTION_RUNTIME +
  I3_HUD_ITEM_INPUT_CHARACTER + I2_PLAYER_MOTION_PROJECTION +
  G41_IN_RUN_CORE_GAMEPLAY_RUNTIME
rendered_evidence=docs/40_validation/i3r_ui_current/
  i3r_run_open_chest_popup_1280x720_v2.png
visual_check=1280x720 生产局内；已开启箱子悬浮窗不覆盖箱子、角色、协议卡、底栏或下门；
  “周围雷险：3”位于房间与反馈带之间
current_targeted=I2_WORLD_INTERACTION_RUNTIME=PASS;
  I3_SEARCH_WORLD_FEEDBACK=PASS;
  I3_MAP_LOCAL_CONTEXT_INTERACTION=PASS;
  I2_INVENTORY_HOVER_FOCUS=PASS;
  I2_SPECIAL_ROOM_PLAYER_EXPERIENCE=PASS;
  I3_COMBAT_SPECIAL_RESULT_RUNTIME=PASS;
  I2_TERMINAL_RESULT_AUTHORITY=PASS;
  I2_TERMINAL_COMMIT_RECOVERY=PASS
production_subsystems=搜索首次揭示/重访/靠近显示/显式拾取；
   KnownMap/小地图/语义格/外点关闭；背包滚动/详情/使用/丢弃/容量替换；
   战斗/事件/雷房/撤离；成功/失败/放弃及保存重试
frozen_evidence=标准 `.tmp/i3r4_final_standard_rendered_20260726` PASS；
  checkpoints=20 screenshots=20 inputs=137；满包
  `.tmp/i3r4_final_full_bag_rendered_20260726` PASS；screenshots=13 inputs=222；
  终局 `.tmp/i3r4_final_terminal_all_rendered_20260726` PASS；screenshots=15 inputs=129；
  outcomes=Abandoned,Failed；natural_failure_reason=runtime_combat_projectile
state_gallery=.tmp/i1/20260726T021919201Z_7d105484/i3r_production_state_gallery/
  wrapper_report.json；PASS_WITH_VISUAL_REVIEW_REQUIRED；cases=12；
  manifest 同目录；scoped Codex visual review=complete
current_fixes=已行动成功条移除；箱体闭开主体连续；雷机关 armed/triggered/resolved 可辨；
  地雷/角色/FX 深度分离；满包替换行两行且无裁切；战斗入口净空；
  结算保存重试保留原结果主体
remaining=final post-governance full、最终矩阵、真实键鼠/手柄、目标 GPU 长局、
  动态玩家观感与人工玩家签收、exact-head/commit/push
status=TARGETED_PASS / CURRENT_PRODUCTION_JOURNEYS_PASS / CODEX_VISUAL_REVIEW_PASS /
  DEVICE_AND_PLAYER_SIGNOFF_PENDING
```

## I3R.2 字体与文本安全区定向记录

```text
font_stack=FusionPixel player UI default + Noto CJK missing-glyph fallback only
coverage=Settings + OptionButton PopupMenu + native Tooltip + inventory hover +
  world popup + confirmation + result + long-term
runtime_assertion=get_theme_font resolves FusionPixelPlayerUIWithNotoGlyphFallback
root_cause=旧预览把 UI 缩放写入 Window.content_scale_factor，同时页面仍用固定字号/
  偏移；结果是世界与背景被二次缩放，边框拉伸且文字、角饰、滚动条和焦点框相交
production_fix=Window canvas scale 保持 1.0；Art10 UI scale authority 经
  RunScene/AppShell 传播到生产 Control 字号、最小尺寸、间距和 UILayerContract 安全区
targeted=I3R_UI_COMPOSITION_CONTRACT=PASS;
  I3R_UI_MATERIAL_SAFE_ZONE=PASS;
  I3R_TUTORIAL_RESPONSIVE_LAYOUT=PASS;
  ART23_LONG_TERM_MAIN_ROUTE=PASS
regression=settings transaction/shell + inventory hover + world popup layout +
  result authority + ART23 long-term + ART25 validator
rendered_evidence=docs/40_validation/i3r_ui_current/i3r_fusionpixel_ui.png
visual_check=1600x1200；设置/tooltip/世界弹窗/物品详情两两不相交，长中文完整
scale_evidence=.tmp/i3r_main_menu_scale/after +
  .tmp/i3r_tutorial_responsive；两页各覆盖 1280x720/1920x1080 × 100/125/150
long_term_scale=生产 Control 的 100/125/150% 字号、换行与安全区真实变化；
  同场景同分辨率三档截图 SHA 必须互异，重复哈希即失败；定向截图与反自证门已通过
final_preview_matrix=132/132 生成；四基准分辨率 × 100/125/150%；污染门 PASS
final_long_term_matrix=125/125 生成；25 页面 × 五分辨率；污染门 PASS
final_static_review=132+125+12=269/269；Codex 静态复核完成
boundary=自动状态仍为 PASS_WITH_VISUAL_REVIEW_REQUIRED；不替代动态人工玩家签收
remaining=动态玩家观感和真实设备
status=IMPLEMENTED_PRODUCTION / LONG_TERM_SCALE_ANTI_SELF_PROOF_PASS /
  FINAL_MATRIX_AND_CODEX_REVIEW_PASS / PLAYER_VISUAL_PASS_PENDING
```

## I3R.6 教程地图模式定向记录

```text
production_route=Deploy 地图页 -> tutorial_5x5 -> standard_run
content=固定 5x5；13 类 UE 教学内容；出生/出口阻塞，其余默认非阻塞；
  四个事件格经真实 CommandBus -> RoomResolver -> EventService -> TutorialService，
  按 UE 30/25/25/20 权重得到 trap -> dice -> altar -> trader
persistence=首通只写 tutorial_completed；失败/放弃/重玩不写正式成长；
  完成与重播结果的金币、物品和 salvage 均为零
interaction=地图格 Button.pressed 为鼠标与 ui_accept 的共同执行边界；
  未知格标记/取消，已探索且可回传安全格回传，焦点移动只选择；
  教学不再引用地图内不存在的 flag_cell，非阻塞提示可点击关闭且不抢键盘焦点
layout=教程框与左 HUD、房间、协议卡、底栏互斥；长文换行/滚动；
  1280x720/1920x1080 × UI 100/125/150 定向通过；
  1280x720@150% 标题单行、确认键提示完整且 350 px 房间仍可操作
player_journey=I3R_TUTORIAL_PLAYER_JOURNEY=PASS；真实 main.tscn；
  Deploy 可见目录 -> tutorial_5x5 -> standard_run；解析生产输入完成首通与重播；
  首通返回 Deploy，重播按规则返回主菜单；重载存档保持 completion-only 且无正式成长污染
targeted=I3R_TUTORIAL_MAP_MODE=PASS; I3R_TUTORIAL_EVENT_DIVERSITY=PASS;
  I3R_TUTORIAL_RESPONSIVE_LAYOUT=PASS; I3R_TUTORIAL_PLAYER_JOURNEY=PASS;
  I2_RUNTIME_MODAL_PRIORITY=PASS; I3_MAP_LOCAL_CONTEXT_INTERACTION=PASS;
  I2_MAP_PUBLIC_INFORMATION_INPUT=PASS
regression=I2_SPECIAL_ROOM_PLAYER_EXPERIENCE + G41_IN_RUN_CORE_GAMEPLAY_RUNTIME
visual_evidence=.tmp/i3r6_popup_fix/visual/capture.png
combined_evidence=.tmp/i3r6_final_combined_20260726
remaining=真实设备输入和动态玩家观感签收
status=TARGETED_PASS / CURRENT_COMBINED_SUITE_PASS / UE_INTERACTION_ALIGNMENT_PASS /
  CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING
```

## I3R.5 仓库批量售卖定向记录

```text
production_route=Deploy 仓库 -> 批选/全选可售/清除 -> 数量与总价 -> 二次确认
transaction=MetaActionEnvelope + request_id；all-or-nothing；保存失败恢复 previous_data
blocked=缺失/重复实例、不可售、唯一物和当前出勤项均给出玩家原因并使整批不变
sync=成功后金币、仓库与仍在库中的出勤配置由权威 summary 同步刷新
targeted=I3R_WAREHOUSE_BATCH_SALE=PASS
regression=I2_DEPLOY_META_ACTION_TRANSACTION + I2_DEPLOY_MAP_PROJECTION +
  I3R_UI_COMPOSITION_CONTRACT
player_journey=真实 main.tscn 局外旅程已覆盖批选后取消与确认，权威金币/仓库摘要同步；
  22 checkpoint/22 PNG/36 inputs
remaining=真实键鼠/手柄、目标设备与动态人工玩家签收
status=TARGETED_PASS / PRODUCTION_PLAYER_JOURNEY_PASS / CODEX_SCOPED_VISUAL_REVIEW_PASS
```

## I3R.5 天赋、结果归档与角色档案定向记录

```text
talent=3 分支 / 6 节点；真实前置、永久点数、精确新局效果；
  MetaActionEnvelope 幂等、冲突关闭、保存失败回滚；教程零正式成长污染
archive=结算持久化 terminal_reason_code、携入、带回/保全/损失、现场遗留、
  黑资/金币与锁定收益；角色历史与结果页复用同一失败原因
profile=真实称号、探索数、撤离率、档案数、长期金币与下一等级经验阈值；
  profile 为只读 archive，不伪装可写
targeted=I3R_TALENT_SYSTEM + I3R_OUT_OF_RUN_PLAYER_ARCHIVE +
  I3R_WAREHOUSE_BATCH_SALE
regression=ART21 main-menu/transition + ART22 Deploy + ART23 long-term +
  I2 settings/terminal + I3 result/long-term + M7 900 fixed-seed map runs
player_journey=真实 main.tscn 局外旅程已覆盖任务、天赋、档案和
  secondary -> primary -> main 的三级 Esc；22 checkpoint/22 PNG/36 inputs
remaining=真实键鼠/手柄、目标设备与动态人工玩家签收；
  外观仍无生产获取/选择 UI、拥有/应用权威交易或跨局外场景一致，
  继续保留为真实只读收藏档案
status=TARGETED_PASS / PRODUCTION_PLAYER_JOURNEY_PASS / CODEX_SCOPED_VISUAL_REVIEW_PASS
```

## I3R.5 局外生产旅程与视觉修正记录

```text
production_entry=res://scenes/main/main.tscn
journey=I3R_OUT_OF_RUN_PRODUCTION_JOURNEY=PASS
coverage=设置安全应用、未应用取消、危险显示回退；
  Deploy 地图/仓库/申领/目标/出勤配置；批售取消后确认；
  长期任务/天赋/档案；secondary -> primary -> main 三级 Esc
evidence=.tmp/i3r5_out_of_run_rendered_20260726/journey.json +
  journey.csv + 22 PNG
inputs=36 parsed pointer/semantic inputs
visual_corrections=危险显示确认内容垂直居中且焦点稳定；
  Deploy 详情动作与“收起内容”保持实际渲染安全间距；
  仓库/出勤配置读取权威藏品等级；
  选中地图不重复工程状态文案；
  主菜单进入长期系统使用生产 clean-plate underlay，消除蓝色接缝；
  任务详情补足类型/状态/进度/奖励/领取规则；
  天赋使用专用三分支像素图标；
  档案时间精确到分钟且不裁切；
  “收起档案”改为档案抽屉与方向箭头，不再呈现放大镜语义
scoped_review=22 张当前生产截图已逐项复核上述可见问题；
  不等同动态手感、真实设备或用户签收
known_boundary=外观获取/选择 UI、真实时装资产与权威交易仍未实现；
  最终矩阵、真实键鼠/手柄、目标设备和动态人工玩家签收留在 I3R.8
status=TARGETED_PASS / PRODUCTION_PLAYER_JOURNEY_PASS /
  CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_SIGNOFF_PENDING
```

## I3R.1 / I3R.4 玩家反馈定向记录

```text
service=PlayerFeedbackService 单一入口；只观察已发生领域/呈现事件，不改玩法权威
source_gate=9 个项目内部程序化 WAV；registry/runtime SHA 门通过；
  当前本机观测的 UE 仓库历史提交 + Git LFS OID 完整来源门通过；
  未准入 Hero Immortal BGM；本机绝对路径不是跨机器权威
routes=UI 确认/拒绝、搜索、拾取、箱开、恢复、攻击、实际命中、受伤、雷爆、
  敌人死亡、成功/失败终局
dedupe=同一领域 event_id 防止重复 cue；战斗 recent_events 另有已消费序号门
settings=schema 4；master_volume + effects_volume + haptics_enabled；
  共享草稿/应用/持久化/危险显示回滚事务；Master/Effects 总线真实生效
haptics=当前语义手柄；无设备安全跳过；reduced-motion 保留音频并将强震动上限压至 0.12/0.08s
targeted=I3R_PLAYER_FEEDBACK_AUDIO=PASS
regression=I2_SETTINGS_TRANSACTION + I2_SETTINGS_SHELL_WIRING +
  I2_ACCESSIBILITY_RUNTIME + I3R_UI_COMPOSITION_CONTRACT
remaining=真实物理手柄、目标设备混音/响度与完整生产玩家旅程签收
status=TARGETED_PASS
```

## I3R.7 Base 定向记录

```text
immutable_base=PASS planning=25 art_members=1407 art_unique=1012 aliases=395
planning_policy=sources/base/原始策划案保留原名、完整字节、信息量和来源 SHA；
  只允许统一承载格式，不得摘要替换或减少内容
dedupe_policy=仅按内容 SHA 精确折叠；保留全部原始 alias/路径；
  同名不同内容不覆盖，同内容不同语义不丢失关联
semantic_registry=PASS base_objects=1012 uncategorized=0
runtime_crosswalk=PASS rows=178 paths=175 unique_sha=149 explicit_promotions=1
consumer_proof=direct_token=47 dynamic_contract=108 scene_resource=0
  staging_no_consumer=6 no_production_consumer=17
consumer_boundary=manifest/translation/tests/mapping 不得作为最终生产消费者自证；
  semicolon consumers 按独立消费者逐项解析
runtime_alias_debt=groups=2 assets=2；minimap spawn/event 共享别名是公开替换债，
  不得伪装为唯一语义资产
unadjudicated_runtime_matches=0
quarantined_semantic_mismatch=1
visual_reviewed=75 existing_runtime=14 staging_reference=35 restricted=25 semantic_mismatch=1
pending_visual_review=0
evidence=.tmp/i3r/base_visual_review (5 pages) + I3R_BASE_VISUAL_REVIEW_REGISTRY.csv
command=tools/i3r/invoke_i3r.ps1 -GovernanceOnly
status=MACHINE_GATE_PASS / PLAYER_ROUTE_SIGNOFF_PENDING
```

## I3R.7 当前长期系统与历史 ART23 边界

```text
current_production=6 modules / 25 pages / 58 runtime assets
current_modules=tasks, talent, archive, collection, profile, research
removed_runtime=gacha controls 5 + gacha furniture 1；manifest gacha rows=0
talent_asset=5 dedicated controls + dedicated talent furniture；不复用抽卡家具
current_gate=I3R_LONG_TERM_CURRENT_GOVERNANCE=PASS
current_evidence=docs/40_validation/i3r_long_term_current/
historical_art23=保留原始 6×27 页面矩阵与 58 texture 记录；
  历史 gacha source/screenshot 仅作为冻结证据，不是当前生产许可
historical_validator=tools/validate_art23_long_term_final_ui.ps1 只验证其历史对象，
  不得替代当前长期系统门
visual_review=talent_tree_1280x720.png 已检查；详细木铜家具为背景承载，
  前景羊皮纸信息层级、文字安全区和焦点均可读
status=CURRENT_PRODUCTION_GATE_PASS / HISTORICAL_ART23_PRESERVED /
  FINAL_MATRIX_AND_CODEX_REVIEW_PASS / PLAYER_SIGNOFF_PENDING
```

## I3R.8 快速阅览与终验边界

```text
implemented=tools/i3r/invoke_i3r_preview_matrix.ps1；
  每例只实例化生产 res://scenes/main/main.tscn，输出 PNG、metadata 和日志；
  tools/i3r/invoke_i3r_state_gallery.ps1 单次实例化生产 main.tscn，
  固定 seed 13 输出当前 12 个对象/特殊房/战斗状态及逐项 SHA sidecar；
  历史 11/11 画廊仍作为其快照记录保留
in_run_production_journey=PASS；seed 13；生产 main.tscn；20 checkpoint/20 screenshot；
  主菜单 -> 洞口转场 -> Deploy -> Run -> 撤离 -> 真实保存失败重试 -> 返回主菜单
out_of_run_production_journey=PASS；生产 main.tscn；22 checkpoint/22 PNG/36 inputs；
  设置安全应用/取消/危险显示回退、Deploy 五页、批售取消/确认、
  长期任务/天赋/档案与 secondary -> primary -> main 三级 Esc
tutorial_journey=PASS；生产 main.tscn；Deploy catalog -> tutorial_5x5 -> standard_run；
  首通 + 重播；completion-only；金币/物品/salvage 零污染；返回路由正确
combat_journey=PASS；seed 13；生产 main.tscn；解析 D/Space；
  可见祭坛同源阻挡移动/判定/扇区视觉；近战自然绕障；
  held 战斗门单次拒绝/零 transition dispatch；敌预警可见；
  攻击期朝向锁定后释放；早按拒绝不耗回合、后段输入缓冲；
  遮挡视觉裁剪且 blocked/no-hit；无遮挡 one-hit；
  结算、解除封锁并正常离房；inputs=64
historical_state_gallery_evidence=.tmp/i1/20260724T081913076Z_117ed89a/
  i3r_production_state_gallery/manifest.json；11/11；
  SHA256=1E09A272B4F3D5EA4FFB00D14B5BEDC98074BD0FD4B8A20F2DA129D02FE7C7E4
final_state_gallery_evidence=.tmp/i1/20260726T174413001Z_03839547/
  i3r_production_state_gallery/wrapper_report.json；PASS_WITH_VISUAL_REVIEW_REQUIRED；12/12；
  wrapper SHA256=5854567A235971BAF0B4689BF3B925A7E3E3229E157E9276FBAEABBB1CB7A7D2；
  manifest SHA256=3D5003B9C19161C8D79A75DAB017C9ABAA2BE8C5F7FD564DA26E62432F7C277D
preview_matrix_evidence=.tmp/i1/20260726T171343894Z_6892a1f1/
  i3r_preview_matrix/matrix_manifest.json；132/132；四分辨率 × 三 UI 缩放；
  preflight/capture pollution PASS；mirror unchanged；
  SHA256=DCB8DA67E8D19B496024585447987CEF1F77916A20325573F13E5D0EB72D7494
long_term_matrix_evidence=.tmp/i1/20260726T173939443Z_6d8ac659/
  i3r_long_term_matrix/matrix_manifest.json；125/125；25 页面 × 五分辨率；
  SHA256=BE3535EB0CDBA9A181C5A5A2DD61890D290145019CD02E37F86A7CFE15B545F6
physical_frame=1366x768 使用生产 keep-aspect 的 1365x768 内容 + 右侧 1px 黑边；
  metadata schema 3 严格记录并复算，不拉伸、不放宽尺寸容差
codex_visual_review=最终 132 生产预览 + 125 长期系统 + 12 状态画廊，
  共 269/269 张静态图完成范围化复核；未发现阻断项
metadata_boundary=GENERATED_REVIEW_REQUIRED / visual_acceptance=NOT_RUN；
  scoped Codex review 不替代真实设备或人工玩家签收
final_worktree_full=.tmp/i1/20260726T171400780Z_6f66cb6f/report.json；
  96/96 PASS；53 plain + 43 cleanup-diagnostic；0 hard failure；
  static/registration/pollution PASS；duration_ms=1053141；
  manifest SHA256=11B32B377A244B9DDF98637020CC9F263ABCDEB488472FA624F11F5A0A575406；
  report SHA256=3CDF02791EC61CD580B78489A4C5B2581EF7E974AADEEA897AF06FEBD1494BC4；
  business files=2333；fingerprint=E7ACAA39576A6DFEEB8B22EA18C41B0914A008F84F33348637183B1541C25A1F
writeback_boundary=上述 full 绑定最终生产/工具快照；之后仅回写治理文档和存储终态，
  不把文档回写伪装为其 business fingerprint 覆盖内容
remaining=真实设备/GPU 长局；动态人工玩家签收；
  exact-head/full 与 commit/push/remote SHA 由最终交付记录提供
status=FINAL_WORKTREE_FULL_AND_MATRICES_PASS /
  EXTERNAL_ACCEPTANCE_PENDING
```

## I3R 空间治理记录

```text
archive_model=内容寻址 CAS + 固定 index + 每快照 manifest
final_archive=PASS；snapshots=123；i3r_snapshots=60；
  snapshot_files=543197；snapshot_logical_bytes=81804420162；
  CAS objects=6489；CAS bytes=735449033
archive_index_sha256=16974A206B007F737CB4CC45163720F3D10AF1170A657EC1DD477B26DE61AEAE
final_global_proof_sha256=A9B1286576B9E877642F9B2D0FACC7FE90F22C06D40C14856A1C7C7D97A377C4
restore_proof=最终 full `20260726T171400780Z_6f66cb6f` 已执行 V2 独立复制恢复；
  两次完整树校验 PASS；还原副本已移除；
  manifest SHA256=0D22EF6641CE54A536A230E43DE9006F997FE1FBF9B8BA7EE29380AAE2B54764；
  proof SHA256=ACE86F8E3614CBA2BB8E0A52EC82B1E3A320609422CF20FD17AC274F1D483195
current_prune=38/38 snapshot worktree 镜像按事务凭证移除；
  interrupted 事务取证目录保留；worktree=0；tombstone=0
transient_cleanup=76 个 process_env/engine_hardlink_view 目标已移除；
  孤立 restore staging 752427027 bytes 已在精确校验后移除
physical_result=2026-07-27 E:\AGAME1 9.1937 GiB / 56331 files；
  E 盘可用 112984649728 bytes（105.2252 GiB）；
  相对本轮清理前 E 盘可用空间增加 32890380288 bytes
preserved=report、manifest、CAS 对象、index、V2 restore proof、事务回执、
  interrupted 事故取证、sources.zip、Base 原件与运行时素材
protected=原始 sources.zip、Base、原始策划案与运行时素材均保留且不视为缓存
stage_git_worktrees=不属于快照缓存；I2 含修改，I3/I3-baseline 虽可重建但可能绑定
  历史任务，均未删除
retention_policy=以后最多保留一个活动验证镜像；候选提交与 exact-head 证据形成后，
  依次 archive → verify → V2 restore → transaction prune；禁止通配或手工删除
pending=后续新增验证仍须遵循 archive → verify → V2 restore → transaction prune；
  活动验证镜像最多保留一个；不得清理原始来源或未关闭任务绑定的 Git worktree
status=CURRENT_CAS_INDEX_V2_RESTORE_PRUNE_AND_VERIFIER_PASS
```

## 单门记录格式

```text
gate:
precheck:
decision:
allowed_paths:
protected_paths:
implementation:
real_consumers:
targeted_tests:
rendered_evidence:
player_journey:
performance:
residuals:
status:
```
