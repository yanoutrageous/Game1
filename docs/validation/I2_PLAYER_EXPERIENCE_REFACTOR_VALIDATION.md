# I2 玩家体验侧重构验证记录

状态：`CLOSED / PASS_WITH_NOTES`

日期：2026-07-22
阶段：I2 Player-experience Refactor and Incremental Baseline（单一阶段）

## 中文摘要

I2 是从工程侧交付转向玩家实际体验侧的单一跨线重构阶段；I2.0–I2.7 是阶段内部切片，不是独立阶段，也不单独授予后续开发权限。本记录只登记已实际验证的范围：主界面、出发探索、长期系统、局内交互、特殊房、战斗房和结果解释的受控重构，以及它们对 I1 权威、保存、结算、运行时安全和既有回归门的继承。

最终结论为 `CLOSED / PASS_WITH_NOTES`。原因是自动化目标矩阵、生产 capture 静态人工检查与性能对照均已取得规定证据，但最终审美、音频、动态交互手感、长局、设备矩阵、CI full、导出与发布均为 `NOT_RUN`，不得被本记录暗示为已验收或已发布。

运行时实现对象已冻结为 commit `c500bdb8b931fada26f4f617a3feaad643281b4c`、tree `7b04e81882961f65a516e192c33093ec98162667`。关闭文档仍须经过 final worktree 与提交态 full/head；其报告在下方 closeout 门完成后补录。

```text
active_repo: resolve with git rev-parse --show-toplevel
branch: codex/i2-player-experience-refactor
i2_entry_head: b77132b9de655b36f71c930a35a191c383b55522
i2_implementation_commit: c500bdb8b931fada26f4f617a3feaad643281b4c
i2_implementation_tree: 7b04e81882961f65a516e192c33093ec98162667
engine: Godot 4.6.3.stable.official.7d41c59c4
```

## 范围与反馈追踪

- I2 保持为单阶段；内部 I2.0–I2.7 的通过只构成本阶段的收口证据。
- 玩家反馈追踪矩阵共 43 项：34 项在本阶段被实现并验证，9 项明确延后或保留为未验收内容。
- 明确未采用的方向包括：未经过管线、性能和时装替换验证的运行时骨骼帧自动生成；将出发探索地图退回为“区域→难度”分步页；复制 UE 架构、`.uasset` 或未知许可素材。
- Godot 是唯一实现与运行时权威；`E:\UE\Game\UE\Graytail` 只读用于概念、交互与视觉参考。

## 运行时核心收口

以下 I2.6 runner 均为 PASS，marker 原文如下：

```text
I2_COMBAT_ROOM_EXPERIENCE=PASS touch=zero_command mouse=enabled invalid=zero_command cancel=zero_command confirm=flee_1,transition_retry_2 modal=blocked
I2_SPECIAL_ROOM_PLAYER_EXPERIENCE=PASS event=structured,proximity_gated,room_entry_scrub,stage_feedback,token_scrub world=proximity_only mine=entry_result monster=0.18s exit=public_summary,proximity_gated
I2_TERMINAL_RESULT_AUTHORITY=PASS outcomes=success,failure_pending,failure_finalized,abandon reason=lifecycle_event items=authoritative_arrays floor_loss=visible pending_meta_writes=0
I2_TERMINAL_COMMIT_RECOVERY=PASS nonce=128bit legacy_ids=compatible save_failure=rollback retry=same_snapshot duplicate=idempotent result_signals=unchanged exits=guarded discard_confirmations=2
```

这些证据覆盖的边界包括：战斗房逃离必须由显式确认触发，门接触不会绕过战斗；事件、撤离和地雷房使用面向玩家的结构化信息与距离门；箱子、地面物、出口摘要和特殊房反馈不以工程 token 作为玩家文本；结果面板以生命周期事件、权威物品数组和保存回滚/重试/幂等规则解释成功、失败、放弃及未完成结算。

## 继承门与定向回归

下列 marker 在最终目标矩阵中通过；它们证明 I2 没有绕过 I1/G41 的既有权威边界。为可复核性，保留 runner 输出的精确 marker（无附加参数者即为完整 PASS marker）。

```text
I2_RUNTIME_MODAL_PRIORITY=PASS stack=top_only nested=map_over_inventory shield=immediate_top_sibling settings=shared map_open_commands=3 map_actions=toggle_flag:1,fast_return:1 lower_layers=blocked real_input=M,Q,Esc map_focus=map_pos inventory_actions=use:1,drop:1 inventory_focus=preferred abandon_commands=1 failure_focus=use,drop,flag
I2_WORLD_INTERACTION_RUNTIME=PASS chest=single_projection command=before_animation proximity=display_only doors=public_snapshot asset=open_png_blocked
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS fixed_hz=60 outer_schedules=30,60,144,hitch monsters=slime,slimeling,bat,drone visual_contract=v1
I1_UI_INTERACTION=PASS
I1_SAVE_RELIABILITY=PASS atomic_replace=PASS backup_recovery=PASS future_schema=PASS long_term_view_rollback=PASS
I1_RUNTIME_SAFETY=PASS
I1_TERMINAL_AUTHORITY=PASS no_ui_commit=PASS exactly_once=PASS pending_failure=PASS
ART24_RESULT_PANEL_SCENE=PASS resolutions=5 states=success,failure_empty,failure_pending,failure_selected,failure_capacity_blocked,failure_final,abandon,save_failed focus=visible danger=preserved item_sections=whole
TARGET_MATRIX_FINAL=PASS count=12
```

