# Current State

文档状态：M7 合并、ART24R2 返工恢复后的当前仓库事实；最后更新 2026-07-20。

## 当前基线

```text
branch: art/art24r2-g41-m6-combat-ui
program_baseline: ART23 + G41 + M6 + M7
art_baseline: ART23
latest_art_attempt: ART24R2 resumed from 24/61 failed audit
excluded_baseline: ART24 / ART24R1 / ART24R2
latest_closed_program_stage: M7
active_successor_stage: ART24R2 rework
godot: D:\AGAME1\active\tools\runtimes\godot\4.6.3\godot_v4.6.3-stable_win64_console.exe
git: resolved from PATH
```

当前仓库必须由 `git rev-parse --show-toplevel` 解析，历史文档中的旧盘符路径不再具有当前执行权威。ART24R2 已合并 M7 最新程序接口并从 24/61 的失败审计继续返工；在重新达到冻结标准前仍不能作为已验收美术基线。

## 已完成的程序闭环

- ART21/22/23：主菜单、出发页和长期页的既有美术运行基线。
- G41：连续房间移动、距离交互、宝箱、地面掉落、拾取/替换/丢弃、固定步长战斗、怪物、逃跑和生命周期清理。
- M6：仓库真实实例、玩家手动出勤、局内获取与使用、成功/失败/放弃结算、仓库写回和最多 50 条历史记录。
- 新档初始库存：护目镜、绝缘套、压缩饼两份、胶带卷、扫描针；金色资源为 0。
- 出勤上限：最多 2 件装备、3 个消耗品实例；基础背包 10，基础失败保全容量 4。
- 消耗品在所有终局清除；失败由玩家按重量手动确认非消耗品保全；放弃保全容量为 0。
- 当前进程内可以从局内返回出发页，再继续同一个 `run_id`；确认放弃走真实结算。
- 所有非唯一实体物品已有搜索、宝箱、战斗、事件或祭坛来源；旅商收据是虚拟记录，唯一占位保持锁定。
- M7：八档真实地图已实装，包括 7×7 两档、10×10 三档、13×13 普通 / 困难 / 地狱三档；地图、难度和委托贯穿出发、局内、结算与历史。
- M7：六个本局委托、七段顺序任务、一个失败可选任务、八项成就和三项研究均接入权威事件、奖励与持久化。
- M7：基地商店、普通藏品单件出售、永久图鉴、五级资历、三组收藏和五类真实红点已实装；抽奖与实际外观继续锁定。
- ART23 长期页保留六模块容器；目标、图鉴、研究、资历和收藏已有真实状态与分页，全部策划条目可以访问。

## 当前验证事实

```text
M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP=PASS
M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION=PASS_WITH_CLEANUP_DIAGNOSTIC
M7_CONTENT_RUNTIME=PASS maps=8 seeds_per_map=100
M7_META_UI_RUNTIME=PASS
M7_13X13_VISIBILITY=PASS sizes=1280x720,1600x900,1920x1080
M7_META_VISIBILITY=PASS states=deploy_map,goals,research,collection
ART22_DEPLOY_PREP_RUNTIME=PASS
ART23_LONG_TERM_RUNTIME=PASS
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS
ART24_STATIC_VALIDATION=PASS
ART24_FOCUSED_PROBES=PASS (8/8)
ART24R2_FINAL_COMPUTER_USE=FAIL (24/61 PASS)
G41_WRAPPER_VALIDATION=FAIL (art-path audit markers)
git diff --check=PASS
```

M6 与 ART24 背包场景探针在退出时仍报告 `ObjectDB/resources still in use` 清理诊断；逻辑断言通过，但该诊断和 G41 包装校验失败均被保留，不得扩写为完整长期运行、最终美术或发布通过。

## ART24R2 返工事实

- 已改善角色/房间比例、左栏、协议层、底栏、展开地图、背包、结算、世界掉落与可重复开合箱子。
- 代码门覆盖 8 个一级模块、61 个状态契约和 5 档分辨率；代码门不能替代实机验收。
- Computer Use 已通过 24 个状态；其余 37 个状态因未形成冻结证据或未完成实机检查统一记为 `FAIL`。
- 2026-07-19 的封存与 push 不代表 ART24R2 完成；2026-07-20 已按持续目标恢复返工并合并 M7。
- 详细结果见 `docs/validation/ART24R2_FINAL_COMPUTER_USE_RESULTS.md`。

## 尚未声明完成

- 完整仓库整理、堆叠、扩容、保险、寄售、批量出售和更深经济；
- 装备强化、耐久、随机词条、完整被动与最终数值平衡；
- 更深目标 / 奖励池、更多研究、抽奖、唯一物真实获取和实际外观；
- Boss、精英、完整事件与更深内容量；
- 退出 Godot 进程后的局内检查点恢复；
- 最终美术、音频、完整人工长时间游玩、性能、CI、导出和发布。

M7 详细证据见 `docs/validation/M7_COMPLETE_MAP_DIFFICULTY_LONG_TERM_CONTENT_VALIDATION.md` 和 `docs/audits/AUDIT_M7_EXECUTION_COMPLETE_MAP_DIFFICULTY_LONG_TERM_CONTENT.md`；M6 原始证据继续保留。
