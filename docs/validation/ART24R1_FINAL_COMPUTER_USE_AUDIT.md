# ART24R1 最终 Computer Use 验收报告

- 验收标准：`ART24R1-FINAL-CU-FROZEN-1`
- 标准冻结顺序：先冻结验收标准，再启动本次最终 Computer Use 验收。
- 视觉基准：Computer Use 实际运行 `D:\AGAME1\external\ue_prototype\UE\Graytail\Graytail.uproject`。
- 事实基准：当前 Godot 生产入口、生产快照、`CommandBus`、房间与物品状态。
- 明确排除：旧 Godot 局内界面与 `art24_in_run_art_preview_runner.gd` 不作为视觉验收标准。
- 验收环境：Windows、Godot 4.6.3、UE 5.7；Godot 窗口以生产 `main.tscn` 启动。

## Computer Use 真实玩家路径

1. 主菜单点击“出发探索”，在部署页点击“确认出发”，进入真实局内。
2. 检查左侧扫描/资源/作业/背包摘要、中央房间、右上协议/压力、底部横向键位条。
3. 分别输入 `D` 与 `S`，验证水平、垂直位移及对应朝向；再连续移动到右侧房门。
4. 穿过房门进入相邻房间，角色从对应入口出现；小地图位置和压力状态同步更新。
5. 在可搜索房间输入 `E`，检查回收结果面板；确认后检查房间中的世界掉落实体、光柱、名称、估值和 `G` 提示。
6. 输入 `G` 打开地面回收，点击真实“拾取”；地面数量由 1 变 0，背包由 0 变 1，命令结果更新。
7. 关闭地面回收，确认世界实体与提示消失；输入 `Q`，在背包中检查同一真实物品及使用/丢弃状态。
8. 关闭背包后输入 `M`，检查大幅扫描地图；输入 `Esc` 关闭地图，再输入 `D`，确认局内移动恢复。

## 冻结标准逐项结论

| 项目 | 结论 | 证据摘要 |
| --- | --- | --- |
| A. 真实入口与主构图 | PASS | 经生产主菜单和部署页进入；局内形成 UE 原型同类的左侧固定信息、中央房间主视觉、右上窄状态、底部横向键位层级。 |
| B. 移动、方向与房间切换 | PASS | 单次水平/垂直输入均产生可见位移和朝向；连续移动可跨门，角色从相邻入口出现；小地图与压力同步。 |
| C. 搜索、结果与世界掉落 | PASS | `E` 返回 2 件、总估值 40 的真实搜索结果；面板确认后，世界中出现由 `room_floor_items` 驱动的实体、光柱、名称、估值和提示。 |
| D. 地面回收与背包闭环 | PASS | Computer Use 点击拾取后地面 1→0、背包 0→1；关闭面板后世界掉落消失；`Q` 中出现同一物品，操作状态清楚。 |
| E. 大地图与连续界面 | PASS | `M` 打开居中 10×10 全屏扫描层；地图、背包、地面回收、结果框互斥；关闭地图后 `D` 移动恢复。 |
| F. 技术与污染守卫 | PASS | G41 与 ART24R1 验证通过；干净生产启动无脚本/解析/Unicode 警告；`.gdignore` 阻止验收 CSV 生成二进制翻译副产物，最终污染检查通过。 |

## 与 UE 原型的客观对照

- 对齐的是空间权重与反馈顺序，不是逐像素照搬：左侧固定信息约占窄栏，中央房间保留最大面积，右上协议/压力仅占短条，底部键位保持横向分段。
- 搜索结果采用 UE 原型的“压暗场景 + 居中金属结果板 + 摘要 + 物品卡 + 底部确认”层级。
- Godot 继续使用自身生产分辨率、现有房间资产、真实状态字段和输入体系；运行时代码不依赖 `D:\UE` 或外部克隆路径。
- 旧 Godot 界面只提供了既有操作入口和状态语义，未被用作视觉通过依据。

