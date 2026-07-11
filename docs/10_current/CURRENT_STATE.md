# Current State

文档状态：当前权威事实摘要
最后更新：2026-07-11（I0.7 closeout）

## 1. 活动基线

```text
workspace_root: D:\AGAME1
active_repo: D:\AGAME1\active\Game1_work
godot_project: D:\AGAME1\active\Game1_work\Godot\GraytailGodot
branch: i0/project-baseline-refactor
i0_code_and_path_baseline_head: ba467dd2afdfd517ce798b9d674742891face4b7
i0_validated_implementation_head: d34f869e85993704ca4091b26f9e40a39795c860
i0_source_head: d4168a6111cfd30be28880301ded52be2d32f462
upstream: none
```

旧活动路径 `D:\AGAME1\_repo_cache\Game1_work` 已在 I0.5 通过同卷原子目录移动迁出，当前应不存在。历史报告中的旧路径是时间点证据，不应批量替换。

## 2. 当前阶段

I0 是已关闭的独立项目基准阶段，不属于 G / ART / M / P 线路。当前没有已授权 active stage。后续线路均应使用 I0 固定的活动路径、Godot 工具链、测试隔离、污染守卫和声明边界，并新增“可见启动先证明游戏日志隔离”的安全门。

| 阶段 | 状态 |
| --- | --- |
| I0.0 原始状态冻结 | complete |
| I0.1 项目本地工具链 | complete_with_recorded_chain_limitation |
| I0.2 隔离特征测试 | complete |
| I0.3 四项基线缺陷修复 | complete |
| I0.4 RunScene 最小职责提取 | complete |
| I0.5 原子迁移与双次复验 | complete_with_followups_closed_in_I0.6 |
| I0.6 文档与流程治理 | complete_with_recorded_limitations |
| I0.7 最终自动化 / 可见 / 人工观察 | closed_with_recorded_safety_nonconformance_and_limitations |

I0 契约：`docs/20_product/I0_PROJECT_BASELINE_REFACTOR_CONTRACT.md`。

## 3. 产品与进度

当前项目是《灰尾回收 / 五四三二一》的 Godot 4 单人撤离式 roguelite 纵向切片，以扫雷式信息推理驱动房间探索、风险与撤离决策。

```text
engineering_vertical_slice: 65%-75%
public_mvp: 40%-50%
full_product_vision: 25%-35%
release_readiness: 20%-30%
current_engineering_health: about 6/10, yellow
```

完整依据、置信度和未来路线见 `docs/10_current/I0_BASELINE_ASSESSMENT.md`。

## 4. I0 已改变的事实

- 保存默认值和规范化不再丢失 `abandon_count`。
- 资产 CSV 使用 RFC4180 解析，六行含逗号字段已正确引用，179 行身份与顺序未改变。
- `open_inventory`、`open_ground_loot`、`request_extract` 已有 InputMap 定义。
- 调试面板 toggle / open 恢复受 `DebugGate` 控制的显示能力。
- ART21R2 调试播种由 `art21r2_run_smoke_seeder.gd` 持有；`RunScene` 从 1,768 行降至 1,668 行。
- Godot 4.6.3 固定在 `D:\AGAME1\tools\runtimes\godot\4.6.3`。
- 活动仓库已原子迁移到 `D:\AGAME1\active\Game1_work`。

## 5. 自动化验证事实

恢复后的 I0.7 最终隔离运行得到：

```text
overall: PASS_WITH_NOTES
characterization: PASS_REMEDIATED_WITH_NOTES
runners: 12/12
blocking_diagnostics: 0
cleanup_diagnostics: 24
pollution_guard: PASS
RunScene canonical snapshots: 5/5 identical between runs
business_file_count: 656
business_fingerprint: A344034211ACD8299E1FE3F1CDED47A80D58815B4D77D9E6B312A4A0569D0928
```

