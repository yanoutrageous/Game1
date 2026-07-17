# ART22 出发探索最终美术 UI 验证

状态：**PASS**

日期：2026-07-18

## 结论

ART22 已把实际 `main.tscn → 出发探索` 页面替换为可交付的场景式 UI，并按事先冻结的
`ART22-CU-FROZEN-2` 完成 Computer Use 全量验收。5 个一级页签、34 个二级状态、
4 页摘要、展开 / 收起、进行时继续 / 取消、强确认边界、键盘焦点、列表末端和超过
12 秒的动效观察全部通过；没有使用抽样或“有条件通过”。

```text
Acceptance-Version: ART22-CU-FROZEN-2
Pass-Policy: ALL_34_STATES_AND_MOTION_OR_FAIL
Rework-Policy: SAME_CRITERIA_FULL_RESTART
Computer-Use: PASS
Matrix-Result: 34/34 PASS
```

## Computer Use 失败—返工记录

冻结标准生效后发现任何失败均停止当轮，并从真实主菜单重新开始：

| 轮次 | 发现 | 返工 | 结果 |
| --- | --- | --- | --- |
| 1 | 清除未跟踪 `.import` 后，实际项目无法由 `ResourceLoader` 读取 ART21 / ART22 原始 PNG，出发页回退为旧面板观感；宿主页状态也未与 AppShell 页切换同步 | `AssetCatalog` 增加仅对真实存在图片启用的缓存式原图后备；增加真实 `main.tscn` 路由 runner；同步 `page_changed` 到 `RunScene.screen_state` | 重启验收 |
| 2 | 重复点击当前二级筛选会让选中视觉或文字丢失 | 页签使用不可取消的互斥组；同一一级页签内切筛选不再销毁正在派发事件的按钮 | 重启验收 |
| 3 | 悬停“仓库”出现没有底板的原生长 tooltip，形成漂浮英文说明 | 移除已有可见标签上的冗余原生 tooltip；说明继续由卡片、摘要和状态底板承载 | 重启验收 |
| 4 | 出勤配置点击“地图”后，长筛选条因 hover→focus 连锁滚到末端，当前选中项不可见 | 取消移动筛选条上的 hover 抢焦点；按按钮实际边界确定性计算最小滚动量；增加前端→末端→前端 runner | 重启验收 |
| 5 | 同一冻结标准全量执行 | 无失败 | PASS |

## 5 × 34 状态矩阵

每行均实际点击，并共同检查：一级 / 二级选中态、至少一个真实条目、112 px 逻辑卡片、
缩略图 / 标题 / 摘要 / 标签 / 状态分列、单结果提示底板、中文分类、摘要同步、锁定语义、
角色 / 羊皮纸 / 告示牌 / 操作牌不跳位。

| # | 一级页签 | 二级状态 | ID | Computer Use |
| ---: | --- | --- | --- | --- |
| 1 | 地图 | 全部 | `all` | PASS |
| 2 | 地图 | 常规扫雷 | `map_classic_minesweeper` | PASS |
| 3 | 地图 | 蜂窝扫雷 | `map_honeycomb_minesweeper` | PASS |
| 4 | 地图 | 特殊规则 | `map_special_rule` | PASS |
| 5 | 地图 | 已解锁 | `map_unlocked` | PASS |
| 6 | 地图 | 推荐 | `map_recommended` | PASS |
| 7 | 仓库 | 全部 | `all` | PASS |
| 8 | 仓库 | 装备 | `warehouse_equipment` | PASS |
| 9 | 仓库 | 消耗品 | `warehouse_consumable` | PASS |
| 10 | 仓库 | 藏品 | `warehouse_collectible` | PASS |
| 11 | 仓库 | 特殊物 | `warehouse_special` | PASS |
| 12 | 仓库 | 状态 | `warehouse_status` | PASS |
| 13 | 申领 | 全部 | `all` | PASS |
| 14 | 申领 | 可购买 | `claim_purchase` | PASS |
| 15 | 申领 | 可领取 | `claim_receive` | PASS |
| 16 | 申领 | 可回收 | `claim_recycle` | PASS |
| 17 | 申领 | 未解锁 | `claim_locked` | PASS |
| 18 | 申领 | 推荐 | `claim_recommended` | PASS |
| 19 | 目标 | 全部 | `all` | PASS |
| 20 | 目标 | 可接 | `objective_available` | PASS |
| 21 | 目标 | 委托 | `objective_commission` | PASS |
| 22 | 目标 | 地图匹配 | `objective_map_match` | PASS |
| 23 | 目标 | 未解锁 | `objective_locked` | PASS |
| 24 | 目标 | 奖励类型 | `objective_reward` | PASS |
| 25 | 出勤配置 | 全部 | `all` | PASS |
| 26 | 出勤配置 | 地图 | `loadout_map` | PASS |
| 27 | 出勤配置 | 目标 | `loadout_objective` | PASS |
| 28 | 出勤配置 | 装备 | `loadout_equipment` | PASS |
| 29 | 出勤配置 | 消耗品 | `loadout_consumable` | PASS |
| 30 | 出勤配置 | 特殊物 | `loadout_special` | PASS |
| 31 | 出勤配置 | 背包容量 | `loadout_bag` | PASS |
| 32 | 出勤配置 | 合法性 | `loadout_validity` | PASS |
| 33 | 出勤配置 | 开始 / 继续 / 放弃 | `loadout_intent` | PASS |
| 34 | 出勤配置 | 许可接口 | `loadout_permission_interface` | PASS |

