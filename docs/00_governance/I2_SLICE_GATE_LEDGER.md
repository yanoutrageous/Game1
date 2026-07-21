# I2 Slice Gate Ledger

文档状态：I2 当前门账；阶段 `ACTIVE`，所有运行时切片均未开始。
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
I2 runtime implementation: AUTHORIZED_BY_SUBSLICE_GATE / NOT_STARTED / NOT_CLAIMED
I2 capability promotion: NONE
I2 final validation/handoff: NOT_CREATED
entry HEAD: b77132b9de655b36f71c930a35a191c383b55522
entry full/head: 39/39 PASS
```

| Slice | 范围 | 依赖 | 当前状态 | 当前证据/下一门 |
| --- | --- | --- | --- | --- |
| I2.0 | 启动审计、契约、评估、矩阵、架构、验证计划、门账、入口 | I1 closed + exact entry baseline | `ACCEPTED_WITH_NOTES` | 独立复核修正 I1/I2 报告字段后，16/16 allowed paths、43/43 IDs、refs/UTF-8/YAML basic/diff/static 与 quick 21/21 PASS；无 runtime claim |
| I2.1 | 共享导航/转场、设置、focus/modal、character presentation、style/layer seam | I2.0；设置字段与动画技术决策 | `READY` | I2.1A 状态/生命周期与 I2.1B 设置/输入基础已冻结精确路径；跨文件集成仍需后续 gate |
| I2.2 | 主菜单文字/场景/锚点/动效/空间转场 | I2.1 最小 seam | `NOT_STARTED` | 需四入口动态标准、素材复用清单、回退到现有 fade |
| I2.3 | Deploy 双栏、地图同页、仓库/申领/委托/摘要 | I2.1；经济/taxonomy/loadout 决策 | `NOT_STARTED` | 需八地图 ID no-regression、真实命令与批量售卖门 |
| I2.4 | 长期模块重排、任务档案迁移、天赋、角色档案 | I2.1；taxonomy 与天赋数据权威 | `NOT_STARTED` | 先证明任务/成就/红点/领取不丢失，再改 Goal 入口 |
| I2.5 | 局内 HUD、地图、背包、箱/门/掉落、协议、Esc/modal | I2.1；对象/ledger/map characterization | `AUDIT_REQUIRED` | 仅独立的 I2.5A 既有结果框/协议色板/物品 binding 治理为 `READY`；其余局内职责未授权 |
| I2.6 | 战斗/特殊房、结算解释、真实工作负载性能 | I2.5 基础；性能 baseline/阈值 | `NOT_STARTED` | 需 deterministic、结算幂等、1/3/5 敌人 PERF 与失败路径 |
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
status: READY
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
status: READY (foundation only; AppShell/Run integration not yet authorized)
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

### 10.3 I2.5A 既有视觉资产接线与物品绑定治理

```text
status: READY (isolated presentation/asset-governance slice only)
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

## 11. 首批并行写入规则

- I2.1A、I2.1B foundation 与 I2.5A 的 allowed paths 互不重叠；任何代理发现需要越界必须停止并回报，不得自行扩大。
- `tools/i1/validation_manifest.json` 由主审在合并三组 runner 后统一登记，避免并行冲突；未登记前新增 runner 只能定向执行，不能声称统一 profile 已覆盖。
- 每组先交付 worktree diff、定向结果与未运行项；主审完成交叉 review、manifest 登记和 quick/ui/core/full 后才可把状态升级为 `READY_FOR_REVIEW`。
- 运行时实现开始后 I2 仍保持 `ACTIVE`；不得创建 validation/handoff 或提升 capability。
