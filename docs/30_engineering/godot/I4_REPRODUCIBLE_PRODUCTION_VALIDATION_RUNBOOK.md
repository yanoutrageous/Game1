# I4 可复现生产验证操作手册

文档状态：`ACTIVE / FOUNDATION`

规范性质量标准：
`docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md`

## 1. 权威路径

```text
repo_root = git rev-parse --show-toplevel
godot_project = <repo_root>/Godot/GraytailGodot
i4_tools = <repo_root>/tools/i4
```

不得使用历史盘符选择仓库。Godot 路径必须来自参数、专用环境变量或已验证 PATH。

## 2. 标准循环

1. 记录 commit/tree、Godot 版本、renderer/GPU/OS、profile、scenario 和 seed。
2. 核对 `I4-QA-FROZEN-1` 未被候选实现反向放宽。
3. 生成当前内容普查和布局等价类；不能到达的状态立即失败。
4. 重置 `dev_sandbox`，记录默认 profile 的语义哈希。
5. 从公开生产入口加载场景，不调用私有 UI 方法伪造状态。
6. 通过解析后的键鼠/手柄动作执行输入，并记录动作计数。
7. 等待领域状态、公开信号或可查询 UI 状态成立。
8. 等待字体已加载、alpha=1、tween 结束且关键几何连续三次渲染提交稳定。
9. 保存 R/S/G/V/H/F/P 几何、状态快照、日志、原尺寸截图和存档哈希。
10. 先运行机器捕获门；成功状态只写 `VISUAL_CANDIDATE`。
11. 按原尺寸逐图人工复核，再运行真实窗口动态/输入门。
12. 退出并重置 sandbox，再次校验默认 profile 哈希。

## 3. 禁止

- 用固定帧等待代替关键状态完成。
- 直接写玩家坐标、金币、实例、结果页或保存内容作为最终生产证据。
- 用静态截图生成成功宣称交互、手感或动态视觉通过。
- 在默认 profile 上执行修改状态的 debug 命令。
- 忽略单次偶发失败后只保留下一次通过结果。
- 把联系表、缩略图、自动 OCR/几何 PASS 或 headless 输出当作逐原图视觉 PASS。
- 用“清晰”“合理”“无明显遮挡”等没有边界和阈值的文字关闭缺陷。
- 通过缩字号、删信息、增加无意义滚动或扩大控件来保留过宽边框。
- 只修改旧测试期望而不登记旧断言的权威/替代处置。

## 4. 失败包

每个失败目录至少包含：

```text
identity.json
actions.json
state_before.json
state_after.json
save_before.json
save_after.json
focus_modal.json
runtime.log
failure.png
reproduce.ps1
```

`identity.json` 必须含 commit、tree、Godot 版本、scenario、seed、profile、
save target、输入索引、runner 版本、renderer、GPU、窗口、UI 比例和 locale。

`geometry.json` 至少包含每个被检查控件的：

```text
state_id
node_path
layout_class
R
S
G
V
H
F
P
font_asset
font_size_requested
font_size_actual
border_width_top_right_bottom_left
border_nesting_depth
scroll_reachable
```

任一字段无法采集时保持 `NOT_RUN`，不得用节点矩形替代字体墨迹或可见纹理边界。

## 5. 重复门

- 定向关键场景连续 10 次，其中至少 3 次从新 Godot 进程启动。
- 完整局外生产旅程连续 3 次。
- 一旦中途失败，连续计数清零，并保留失败包。
- 状态一致性以领域/保存语义哈希为主；包含时间或动画相位的像素截图不要求逐字节相同。

## 6. 视觉矩阵执行

硬矩阵是 4 个窗口尺寸 × UI 100/125/150%。执行顺序：

1. 1280×720@100% 捕获内容普查的每一行。
2. 1280×720@150% 捕获每一布局类及全部 long/extreme/overflow/error 状态。
3. 其余 10 组捕获每个主页面、布局类和高风险状态。
4. 布局等价证明失败的类扩展为每个内容行 × 12 组。
5. 每个状态同时保存原图、identity、geometry 和 SHA-256。

视觉原图必须来自真实 Windows renderer。headless 只允许运行领域、静态和结构门。
联系表仅用于定位，审查者必须打开原图 100% 检查。

## 7. 遮挡与边框复核

逐图先检查文字墨迹 `G` 是否位于安全区 `S`，再检查兄弟可见边界 `V`、命中区 `H` 和焦点
边界 `F`。任何持续可见的 1 设备像素裁切或交叠都登记失败。

边框按组件级别测量单边可见带宽：

```text
page <= 16
pane <= 8
card/summary/button <= 4
compact/stepper/badge <= 2
```

同时检查比例门和最多两层完整框。normal、focus、selected 必须成组对照；状态描边不得让总边框
增加超过 2 逻辑像素。失败按标准中的根因码登记，并写明信息无损修复顺序与复验范围。

### 7.1 地图层级门

分别从真实 RunScene 打开折叠小地图和展开地图，覆盖标准 10.4.1 的 15 个状态。每个 cell
记录：

```text
cell_rect
cell_safe_rect
clip_contents
base_rect/z
semantic_rect/z/visual_key
count_rect/z/text
focus_rect/z
cross_cell_visible_intersection_px
semantic_count_rect_intersection
```