## 全局可见验收

| 项目 | 结果 |
| --- | --- |
| 真实主菜单进入 ART22 | PASS；从 `main.tscn` 点击“出发探索”进入 |
| 左侧返回主菜单 / 长期系统 | PASS；均走现有 AppShell 路由 |
| 外观 / 时装 | PASS；进入长期系统收藏 / 外观模块 |
| 确认出发 | PASS；实际进入现有可玩局，非 `preview_only` |
| 四页摘要 | PASS；摘要 / 配置 / 效果 / 风险各四行均在独立底板内 |
| 羊皮纸收起 / 展开 | PASS；0.28 s 短缓动，背景完整显露并精确复位 |
| 出勤配置长筛选 | PASS；最后两项完整、自动滚入、左右入口可回到前端 |
| 进行时测试状态 | PASS；显示“继续探索 / 取消当前探索” |
| 取消弹窗 | PASS；遮罩阻断、真实确认禁用、Esc 返回且运行仍在 |
| 键盘 | PASS；方向键邻接、Return 激活、Tab 后选中态保持 |
| 卡片末端 | PASS；地图全部列表滚至末卡，无尺寸漂移 |
| 动效 | PASS；连续观察 12.4 s，角色慢呼吸 / 眨眼 / 间歇侧看，环境光源与粒子不漂浮到 UI，告示牌仅轻摆 |

进行时界面使用项目内既有 `art22_deploy_prep_capture_runner.gd` 的可见
`active_run` 测试状态接受 Computer Use；它只注入展示快照，不伪造持久化或放弃成功。
真实主路由和真实“确认出发”另在 `main.tscn` 实例中可见验证。

## 自动化与回归

| 检查 | 结果 |
| --- | --- |
| `art22_deploy_prep_runtime_runner.gd` | `PASS tabs=5 secondary_states=34 summary_pages=4 states=expanded,collapsed,active_run,cancel_modal character_frames=8 ambient_tracks=10` |
| `art22_deploy_prep_main_route_runner.gd` | `PASS host=main.tscn route=main_menu_to_deploy shell=DeployPrepShell` |
| `tools/validate_art22_deploy_prep_final_ui.ps1` | PASS |
| ART21 主菜单场景 | PASS |
| ART21 UI placement | PASS |
| G39 navigation boundary | PASS |
| ART17 layering | PASS |
| Python builder compilation | PASS |
| `git diff --check` | PASS |

I0 的最终 `head` 模式报告在提交后生成；其历史 `PASS_WITH_NOTES`、退出清理提示和安全
不符合记录继续有效，不被 ART22 覆盖。

## 资产与证据

- ART22 运行时资产：57 个 PNG；默认挂载 36 个。
- 默认保守解码：8.18 MiB；总量 9.36 MiB。
- Manifest：388 行、17 列、唯一 ID。
- 5 张 34 状态矩阵联系表：`docs/art/validation/art22/filter_matrix/`。
- 12 张状态 / 五分辨率截图：`docs/art/validation/art22/screenshots/`。
- 6 张动作时序截图：`docs/art/validation/art22/motion/`。
- 17 行 motion contract：`deploy_prep_motion_contract.csv`。
- 运行时资产报告与哈希：`deploy_prep_runtime_asset_report.csv` / `.json`。

## 未扩大声明

ART22 只关闭“出发探索最终美术 UI”。完整 MVP、长期系统最终美术、真实继续 / 放弃持久化、
完整奖励与许可消耗、全游戏人工游玩、性能、导出、CI 和发布仍未因此自动通过。
