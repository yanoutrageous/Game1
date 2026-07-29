# I4 工程质量标准审计

文档状态：`QUALITY_STANDARD_AUDIT_PASS / IMPLEMENTED_CANDIDATE / EXTERNAL_GATES_BLOCKED`

审计时间：2026-07-30

审计对象：
`docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md`

标准 ID：`I4-QA-FROZEN-1`

## 1. 审计结论

`I4-QA-FROZEN-1` 可以作为 I4 后续实现和验收的规范性质量门。该结论只表示标准本身已经：

- 覆盖当前 I4 范围；
- 给出可判定对象和阈值；
- 接入当前权威文档；
- 区分机器、真实渲染、人工、动态、存档、设备和 Git 证据；
- 登记当前用户截图为 FAIL 反例；
- 将边框过宽纳入 I4.7 硬要求和修复计划。
- 将后续局内反馈作为增量重审接入原 I4.5/I4.7，未删除或放宽此前任何要求。

该结论不表示任何生产页面、runner、截图、输入、存档、设备或 I4 阶段已经通过。

## 2. 输入证据

审计读取：

- I4 总契约、需求矩阵、执行台账、运行手册和活动阶段入口；
- I2 验证/人工复核计划；
- ART22、ART23、ART24、ART25 历史验收；
- 当前 Godot 布局合同、字体 token、Deploy 卡片/摘要候选实现；
- 用户 2026-07-30 Deploy 生产截图；
- 用户新增的边框过宽反馈；
- 用户允许的 `E:\UE` 只读参考。
- 用户后续补充的折叠/展开地图遮挡、房间中央隐形阻挡、协议遮挡、左下宽间距、
  物品/背包品质色和地面掉落缺图反馈；
- 当前 `minimap_panel.gd`、`map_overlay_panel.gd`、`g41_room_runtime_view.gd`、
  `g41_interactable.gd`、`g41_ground_loot_entity.gd`、`run_surface.gd`、
  `art24_item_visual_catalog.gd` 和 `item_rarity_descriptor.gd`。

当前截图：

```text
sha256=1F85061F1C90B1E6B3F673F8519399B8094FD2499B0F4004DB9BCEBD4C3E0C51
result=VISUAL_FAIL
```

UE 只读参考只支持“主框保留美术身份、内层降低边框重量”这一层级原则；其 1536×864
布局、模块、资产、数据和输入没有进入 Godot 标准或 PASS 证据。

## 3. 原计划缺口与修正

| 原缺口 | 风险 | 当前修正 |
| --- | --- | --- |
| “无文字遮挡”没有定义遮挡 | Label rect 不越界仍可能被框/装饰盖住 | 定义 R/S/G/V/H/F/P、0 可见交叠、0.5 逻辑计算容差和 1 设备像素失败 |
| “字体清晰”没有字形门 | 混合字体、非整数缩放和 fallback 可漏检 | 统一中文角色、字号下限、影边/笔画/空腔/对比度门 |
| “间距合理”没有密度 | 72 px 单行摘要也可被机器判绿 | 单行 34–46、双行 47–64、间距 4–8、首屏 6 项 |
| “摘要可滚动”没有内容门 | 只有四条旧信息也能滚动 | 固定四页信息库存，速览首屏六项且不得重复/错栏 |
| 没有边框重量规则 | 多层九宫格挤压内容并放大噪声 | 页面/工作区/卡片/紧凑 16/8/4/2、比例门、最多两层完整框 |
| 自动截图与人工 PASS 混用 | 捕获成功被误写为视觉通过 | 机器最高 `VISUAL_CANDIDATE`，逐原图后才 `VISUAL_PASS` |
| 只抽代表页面 | 其他现有内容缺陷被隐藏 | 当前内容普查、布局等价证明、基线全量与高风险扩展 |
| 测试场只验隔离 | 诊断层可能遮挡生产 UI | 同源、28%/75%、默认收起、零关键遮挡、焦点归还 |
| 操作链只靠描述 | 重复详情/确认无法判案 | 明确动作计数和八类关键任务预算 |
| 旧测试可直接改 expected | 回归被静默删除 | 三类断言处置和强制 replacement gate |
| 地图只写“不要遮挡” | 子层越格、同格争中心、背景 HUD 穿透无法区分 | 固定四层 z、cell clip、语义/计数分配矩形和模态承载板阈值 |
| 房间阻挡没有来源门 | 背景/贴图缺失后玩家仍撞到匿名矩形 | 稳定 obstacle descriptor、90% 足迹覆盖、缺图/退场同事务 |
| 协议只验节点矩形 | 真实框边侵入文字与压力条仍可漏检 | 按实测 B+6/最小 14 计算 S，极值文案和模态组合 |
| 左下只写“紧凑” | 空包仍保留固定大列表槽 | 0/1/3/4/满包内容驱动高度和 8/16 px 空白带门 |
| 品质只写“颜色冗余” | 各表面近似色、焦点覆盖品质、世界掉落固定青色 | 冻结 sRGB、1/255 色差、name/border/beam/自然语言配对 |
| 缺图只验节点存在 | `ArtVisual.texture=null` 时 fallback 被错误隐藏 | resolver 清单、texture 非空/尺寸、显式 fallback 与缺失注入 |

