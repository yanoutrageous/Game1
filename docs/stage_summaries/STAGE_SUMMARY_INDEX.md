# G10-G19 阶段总结索引

## 索引边界

- 本索引覆盖 G10-G19，不覆盖 G20。
- G20-R3c 只新增阶段总结、路线分析、系统边界和阶段依赖图，并更新当前导航文档。
- G20 尚未合并 main。
- G20-R3d 尚未执行。
- G21 未启动。
- 本索引不登记完整分支库存、提交矩阵、验证矩阵、临时/过期文件清单；这些保留给 R3d。

## 阶段总结文件

| 阶段 | 文件 | 稳定名称 | 当前结论 |
| --- | --- | --- | --- |
| G10 | `docs/stage_summaries/G10_SUMMARY.md` | Progress & Art Smoke Foundation | 已完成、已并入 main、静态 closeout 有记录 |
| G11 | `docs/stage_summaries/G11_SUMMARY.md` | Mainline Testability & UX Readability Repair | 已完成、已关闭；未声明 runtime PASS |
| G12 | `docs/stage_summaries/G12_SUMMARY.md` | Legacy Demo Core Loop, Chinese Readability & Typography Parity | 已完成、已关闭；未运行 Godot |
| G13 | `docs/stage_summaries/G13_SUMMARY.md` | Fixed Resolution Layout Adaptation | 已完成、已关闭；静态验证，不是 runtime PASS |
| G14 | `docs/stage_summaries/G14_SUMMARY.md` | Legacy Demo UI Surface Sprint | 已完成、已关闭；RunSurface 是显示层 foundation |
| G15 | `docs/stage_summaries/G15_SUMMARY.md` | Encounter Contract Foundation | 已完成、已并入 main；Encounter foundation，不是完整遭遇系统 |
| G16 | `docs/stage_summaries/G16_SUMMARY.md` | Combat Encounter Foundation | 已完成、已并入 main；Combat foundation，不是完整战斗系统 |
| G17 | `docs/stage_summaries/G17_SUMMARY.md` | AppShell / NavigationIntent / PageRouter / MainMenuShell | 已完成、已并入 main；AppShell/MainMenuShell foundation |
| G18 | `docs/stage_summaries/G18_SUMMARY.md` | DeployPrepShell / DeployConfig / RunStartConfig Foundation | 已完成、已并入 main；DeployPrepShell foundation，不启动 RunScene |
| G19 | `docs/stage_summaries/G19_SUMMARY.md` | LongTermShell Foundation | 已完成、已并入 main；LongTermShell foundation，不是真实长期系统 |

## 配套路由分析

- `docs/route_analysis/ROUTE_ANALYSIS_G10_TO_G19.md`
- `docs/route_analysis/ROADMAP_G20_PLUS.md`
- `docs/route_analysis/SYSTEM_BOUNDARY_MAP.md`
- `docs/route_analysis/STAGE_DEPENDENCY_MAP.md`

## 事实来源优先级

1. `docs/PROJECT_BASELINE.md`
2. `docs/NEXT_HANDOFF.md`
3. `docs/ENGINEERING_STATUS.md`
4. `docs/MILESTONES.md`
5. `docs/validation/*.md`
6. `docs/handoff/*.md`
7. `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`
8. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
9. Git commit log

不足项统一标记为 `unknown`。

## 验证声明边界

- G18/G19 的 `Godot headless project-load/parser smoke PASS` 只代表 headless project-load/parser smoke，不代表 complete gameplay runtime PASS。
- G16/G17 的 parser smoke 也不代表 complete gameplay runtime PASS 或 manual playtest PASS。
- G10-G14 的部分验证来源较分散；没有明确 runtime/manual 证据时，不补写 PASS。
- foundation 不等于完整系统。
