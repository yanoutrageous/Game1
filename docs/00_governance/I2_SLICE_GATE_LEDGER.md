# I2 Slice Gate Ledger

文档状态：I2 当前门账；阶段 `ACTIVE`，已产生若干受门控运行时检查点，但尚未综合关闭。
最后更新：2026-07-22

## 1. 状态定义

| 状态 | 含义 |
| --- | --- |
| `NOT_STARTED` | 未获切片执行授权；不得改运行时/资产 |
| `AUDIT_REQUIRED` | 候选范围已知，但缺 scope/risk/paths/evidence 门 |
| `READY` | 切片审计通过，allowed/protected paths 与验证已冻结 |
| `IN_PROGRESS` | 正在 allowed scope 内实施 |
| `READY_FOR_REVIEW` | 变更与约定证据已产生，尚未被切片审计接受 |
| `ACCEPTED_WITH_NOTES` | 切片证据接受但有登记债务；不等于 I2 关闭 |
| `BLOCKED` | 有 blocking regression、未知 dirty、缺决策或缺证据 |

只有一份最终 I2 综合 validation/handoff；切片状态用于执行控制，不构成独立阶段关闭。

## 2. 当前总览

```text
I2 stage: ACTIVE
I2 runtime implementation: AUTHORIZED_BY_SUBSLICE_GATE / IN_PROGRESS / NOT_CLAIMED
I2 capability promotion: NONE
I2 final validation/handoff: NOT_CREATED
entry HEAD: b77132b9de655b36f71c930a35a191c383b55522
entry full/head: 39/39 PASS
```

| Slice | 范围 | 依赖 | 当前状态 | 当前证据/下一门 |
| --- | --- | --- | --- | --- |
| I2.0 | 启动审计、契约、评估、矩阵、架构、验证计划、门账、入口 | I1 closed + exact entry baseline | `ACCEPTED_WITH_NOTES` | 独立复核修正 I1/I2 报告字段后，16/16 allowed paths、43/43 IDs、refs/UTF-8/YAML basic/diff/static 与 quick 21/21 PASS；无 runtime claim |
| I2.1 | 共享导航/转场、设置、focus/modal、character presentation、style/layer seam | I2.0；设置字段与动画技术决策 | `IN_PROGRESS` | I2.1A/B/C 的路由、真实设置、输入、focus 与生命周期基础已 `READY_FOR_REVIEW`；character/transition/style seam 随 I2.2 继续，不提前关闭 I2.1 |
| I2.2 | 主菜单文字/场景/锚点/动效/空间转场 | I2.1 最小 seam | `IN_PROGRESS` | I2.2A 主菜单安全回退切片已 `ACCEPTED_WITH_NOTES`；完整洞口步行动画、下层连续背景与玩家手感复核仍待后续切片，不关闭 I2.2 |
| I2.3 | Deploy 双栏、地图同页、仓库/申领/委托/摘要 | I2.1；经济/taxonomy/loadout 决策 | `ACCEPTED_WITH_NOTES` | I2.3A 同页双栏与八地图精确投影、I2.3B 单件购买/出售真实事务闭环均已接受；批量售卖继续禁止，玩家动态手感并入 I2.7 综合复核 |
| I2.4 | 长期模块重排、任务档案迁移、天赋、角色档案 | I2.1；taxonomy 与天赋数据权威 | `IN_PROGRESS` | I2.4A 任务档案责任迁移与红点可靠性门已进入实施；天赋仍受产品权威决策门阻塞，不伪造可玩能力 |
| I2.5 | 局内 HUD、地图、背包、箱/门/掉落、协议、Esc/modal | I2.1；对象/ledger/map characterization | `AUDIT_REQUIRED` | 独立 I2.5A 结果框/协议色板/物品 binding 已 `READY_FOR_REVIEW`；其余局内职责仍待分项授权 |
| I2.6 | 战斗/特殊房、结算解释、真实工作负载性能 | I2.5 基础；性能 baseline/阈值 | `IN_PROGRESS` | I2.6A v2 工作负载与 I2.6B pre-authority combat asset admission 已 `READY_FOR_REVIEW`；特殊房、结算与 visible 验收仍待后续 gate |
| I2.7 | 跨页面整合、操作说明、全量回归、综合验收 | I2.1–I2.6 accepted/deferred with owner | `NOT_STARTED` | full/worktree→commit→full/head；matrix 逐项；创建唯一 validation/handoff |

## 3. 全局进入门

任一 I2.1–I2.6 切片从 `AUDIT_REQUIRED/NOT_STARTED` 进入 `READY` 前必须登记：

```text
Goal and non-goals
User-feedback IDs
Current code/runtime characterization
Product decisions and unresolved decisions
Allowed paths
Protected/forbidden paths
Expected authority/state changes
Asset/source/import status
Baseline commands and fingerprints
Targeted + regression validation
Dynamic/input/accessibility/failure review
Performance workload if claimed
Rollback point
Stop conditions
```

没有精确 allowed paths 的 scene/resource/project/metadata/asset 切片保持 `BLOCKED`。不能用“同一 I2 阶段”扩大当前切片权限。

## 4. 不可变全局门

### 4.1 权威门

- Godot 是实现目标；UE 只读参考。
- `RunStateMachine`、`RunAssetLedger`、terminal settlement、保存安全和幂等边界不得回归。
- UI/动画/计时器不拥有领域提交。
- Deploy 地图始终为同一页 split view，不增加 region→difficulty page flow。

### 4.2 反馈门

切片必须列出其处理的 `MAIN-*`、`DEP-*`、`LONG-*`、`RUN-*`、`ROOM-*`、`CROSS-*`。用户观察需要运行证据确认；不采纳的方案必须给仓库证据和替代方案，不得静默删除。

### 4.3 资产门

```text
reuse registered Godot asset
  -> use audited-but-unwired Godot asset
  -> audit/import selected external asset
  -> generate only after confirmed gap and approval
```

每个新增/改绑资源必须有 source、license、SHA-256、usage、target、runtime key、replacement 状态和确定性结论。禁止直接迁入 `.uasset`、UE 烤字布局、过程帧或未知许可素材。

### 4.4 证据门

- 自动化、CAP、DYN、INPUT、PERF、FAIL、ASSET、TEXT 分开记录。
- `PASS_WITH_VISUAL_REVIEW_REQUIRED` 不是视觉 PASS。
- combat refresh 微基准不是 FPS/通用性能。
- worktree PASS 不是 exact HEAD PASS。
- 未运行必须写 `NOT_RUN`。

## 5. 受保护 dirty / metadata 门

I2 隔离 worktree 启动时干净。主工作树 `E:\AGAME1` 的以下状态属于外部受保护内容：

```text
Godot/GraytailGodot/project.godot
Godot/GraytailGodot/data/assets/asset_manifest.category.translation
Godot/GraytailGodot/data/assets/asset_manifest.import.translation
Godot/GraytailGodot/data/assets/asset_manifest.license.translation
Godot/GraytailGodot/data/assets/asset_manifest.linked.translation
Godot/GraytailGodot/data/assets/asset_manifest.note.translation
Godot/GraytailGodot/data/assets/asset_manifest.replacement.translation
Godot/GraytailGodot/data/assets/asset_manifest.usage.translation
```

规则：

1. 不清理、restore、复制、重放、stash pop 或暂存这些状态。
2. 任何 I2 切片需要同类型文件时，只在隔离 worktree 以起点 preimage 新建精确 diff。
3. `project.godot` 必须说明每个语义键；不能把 stretch/aspect 等变化归类为无害 metadata。
4. scene/resource/`.uid`/`.translation`/import metadata 需要专门 gate 与精确暂存清单。
5. 检测到 unexplained dirty、staged 或 external write，立即停止并回到风险审计。

## 6. 切片专门停止条件

| Slice | Blocking stop condition |
| --- | --- |
| I2.1 | 转场双提交/失焦；设置伪生效或保存失败冒充成功；角色 fallback 阻断玩法 |
| I2.2 | 路由依赖动画计时提交；锚点在目标分辨率漂移；reduced-motion 无可理解反馈 |
| I2.3 | 地图离开同一 Deploy 页；地图 ID/schema 漂移；UI 直接改金币/库存；批售无幂等/确认 |
| I2.4 | Goal 改名先于任务迁移；任务/成就/红点/领取丢失；天赋只有展示无真实权威却被声明完成 |
| I2.5 | proximity 自动拾取；UI 泄露地图 truth；箱/门视觉与状态不一致；模态输入穿透 |
| I2.6 | 触边自动逃跑仍存在；结算重复提交；性能数据非同条件或只测 refresh；失败路径未覆盖 |
| I2.7 | 任一矩阵项静默遗漏；未知 dirty；full/head、人工或来源门缺失；声明超过证据 |

