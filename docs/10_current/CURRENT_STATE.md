# Current State

文档状态：ART22 关闭后的当前权威事实摘要
最后更新：2026-07-18

## 1. 基线身份

```text
branch: art/art22-deploy-prep-final-ui
base: origin/integration/i0-art21-baseline
I0_source: origin/i0/project-baseline-refactor
I0_source_head: 77569579a6c66d9f4350f0ba419906a7814dd502
ART21_source: origin/art/art21-main-menu-scene-reconstruction
ART21_source_head: 93420a8f3799c540ac8a2b46d3c264d5f3ee10f1
common_base: 3dbb843e34f16a9a10b7122a0e094c457a7057c6
latest_closed_art_stage: ART22
active_successor_stage: none
```

当前路径从 Git worktree 解析。旧机器 `D:\AGAME1` 路径继续保留在历史
validation / handoff 中，但不控制当前执行。

## 2. I0 工程基线

I0 仍是最新关闭的非美术阶段，关闭状态为
`CLOSED_WITH_RECORDED_SAFETY_NONCONFORMANCE_AND_LIMITATIONS`。

整合后仍保留：

- `abandon_count` 默认值与规范化。
- RFC 4180 资产 CSV 解析。
- `open_inventory`、`open_ground_loot`、`request_extract` InputMap。
- DebugGate 对调试面板入口的约束。
- ART21R2 smoke seeder 与 RunScene 的职责拆分。
- 12 个 I0 headless runner、污染守卫和文档编码门。

历史 I0 的有限可见 smoke、24 条退出清理提示类别、AppData log
安全不符合记录和未完成完整人工游玩结论均未被本次整合抹除。

## 3. ART21 美术基线

ART21 仍是最新关闭的美术阶段。主菜单已使用场景式布局：

- 1280×720 clean plate。
- 左侧地牢、标题招牌、公告和主角。
- 右侧公司与四个入口：出发探索、长期系统、设置、退出游戏。
- 引擎渲染中文文字、设置与退出覆盖层、路由过渡。
- 152 个主菜单运行时 PNG、66 个 live / interaction-reachable 资产。
- 默认保守解码预算 10.40 MiB。
- 10 个运行时 motion group、6 张三分辨率/状态证据图。

ART21R2、ART21R1 与早期 ART21 placement 工作仍是历史预备切片。

## 4. ART22 美术基线

ART22 是最新关闭的美术阶段：

- 真实 `main.tscn → AppShell → DeployPrepShell` 接入。
- 57 个运行时 PNG，默认 8.18 MiB，总量 9.36 MiB。
- 5 个一级页签、34 个二级状态、四页摘要、可收起羊皮纸。
- 8 张角色帧、8 组环境帧动画、2 组粒子。
- 12 张状态 / 五分辨率截图、5 张矩阵联系表、6 张动作时序截图。
- `ART22-CU-FROZEN-2` Computer Use 全量验收 PASS。
- Asset manifest 为 388 行、17 列、唯一 ID。

## 5. 整合验证事实

2026-07-18 的 ART22 提交前工作树验收：

```text
I0 overall: PASS_WITH_NOTES
I0 characterization: PASS_REMEDIATED_WITH_NOTES
I0 runners: 12/12
blocking diagnostics: 0
cleanup diagnostics: 24
document encoding: PASS_WITH_RECORDED_LIMITATION
pollution guard: PASS
asset_manifest rows: 388
ART21 runtime: PASS entries=4 overlays=2 transitions=2 shortcuts=2 motion_groups=10
ART22 runtime: PASS tabs=5 secondary_states=34 summary_pages=4 character_frames=8 ambient_tracks=10
ART21 scene / placement / ART20 / ART21R1 / G39 / ART17 regressions: PASS
Computer Use: ART22 PASS, 34/34 states plus motion and route checks
visible Godot: launched for ART22 acceptance
```

I0 工作树报告：
`D:\AGAME1\reports\i0\I0.2_20260717T210626351Z_4d3d0c77.json`。
该绝对路径是当前机器运行证据，不是仓库路径权威。

## 6. 当前边界

- 当前没有已授权的 ART22 后继、工程、内容、CI 或发布阶段。
- 完整人工游玩、最终视觉、性能、兼容性、导出与发布 PASS 未声明。
- 其他原始 worktree 的 dirty 文件和 stash 不属于本整合提交。
- ART22 详细证据见 `docs/validation/ART22_DEPLOY_PREP_FINAL_UI_VALIDATION.md`；
  I0 + ART21 工程基线仍见 `docs/validation/I0_ART21_BASELINE_INTEGRATION_VALIDATION.md`。
