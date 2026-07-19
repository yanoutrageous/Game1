# M7 执行审计：完整地图难度与首轮长期成长内容

审计状态：PASS_WITH_NOTES
审计日期：2026-07-19
审计对象：M7 实现、自动化、可见证据和上传前变更集

## 审计结论

```text
Scope: valid_stage
Risk: high
Implementation: complete
Acceptance: pass
Evidence: automated + visible + regression
Art boundary: preserved
Action: commit_and_upload
Notes: final balance / long manual play / performance / export remain non-goals
```

M7 已按计划审计后的契约完成，13×13 三档包含在真实运行范围内。没有发现需要阻止提交上传的 P0 / P1 问题；保留项均为契约已经声明的后续验证或后续内容，不影响 M7 关闭。

## 硬门禁复核

| 门禁 | 结果 | 说明 |
|---|---|---|
| 基线正确 | PASS | 从 `ART23 + G41 + M6` 的最新闭合提交 `2fd9d4d` 开始；未采用 ART24 / ART24R1 |
| 八档地图真实可玩 | PASS | 所有地图进入同一 `TruthMap → RunContext → RunStateMachine` 路径 |
| 13×13 三档纳入 | PASS | 普通 / 困难 / 地狱均参与 100 种子矩阵及三分辨率可见验证 |
| 失败前不写局外 | PASS | 未确认抢救直接返回 `awaiting_salvage_selection` |
| 奖励与交易幂等 | PASS | 结算、委托、任务、成就、购买、出售和研究均有重复门禁 |
| 旧档不丢字段 | PASS | schema v3 迁移与规范化保留 M6 资产和历史 |
| 全部长期条目可达 | PASS | ART23 三卡容器增加程序化分页，不再只展示前三条 |
| 回归 | PASS | G41、ART22、ART23 和 Godot 项目加载通过 |
| 美术并行边界 | PASS | 没有修改共享资产、场景、导入信息、UID、主题或项目设置 |
| diff 卫生 | PASS | `git diff --check` 通过；临时重复截图已移除，正式证据保留在 `docs/art/validation/m7` |

## 执行中发现并修正的问题

1. 地图打开计数最初误接在战斗击败路径；已移动到真实打开大地图命令，避免战斗污染探索事实。
2. 事件与怪物日志最初缺少策划判定所需类型；已由房间解析器补充 `event_type` 与 `monster_types`，目标不再依赖 UI 或推测。
3. ART23 容器固定显示三卡，条目超过三项时原实现不可达；已增加上一页 / 下一页和页码，同时保留原三卡布局。
4. 购买、研究或出售后的出发配置刷新可能丢失地图、委托与携入选择；已按仍然存在且合法的实例重建选择。
5. 13×13 在旧最小格尺寸下过密；已降低小地图 / 大地图的最小格与字号下限，并用 1280、1600、1920 三档截图确认不越界。

## 证据索引

- 阶段契约：`docs/20_product/M7_COMPLETE_MAP_DIFFICULTY_LONG_TERM_CONTENT_CONTRACT.md`
- 自动化和可见验证：`docs/validation/M7_COMPLETE_MAP_DIFFICULTY_LONG_TERM_CONTENT_VALIDATION.md`
- 阶段前实例总览：`docs/20_product/M7_0_CURRENT_INSTANCE_CONTENT_BASELINE.md`
- 正式截图：`docs/art/validation/m7/`

## 非阻断备注

- 当前数值是首轮可玩值，不代表最终平衡认证。
- 没有声明完整人工长时间游玩、性能、CI、导出或发布通过。
- 抽奖、唯一物真实获取和实际外观按契约继续锁定。
- 美术侧后续可以在既有显示键和锚点上替换表现，但不得改变地图、奖励、容量、碰撞或结算权威。