## 7. I2.0 文档切片 allowed paths

本次 I2.0 只允许：

```text
AUDIT_ENTRYPOINT.md
docs/README.md
docs/INDEX.md
docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md
docs/00_governance/I2_PRE_EXECUTION_SCOPE_RISK_AUDIT.md
docs/00_governance/I2_SLICE_GATE_LEDGER.md
docs/10_current/AUDIT_SCOPE.md
docs/10_current/CAPABILITY_MATRIX.yaml  # 仅阶段/起点 metadata；不得提升 runtime capability
docs/10_current/CURRENT_STATE.md
docs/10_current/I2_PRE_EXECUTION_BASELINE_ASSESSMENT.md
docs/10_current/NEXT_ACTION.md
docs/20_product/I2_REFACTOR_DIRECTION_AND_INCREMENTAL_BASELINE_CONTRACT.md
docs/20_product/I2_PLAYER_FEEDBACK_TRACEABILITY_MATRIX.md
docs/30_engineering/architecture/I2_TARGET_ARCHITECTURE_AND_MIGRATION_PLAN.md
docs/30_engineering/godot/I2_VALIDATION_PREVIEW_AND_MANUAL_REVIEW_PLAN.md
docs/50_stages/active/STAGE_INDEX.md
```

I2.0 明确禁止修改 Godot、tools、assets、validation、handoff、closed stage index、历史审计和外部 source pack。

## 8. 门账更新规则

- 执行角色在切片开始、产生证据、遇到阻塞和完成 review 时更新状态与证据路径。
- `READY_FOR_REVIEW` 不能自行升级为 accepted；需要独立 scope/claim review。
- 切片接受后仍保持 I2 `ACTIVE`，直到 I2.7 综合关闭。
- I2.0 自检完成后只可记为“docs ready for review / no runtime delta”，不得创建 validation/handoff 或修改 runtime capability。

## 9. I2.0 自检记录

```text
changed paths: 16 / 16 in I2.0 allowlist
feedback IDs: 43 / 43, no missing/extra/duplicate
repository document references: 35 unique, all resolved
strict UTF-8: PASS
CAPABILITY_MATRIX YAML basic structure/required keys: PASS
git diff --check: PASS
I1 validate_static.ps1 / worktree: PASS
I1 quick/worktree: PASS 21/21; 9 PASS + 12 PASS_WITH_CLEANUP_DIAGNOSTIC
quick report: E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T200136741Z_9257b2a5\report.json
quick report SHA-256: DE0BBEA26E0A41A0F9DAFEC3E1EBC85C2059664EFC7CF61C36CBFA2162D21666
quick duration: 170878 ms
core/ui/full worktree after docs: NOT_RUN (docs-only slice; no runtime claim; entry full/head remains separately recorded)
```

Python 环境未安装 PyYAML，因此 YAML 自检使用严格的当前文件子集结构、缩进、重复键与 required-key 检查；这是已登记的工具限制，不等于完整 schema validator。独立 claim review 同时把能力矩阵中的 I1 关闭报告与 I2 entry 报告拆成独立字段，避免把不同运行的哈希和微基准混为一组。I2 entry exact full/head 39/39 仍为运行时进入基线，不被本次 docs 自检改写。

## 10. 首批运行切片门（2026-07-22）

### 10.1 I2.1A 状态权威与页面生命周期

```text
status: READY_FOR_REVIEW
feedback: MAIN-04(partial), DEP-03(no-regression), DEP-07, DEP-10, LONG-01(partial), CROSS-01, CROSS-04, CROSS-05, CROSS-08
rollback: 75f2168 (I2.0 accepted baseline)
```

当前 characterization：启动命令失败后仍可能重置玩家并切入局内；关闭设置后 AppShell 可见页与 `RunScene.screen_state` 可失配；active run 只恢复携带物而未完整恢复/锁定地图、难度和委托；Main/Long 隐藏后仍继续 `_process` 与 Tween。该切片只修复这些权威和生命周期缺口，不重排页面、不实现空间动画、不改变地图 ID、经济、结算或保存 schema。

允许路径：

```text
Godot/GraytailGodot/scripts/core/run/run_scene_route_controller.gd
Godot/GraytailGodot/scripts/core/run/run_scene.gd
Godot/GraytailGodot/scripts/ui/app_shell/app_shell.gd
Godot/GraytailGodot/scripts/ui/app_shell/page_router.gd
Godot/GraytailGodot/scripts/ui/app_shell/navigation_intent.gd
Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd
Godot/GraytailGodot/tests/i2_route_authority_lifecycle_runner.gd
```

保护/禁止：`project.godot`、scene/resource/asset/import/translation、settings/input 文件、`RunStateMachine`、`RunAssetLedger`、terminal settlement、SaveAdapter、MetaProgress、ContentDB、I1 manifest，以及白名单外测试。只有 command 成功且 runtime 为 running 才可提交 Run 路由；active run 必须投影 canonical `map_config_id`/objective/loadout 并禁止本地改写；隐藏页不得处理动画、输入或保留焦点。定向 runner 后跑 quick；集成 review 跑 ui/full。动态门覆盖命令失败、重复点击、返回、隐藏页时钟与 active-run 锁定。

### 10.2 I2.1B 设置、运行时输入与焦点基础

```text
status: READY_FOR_REVIEW (foundation accepted by production integration gate)
feedback: MAIN-05, MAIN-02(partial), DEP-01(partial), LONG-01(partial), RUN-02(partial), RUN-10(partial), RUN-11(partial), CROSS-05, CROSS-07, CROSS-08
rollback: 75f2168 (I2.0 accepted baseline)
```

首批真实字段冻结为 `display.window_mode`（windowed/borderless/exclusive）、`display.resolution_id`（auto + 现有五档 16:9）、`display.vsync_mode`（enabled/disabled/adaptive）、`display.frame_limit`（0/60/120/144）和 `accessibility.reduce_motion`。windowed 使用固定 16:9 档位并禁止自由拖拽，直到非 16:9/DPI 动态门建立。音量、UI scale、震屏、高对比度等没有真实消费者的控件不得显示或持久化；音频保持 `AUDIO_BLOCKED_BY_SOURCE_LICENSE_AND_RUNTIME_CONSUMER`。

允许路径：

```text
Godot/GraytailGodot/scripts/core/settings/settings_manager.gd
Godot/GraytailGodot/scripts/core/settings/settings_store.gd                 # new
Godot/GraytailGodot/scripts/core/input/runtime_input_profile.gd             # new
Godot/GraytailGodot/scripts/ui/settings/settings_panel.gd                    # new
Godot/GraytailGodot/scripts/ui/shell/modal_focus_stack.gd                    # new
Godot/GraytailGodot/tests/i2_settings_transaction_runner.gd                  # new
Godot/GraytailGodot/tests/i2_runtime_input_profile_runner.gd                 # new
Godot/GraytailGodot/tests/i2_modal_focus_lifecycle_runner.gd                 # new foundation tests only
Godot/GraytailGodot/tests/i2_accessibility_runtime_runner.gd                 # new foundation tests only
```

保护/禁止：`project.godot`、AppShell/RunScene/页面 shell（待 I2.1A review 后另开 integration gate）、scene/resource/asset/import/translation、SaveAdapter/meta/run 存档、I1 manifest。SettingsManager 独占 committed/applied/draft/rollback，使用独立版本化 `user://settings.cfg`、原子临时文件/备份/未来 schema 保护；危险显示设置 15 秒确认，取消/超时/关闭恢复完整 rollback。`RuntimeInputProfile` 在运行时幂等补手柄事件，保留键盘且绝不保存 ProjectSettings。测试必须注入隔离路径/显示适配器，不污染玩家偏好或桌面窗口。

### 10.2.1 I2.1C 设置生产接线与真实面板挂载

```text
status: READY_FOR_REVIEW (production integration)
feedback: MAIN-05, MAIN-02(partial), DEP-01(partial), LONG-01(partial), CROSS-05, CROSS-07, CROSS-08
rollback: ff66de2 (first runtime slice gates)
```

独立复核确认 foundation 的 `reduce_motion` 只在三张页面 `_ready()` 时读取一次，玩家应用或危险设置回滚后不会即时更新；AppShell 的设置弹层仍是无真实消费者的视觉占位。该切片授权 AppShell 成为唯一运行时 fan-out 与默认 SettingsManager/SettingsPanel 组合 owner：可注入 manager 供测试，也可在无 autoload 时创建单一 owned manager；`settings_applied/settings_reverted` 必须即时传播到 Main/Deploy/Long，隐藏页不得被恢复，进行中的 Tween/转场必须吸附到可理解终态。真实设置入口必须挂载 `SettingsPanel`，不得继续显示假按钮或用视觉状态冒充保存成功。

