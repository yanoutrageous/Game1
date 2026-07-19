# Current State

文档状态：M6 关闭后的当前仓库事实；最后更新 2026-07-19。

## 当前基线

```text
branch: godot/g41-in-run-core-gameplay-runtime
program_baseline: ART23 + G41 + M6
art_baseline: ART23
excluded_baseline: ART24
latest_closed_program_stage: M6
active_successor_stage: none
godot: E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
git: E:\git\cmd\git.exe
```

当前仓库必须由 `git rev-parse --show-toplevel` 解析，历史文档中的旧盘符路径不再具有当前执行权威。ART24 因用户确认的重大运行问题被明确排除，不能作为程序基线。

## 已完成的程序闭环

- ART21/22/23：主菜单、出发页和长期页的既有美术运行基线。
- G41：连续房间移动、距离交互、宝箱、地面掉落、拾取/替换/丢弃、固定步长战斗、怪物、逃跑和生命周期清理。
- M6：仓库真实实例、玩家手动出勤、局内获取与使用、成功/失败/放弃结算、仓库写回和最多 50 条历史记录。
- 新档初始库存：护目镜、绝缘套、压缩饼两份、胶带卷、扫描针；金色资源为 0。
- 出勤上限：最多 2 件装备、3 个消耗品实例；基础背包 10，基础失败保全容量 4。
- 消耗品在所有终局清除；失败由玩家按重量手动确认非消耗品保全；放弃保全容量为 0。
- 当前进程内可以从局内返回出发页，再继续同一个 `run_id`；确认放弃走真实结算。
- 所有非唯一实体物品已有搜索、宝箱、战斗、事件或祭坛来源；旅商收据是虚拟记录，唯一占位保持锁定。

## 当前验证事实

```text
M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION=PASS
M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP=PASS
ART22_DEPLOY_PREP_RUNTIME=PASS
ART23_LONG_TERM_RUNTIME=PASS
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME_VALIDATION=PASS
Godot headless editor/project-load smoke=PASS
git diff --check=PASS
```

M6 外部 headless runner 在退出时仍报告既有的 `ObjectDB/resources still in use` 清理诊断，但进程退出码和 M6 断言均通过；该诊断不被扩写为完整长期运行或发布通过。

## 尚未声明完成

- 完整仓库经济、购买、整理、堆叠、扩容、保险和托运；
- 装备强化、耐久、随机词条、完整被动与最终数值平衡；
- 完整目标/奖励/奖池、研究、抽奖、收藏奖励；
- Boss、精英、完整事件与更深内容量；
- 退出 Godot 进程后的局内检查点恢复；
- 最终美术、音频、完整人工长时间游玩、性能、CI、导出和发布。

详细证据见 `docs/validation/M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION.md` 和 `docs/handoff/HANDOFF_M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP.md`。