## 4. 可判定性审计

| 范围 | 对象 | 阈值 | 根因/修复 | 复验 | 结论 |
| --- | --- | --- | --- | --- | --- |
| 遮挡 | R/S/G/V/H/F/P | 可见交叠 0；浮点 0.5；截图 1 px 即失败 | 13 类根因；10 步无损顺序 | 按共享消费者扩大 | PASS |
| 边框 | page/pane/card/compact | 16/8/4/2 + 比例 + 两层 | 资产/嵌套/状态叠框；B1–B7 | 全消费者、12 组、状态配对 | PASS |
| 字体 | 中文/数字/键位 | token 下限、4.5:1/3:1、整数 scale | 字体度量/fallback/scale | 全玩家页面 | PASS |
| 摘要 | 四页内容与行 | 34–46、4–8、首屏六项 | 空占位/错误投影/固定高度 | model + scroll + 12 组 | PASS |
| 卡片/数量 | 两行与单一语义 | 32×32 命中、4 px 内距、H 零交叠 | stepper/卡框/缩放 | 所有数量消费者 | PASS |
| 操作链 | 八类玩家任务 | 每项明确最大动作 | 重复页面/确认/重定位 | 解析动作日志 + 动态 | PASS |
| 测试场 | clean/expanded/tainted | 28%/75%、零关键遮挡、默认档 hash 相同 | overlay/焦点/隔离 | 12 组 + scenario | PASS |
| 既有内容 | 当前 registry/model | 基线全量；等价失败扩 12 组 | census/layout class | coverage report | PASS |
| 证据 | AUTO/CAP/VIS/DYN 等 | 类别不可替代 | identity/manifest/failure bundle | exact candidate | PASS |
| 地图层级 | cell base/semantic/count/focus | z=0/20/30/40；越格 0；语义/计数矩形交集 0；地图板 alpha≥0.94 | spill/stack/modal；不删地图语义 | 两表面×15 状态×12 组 | PASS |
| 阻挡对应 | 每个 static obstacle | texture/visible/alpha 门；body 被 visual footprint 覆盖≥90%；未知阻挡 0 | anonymous/desync；不删玩法对象 | 全房型/门/状态/缺图/退场 | PASS |
| 协议 | title/state/track | S inset=max(B+6,14)；4/6 px 行距；G/V 零越界 | safe rect/z；不省略压力 | 五等级×0/100×模态×12 组 | PASS |
| 左下密度 | list/empty/detail/capacity | 44–56/4–8/24–30；语义间空白≤8；框尾空白≤16 | fixed empty band；不删详情/负重 | 0/1/3/4/满包/scroll end | PASS |
| 品质 | 8 状态×6 消费者 | 冻结 sRGB；通道差≤1/255；正文对比 4.5:1 | channel override；不恢复 T 码 | normal/focus/selected/blocked | PASS |
| 物品纹理 | registry item×5 消费者 | visual key/path 同一；texture 非空且尺寸>0；缺失时可见 fallback | node-without-texture/silent fallback | 全枚举+两类失败注入 | PASS |

## 5. 历史标准冲突处置

- ART22 的 112 px 卡片和四个固定 72 px 摘要框保持历史记录，不再是 I4 当前结构权威。
- ART23 的混合中文像素字体角色被当前用户截图证伪；I4 改为所有玩家可见中文统一 readable CJK。
- ART24/ART25 的全量、真实窗口和失败重启原则继续有效。
- 旧 runner 的具体断言在逐条处置完成前仍可能阻断；本审计不预先宣布它们全部过时。

## 6. 治理测试

当前可执行：

```powershell
python -m unittest tools.i4.tests.test_i4_quality_standard
```

审计运行结果：

```text
tests=12
result=PASS
```

覆盖：

- 标准 ID/状态；
- 主要章节；
- R/S/G/V/H/F/P；
- 16/8/4/2；
- 摘要和测试场阈值；
- `VISUAL_CANDIDATE` 边界；
- 当前反例；
- I4-R001–I4-R049 连续唯一；
- 当前权威文档交叉引用；
- 禁止的模糊 PASS 句式。
- 地图 z/clip/越格、碰撞 90% 足迹、协议 B/S 和左下 8/16 px 阈值；
- 八档冻结品质色、`1/255` 色差和空纹理/fallback 失败门。

该测试只证明治理结构没有漂移，不证明生产质量。

## 7. 工程门执行更新

本节是标准冻结后的执行事实，不反写前文“标准先于实现”的审计时序。