允许路径：

```text
docs/00_governance/I2_SLICE_GATE_LEDGER.md
docs/30_engineering/godot/I2_VALIDATION_PREVIEW_AND_MANUAL_REVIEW_PLAN.md
Godot/GraytailGodot/scripts/core/settings/settings_manager.gd
Godot/GraytailGodot/scripts/ui/settings/settings_panel.gd
Godot/GraytailGodot/scripts/ui/app_shell/app_shell.gd
Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd
Godot/GraytailGodot/tests/i2_settings_shell_wiring_runner.gd
tools/i1/validation_manifest.json
```

保护/禁止：`project.godot`、RunScene/RunStateMachine、scene/resource/asset/import/translation、SaveAdapter/meta/run 存档及五个冻结字段以外的伪设置。动态门覆盖真实 SettingsPanel 提交、同步回刷竞态、Main 半途转场 snap、Deploy/Long Tween 与粒子、危险显示项超时完整 rollback、跨页隐藏时钟、manager 重绑、默认 production owner、打开/关闭/焦点，以及旧 ART21/22/23/route/accessibility/settings 回归。

### 10.3 I2.5A 既有视觉资产接线与物品绑定治理

```text
status: READY_FOR_REVIEW (isolated presentation/asset-governance slice only)
feedback: RUN-05(partial), RUN-08(partial), RUN-10(partial), RUN-12(partial), CROSS-03, CROSS-04, CROSS-05, CROSS-07
rollback: 75f2168 (I2.0 accepted baseline)
```

复用现有已登记 Godot 资产：ART24 success/failure/abandoned 三态空白结果框、五级协议色板与已审计协议外框。生产结果页必须保留动态本地化标题，协议必须用色板 + 等级文字 + 实时压力冗余表达。物品 catalog 已消费的未登记源图不得扩大绑定；能证明来源/许可/hash 时补 manifest，否则改绑已登记 ART24/ART25 输出。不得导入/修改任何 PNG，不得使用 UE `.uasset`、烤字图或未知许可音频，不生成新素材。

允许路径：

```text
Godot/GraytailGodot/scripts/ui/result/result_panel.gd
Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd
Godot/GraytailGodot/scripts/presentation/art24/art24_item_visual_catalog.gd
Godot/GraytailGodot/data/assets/asset_manifest.csv
Godot/GraytailGodot/tests/art24_result_panel_scene_probe.gd
Godot/GraytailGodot/tests/art24_run_surface_layout_probe.gd
Godot/GraytailGodot/tests/art24_in_run_runtime_runner.gd
Godot/GraytailGodot/tests/i2_asset_binding_runner.gd                         # new
```

只读来源：`assets/art24/ui/result/`、`assets/art24/ui/protocol/`、已登记 ART24/ART25 物品输出。保护/禁止：全部图片本体、scene/resource/`.uid`/import metadata、七个 `asset_manifest.*.translation`、`project.godot`、UE/外部目录、领域/结算权威、I1 manifest。定向 probe/runner 后跑 ui + quick；视觉 capture 仍标 `VISUAL_REVIEW_REQUIRED`，不能以纹理路径断言替代动态标题、压力变化和颜色冗余人工复核。

### 10.4 I2.6A 真实战斗工作负载性能基线

```text
status: READY_FOR_REVIEW (measurement only; no GPU/visible claim)
feedback: RUN-02(partial), RUN-10(partial), ROOM-01(performance baseline), CROSS-04, CROSS-05, CROSS-08
rollback: ff66de2 (first runtime slice gates)
```

现有 `I1_COMBAT_REFRESH` 只测命令触发的 UI refresh，`G41_IN_RUN_CORE_GAMEPLAY_RUNTIME` 只证明固定步长调度确定性；二者均不得被表述为玩家可见 FPS。I2.6A 使用真实 Main/Run/G41/RoomRuntimeView/ActorView 路径，固定 seed、1280×720、GL compatibility，以 `workload_schema=v2` 运行 300 帧预热与 3600 帧采样，覆盖 1/3/5 敌人及持续补足 15 枚真实结构弹丸的峰值场景。v2 禁用 PlayerController/ActorView 自动 process，并在 presentation 计时内显式固定 60Hz 推进，阻止 headless 未限速 delta 低估动画与纹理应用成本；同时登记逐帧 visual-step 和自动 process 违规门。该 workload 在 production 容器内注入 roster/弹丸维护，不覆盖完整 encounter bootstrap；四场景同进程但逐场景重置 simulation/view/log，只用于场景内增长门。headless 只产出 CPU/模拟/快照/呈现/生命周期基线；GPU、显存与玩家可见 FPS 必须由同一 runner 的 visible 工作流另行验收。

允许路径：

```text
docs/00_governance/I2_SLICE_GATE_LEDGER.md
docs/30_engineering/godot/I2_VALIDATION_PREVIEW_AND_MANUAL_REVIEW_PLAN.md
Godot/GraytailGodot/tests/i2_combat_frame_baseline_runner.gd             # new
tools/i1/validation_manifest.json
tools/i1/invoke_i1.ps1
tools/i1/validate_static.ps1
```

基线切片不得修改任何 production 脚本、scene/resource/project/assets/import/translation。首次门只阻断工作负载漂移、资源加载失败、纹理加载无法在最后十秒进入平台、12-step 饱和、持续内存增长与节点/资源未回收；预热后仍发生的 late load 必须如实登记为后续 I2.6 优化债，I2.6 完成门再收紧为预热后 `loads_delta == 0`。不得在取得同机同 executable 五次结果前伪造相对性能阈值。runner 纳入独立 `performance` profile 与 full，不纳入 quick；严格登记 cleanup contract。visible 模式每场景至少运行 60 秒，且不能用 dummy renderer 的 `TIME_FPS` 代替可见验收。

### 10.5 I2.6B combat actor 纹理生产预热

```text
status: READY_FOR_REVIEW (pre-authority admission with exact zero-late-load gate)
feedback: RUN-02(partial), ROOM-01(performance), CROSS-04, CROSS-05
rollback: ff66de2 (first runtime slice gates)
```

只读资产与 consumer 检查确认：当前生产可达的玩家动态帧为 36 张，slime/slimeling/bat/drone base 动态帧去重后为 35 张，合计 71 张；声明路径全部存在。源 PNG 合计约 1.681 MiB，按无 mipmap RGBA 解码约 6.393 MiB，允许在进入 Run 时一次性常驻预热；GPU/显存与启动体感仍由 visible 门复核。projectile 专用贴图、player interact、ironback 与 laser FX 不在本切片的生产 consumer 边界内，不得据此声称“整个 Run 零纹理加载”。

允许路径：

```text
docs/00_governance/I2_SLICE_GATE_LEDGER.md
docs/30_engineering/godot/I2_VALIDATION_PREVIEW_AND_MANUAL_REVIEW_PLAN.md
Godot/GraytailGodot/scripts/presentation/runtime_texture_cache.gd
Godot/GraytailGodot/scripts/presentation/art24/art24_runtime_animation_catalog.gd
Godot/GraytailGodot/scripts/presentation/art24/art24_enemy_visual_catalog.gd
Godot/GraytailGodot/scripts/core/run/run_scene.gd
Godot/GraytailGodot/tests/i2_combat_frame_baseline_runner.gd
```

`RuntimeTextureCache` 只提供 load-idempotent、按实际 cache 状态核对的 `prewarm(paths)` 机制，已缓存路径不得重复增加 request 指标；两个 catalog 各自声明生产路径；`RunScene` 是唯一组合 owner。新局路径必须先由 `_run_start_asset_admission()` 完成 71 张资源准入，再允许 `RunSceneRouteController` dispatch 权威启动命令；准入失败必须零 dispatch、保持 `run_active=false/phase=idle`、登记 degraded 状态并留在来源页。命令成功后 `_show_run_screen()` 只做同一集合的幂等复核与玩法层启用；当前主场景初始化会先消费 2 张隐藏玩家 idle 纹理，因此本门不声称“应用启动后零纹理加载”。不得把准入放进 simulation、ActorView spawn 或测试桩，也不得用 fallback 掩盖缺图。动态门固定为 `ok=true`、declared/cached=71、missing/failure/rejected=0；show-time 复核必须 `already_cached=71/loaded=0`，四个正式场景的 cache `loads_delta/failures_delta/entries_delta` 必须全部为 0。production 集成门还必须证明真实 `_start_run_from_route()` 留下成功 admission 报告后才进入 running/Run；正式 teardown 首次至少释放 64 个 Resource，随后再执行一次 build→Run→teardown，第二次 Node/Resource/orphan 不得高于第一次稳定缓存平台容差（Resource +8）。

