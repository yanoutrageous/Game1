# Handoff I1 Incremental Development Baseline

文档状态：`DRAFT_WORKTREE_ACCEPTED_HEAD_PENDING`
阶段状态：`IN_PROGRESS`
最后更新：2026-07-20

## 1. 中文摘要

I1 worktree candidate 已通过 static、preflight、quick 21/21、core 24/24、ui 23/23、最新 full 39/39、ART25 资源门和最新 27/27 production preview 生成。27 张图片已人工逐张检查，三分辨率九状态的静态布局、层级、文字、无遮挡与无裁切通过。

精确提交后的 full HEAD、commit 和 push 仍是 pending，因此本 handoff 只交接已接受的 worktree candidate，不能作为阶段关闭证明。

## 2. 基线身份

```text
active_repo: git rev-parse --show-toplevel
godot_project: <active_repo>/Godot/GraytailGodot
branch_observed: codex/i1-baseline-stabilization
source_head_before_i1: 2212992337aeef7cda412dbaaa191c3ad6cbb81a
validated_worktree_base_head: 2212992337aeef7cda412dbaaa191c3ad6cbb81a
validated_head: PENDING
latest_closed_non_art_baseline: I0
latest_closed_art_stage: ART21
later_accepted_ui_evidence: ART23
failed_historical_art_attempt: ART24R2
engine: Godot 4.6.3.stable.official.7d41c59c4
```

## 3. 已验证交付

- 安全：普通 restart 强确认、debug restart gate、运行配置身份保持。
- 持久化：原子写入、backup 恢复、损坏保护和未来 schema 防降级。
- 权威：state machine 单一 phase 写入、runtime controller 终局幂等提交、UI 纯展示。
- 模块：物品命令 handler、`ContentDBAccess`、作用域刷新、可见页 revision、运行时贴图缓存与动画 catalog。
- 性能：最新 full worktree combat p95 321 μs、full refresh p95 333,855 μs；仅限微基准。
- UI：三档分辨率、焦点、最小字号、命令反馈和禁用原因自动契约通过；run/combat 底部双行状态框内距/行高与 deploy 单行摘要修复由 `I1_UI_INTERACTION` 和 ART22 34 状态 runner 覆盖。
- 可见：九状态 × 三分辨率静态预览的布局、层级、文字、无遮挡与无裁切人工检查通过；鼠标/手柄、动态动画和音频仍排除。
- 资源：ART25 validator 107 assets 通过；生成 fingerprint 前后均为 `CE8A6BFFA8AF81125956ECDA943E86A20B2DF53809C689C499029088D1BA061C`。
- 工具：I1 static、profiles、worktree/head、JSON、污染守卫和生产预览已建立；preflight 最新为 120,233 ms，较旧观测减少 69,172 ms / 36.5%，扫描剪枝未削弱目标完整性与隔离门。
- 治理：首入口、来源/重复/Godot docs registry、contract/assessment/architecture/runbook/validation/handoff 已统一。

详细路径、hash、cleanup 分类与范围见 `docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`。

## 4. 验收中校准

- I04 从旧 GroundLootPanel / `seed 2+0` 校准到 current world-context 与 `1 floor + 1 backpack`。
- 三个 ART24 probe 从 Node 改为 SceneTree runner。
- `ContentDBAccess` 消除可复用脚本的编译期 autoload 耦合。
- run/combat 底部双行状态框内距/行高与 deploy 单行摘要已修正；定向 UI runner 和最新 full 均通过。

所有校准已包含在 full worktree 39/39 PASS candidate 内。

16:05 full 曾因 M5 旧测试夹具未固定 `m7_map` seed 而 38/39 FAIL；fixture 固定 `seed_value=1001` 后独立进程连续 3 次 PASS，并由当前 16:15 full 39/39 覆盖。15:46 preview 虽早于该 fixture 修复和 `game_kernel` diagnostic 校准，但两项都没有 autoload/消费者/UI 可见路径变化，因此既有 27 图静态结论继续适用，机器视觉状态仍为 review required。

## 5. 默认操作入口

```powershell
# 日常快速回归
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile quick -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'

# UI / 美术快速阅览
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 -All `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'

# 提交后的最终门
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 -Profile full -SourceMode head `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

`E:\Godot` 只是本机示例，其他机器按参数、环境变量、PATH 顺序解析。

## 6. 必须继承的不变量

1. 后续变更默认先跑 quick，按改动追加 core 或 ui，关闭前跑 full；提交后用 head 再验。
2. UI 不拥有 gameplay、结算或持久化事实。
3. combat 高频变化不得无证据退回全量刷新。
4. state phase、terminal commit、item location 和 save file 各自只有明确权威。
5. 新 runner 必须注册或明确排除；capture 生成不等于视觉 PASS。
6. 新资产先过来源/许可/manifest/import gate。
7. Godot metadata 变更必须使用单独暂存清单与验证门。
8. 历史 stage、absolute path 和失败记录不得被当前摘要改写。

## 7. 保留债务

- `RunScene` 仍是大型协调器，I1 不是全面解耦完成声明。
- active-run 跨进程恢复未实现。
- full 中 22 个 runner 保留已分类 cleanup diagnostic；blocking diagnostic 为 0。
- 完整仓库经济、Boss/精英、更深内容、装备强化/耐久/随机词条、抽奖/唯一物和实际外观仍未完成。
- 玩家独立 death bitmap、音频、最终动画与交互手感未验收。
- 完整人工长局、通用性能、设备矩阵、导出和发布未验收。
- GitHub Actions workflow 已配置，但远端成功前仍为 `configured_unproven`。

## 8. 最终交接待填

```text
preflight_report: PASS / E:\AGAME1\.tmp\i1\20260720T121125570Z_19409ad4\report.json
worktree_full_report: PASS / E:\AGAME1\.tmp\i1\20260720T161528162Z_4c36eeef\report.json
worktree_full_duration_ms: 400736
worktree_business_files: 2121
worktree_business_fingerprint: BD1BD6D26C6BC4C794FBA3ADAFA73E642B56BCD4670836E661E1A74E71F94038
preview_report: PASS_WITH_VISUAL_REVIEW_REQUIRED / E:\AGAME1\.tmp\i1\20260720T154608674Z_b8f19552\preview_report.json
preview_review: PASS_STATIC_LAYOUT_27_OF_27
art25_validation: PASS
validated_head: PENDING
head_full_report: PENDING
git_commit: PENDING
git_push: PENDING
overall_worktree: PASS_WITH_NOTES
overall_stage: PENDING_COMMITTED_HEAD
```

最终事实必须从 I1 validation 回填；在 committed HEAD 验证与 Git 交付完成前不得将本文状态改为 CLOSED。