已完成定向门：

- 156 行当前内容普查，覆盖 Deploy 5 页/13 筛选、长期 6/25/58、6 房型和 6 测试场景；
- R/S/G/V/H/F/P、边框预算、字体角色、摘要六项、数量器、地图四层、协议 B/S、
  左下 0/1/3/4/满包、品质/纹理枚举和缺失注入；
- 测试场设置入口、CLEAN/TAINTED、默认档哈希、读写分区、失败包、焦点/移动输入门；
- obstacle descriptor、全房型扫描、可见足迹、缺图/退场同步；
- Deploy 12 状态、长期 25 页面和生产 14 高风险状态真实 Windows renderer 捕获；
- 关键 runner 6×10 独立进程和局外生产旅程 3×重复；
- 统一 worktree 预检：质量测试 12/12、I4 runner 8、protected dirty 0、
  fixed-frame helper 0。

仍保持未关闭：

- 非 Deploy 四分辨率×三 UI 比例全状态逐原图、动态输入与玩家体验门；
- 测试场 clean/expanded 的 12 组完整视觉矩阵；
- 旧失败断言全量处置；当前只登记四组 replacement gate；
- 物理手柄（当前枚举为 0）、实际听音、目标 GPU 长局性能和动态玩家验收；
- 候选提交后的 clean exact-head/full、push 和远端 SHA。

## 8. 审计判定

```text
quality_standard=PASS
production_visual=VISUAL_CANDIDATE
production_functional=TARGETED_PASS
i4_stage=ACTIVE
stage_acceptance=BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE
next_gate=commit + exact-head/full + push, while external gates remain open
```

## 9. 局内补充的八字段完整性审计

| 规则 | 对象/前置 | 测量/失败阈值 | 根因/修复顺序 | 信息保护/复验 |
| --- | --- | --- | --- | --- |
| MAP | 每个 cell；折叠/展开；15 状态；12 组 | 子层 R/V/z/clip；越格 1 设备像素失败；语义与计数分配矩形交集 >0 失败 | clip/offset → 分配矩形 → z → 图标尺寸 | 不删玩家/房型/计数/选择；两表面全复验 |
| COLLISION | 全房型、门、对象状态、缺图/退场 | descriptor 完整；texture/visible/alpha；body 覆盖 <90% 或未知阻挡 >0 失败 | 来源 → 纹理门 → 状态事务 → 足迹 | 不删玩法必需对象/碰撞系统；全房型+攻击/门回归 |
| PROTOCOL | 五等级、压力 0/100、全部模态、12 组 | 实测 B/S/G/V/H；任一越界/交集/错误命中失败 | 安全内边距 → 行布局 → 层级 → 框尺寸 | 不省略等级/状态/压力；所有 HUD 模态 |
| LEFT_DENSITY | 0/1/3/4/满包、长名、150% | 行/空态/详情/footer 高度；语义间 >8 或框尾 >16 失败 | 内容高度 → 空列表收起 → 详情 → footer → 外框 | 不删物品/详情/负重/scroll；12 组 |
| RARITY | 8 品质、6 消费者、4 状态 | sRGB 每通道差 >1/255、品质被 focus/blocked 替代或缺自然语言失败 | 描述器 → name/border/beam → focus/failed 分层 | 不恢复 T 码，不删名称/数量/类别/实例；全配对 |
| TEXTURE | 当前全 item ID、五消费者、两类缺失注入 | key/path 不同、texture null/0 size、空本体或静默 fallback 即失败 | 映射 → 资源 → resolver → fallback → 消费者 | 不用无关图静默掩盖；全枚举+世界动态 |

六条规则均明确了对象、前置、测量、阈值、根因、修复顺序、信息保护和复验范围；不存在
仅以“遮挡”“太宽”“缺图”“颜色不明显”等宽泛描述关闭缺陷的路径。

## 10. 计划重排审计

重排只改变执行依赖，不改变既有结果集合：

- I4-R001–R042 原样保留；新增要求从 I4-R043 连续编号。
- Deploy 截图的 `VISUAL_FAIL`、I4.4/I4.7 重开和 B1–B7 边框计划继续有效。
- I4.5 原有实例聚合定向证据保留，但不能豁免新增 I4.5B。
- 共享视觉基础 I4.7A 前置于消费者，是为避免 Deploy/局内/长期分别维护近似色表、
  纹理 resolver 和地图格规则；它不授权重写页面。
- I4.8 仍是唯一关闭路径；任何定向通过都不能跳过真实渲染、动态、存档、exact-head、
  阶段审计和 push。

治理测试已于 2026-07-30 以 12/12 通过；P1–P8 随后形成
`TARGETED_PASS / VISUAL_CANDIDATE`，但 P8 的全矩阵和 P9/external gates 尚未关闭。
因此本节只允许把当前版本称为“活动候选”，不能称为 I4 阶段 PASS。