## 11. 首批并行写入规则

- I2.1A、I2.1B foundation 与 I2.5A 的 allowed paths 互不重叠；任何代理发现需要越界必须停止并回报，不得自行扩大。
- `tools/i1/validation_manifest.json` 由主审在合并三组 runner 后统一登记，避免并行冲突；未登记前新增 runner 只能定向执行，不能声称统一 profile 已覆盖。
- 每组先交付 worktree diff、定向结果与未运行项；主审完成交叉 review、manifest 登记和 quick/ui/core/full 后才可把状态升级为 `READY_FOR_REVIEW`。
- 运行时实现开始后 I2 仍保持 `ACTIVE`；不得创建 validation/handoff 或提升 capability。

## 12. 首个运行时检查点复核记录（2026-07-22）

本检查点只把 I2.1A/B/C、I2.5A 与 I2.6A/B 提交到 review 边界；不关闭 I2，不创建 validation/handoff，不宣称 I2.2–I2.7 已完成。独立复核先发现并随后验证关闭了三项问题：settings runner 精确 marker 与 manifest 错配；combat 资源准入晚于权威提交；teardown Resource 门允许不回落。最终 production 路径满足：准入失败零 dispatch；真实 `_start_run_from_route()` 先留存 71/71 admission 再进入 running；show-time 71 项全命中、0 新加载；Resource 405→160，重复生命周期仍为 160，orphan=0；设置打开失败回到 Main 且不误发 Settings page commit。复核后无未关闭 P0/P1，production callsite 与治理文字两项 P2 也已补门。

```text
manifest SHA-256: F2E8DEAEB6ADF8821EE1848C720302BCC32D5F9297777A46A9C7DAC01983F980

quick/worktree: 28/28 PASS
report: E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T223439295Z_f16a3375\report.json
SHA-256: 0831418E9246DA870C0AE6FBB636ED76E2829995C76F644E8723B17850F66EBA

ui/worktree: 29/29 PASS
report: E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T223929897Z_3cfc50d5\report.json
SHA-256: D77A21695292F8E2362F4DCC1F39ED9AD4E9611E12A4ADD406A6D4BA77332AC2

core/worktree: 27/27 PASS
report: E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T222341804Z_58dbd4b3\report.json
SHA-256: 6231AA7D36430CFB80B5710EB1398C57F971D9CA4B5BC9EB9E363BA981139A09

performance/worktree: 1/1 PASS; workload_schema=v2
report: E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T222735091Z_3510c049\report.json
SHA-256: B22687D496BFAC6BA9741A8CC45C33CFCC902DC77FA1A7D810F17DE71C688BE4

git diff --check: PASS
protected scene/resource/project/uid/translation/import dirty in I2 worktree: NONE
full/worktree and exact full/head: NOT_RUN (reserved for I2.7 closeout)
visible GPU/input-feel acceptance: NOT_RUN
```

## 13. I2.2A 主菜单安全回退切片（2026-07-22）

```text
status: ACCEPTED_WITH_NOTES (safe fallback only; I2.2 remains IN_PROGRESS)
feedback: MAIN-01, MAIN-02(partial), MAIN-03, MAIN-04(partial), MAIN-05(no-regression), CROSS-01, CROSS-04, CROSS-05, CROSS-07, CROSS-08
rollback: c053293 (I2 runtime foundation checkpoint)
```

本切片把四个主菜单入口冻结为语义 profile：`enter_cave`、`descend`、`open_overlay`、`open_confirm`。`AppShell` 的 navigation transition coordinator 是路由编排 owner：prepare、play、commit、settle 每次只允许一个有效 token，重复请求拒绝、过期回调忽略，且 route/page commit 至多一次。`MainMenu` presenter 只生成画面 pose，不拥有页面、Run、设置或退出权威；transition profile 不进入 `NavigationIntent` 领域载荷。取消、准备失败、提交失败与页面隐藏都必须回到 Main 并恢复原入口焦点；运行中启用 `reduce_motion` 时吸附到可理解终态并仍由 coordinator 单次提交，不能由动画计时器直接改路由。

安全回退边界如下：

- Deploy 只使用角色 focus pose、cave glow 与暗渐变；没有完整步行动画，不能宣称“角色已经完整走入洞口”。ART21 的 4 帧 `walk_dungeon`/`walk_company` 继续保持 deferred，既不作为生产加载依赖，也不据此关闭 MAIN-04。
- Long Term 对全部非 overlay 场景根统一下移 48 个 logical px，并使用固定底色/暖渐变维持连续观感；当前没有可连续展示的完整下层空间或背景，不能宣称“已经实现完整下层场景”。
- Settings/Exit 分别使用 `open_overlay`/`open_confirm` 的短 pressed/dim 反馈；设置仍复用真实 `SettingsPanel`，失败不冒充进入 Settings。

布局契约矩阵覆盖 1280×720、1600×900、1920×1080 三个分辨率，三个文字 profile 与四个焦点状态，共 36 个 contract case；它锁定入口木牌、文字、命中区和焦点反馈共享语义锚点、文字最多两行且最小字号 18，但不冒充真实字体渲染或截图验收。公告栏改为单条标题 + 可换行正文，不再压入四条工程式小字。快捷键 F2 的“仓库”入口归属 Deploy，并通过 `tab=warehouse` 打开同页内容；不得把地图拆成 region→difficulty 流程。缺失的角色、旗帜、transition 或未知 key 使用精确 `null` fallback，不再误回退到整张主菜单背景；同一规则已同时落到 ART21 权威 builder 与生成产物，并由 parity runner 锁定。

独立复核发现并关闭了两项并发/生成源问题：busy coordinator 会拒绝 direct intent；公开 `show_*` 仅在成功取消未提交转场后才切页，`COMMITTING + commit_issued` 被拒绝取消时保持原 token、页面与生命周期。权威 route commit 只调用 private internal show path，不会自我取消。ART21 builder 不再再生整屏背景 fallback。复核后的剩余 P0/P1/P2 为零。

本切片只复用已审计并已登记的 ART21 主菜单输出；没有从 UE、外部 source pack 或未知许可来源导入素材，也没有生成新素材。生产截图位于 worktree 临时目录 `E:\AGAME1\.tmp\worktrees\i2\.tmp\i2-main-menu-captures`：已生成 1280×720、1600×900、1920×1080 默认态，以及 Deploy、Long Term、Settings、Exit 四个 1280×720 中间态并完成当前检查点目检。截图/定向 runner 只证明当前切片证据，不能代替统一 quick/ui/full 门，也不能冒充最终玩家手感验收。

允许路径：

```text
docs/00_governance/I2_SLICE_GATE_LEDGER.md
Godot/GraytailGodot/scripts/presentation/art21_main_menu_asset_contract.gd
Godot/GraytailGodot/scripts/ui/app_shell/app_shell.gd
Godot/GraytailGodot/scripts/ui/app_shell/navigation_transition_coordinator.gd
Godot/GraytailGodot/scripts/ui/main_menu/main_menu_layout_contract.gd
Godot/GraytailGodot/scripts/ui/main_menu/main_menu_model.gd
Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd
Godot/GraytailGodot/scripts/ui/main_menu/main_menu_transition_presenter.gd
Godot/GraytailGodot/tests/art21_main_menu_capture_runner.gd
Godot/GraytailGodot/tests/art21_main_menu_runtime_runner.gd
Godot/GraytailGodot/tests/art22_deploy_prep_main_route_runner.gd
Godot/GraytailGodot/tests/art23_long_term_main_route_runner.gd
Godot/GraytailGodot/tests/i2_main_menu_anchor_text_runner.gd
Godot/GraytailGodot/tests/i2_main_menu_transition_coordinator_runner.gd
Godot/GraytailGodot/tests/i2_main_menu_transition_fallback_runner.gd
Godot/GraytailGodot/tests/i2_settings_shell_wiring_runner.gd
tools/art21_build_main_menu_runtime.py
tools/i1/validation_manifest.json
```

保护边界：`project.godot`、全部 scene/resource/`.uid`/`.translation`/import metadata、PNG/音频/字体等素材本体、七个 `asset_manifest.*.translation`、RunStateMachine、RunAssetLedger、terminal settlement、SaveAdapter、经济/库存/地图 schema 与 I1 closed evidence 均禁止修改。UE 仍为只读视觉参考。本切片实际未修改 scene/resource/project/uid/translation/import 或任何素材本体。

定向与兼容门记录：