自动门要求局部 z 精确为 0/20/30/40、越格像素 0、语义/计数分配矩形交集 0。展开地图另记录
content backing alpha、dimmer alpha、背景 HUD mouse filter 和 focus owner。自动通过仍只产生
`VISUAL_CANDIDATE`；人工必须查看相邻格边缘、玩家+计数、focus/selected 和地图板下的协议。

### 7.2 阻挡—可见物门

从 `build_read_only_snapshot()` 导出每个 obstacle 的完整描述器，不接受只有 `Rect2` 的记录。
按不大于玩家半径一半的网格步长扫描可行走区，对每个被拒绝点保存返回的 `obstacle_id`，
再核对：

```text
texture_resolved=true
visual_visible=true
final_alpha>=0.25
body_center_in_visual_footprint=true
intersection_area/body_area>=0.90
```

依次执行 Normal、Monster 战斗前/中/清场、Chest 关/开/空、Event 可用/完成、Mine
隐藏/触发/解除、Exit 不可用/可用和四向门锁定/解锁。再注入可选装饰缺图和必需交互物缺图：
前者必须关闭碰撞，后者必须出现对齐 fallback 或在取得控制前失败。任何未知阻挡、隐形碰撞
或视觉/碰撞跨稳定提交不同步均立即保留失败包。

### 7.3 协议与左下密度门

协议 geometry 报告必须包含真实边框 `B`、按 `max(B+6,14)` 计算的 `S_protocol`、标题/状态
字形 `G`、压力条 `V` 和全部 `H`。执行五等级、压力 0/100、地图/库存/掉落/暂停模态和
12 组矩阵。

左下物品簇执行 0/1/3/4/满包。报告每行、空态、详情、负重和承载框 `R`，以及相邻空白带。
0–3 件时不得存在固定空 ScrollContainer；4 件起验证三完整行和末端滚动。语义间空白 >8 px
或负重后框内空白 >16 px 立即失败。

### 7.4 品质与纹理门

从当前 registry 枚举全部 item ID。对每个 item 在 Deploy、背包快捷列、库存、地面列表、
世界掉落和结果记录 requested/resolved visual key/path、texture size、fallback 和品质描述器。
同一物品跨消费者的 key/path 必须一致，纹理非空且宽高 >0。

品质色逐通道与标准表比较，容差 `1/255`。配对捕获 normal/focus/selected/blocked，确认
focus/失败不覆盖品质；世界物品原纹理不着色，光束/地环采用品质色，详情显示自然语言。
另注入不存在的显式路径和未知 item ID，分别验证可见 fallback+诊断与有记录的类别 fallback。
出现“只有光束、没有物品本体”或 `ArtVisual.texture=null` 但占位隐藏，立即失败。

### 7.5 增量重审后的执行依赖

执行顺序冻结为：

```text
P0 supplement audit
P1 sandbox/diagnostics
P2 quantity/domain
P3 shared visual foundation
P4 Deploy
P5 in-run instance semantics
P6 collision/assets/world drop
P7 long-term
P8 cross-surface visual/input matrix
P9 full/exact-head/audit/push
```

P3 的共享字体、边框、品质或 resolver 变更会使 P4–P8 的旧视觉证据失效；P6 的碰撞/对象变更
会使全房型、门、攻击裁切和结算相关旧证据失效。失效证据保留历史身份，但不能继续计入候选。

## 8. 旧测试处置

任何历史 runner 失败后，先逐断言生成处置记录：

```text
assertion_id:
historical_requirement:
current_runtime_fact:
disposition: STILL_AUTHORITATIVE | SUPERSEDED_WITH_REPLACEMENT | INVALID_WITH_EVIDENCE
replacement_requirement:
replacement_runner_or_visual_gate:
evidence:
```

没有 replacement gate 的 `SUPERSEDED_WITH_REPLACEMENT` 无效。处置完成前不得删除断言或只改 expected。

## 9. 视觉审查记录

每张原图的记录至少包含：

```text
image_sha256:
state_id/layout_class:
resolution/ui_scale:
rules_checked:
actual:
status:
failure_bbox:
severity:
root_cause:
retest_scope:
reviewer/time:
```

截图生成成功、自动几何通过和人工视觉通过必须是三个独立字段。

## 10. C/E 盘验证存储收口

存储整理只能使用“精确目标清单”，不能按盘符、仓库根目录、通配目录或“看起来较旧”
批量删除。执行顺序：

1. 记录 C/E 盘可用字节和目标目录的精确字节数；
2. 将最终候选报告、唯一失败反例、来源包、用户档、Git stash、CAS/index、恢复证明和
   正在使用的 worktree 登记为保留项；
3. 逐项校验待删目录的绝对路径、身份和处置理由，只允许删除可重建镜像、已中断输出、
   已被正确候选取代的重复捕获及治理脚本明确判定可裁剪的历史运行产物；
4. 删除后复核保留项仍可读取，记录每个目标的实际回收字节和 C/E 盘可用字节变化；
5. 最终 exact-head/full 与 exact-head 矩阵形成后再执行末轮复量，避免把最终证据当缓存清除。

若候选目录同时含最终报告或唯一失败证据，必须先保留该文件及其身份/哈希，不能因目录整体
可重建而一并删除。任何来源包、用户存档、Git stash、CAS/index、恢复证明、当前工作区或
正在运行的编辑器目录均不属于 I4-R050 的删除范围。
