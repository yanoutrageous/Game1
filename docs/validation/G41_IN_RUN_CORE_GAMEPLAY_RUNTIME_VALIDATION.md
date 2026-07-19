# G41 局内基础玩法运行时与交互接口补全验证

状态：CLOSED / PASS

执行审计日期：2026-07-19

分支：`godot/g41-in-run-core-gameplay-runtime`

基线：ART23 `7f2e0b304e2cd7959411bfe6422d3d0b3337462f`

## 结论

G41 的程序实现、正式执行审计、缺陷修正、全量 G41 复验和相关回归均已通过。玩家可在真实房间内连续移动并按距离交互；宝箱只结算一次并产生逐实例地面掉落；拾取、满包阻塞、替换和再次丢下均经现有资产账本；怪物房使用 60 Hz 固定步长权威模拟，胜利、逃跑、自然死亡和结束生命周期经现有 CommandBus / Rule / Effect 边界提交。

执行审计发现并修复一项真实问题：自然战斗死亡虽已生成失败结算，但同一帧剩余域事件会在控制器重置后重新写入 `G41InRunRuntime.recent_domain_events`。修正后，非活动局会再次统一 `reset()`；新增自然死亡黑盒测试验证战斗实例、房间键、遭遇序号与事件缓存全部清空。

远端 ART24 曾在用户给出排除指令前被短暂 fetch/检查，随后分支以 `reset --keep` 安全退回 ART23，且 G41 工作树保持不变。用户明确要求 ART24 不作为基线；其提交、程序与美术接口均未进入 G41 实现或验收结论。

## 验收矩阵

| # | 验收项 | 结果 | 直接证据 |
| --- | --- | --- | --- |
| 1 | Godot 4.6.3 主场景加载与脚本解析 | PASS | 主项目 `--headless --quit-after 8` 退出码 0；G41 runner 解析并运行 |
| 2 | `RunAssetLedger` 为物品位置唯一权威 | PASS | 房间实体只读取 `room_floor_items`；静态只读扫描；重建投影与账本逐实例一致 |
| 3 | 宝箱只结算一次 | PASS | `closed → opening → opened`；重复搜索前后物品数与黑币不变 |
| 4 | 拾取、满包、替换与回地面 | PASS | 成功拾取、容量阻塞不消费实例、替换双方位置及世界投影全部断言 |
| 5 | 四种怪物、攻击、冷却、无敌帧与失败 | PASS | 史莱姆/幼体、蝙蝠三发、无人机激光/冲刺、120° 锥形、重叠攻击无敌帧、自然失败事件 |
| 6 | 一次性胜利奖励成为实际世界实体 | PASS | 清房后产生 `room_floor` 怪物掉落；重复 resolve 不增加；房间视图一对一投影 |
| 7 | 逃跑损失与重进 | PASS | 精确扣除 `floor(black_coin × 10%)`；确定性物品仅移动到本房间地面；房间未清理并重启战斗 |
| 8 | 30/60/144 Hz 与 0.2 s 卡顿确定性 | PASS | 规范状态和完整域事件顺序均相同，3 秒恰为 180 tick |
| 9 | 暂停 5 秒不推进 | PASS | 暂停前后规范快照完全相同；解除暂停后与连续运行一致 |
| 10 | 缺失/替换美术不改变逻辑 | PASS | 程序占位可实例化；8 个稳定锚点；`ArtVisual` 只隐藏占位；逻辑障碍与纹理尺寸无关 |
| 11 | G41 runner 标记 | PASS | `G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS` |
| 12 | 既有结构与主要路线不回归 | PASS | M2/M3/M3R/M3H/M5、I0.4、G36/G37/G38/G39、ART21/22/23 主路线全部 PASS |

## G41 主门

```powershell
Godot/GraytailGodot/tools/validate_g41_in_run_core_gameplay_runtime.ps1 `
  -GodotExecutable E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

结果：

```text
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS fixed_hz=60 outer_schedules=30,60,144,hitch monsters=slime,slimeling,bat,drone visual_contract=v1
G41_IN_RUN_CORE_GAMEPLAY_RUNTIME_VALIDATION=PASS
REQUIRED_FILES=11
```

Runner 额外覆盖：房间视图重复配置与销毁重建、稳定掉落坐标、战斗视图重建不推进权威 tick、VisualRoot 热替换、扫掠投射物、无人机冲刺事件、自然战斗死亡、正常撤离、直接失败和放弃清理。

## 回归结果

静态门：

- M2、M3、M3R、M3H、M5：PASS。
- G36、G37、G38、G39：PASS。
- `git diff --check`：PASS。

Godot 运行门：

- M2、M3、M3R、M3H、M5 runner：PASS。
- I0.4 RunScene contract：PASS。
- G37 command sequence、G39 navigation boundary：PASS。
- ART21 main-menu runtime：PASS。
- ART22 DeployPrep main route：PASS。
- ART23 LongTerm main route：PASS。

Godot runner 退出时仍会出现历史 ObjectDB/resource cleanup diagnostic；退出码和 PASS marker 正常，G41 未新增资源文件或场景文件。

## 已知基线限制与非回归判定

- ART21 完整静态 validator 会因 ART23 基线已跟踪的 `.import` 文件报告副作用；这些文件与 HEAD 一致，G41 未修改。真实 ART21 main-menu runner 为 PASS。
- ART23 完整静态 validator 会在 `ui.art23.long_term.decoration.rail` 的归档 source-hash 检查失败；实际 `module_rail.png` SHA-256 为清单声明的 `3bfa0c1b...3512`，工作树 blob 与 ART23 HEAD blob 相同。真实 ART23 主路线为 PASS。
- G8.1 仍因既有 `scripts/core/save/save_adapter.gd` 写入接口失败；G8.2 仍因该文件及 ART23 HEAD 已存在的 CommandBus 资产直写路径失败。G41 新增战斗写入均经 RoomResolver / Rule / Effect，不把这些历史限制声明为已修复。
- I0 全套隔离验证依赖其专用 workspace/toolchain 布局；本轮执行 I0.4 运行契约并继承 I0 已记录的 PASS_WITH_NOTES，不声明重新完成 I0 发布级复验。

## 污染与所有权

- 未修改或提交 `project.godot`、`.tscn`、`.tres`、`.res`、`.uid`、`.translation`、`.import`。
- 未修改图片、音频、SpriteFrames、全局 manifest 或 ART 文档/资产。
- G41 新增内容仅位于程序脚本、测试、验证工具与 G41 文档边界。
- UI/HUD/房间实体只消费快照；没有直接写 HP、TruthMap 或 RunAssetLedger。

## 不声明

本报告不声明最终美术、完整人工长时间游玩、最终数值平衡、性能、CI、导出、发布、Boss/精英/技能、完整被动/事件或跨进程局内保存完成。