```text
I2_MAIN_MENU_TRANSITION_COORDINATOR: PASS; profiles=4; duplicate rejected; stale ignored; cancel/prepare_fail/commit_fail recovered; reduced_midflight profile-only; commit_once=true
I2_MAIN_MENU_ANCHOR_TEXT: PASS; contract_cases=36; resolutions=3; text_profiles=3; focus_states=4; entry_lines_max=2; entry_font_min=18
I2_MAIN_MENU_TRANSITION_FALLBACK: PASS; registered=3; missing_character/flag/transition/unknown=null; builder_fallback=null
ART21_MAIN_MENU_RUNTIME: PASS; entries=4; overlays=2; transitions=4; shortcuts=2; motion_groups=10
ART22_DEPLOY_PREP_MAIN_ROUTE: PASS; route=main_menu_to_deploy
ART23_LONG_TERM_MAIN_ROUTE: PASS; route=main_menu_to_long_term
I2_SETTINGS_SHELL_WIRING: PASS; production panel; rollback complete; busy direct rejected; external show cancel-gated; commit-in-flight reentry blocked
I2_ROUTE_AUTHORITY_LIFECYCLE: PASS; command failure no route; duplicate deduplicated; hidden pages paused; active run canonical locked
capture matrix/manual checkpoint review: PASS_WITH_VISUAL_REVIEW_REQUIRED
quick/worktree: 31/31 PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T234455058Z_43021d2c\report.json; SHA-256=E9D57CAF4193D19FF1A3B9D9B09C3A803AF3E6F30A6F0F7AEF4ECBF3E2BC0DF7
ui/worktree: 32/32 PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T234917077Z_70a01046\report.json; SHA-256=3CAAEAEC4D040FD9687536001E4D96DD4A0456270D07FB71E97D40E6EC902CE2
manifest SHA-256: D0712E9421C877B84A3C3111E4F5089C13287FA875575CE26ABFBCCEBEBF2603; static=PASS; pollution_guard=PASS
full/worktree and exact full/head: NOT_RUN
player input-feel acceptance: NOT_RUN
```

I2.2A 已通过定向、兼容、统一 quick/ui、独立复核与三分辨率截图检查点，因此只以安全回退范围 `ACCEPTED_WITH_NOTES`。full/head 仍保留到 I2.7；完整洞口步行动画、连续下层空间与玩家手感复核继续留在 I2.2 后续 gate，不能据此关闭整个 I2.2。

## 14. I2.3A Deploy 同页双栏与精确投影门（2026-07-22）

```text
status: ACCEPTED_WITH_NOTES (engineering checkpoint inside I2.3; not a separate product stage)
feedback: DEPLOY-01..DEPLOY-10, MAIN-04(route continuity), CROSS-01, CROSS-04, CROSS-05, CROSS-07, CROSS-08
rollback: 152873d (I2.2A accepted-with-notes checkpoint)
```

代码优先核查确认当前 Deploy 已接通真实金币、八地图、仓库实例、申领、委托、携带配置、开始/继续/放弃流程，缺口是工程配置器式信息架构，而不是缺少第二套 schema。本门授权把中央区重排为同页“左侧选择 + 右侧详情/显式动作”，右上金币常驻；一级页签玩家文案为地图、仓库、申领、本局委托、携带清单。选择行只改变查看焦点，地图/委托/携带等 draft 修改必须走显式动作；购买/出售只产生已有 meta action，不在 UI 预扣金币或推断成功。

地图硬约束：八个既有 `map_config_id` 保持精确往返，三种显示规模为 7×7、10×10、13×13，右侧显示该规模真实难度与详情。`region_id` 仅为上下文，禁止新增 region 页面、region→difficulty 步骤、route、存档层级或 `RunStartConfig` 权威字段。未知 ID 必须 fail closed，不得再借 catalog 的历史默认回退伪装成 10×10 标准；active run 使用 canonical config 并锁定修改。

摘要固定为概览、配置、效果、目标：删除“当前选择”“路线 / 难度”“运行状态”等工程说明；配置列具体物品名，效果只列真实附加效果，目标列所选本局委托。`risk_summary` 可保留为兼容字段，但不再作为玩家顶层页签。金币缺失显示“—”，不得伪装为 0。品质必须使用文字 + 色/边框冗余表达，不能只依赖颜色。

本门不授权批量/快捷售卖、UI 层循环出售、未知许可素材导入、生成新素材、运行时骨骼系统、成就/等级任务迁入 Deploy 或经济/存档权威改写。现有审计资产足以完成该门；UE 仅参考信息层级、金币常驻、品质与显式动作，不复制旧分页或 `.uasset`。

允许路径：

```text
docs/00_governance/I2_SLICE_GATE_LEDGER.md
Godot/GraytailGodot/scripts/core/content/m7_content_catalog.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_map_projection.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_map_split_view.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_card_view.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_layout_contract.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_tab_model.gd
Godot/GraytailGodot/tests/art22_deploy_prep_capture_runner.gd
Godot/GraytailGodot/tests/art22_deploy_prep_main_route_runner.gd
Godot/GraytailGodot/tests/art22_deploy_prep_matrix_capture_runner.gd
Godot/GraytailGodot/tests/art22_deploy_prep_runtime_runner.gd
Godot/GraytailGodot/tests/i2_deploy_map_projection_runner.gd
Godot/GraytailGodot/tests/i2_route_authority_lifecycle_runner.gd
Godot/GraytailGodot/tests/m7_meta_ui_runtime_runner.gd
tools/godot_g39_navigation_boundary_runner.gd
tools/i1/validation_manifest.json
```

保护边界：`project.godot`、scene/resource/`.uid`/`.translation`/import、全部素材本体与 asset manifest、MetaProgressAdapter、SaveAdapter、RunStateMachine、RunAssetLedger、terminal settlement、八地图 ID/schema 和 active-run canonical authority 均禁止修改。本门完成要求包括八地图/三规模 exact runner、单页/无 region route 断言、选择与破坏性动作分离、摘要禁词与具体内容、焦点/ESC/reduced-motion、三分辨率截图检查点、quick/ui；full/head 仍留到 I2.7。

### 14.1 I2.3A 复核与接受记录

I2.3A 已把地图保留在同一 Deploy 页：左侧只显示常规扫雷的 7×7、10×10、13×13 三种规模，右侧分别投影 2/3/3 个真实难度并以 exact `map_config_id` 提交。catalog 新增 exact 查询而保留历史 fallback；选择、合法性、active-run 锁和 route round-trip 均 fail closed。非地图页使用左侧选择、右侧详情/明确动作；行点击不再改变配置或发出 meta action。仓库重复物品按 exact `instance_id` 显示和操作；本地动作后左右投影同步重建。单件出售采用可见“确认出售”，切行、筛选或页签会取消待确认态，确认提交仍只携带单一实例。申领、本局委托、携带清单、金币缺失态、品质文字+颜色边及概览/配置/效果/目标摘要均已接入，未新增素材或运行时权威。Deploy 放弃确认接入共享 modal focus lifecycle，ESC echo、焦点环与 reduced-motion 稳定态均 fail closed。

验证记录：

```text
I2_DEPLOY_MAP_PROJECTION=PASS maps=8 scales=3 round_trip=8 route_pages=1 fallback=fail_closed
ART22_DEPLOY_PREP_RUNTIME=PASS tabs=5 map_page=single map_scales=3 map_difficulties=2,3,3 exact_maps=8 split=selection_detail explicit_actions=local,meta summary=overview,config,effect,objective card_height=76 active_run=locked input=focus,escape,reduced_motion
ART22_DEPLOY_PREP_MAIN_ROUTE=PASS host=main.tscn route=main_menu_to_deploy commit=once map_page=single scales=3
static/worktree: PASS; manifest sha256 5B68E79B65976CCC9F331A19D137F0B5E6724523FB1359F02EF525630A070A9A
quick/worktree: 32/32 PASS; registration complete; pollution PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T011703418Z_8292ac71\report.json; report sha256 8B6A44EAAC8C4F4D2E8F9B26A8357C28AEA03D7DA9F35FEB9362072EB536201F
ui/worktree: 33/33 PASS; registration complete; pollution PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T011114418Z_5b5467b3\report.json; report sha256 A965A4D1ED691262E4A77581EDB4DF25C18AB4CA31B3FC9F78F2AD919CE015F6
visible checkpoint: final-code map + claim at 1280x720, 1600x900, 1920x1080 in .tmp/i2-deploy-captures/final; manually reviewed for clipping, overlap and light-surface text contrast
independent reviews: exact/domain, split-view, duplicate-instance, left/right projection, explicit confirmation, focus/ESC/reduced-motion findings resolved; final P0/P1/P2 none
```