## 两轮问题驱动优化

### 第一轮

- 把 ART24 从隔离预览接入生产主流程，恢复真实房间内移动和房门切换。
- 新增快照驱动的世界掉落表现与 UE 式回收结果面板。
- 初次 Computer Use 审计发现：旧内框层级过多、正文被压缩、底部键位识别弱、地图说明区拥挤。

### 第二轮

- 不改变核心结构，改为扁平金属信息分区，扩大可读字号和有效内容面积。
- 重做底部横向键位分段、地图标题/详情/页脚区，修正覆盖与压字。
- 补齐更稳定的离散键盘输入桥和四阶段移动帧序列，调低单步位移以保证实际操控与跨门连续性。

## G41 程序同步后的完成审计与返工

- 远端在封口前新增程序分支 `godot/g41-in-run-core-gameplay-runtime`（`7fc32fe`）。直接推送旧树会造成 `run_scene.gd`、角色移动和世界掉落实体重复，因此先合入 G41，再重跑验收。
- ART24R1 不再生成独立世界掉落 presenter；图标、拾取光效、名称/估值和焦点反馈直接挂到 G41 的唯一 `G41GroundLootEntity`。
- 第一次合并后 Computer Use 判定失败：G41 普通房间中央障碍与 `(0.5, 0.5)` 出生点重叠，角色只有朝向变化而没有合格位移。修复为左侧安全地面出生后，重新从生产主菜单完整验收并通过。
- 新增共享 `G41RuntimeLayout`，统一角色、障碍、交互物、敌人、投射物和门锁提示使用的房间矩形，避免后续美术改尺寸后碰撞与图像漂移。
- 角色动画在保留四阶段行走循环的同时接入 G41 的 `attack_windup / attack_active / attack_recovery / hurt / dead` 稳定状态；程序逻辑不依赖贴图尺寸。

## 自动验证

- Godot headless project-load/parser：PASS；无 `SCRIPT ERROR`、`Parse Error` 或 `Compile Error`。
- `M3_MINIMUM_ITEM_DROP_LOOP=PASS`
- `M3R_ITEM_USABILITY_COMPLETION=PASS`
- `M3H_ITEM_LOOP_HARDENING=PASS`
- `M5_ITEM_DROP_LOOP_FULL_CONTENT=PASS`
- `G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS`，覆盖 30/60/144 Hz 与 hitch 调度、四类怪物及 `g41.runtime_visual.v1`。
- 上述 runner 均以退出码 0 完成；Godot 退出清理阶段仍报告既有的 ObjectDB/resource leak 警告。该警告不属于脚本解析、生产运行或断言失败，已单独记录，不将其伪装为不存在。
- ART24R1 结构与污染验证：`ART24R1_UE_GAMEPLAY_UI_VALIDATION=PASS_STRUCTURAL`。
- 干净生产启动：PASS；无 `SCRIPT ERROR`、`Parse Error`、`Compile Error` 或 Unicode/NUL 解析警告，验收合同目录不再生成 `.translation` / `.import` 副产物。

## 提交与远端状态

- 门禁结果：全部验收项先于提交 PASS，随后才执行 commit/push。
- 实现与验收合并提交：`1b6985e74297ca3887f5c2282d136e7894aa41d0`。
- 合并父提交：ART24 `d5d5a42d909d0326b17d5651a8053dc1b15d595c`，G41 `7fc32feccda1005d11b7eb514e88c540133af136`。
- 远端分支：`origin/art/art24r1-ue-parity-gameplay`；首次推送后以 `git ls-remote` 验证远端头为 `1b6985e74297ca3887f5c2282d136e7894aa41d0`。
- 本次仅补充提交号与远端事实的审计封口文档将作为后续纯文档提交继续推送到同一分支，不改变生产代码和验收结论。

## 最终结论

当前结论：`PASS`。冻结标准 A-F 全部通过，允许进入 commit/push；旧 Godot 界面与隔离 runner 未被用于视觉通过判定。