报告：`D:\AGAME1\reports\i0\I0.2_20260711T064535471Z_5b55f8c8.json`；SHA256 `6868337E7E51DB03BA083725914165D6D7456F017252823C866939CF4B98782F`。

24 条提示来自 ObjectDB / resource 退出清理，当前不阻断行为结论，但仍是健康债务。

I0.6 已把严格文档编码门接入同一主套件：376 个文本、428 个图片 magic 验证、5 个精确历史异常、0 个新增异常；340 张历史截图为 `.png` 扩展名 / JPEG magic 不一致并已计数。未知类型 canary 会在 Godot runner 前 fail closed。

I0.7 closeout 文档落位后的独立编码门为 805 inventory、377 个文本、428 个图片 magic、5 个精确历史异常、0 error；该门用于验证 closeout 文档树，不冒充在 closeout 文档提交 HEAD 上重新运行了 12 个 Godot runners。

可见有限烟测观察到主菜单 → 出发整备 → 局内 HUD，以及 M 地图、Q 背包、G 地面回收和 T 任务提示响应。移动、撤离完成、结算和返回未观察；不声明完整人工游玩或最终视觉 PASS。

## 6. 受保护的原始工作树状态

I0 开始前的 12 项 status 被精确保留，且无 staged 文件：

```text
7 tracked *.translation modifications
1 tracked project.godot modification
1 tracked scripts/ui/run_surface/run_surface.gd modification (EOL-only)
2 untracked ART21R2 smoke screenshots
1 untracked tools/__pycache__/ directory
```

保护性 stash 保持：

```text
a608462968d7913a5bf63c376c186fe1df89d2db
On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two
```

这些内容属于用户原有状态。I0 不清理、不丢弃、不自动提交。

## 7. 已知限制与安全记录

- 工具链签名者和时间戳可读取；本机证书链返回 untrusted root，因此记录为限制，不声称完整链验证 PASS。
- 历史 G37 验证器曾意外选择 `D:\Godot` 下的 Godot，并在 `D:\AGAME1` 外产生 Godot AppData 日志写入。
- I0.7 的项目内固定 Godot 可见启动再次在同一 AppData logs 目录新增 / 改写两个日志，构成明确 `SAFETY_NONCONFORMANCE`。活动工程内被改变的 8 个业务路径已从可信 preimage 恢复；12 个原始 status 路径成员全部保留，11 / 12 与 I0.0 raw 字节相同，`project.godot` 恢复到含 I0.3 合法修复的 post-I0 preimage `CD7C9662...E3D46`。恢复 / 后续处置没有删除或再次修改这些范围外日志。直接可见 Godot 在证明日志隔离前不再授权。
- ART-13 在原始脏状态下 exit 0 并报告 28 个 warning；ART-14 的 5 个 error 均可由原始 `run_surface.gd`、两张截图和 `tools/__pycache__` 解释，不是迁移回归。
- 五个历史 / 导航文档存在 I0 前即有的 UTF-8 字节损坏；I0 保留精确 preimage，并为三个导航职责建立有效 `I0_INDEX.md`，不猜测恢复历史正文。处理见编码台账。
- 可见验收为有限覆盖；完整人工游玩、发布和完整视觉 PASS 均未声明。

## 8. 当前读取顺序

1. `docs/10_current/CURRENT_STATE.md`
2. `docs/10_current/I0_BASELINE_ASSESSMENT.md`
3. `docs/10_current/CAPABILITY_MATRIX.yaml`
4. `docs/20_product/I0_PROJECT_BASELINE_REFACTOR_CONTRACT.md`
5. `docs/40_validation/VALIDATION_INDEX.md`
6. `docs/10_current/KNOWN_UNFINISHED_SYSTEMS.md`
7. `docs/10_current/NEXT_ACTION.md`

G40 及更早阶段文件继续作为历史证据，不再控制当前路径、当前阶段或当前验证声明。