接受边界：本记录只接受 I2.3A，不关闭 I2.3 或 I2。真实 purchase/sell 结果关联、失败回执与刷新证明进入 I2.3B；无原子命令、幂等、确认和回滚前继续禁止批量售卖。截图仅为人工布局检查点，不构成自动玩家手感 PASS；full/worktree、commit 后 full/head 与最终 capability promotion 仍留到 I2.7。

## 15. I2.3B Deploy 单件经济事务闭环门（2026-07-22）

```text
status: ACCEPTED_WITH_NOTES (single-item economy closure; I2 remains active)
feedback: DEPLOY-04, DEPLOY-05, DEPLOY-08, CROSS-04, CROSS-07
rollback: 44c1907 (I2.3A accepted checkpoint)
```

代码优先审计确认购买/出售的真实权威已存在于 `MetaProgressAdapter`，保存失败也已有内存回滚；当前缺口是 Deploy 的同步调用时序会覆盖真实结果，且没有请求/结果关联或同请求去重。本门只为现有单件 `purchase` / `sell_collectible` 建立会话内事务 envelope：UI 在发出前进入 pending，运行时按 `request_id + normalized payload` 去重并执行一次，AppShell 把匹配结果返回来源页，Deploy 只消费自己的匹配结果并从真实快照刷新余额与库存。价格与售价继续由 catalog/adapter 决定，UI payload 不得成为经济权威。

允许路径：

```text
docs/00_governance/I2_SLICE_GATE_LEDGER.md
Godot/GraytailGodot/scripts/core/run/run_runtime_controller.gd
Godot/GraytailGodot/scripts/core/run/run_scene.gd
Godot/GraytailGodot/scripts/ui/app_shell/app_shell.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd
Godot/GraytailGodot/tests/i2_deploy_meta_action_transaction_runner.gd
Godot/GraytailGodot/tests/art22_deploy_prep_runtime_runner.gd
Godot/GraytailGodot/tests/art22_deploy_prep_main_route_runner.gd
Godot/GraytailGodot/tests/m7_meta_ui_runtime_runner.gd
tools/i1/validation_manifest.json
```

保护边界：`MetaProgressAdapter`、`SaveAdapter`/save schema、`RunStateMachine`、`RunAssetLedger`、terminal settlement、地图/content schema、scene/resource/素材/import/translation 均禁止修改；不持久化 request ID，不引入网络或异步队列，不新增 `instance_ids`、循环出售或批量出售入口。

审计中确认仅有控制器、页面与真实适配器的分层测试不足以证明同步生产链的 signal bind、快照先刷新和结果后回送顺序，因此本门补充允许既有 `art22_deploy_prep_main_route_runner.gd`，只用于 `Main/RunScene/AppShell/Deploy/MetaProgressAdapter` 的购买与出售整链断言；不扩大任何 production 写入边界。

### 15.1 I2.3B 复核与接受记录

单件购买与出售现在统一由 `RunRuntimeController.execute_meta_action()` 包装现有 `MetaProgressAdapter` 权威：请求以 `request_id + normalized payload` 在同一 controller/adapter 会话完整去重，同 ID 同 payload 返回不可变缓存副本，同 ID 异 payload 以 `request_id_conflict` fail closed；切换适配器才清空会话缓存。UI 不计算价格、售价或成功结果。Deploy 在同步 emit 前建立 pending，阻止重复提交，只消费 request/source/action/target 全部匹配的结果；RunScene 先应用真实 meta 快照，再把事务 envelope 回送来源页。AppShell 的只读 delivery trace 记录结果交付时的全局与页面 snapshot revision，生产整链测试要求每笔交易恰好刷新一次且结果交付 revision 与刷新后 revision 相同，从而阻断调用顺序回退。

真实适配器回归证明：购买按 catalog 精确扣款且只增加一个真实实例；出售只删除 exact `instance_id` 并按 `base_value` 精确加款；锁定购买、配置中物品出售等失败前后 gold/warehouse 完整不变；同请求不二次写入；购买与出售刷新后地图、本局委托、装备及消耗品草稿保持。玩家页显示购买成功、真实出售获币及已登记失败文案。批量/循环出售、持久化 request ID、网络/异步队列与经济 schema 修改仍不在本门授权内。

验证记录：

```text
I2_DEPLOY_META_ACTION_TRANSACTION=PASS actions=5 duplicate=cached conflict=fail_closed cache=session authority=adapter
M7_META_UI_RUNTIME:PASS long_term=PASS deploy_refresh=PASS sale_confirm=PASS meta_transactions=PASS map_fact=PASS
ART22_DEPLOY_PREP_RUNTIME=PASS tabs=5 map_page=single map_scales=3 map_difficulties=2,3,3 exact_maps=8 split=selection_detail explicit_actions=local,meta summary=overview,config,effect,objective card_height=76 active_run=locked input=focus,escape,reduced_motion
ART22_DEPLOY_PREP_MAIN_ROUTE=PASS host=main.tscn route=main_menu_to_deploy commit=once map_page=single scales=3 meta=purchase,sell
I1_SAVE_RELIABILITY=PASS atomic_replace=PASS backup_recovery=PASS future_schema=PASS
quick/worktree: 33/33 PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T015916488Z_9abf1c12\report.json; SHA-256=879914C4B1A777F7284BB6CDDB1F28343CE9D4FF244EC44AE7B0C5F818704939
ui/worktree: 34/34 PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T015916486Z_414e3e9e\report.json; SHA-256=8054E52DF7B54DEE4C04413BE936C87422BAAE8CF1D82976BB755B188B6BE129
manifest SHA-256: 7CB171162F5862BE017520472B0224266904EE3DDC9A0976F50ED325E4633ACB; pollution_guard=PASS
independent final review: P0=0, P1=0, P2=2 (non-blocking: 1280 Codex secondary-tab overflow lacks an explicit mouse hint; paired Research/Collection pages still share honest source records and differ mainly by page semantics)
full/worktree and exact full/head: NOT_RUN (reserved for I2.7 closeout)
player input-feel acceptance: NOT_RUN (I2.7 integrated manual route)
```

接受边界：本记录关闭 I2.3 的已授权单件经济与信息架构范围，不关闭 I2；批量出售仍需独立原子事务、确认、幂等、失败回滚和产品规则后才能进入。动态鼠标/手柄手感、生产长时间交互与跨页面综合说明继续由 I2.7 验收。

停止条件：购买成功必须精确扣款并只新增一个真实实例；出售成功必须只删除指定实例并精确加款；失败前后余额/库存不变；同 ID 同 payload 返回缓存结果且不得二次写入，同 ID 异 payload fail closed，不同 ID 的同类购买仍允许。pending 必须先于同步 emit 建立，pending 时禁止重复提交；只有匹配结果能清除 pending，陈旧/未知/其他页面结果必须忽略。`insufficient_gold`、`locked`、`write_blocked`、`save_failed`、`configured_item_blocked`、`instance_not_found`、`item_not_sellable` 均需玩家文案。若需要改写 MetaProgress/Save schema、根据快照差值猜测结果、或无法证明保存失败不改变经济状态，立即停止本门。

## 16. I2.4A 任务档案责任迁移与红点可靠性门（2026-07-22）

```text
status: ACCEPTED_WITH_NOTES (task archive migration only; talent authority remains blocked)
feedback: LONG-01, LONG-02, LONG-03, LONG-04, CROSS-01, CROSS-04, CROSS-05, CROSS-07, CROSS-08
rollback: 6cd923d (I2.3B accepted checkpoint)
```

代码优先审计确认任务、成就、领取状态、红点和委托历史已经由现有 M7 progression/save 数据提供真实权威，缺口是长期页仍以旧 `goals` 命名并混入工程预览文案；委托投影还只返回最近七条记录。该数据足以迁移为玩家语义上的“任务档案”，无需新增任务 schema 或重算进度。本门以 `task_archive` 为 canonical module ID，将历史 `goals`、`tasks` 与通用 `overview` 路由规范化为同一入口；二级页固定为任务、成就、委托记录。旧 ID 只保留为输入兼容，不作为新的显示或存档权威。

任务档案查看不得清除 `claimable_rewards`；任务/成就领取继续只走现有 `claim_goal_reward` 权威，卡片选择不触发领域动作。委托记录必须投影当前存档中全部保留记录并由现有分页浏览，不得静默截断为最近七条。`mark_long_term_viewed` 仍只处理 codex/history/collection；若保存失败，已读数组与派生红点必须回滚到调用前状态，不得让 UI 快照冒充已保存成功。