`I1_UI_INTERACTION=PASS` 的同次详情为：`production=main resolutions=1280x720,1600x900,1920x1080 focus=PASS fonts=PASS feedback=PASS disabled_reason=PASS`。它是 UI 交互/布局的自动契约，不代替人工审美或动态手感判断。

## 生产场景 capture 与人工静态检查

最终 production capture 矩阵已接受：

```text
CAPTURE_MATRIX_ACCEPTED=PASS expected=39 actual=39
```

输出目录：`E:\AGAME1\.tmp\i2_6_final_capture_accepted`。

覆盖 13 个状态、3 个分辨率，共 39/39：`event`、`event_merchant`、`chest`、`monster`、`mine`、`exit`、`reduced_motion`、`result_success`、`result_failure_empty`、`result_failure_mixed`、`result_failure_final`、`result_abandon`、`result_save_failed`。

人工静态检查确认的范围是：商人五项选择以 3+2 显示且没有裁切或原始英文 token；出口 context popup 与实体提示不重复；非战斗门不再出现误导性的青色边框；战斗锁定仍保留红色语义；结果面板的焦点、危险动作、物品区和失败/放弃文案可见且无半行裁切。

此项证据严格是**静态人工 capture 检查**。它不是动态视觉、最终审美、音频、动画质量、输入手感、完整游玩、设备兼容性或发布验收。

## 性能对照

最终五轮使用同一可比工作负载，依次记录 `enemy1 / enemy3 / enemy5 / projectile` 四个场景的 p95（单位：μs）：

| 轮次 | enemy1 | enemy3 | enemy5 | projectile | cache late load | orphan delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| run1 | 757 | 1328 | 1548 | 1784 | 0 | 0 |
| run2 | 748 | 1284 | 1382 | 1703 | 0 | 0 |
| run3 | 756 | 1318 | 1675 | 1600 | 0 | 0 |
| run4 | 787 | 1315 | 1686 | 1883 | 0 | 0 |
| run5 | 799 | 1258 | 1884 | 1159 | 0 | 0 |
| median | 757 | 1315 | 1675 | 1703 | 0 | 0 |

另完成非 headless 的生产场景可见测量：4 个场景各 60 秒，marker 为：

```text
I2_COMBAT_FRAME_VISIBLE=MEASURED_NOT_ACCEPTED
```

性能结论仅限于：在本机、可比负载与上述测量边界下，**未见系统性相对回退**。历史绝对值会受机器功耗和调度影响，不能从此推出 FPS 提升、通用性能提升、设备性能达标或长局稳定性。

## 素材与外部参考边界

- 运行时只复用已治理的 Godot 素材。
- 本阶段没有新增、生成或导入运行时素材，也没有将 UE 素材、`.uasset`、UE 架构或固定烤字布局带入 Godot。
- UE 仅以只读方式提供参考；它不构成当前代码、性能、许可或资产来源权威。

## NOT_RUN / 未验收

以下项目均为 `NOT_RUN`，不包含在 `CLOSED / PASS_WITH_NOTES` 的通过范围：

- 最终审美验收、完整动画质量与音频验收；
- 动态交互手感和完整玩家人工游玩；
- 长局、内存稳定性与跨进程恢复；
- 多设备、输入设备与分辨率/性能设备矩阵；
- CI full；
- 导出包验证与发布。

## 提交前后 closeout 门

| Gate | 当前结果 | 证据 |
| --- | --- | --- |
| static/worktree | PASS / manifest 67 required runner / failures 0 | manifest SHA256 `B294F80EC3953B7DDC86A662DD744B824D99A68AA3988139ABF63A7D81295A92` |
| quick/worktree | PASS 48/48 / 30 plain + 18 cleanup / 480,990 ms / pollution PASS | `E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T111500319Z_4fe84c8e\report.json`; SHA256 `9A480DC36C211EF33E33F81FFE7B7F889C576F8F6486C72A45A7FFE878486117` |
| ui/worktree | PASS 49/49 / 33 plain + 16 cleanup / 333,221 ms / pollution PASS | `E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T112353175Z_7edf3a02\report.json`; SHA256 `DAFFEAD953E3BE4E853EC1CC1649369E4F0227BEB98FEA7E98C66F0B2DBD2925` |
| full/worktree | PASS 67/67 / 39 plain + 28 cleanup / 56 classified cleanup diagnostics / blocking 0 / 598,866 ms / pollution PASS | `E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260722T113228922Z_4f00a3b8\report.json`; SHA256 `A6F7978C038EFC6F5FFCA9FA058A0DA161AA28B12DD0B589F87354E126FABCAB`; source head `c500bdb8…`; business 2,207 files / fingerprint `B2D8AC543DD54C699586C5DA8CC71936521E81E89C8A129BF221BFEBE0A34423` |
| full/head | POST-COMMIT EXACT-HEAD GATE REQUIRED | 关闭文档无法自指其最终 commit；提交后报告与最终交付共同记录精确 HEAD/tree、报告路径与 SHA，未通过则不得推送为闭合基线 |

worktree 报告的 source head 为当时的基底/实现提交，实际候选还包含报告所冻结的 tracked 与 untracked closeout 文件；污染守卫证明运行前后 Git 状态与 business fingerprint 不变。`SourceMode head` 才是最终提交对象的精确权威，最终交付必须给出其结果，不能由本文件预写。

## 关闭规则

I2 关闭只交接本文已登记的已验证范围，不能自动授权 I3、后续美术阶段、发布或任何未列入范围的功能。新开发必须先获得新的用户或治理授权，并重新声明其验证和玩家体验验收边界。
