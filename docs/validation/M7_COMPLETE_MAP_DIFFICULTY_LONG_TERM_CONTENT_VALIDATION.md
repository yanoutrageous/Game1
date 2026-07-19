# M7 完整地图难度与首轮长期成长内容验证

验证状态：PASS_WITH_NOTES（阶段验收通过；保留明确非声明项）
验证日期：2026-07-19
工作分支：`godot/m7-map-difficulty-long-term-content`
程序基线：ART23 + G41 + M6；明确排除 ART24 / ART24R1

## 1. 验证结论

M7 的程序侧阶段契约已经实现并通过自动化与可见验证。八档地图均可由同一真实开局路径生成，其中 13×13 普通 / 困难 / 地狱不是卡片占位；委托、任务、成就、研究、图鉴、资历、收藏、红点、购买和普通藏品单件出售均由真实局外状态驱动。失败结算仍在抢救确认后才允许提交，重复奖励和重复交易被幂等门禁阻止。

本结论允许 M7 关闭并上传，但不扩写为最终平衡、完整人工长时间游玩、性能、导出或发布认证。

## 2. 验收覆盖

| 验收面 | 结果 | 证据摘要 |
|---|---|---|
| 八档地图 | PASS | 7×7 两档、10×10 三档、13×13 三档，每档 100 个种子；同种子重复生成 |
| 房型与撤离点 | PASS | 数量精确、房型互斥、撤离点合法；7×7 简单仅公开撤离位置，不公开路径 |
| 13×13 运行与显示 | PASS | 169 格真实大地图；1280×720、1600×900、1920×1080 均完整显示 13 列 |
| 出发选择 | PASS | 八张地图卡、解锁状态、委托候选与真实出发配置一致 |
| 局内事实 | PASS | 唯一房间、地图打开、标记、宝箱、事件和怪物类型由权威运行事件记录 |
| 委托 / 任务 / 成就 | PASS | 委托自动判定与发奖；任务和成就手动领取；重复领取无增量 |
| 购买 / 出售 / 研究 | PASS | 金币和实例精确变化；配置中 / 唯一 / 非藏品不可出售；研究材料只消费一次 |
| 失败门禁 | PASS | 抢救未确认时拒绝写入局外；确认后只提交一次 |
| 长期模块 | PASS | 目标、图鉴、研究、资历、收藏为真实内容；抽奖仍锁定；全部条目可分页访问 |
| 存档迁移 | PASS | schema v3 规范化保留 M6 金币、仓库、历史与既有字段 |
| 美术边界 | PASS | 未改共享场景、源美术、导入元数据、资源 UID、主题与 `project.godot` |

## 3. 自动化结果

使用 `E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe` 执行：

```text
Godot headless editor/project-load smoke=PASS
M7_CONTENT_RUNTIME:PASS maps=8 seeds_per_map=100 transactions=PASS progression=PASS
M7_META_UI_RUNTIME:PASS long_term=PASS deploy_refresh=PASS sale_confirm=PASS map_fact=PASS
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS fixed_hz=60 outer_schedules=30,60,144,hitch monsters=slime,slimeling,bat,drone visual_contract=v1
ART22_DEPLOY_PREP_RUNTIME=PASS tabs=5 secondary_states=34 summary_pages=4 states=expanded,collapsed,active_run,cancel_modal character_frames=8 ambient_tracks=10
ART23_LONG_TERM_RUNTIME=PASS primary_modules=6 secondary_pages=27 character_frames=8 states=OPEN,CLOSED,OPENING,CLOSING,SWITCHING
M7_13X13_VISIBILITY:PASS size=1280x720 columns=13 markers=169
M7_13X13_VISIBILITY:PASS size=1600x900 columns=13 markers=169
M7_13X13_VISIBILITY:PASS size=1920x1080 columns=13 markers=169
M7_META_VISIBILITY:PASS state=deploy_map size=1280x720
M7_META_VISIBILITY:PASS state=goals size=1280x720
M7_META_VISIBILITY:PASS state=research size=1280x720
M7_META_VISIBILITY:PASS state=collection size=1280x720
git diff --check=PASS
```

地图矩阵实际执行 8 档 × 100 种子 × 2 次同种子生成，共 1600 次地图生成。该矩阵同时断言精确房间数、房型互斥、撤离点数量与合法性、种子确定性及可见撤离点语义。

## 4. 可见证据

- [13×13，1280×720](../art/validation/m7/m7_13x13_1280x720.png)
- [13×13，1600×900](../art/validation/m7/m7_13x13_1600x900.png)
- [13×13，1920×1080](../art/validation/m7/m7_13x13_1920x1080.png)
- [出发页 13×13 地图选择](../art/validation/m7/m7_deploy_map_selection_1280x720.png)
- [任务可领取状态](../art/validation/m7/m7_goal_claimable_1280x720.png)
- [研究可执行状态](../art/validation/m7/m7_research_available_1280x720.png)
- [收藏完成状态](../art/validation/m7/m7_collection_complete_1280x720.png)
- [图鉴分页状态](../art/validation/m7/m7_long_term_codex_pagination.png)

目视检查结果：13×13 的 169 个格子均位于大地图边界内，标题、计数、标记和底部说明可读；出发页能滚动到 13×13 三档并显示选中结果；目标、研究、收藏和图鉴保持 ART23 的三卡布局，操作按钮、状态和页码没有越界。

## 5. 权威边界

- UI 只投影状态和发出意图，不直接推进委托、任务、成就或解锁。
- 地图打开次数、标记数、房间探索、事件完成与怪物类型来自局内权威事件。
- `MetaProgressAdapter` 只消费最终结算或显式局外交易；同一结果或奖励再次提交被忽略。
- 图鉴与收藏记录永久保留，不因出售或研究消费实体物品而倒退。
- 失败抢救未最终确认时，金币、仓库、历史和长期进度均不变化。

## 6. Notes / 非声明项

- 未执行完整人工长时间游玩、最终数值平衡、性能压力、CI、导出和发布验证。
- 抽奖、唯一物真实获取和实际外观仍为后续内容；当前锁定状态是正确结果。
- Windows headless 渲染无法提供稳定屏幕回读，因此截图使用 `gl_compatibility` 图形模式；逻辑 runner 与项目加载仍使用 headless。
- 若 Godot 退出时继续出现既有资源清理诊断，应按真实日志记录；本验证不将其写成“完全无警告”。