现有 ART23/ART25 已审计素材足以完成本门：`task_archive` 显式复用既有 `goals` 模块按钮、家具与任务/成就/委托卡面运行时键。不得修改素材、manifest、import metadata 或生成新图。尚无点数来源、花费、依赖、等级、重置/返还规则的天赋树继续保持阻塞；尚无概率/消耗/保底权威的抽奖不进入生产一级导航，也不得以禁用按钮冒充玩家模块。

允许路径：

```text
docs/00_governance/I2_SLICE_GATE_LEDGER.md
Godot/GraytailGodot/scripts/core/save/meta_progress_adapter.gd
Godot/GraytailGodot/scripts/presentation/art23_long_term_asset_contract.gd
Godot/GraytailGodot/scripts/presentation/art25_content_asset_contract.gd
Godot/GraytailGodot/scripts/ui/app_shell/app_shell.gd
Godot/GraytailGodot/scripts/ui/app_shell/navigation_intent.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_content_framework.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_content_slot_model.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_layout_contract.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_model.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_snapshot.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_tab_model.gd
Godot/GraytailGodot/tests/art23_long_term_main_route_runner.gd
Godot/GraytailGodot/tests/art23_long_term_capture_runner.gd
Godot/GraytailGodot/tests/art23_long_term_matrix_capture_runner.gd
Godot/GraytailGodot/tests/art23_long_term_runtime_runner.gd
Godot/GraytailGodot/tests/i1_save_reliability_runner.gd
Godot/GraytailGodot/tests/i1_refresh_scope_runner.gd
Godot/GraytailGodot/tests/i2_long_term_task_archive_runner.gd
Godot/GraytailGodot/tests/i2_route_authority_lifecycle_runner.gd
Godot/GraytailGodot/tests/i2_settings_shell_wiring_runner.gd
Godot/GraytailGodot/tests/m7_meta_ui_runtime_runner.gd
tools/i1/validation_manifest.json
```

保护边界：`project.godot`、scene/resource/`.uid`/`.translation`/import、全部素材本体与 asset manifest、SaveAdapter/save schema 与既有字段、M7 task/achievement 定义和 ID、任务判定/奖励数值/领取规则、RunStateMachine、RunAssetLedger、terminal settlement、经济权威与天赋字段/规则均禁止修改。本门不得新增任务、奖励、货币、天赋节点、点数来源、抽奖能力或批量领域动作。

完成证据必须覆盖：canonical/alias 路由往返；生产主场景从主菜单和 Deploy 进入任务档案；任务/成就定义、状态、已领取与已发放记录迁移前后精确相等；claimable 红点查看后不变；成功领取仍恰好一次；已读保存失败时原数据与红点精确回滚；全部保留委托记录可分页到达；抽奖不在生产一级导航；ART23/ART25 复用解析；focus/ESC/reduced-motion；static、定向、quick/ui 与三分辨率截图检查点。full/worktree 与 exact full/head 仍由 I2.7 统一执行。

停止条件：旧 `goals`/`tasks` 不能无损归一化；任务/成就 ID、状态、claimed/granted、claimable 红点或委托记录发生差异；查看任务档案清除待领取奖励；保存失败后内存已读/红点仍被修改；需要改写 schema、任务/奖励权威或素材 manifest；把预览天赋/抽奖声明为可玩。任一条件出现即回退到 `6cd923d` 并将本门标记 `BLOCKED`。

### 16.1 I2.4A 复核与接受记录

生产长期页现以 `task_archive` 为唯一正式入口，主菜单、Deploy、AppShell 与 G39 导航边界均输出 canonical payload；历史 `goals`、`tasks` 和通用 `overview` 在导航、模型、framework、slot 与 shell 边界无损归一。一级导航只保留任务档案、图鉴、研究、角色与收藏外观五个已有权威模块，未显示无概率/消耗权威的抽奖，也未伪造天赋树。

任务/成就 definitions、states、claimed/granted 和 claimable 红点均只读投影；打开任务档案显式禁止发出 `mark_viewed`，领取仍只走既有 `claim_goal` 事务。委托记录由“最近七条”改为投影存档中全部保留记录，并由现有三卡分页完整到达。`MetaProgressAdapter.mark_long_term_viewed()` 在真实保存失败时恢复完整 `data` 与派生红点，返回 summary 也反映回滚态。ART23 的 `task_archive` 家具/按钮和 ART25 卡片显式映射到既有 `goals` 审计资产；未修改或生成素材、manifest、import metadata。

首轮 quick 暴露 G39 仍期待旧 payload，修正为 canonical 断言并纳入 allowed path；独立复核随后发现 `overview` 只在导航层归一、模型能力标记与 slot 不一致，补齐五层 alias 后最终审查为 P0/P1/P2=0。三分辨率代表图及 1280×720 的 24 页完整矩阵均使用最终代码生成；人工检查未见阻塞性裁切/遮挡，但中央内容区偏小、五模块仍过度共享三卡模板，明确进入 I2.4B，不能据此关闭 I2.4。

验证记录：

```text
I2_LONG_TERM_TASK_ARCHIVE=PASS canonical=task_archive aliases=goals,tasks,overview modules=5 commission_records=12 pages=4 authority=read_only
I1_SAVE_RELIABILITY=PASS atomic_replace=PASS backup_recovery=PASS future_schema=PASS long_term_view_rollback=PASS
ART23_LONG_TERM_RUNTIME=PASS primary_modules=5 secondary_pages=24 canonical=task_archive character_frames=8 states=OPEN,CLOSED,OPENING,CLOSING,SWITCHING
ART23_LONG_TERM_MAIN_ROUTE=PASS host=main.tscn route=main_menu_to_long_term shell=LongTermShell modules=5 canonical=task_archive
G39_NAVIGATION_BOUNDARY=PASS
static/worktree: PASS; manifest SHA-256=22E5EACD66EFEB282B498635012B1EA486508F0F845FF846DABA65BB18E64638
quick/worktree: 34/34 PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T023552379Z_41bf8877\report.json; SHA-256=E8CA8C1778536088F5ABD11E1D402497B3CF448819880873FB2676B59A283E1B
ui/worktree: 35/35 PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T024030731Z_371b26b7\report.json; SHA-256=94858C14AABDCB18FDC8281A1905FE59AA49FED9C51C094DC97FB59150015B26
visible captures: task_archive/task at 1280x720, 1600x900, 1920x1080 plus 24-state 1280x720 matrix; output=.tmp/i2-longterm-captures/i2_4a; manual blocking layout findings=0
independent final review: P0=0, P1=0, P2=0
full/worktree and exact full/head: NOT_RUN (reserved for I2.7 closeout)
player input-feel acceptance: NOT_RUN (I2.4B/I2.7 production route)
```

接受边界：本记录仅接受任务档案责任迁移、红点/已读可靠性和生产入口清理，不关闭 I2.4 或 I2。模块专用信息布局、角色档案与可替换角色表现进入 I2.4B；天赋点来源、成本、依赖、等级、重置/返还和六节点效果权威仍缺产品规则，因此继续显式阻塞，不以空树、禁用按钮或历史 UE/Lua 价格冒充完成。

## 17. I2.4B 模块专用工作区与局外角色表现端口（2026-07-22）

```text
status: ACCEPTED_WITH_NOTES (I2.4 authorised workspace/presentation scope; talent authority remains blocked; I2 remains active)
feedback: LONG-01, LONG-02, LONG-04, CROSS-01, CROSS-04, CROSS-05, CROSS-07, CROSS-08
rollback: 6b06f25 (I2.4A accepted checkpoint)
```

代码优先检查确认五个正式模块均已有足够的真实只读数据或既有显式事务：任务档案具有任务、成就、委托记录及领取；图鉴具有分类、发现态和未知态；研究具有链路、前置、金币/材料、效果、阻塞原因及确认；角色档案具有等级阈值、真实统计、称号徽章与完整局次记录；收藏外观具有收集进度、图册与详情。当前问题是这些数据仍被压进同一组三卡工程模板，中央工作区过小、真实记录被分页和占位卡稀释、详情不足，而不是缺少第二套领域 schema。

本门把中央区改为模块专用语义的“可滚动真实记录列表 + 同步详情/事实 + 既有显式动作”工作区。生产 UI 不得为了填满版面补“预留档案位”“暂无更多记录”等假卡；零数据只允许一个与当前模块相符的诚实空态，任意数量真实记录均须可达。卡片选择、悬停和焦点只改变只读详情，领取与研究确认继续走既有显式事务，禁止显示选择直接提交。角色档案要展示已有等级、统计、称号、徽章和完整历史，不得把当前没有的可装备外观、多角色队伍或战斗属性伪装成可操作能力；右侧“设置外观”改为诚实的收藏档案入口。

同时建立局外角色表现端口：以 `actor_id + appearance_id + clip_id` 描述表现，默认只解析现有 ART21 角色帧；Main Menu、Deploy、Long Term 共享同一目录和帧序列解析，不再假设八帧、固定前缀或固定路径。缺少角色、外观、动作或单帧时必须稳定回退到已审计默认表现并保持导航可用；测试夹具需证明可变帧数、不同序列和缺失 clip 均可处理。该端口是后续素材替换的接缝，不新增皮肤持有/装备权威，不触碰 ART24 局内角色，也不引入运行时骨骼系统。

现有 ART21、ART23、ART25 审计素材足够完成本门，不生成、不导入且不修改任何素材或 manifest。天赋树和抽奖继续阻塞；appearance 仅是表现描述符与默认值，不进入 save/meta schema，也不能在玩家文案中声明“已拥有/已装备”。

允许路径：

```text
docs/00_governance/I2_SLICE_GATE_LEDGER.md
Godot/GraytailGodot/scripts/presentation/character/character_presentation_catalog.gd
Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_content_card_view.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_content_framework.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_layout_contract.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_model.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_module_projection.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd
Godot/GraytailGodot/scripts/ui/long_term/long_term_tab_model.gd
Godot/GraytailGodot/tests/art21_main_menu_runtime_runner.gd
Godot/GraytailGodot/tests/art22_deploy_prep_runtime_runner.gd
Godot/GraytailGodot/tests/art23_long_term_capture_runner.gd
Godot/GraytailGodot/tests/art23_long_term_main_route_runner.gd
Godot/GraytailGodot/tests/art23_long_term_matrix_capture_runner.gd
Godot/GraytailGodot/tests/art23_long_term_runtime_runner.gd
Godot/GraytailGodot/tests/m7_meta_ui_runtime_runner.gd
Godot/GraytailGodot/tests/i2_character_presentation_swap_runner.gd
Godot/GraytailGodot/tests/i2_long_term_module_workspace_runner.gd
tools/i1/validation_manifest.json
```

保护边界：`project.godot`、全部 scene/resource/`.uid`/`.translation`/import metadata、素材本体与 asset manifest、SaveAdapter/MetaProgressAdapter、save/meta schema、任务/研究/收藏/经济权威、RunStateMachine、RunAssetLedger、terminal settlement、ART24 局内角色、导航/路由权威及历史验收证据均禁止修改。本门不得新增真实角色、皮肤、装备动作、天赋、抽奖、奖励、货币、研究规则或批量领域动作。

完成证据必须覆盖：五模块二十四个二级页均可达；0/1/多条及至少 50 条历史记录不截断且无假占位；模块标题、摘要、事实、空态与动作均取自真实投影；任务领取和研究确认各恰好一次；显示选择零领域动作；长期系统显式事务须在同步 emit 前进入 pending，只接受 request/source/action/target 全部匹配的结果，陈旧或未知结果不得清除 pending，失败结果必须恢复动作并显示玩家文案，自动已读请求也须具有可关联回执；Main Menu/Deploy/Long Term 共用角色表现端口；三帧等可变帧夹具、缺失 clip/帧/角色回退；键鼠/手柄焦点（包括从后续可操作记录进入动作按钮）、ESC、收起/展开、reduced-motion；1280×720、1600×900、1920×1080 三分辨率生产截图矩阵；static、定向、quick/ui 与独立复核。full/worktree 与 exact full/head 仍由 I2.7 统一执行。

停止条件：真实数据需要改 schema 才能投影；列表仍静默截断或补假卡；显示选择发出领取/研究/装备等动作；appearance 被写入存档或冒充已装备皮肤；角色表现仍依赖固定八帧/路径；缺失素材导致导航中断；需要修改素材、manifest、ART24 或领域权威；将天赋/抽奖/多角色声明为完成。任一条件出现即回退到 `6b06f25` 并将本门标记 `BLOCKED`。

### 17.1 I2.4B 复核与接受记录

五个正式模块的二十四个二级页现统一使用“可滚动真实记录列表 + 同步详情/事实 + 显式动作”工作区，但各页标题、摘要、事实与空态由模块语义投影决定，不再补三卡工程占位或截断真实记录。零条数据只生成一个诚实空态；任务、成就、研究、图鉴、收藏、资历统计与完整五十条历史均可到达，选择、悬停和焦点不会提交领域动作。旧 M7 的三卡分页测试已迁移为完整滚动列表契约。

领取与研究的页面事务现在均在同步 signal emit 前生成 `long_term:*` request 并进入全局前台 pending；结果只在 request/source/action/target 四项全部匹配时消费。陈旧、错目标、重复与未知结果不会清除 pending，失败结果恢复动作并显示玩家文案；图鉴/历史/收藏的自动已读请求使用互不覆盖的后台关联集合。生产主路由测试通过真实 `Main -> RunScene -> AppShell -> LongTermShell -> MetaProgressAdapter` 领取链证明：权威快照先刷新、结果后回投、delivery revision 相同且奖励只发放一次。快照刷新同时更新一级模块红点，未知图鉴不再泄露内部 ID 或真实彩色图标。

Main Menu、Deploy 与 Long Term 已共同消费 `actor_id + appearance_id + clip_id` 表现端口；默认仍只解析已审计 ART21 帧。三帧夹具、非固定序列、缺失角色/外观/clip/单帧均稳定回退，且第一语义帧不会因缺图压缩而错位。该端口只负责展示，不写入外观拥有/装备存档，也不触碰 ART24 局内角色或领域状态。右侧入口只打开收藏档案；当前不存在的外观装备能力、天赋树、抽奖和多角色均未伪装为可用功能。

验证记录：

```text
I2_CHARACTER_PRESENTATION_SWAP=PASS default=graytail/base_art21/idle fixture_frames=3 sequence_steps=5 fallbacks=actor,appearance,clip missing_frame=bounded authority=presentation_only
I2_LONG_TERM_MODULE_WORKSPACE=PASS pages=24 records=0,1,many,50 selection_actions=0 explicit_actions=once
I2_LONG_TERM_TASK_ARCHIVE=PASS canonical=task_archive aliases=goals,tasks,overview modules=5 commission_records=12 pages=4 authority=read_only
M7_META_UI_RUNTIME:PASS long_term=PASS deploy_refresh=PASS sale_confirm=PASS meta_transactions=PASS map_fact=PASS
ART21_MAIN_MENU_RUNTIME=PASS
ART22_DEPLOY_PREP_RUNTIME=PASS
ART23_LONG_TERM_RUNTIME=PASS primary_modules=5 secondary_pages=24 canonical=task_archive workspace=scrollable states=OPEN,CLOSED,OPENING,CLOSING,SWITCHING
ART23_LONG_TERM_MAIN_ROUTE=PASS host=main.tscn route=main_menu_to_long_term shell=LongTermShell modules=5 canonical=task_archive
static/worktree: PASS; required/full/runners=55; manifest SHA-256=296BB04D8D9A64301766496626FC7D02006E95702A4C277A1B74BB69573D2220
quick/worktree: 36/36 PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T033342881Z_d259a943\report.json; SHA-256=A23AFE11CCB2E662274F5A016704606067B23B4BD461144DBFEEC90AF841F082; pollution_guard=PASS
ui/worktree: 37/37 PASS; report=E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T033342904Z_b86a9ca4\report.json; SHA-256=1699A778A64D8735CC715D4C825E8E0ACEF8A1BAC499339A829440E8817B0CC5; pollution_guard=PASS
visible captures: 24 pages x 1280x720,1600x900,1920x1080 = 72 PNG; output=.tmp/i2-4b-final-matrix; manual blocking layout findings=0
independent final review: P0=0, P1=0, P2=0
full/worktree and exact full/head: NOT_RUN (reserved for I2.7 closeout)
player input-feel acceptance: NOT_RUN (I2.7 integrated manual route)
```

接受边界：本记录关闭 I2.4 已授权的任务档案迁移、模块工作区与局外角色表现端口范围，不关闭 I2。1280 分辨率下图鉴八个二级页签虽可由焦点自动滚动到达，但鼠标侧尚无“左右仍有内容”的显式提示；研究的两个二级页与收藏的部分二级页继续复用同一组真实权威记录，差异主要体现在页面语义与摘要。这两项登记为非阻塞 P2，不以伪造新 schema 消除。天赋树仍缺少点数来源、成本、依赖、等级、重置/返还和节点效果权威，继续显式阻塞；外观持有/装备、多角色、抽奖和运行时骨骼也未进入本门。局内世界对象、HUD、弹窗、战斗房、特殊房型、终局结果与综合输入手感继续由 I2.5、I2.6、I2.7 处理。
