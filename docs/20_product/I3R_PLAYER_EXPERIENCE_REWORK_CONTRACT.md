# I3R 玩家体验与基础治理返工总契约

阶段状态：`ACTIVE / I3R5_I3R6_I3R7_TARGETED_GATES_PASS / FINAL_FULL_DEVICE_AND_PLAYER_PASS_PENDING`
授权来源：用户明确要求在已结束 I3 的基础上完成 I3 返工。
入口提交：`35189aaf524157761d1ab9cdddc39e76baa0d7ca`
活动分支：`codex/i3r-player-experience-rework`

## 1. 目标

I3R 不改写 I3 的历史关闭记录。它以 I3 为返工基线，解决已被玩家运行反馈证伪或
未被 I3 验收覆盖的问题，并形成后续增量开发可以快速预览、操作和测试的生产基线。

本阶段必须同时覆盖：

- 程序：模块边界、输入与弹层权威、状态转换、战斗攻击与命中、空间碰撞、性能；
- 美术与体验：字体、边框材质、文本安全区、角色与敌人动画、对象状态、动效和音频；
- 页面：主菜单、出发探索、长期系统、设置、局内 HUD/地图/背包/交互/特殊房/结果；
- 教程：作为普通 Deploy 地图目录中的一个教学地图项，不建立独立玩家入口、独立教程页面或
  独立运行接口；
- Base 与治理：原始策划案、素材语义、精确去重、许可、运行时准入、当前文档口径。

## 2. 权威顺序

1. 当前 I3R 工作树中的 Godot 生产代码和可见运行结果；
2. 用户本轮及此前玩家反馈；
3. I3 关闭提交中的行为、来源和回归证据；
4. `E:\UE\Game` 的 Lua/UE 原型仅作体验与内容证据；
5. `sources/base/原始策划案` 仅作完整原始策划来源，冲突时不得覆盖当前代码事实。

UE 的体验结构可以迁移，但不得复制其旧领域、存档、硬编码按键或独立教程入口。

## 3. 不可回退边界

- 出发地图保持同页双栏；不得恢复“区域 → 难度”分步页面。
- 教程是普通地图 catalog 中的 `tutorial_5x5` 项；`mode=tutorial` 只选择教学内容
  规则，并继续使用普通地图选择、详情、摘要和启动链。
- KnownMap、60 Hz fixed tick、swept projectile、GroundLoot、容量替换、结算幂等和
  保存权威不得被 UI 或动画接管。
- UI 可读性缩放只能改变生产 Control 的字体、间距和安全区；不得把
  `Window.content_scale_factor` 当 UI 缩放并同时放大世界、背景和逻辑画布。
- 角色和敌人的帧动画、动画集或未来骨骼呈现只消费玩法状态；不得反向改变 fixed
  tick、攻击起点/方向、命中几何、碰撞、房间状态或存档。
- `sources/base/原始策划案` 的 25 份原件保持原名、完整信息和来源 SHA。
- 精确重复按 SHA 折叠；同名不同内容不得覆盖，同内容不同语义不得丢失 alias。
- 不把自动化、静态截图或资源 SHA 正确扩大解释为最终玩家体验完成。

## 4. 内部门

| Gate | 范围 | 必须交付 |
| --- | --- | --- |
| I3R.0 | 身份、范围、基线 | 本契约、执行台账、需求矩阵、I3 exact entry、基线回归 |
| I3R.1 | 共享脊柱 | 输入上下文、弹层优先级、导航/运行草稿、对象/物品/结果呈现合同及 `RunSceneModalController` |
| I3R.2 | 字体与 UI 构成 | 字体许可与角色、材料 token、逐素材九切与安全区、文本交叉门 |
| I3R.3 | 战斗与运动 | 攻击缓冲、攻击期判定/扇区/贴图朝向同源锁定、近战绕障、命中与视觉裁剪几何、投射物/激光、反馈与性能 |
| I3R.4 | 局内体验 | 箱门、搜索、掉落、地图、背包、HUD、特殊房、撤离、结果 |
| I3R.5 | 局外体验 | 主菜单、同页 Deploy、仓库/申领、长期系统、设置与转场；真实 `main.tscn` 局外旅程 22/22 checkpoint/PNG、36 次解析输入 |
| I3R.6 | 教程地图模式 | Deploy 目录内的 `tutorial_5x5`、固定 5×5、首通/重播、成长隔离、事件差异、地图直接操作、可关闭非阻塞提示及 2 分辨率 × 3 UI 缩放响应门 |
| I3R.7 | Base 与治理 | 语义目录、来源许可、真实消费者交叉账、alias 债；当前长期系统与历史 ART23 证据分权 |
| I3R.8 | 综合终验 | 快速预览入口、生产玩家旅程、渲染矩阵、设备/性能、full/exact-head |

这些是同一阶段的依赖门，不是可分别宣布完成的后继阶段。

当前状态统一使用以下口径：

- `IMPLEMENTED_PRODUCTION`：生产代码已有真实消费者，且对应定向门在当前工作树通过；
- `CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING`：尚缺固定生产旅程、完整缩放/设备矩阵
  或人工玩家验收，不得扩大解释为 I3R 已完成。
- `MAIN_TSCN_AUTOMATED_JOURNEY_PASS`：解析的生产输入已走完指定 `main.tscn` 路线；
  不替代真实设备、动态手感和人工玩家签收。
- `SUPERSEDED_WORKTREE_FULL_PASS`：某次 worktree full 对其快照有效，但已被后续修改
  超越；必须在冻结点重新运行才能形成当前 final full。

| 当前生产子系统 | 当前证据 | 客观状态 |
| --- | --- | --- |
| 搜索与掉落 | 首次搜索、揭示、重访稳定、靠近自动呈现、显式拾取和地面掉落权威门 | `IMPLEMENTED_PRODUCTION / CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` |
| 地图 | KnownMap、5×5 小地图、语义格、焦点/确认、外点与 Esc 关闭门 | `IMPLEMENTED_PRODUCTION / CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` |
| 背包 | 真实物品槽、滚动、悬浮/焦点详情、使用/丢弃/容量替换门 | `IMPLEMENTED_PRODUCTION / CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` |
| 特殊房与撤离 | 战斗阶段、事件、雷房首次/重访、撤离摘要与近距交互门；seed 13 生产战斗障碍旅程已覆盖预警、确定性近战绕障、攻击朝向锁定后释放、遮挡视觉裁剪/命中、结算和离房 | `IMPLEMENTED_PRODUCTION / COMBAT_MAIN_TSCN_JOURNEY_PASS / OTHER_BRANCH_DEVICE_AND_PLAYER_PASS_PENDING` |
| 结算 | 成功/失败/放弃原因、权威物品数组、现场损失、保存失败回滚与同快照重试门；Deploy-origin 放弃结果必须进入可见结果层、取得焦点且不得落入新局启动链 | `IMPLEMENTED_PRODUCTION / DEPLOY_ORIGIN_RESULT_JOURNEY_PASS / CURRENT_FULL_JOURNEY_AND_PLAYER_PASS_PENDING` |
| UI 构成与缩放 | 像素字体、UI-only 生产缩放、材质安全区、局内焦点、历史 132 例矩阵，以及长期系统三档缩放的真实截图哈希互异门 | `IMPLEMENTED_PRODUCTION / LONG_TERM_SCALE_ANTI_SELF_PROOF_PASS / FINAL_MATRIX_AND_PLAYER_VISUAL_PASS_PENDING` |
| 局外生产旅程 | 设置应用/取消/危险显示回退、Deploy 五页、批售取消后确认、长期任务/天赋/档案和三级 Esc | `MAIN_TSCN_AUTOMATED_JOURNEY_PASS / 22_CHECKPOINTS / 22_SCREENSHOTS / CODEX_SCOPED_VISUAL_REVIEW_PASS / DEVICE_AND_PLAYER_PASS_PENDING` |
| 教程 | 普通 Deploy 地图项、标准运行链、固定 5×5；真实 `main.tscn` 首通/重播旅程及 completion-only、零金币/物品/salvage 污染；合并套件覆盖事件差异、地图直接操作、可关闭非阻塞提示和 1280×720/1920×1080 × UI 100/125/150 | `IMPLEMENTED_PRODUCTION / MAIN_TSCN_AUTOMATED_JOURNEY_PASS / CURRENT_COMBINED_SUITE_PASS / DEVICE_AND_PLAYER_PASS_PENDING` |
| 长期系统治理 | 当前生产为 6 模块、25 页面、58 个运行资产；gacha 运行资产为 0，天赋使用独立 furniture；历史 ART23 6×27/58 证据保留但不作为当前生产门 | `CURRENT_LONG_TERM_GOVERNANCE_PASS / HISTORICAL_ART23_PRESERVED / FINAL_MATRIX_AND_PLAYER_PASS_PENDING` |
| Base 治理 | 1012 个语义对象、178 行 runtime 账、175 个 runtime 路径、149 个 runtime SHA、1 条显式 promotion；消费者证明 direct 47、dynamic 108、staging 6、无生产 consumer 17；2 组 alias 债已登记 | `BASE_GOVERNANCE_PASS / PLAYER_ROUTE_SIGNOFF_PENDING` |

## 5. 共享接口

生产页面应逐步统一消费以下只读或事务合同：

- `PlayerProfileSnapshot` / `ActiveRunSummary`
- `RunDraftSession` / `RunStartConfig`
- `NavigationIntent`
- `MetaActionEnvelope`
- `ItemPresentationDescriptor`
- `WorldObjectPresentationDescriptor`
- `TerminalResultSnapshot` / `PersistenceCommitState`
- `InputContext` / `InterruptionDescriptor`
- `ActionHintDescriptor`
- `PlayerFeedbackService` / `FeedbackCueDescriptor`
- `UILayout` / `UIStyle` / `Typography` / `SettingsSnapshot`

任何页面不得通过读取另一个隐藏页面节点来取得当前业务状态。

`RunScene` 的弹层 root 注册、输入盾牌路由、私有 `_focus_stack` 和首选焦点遍历由
`RunSceneModalController` 负责；RunScene 不得暴露底层可变栈，生产 `main.tscn`
接线与相邻弹层回归必须通过架构门。提取时基线为 2959 行 / 174 函数；冻结树架构门
以 2972 行 / 174 函数通过，预算上限
为 2980 / 176。`RunScene` 仍是大型协调器，后续应继续按“一个职责 + 一个特征测试”
提取，但继续减少行数不是 I3R 关闭的独立硬要求。

破坏性确认回调必须再次验证自己的 modal id 仍为栈顶；Deploy 放弃和仓库批售的
stale/wrong-top 调用必须无副作用且不能关闭另一个顶层弹层。`abandon_run` 还必须
经过 CommandBus 的严格布尔确认门；缺失、false 或非布尔确认均 fail closed。

局内空间与信息层必须继续遵守同一份构成合同：

- 房间、角色和当前交互对象是主要视觉焦点；世界悬浮窗优先停靠在房间外围，并把
  玩家、交互对象、协议卡和底栏作为硬避让区，不得以“信息完整”为由盖住交互现场。
- 局内底部的房间标签、`周围雷险`、上下文反馈带和按键栏使用共享几何分区，任意
  支持分辨率下均不得相交；悬浮窗关闭后不保留透明输入或视觉框架。
- 门的房型图源、方向裁切、轴点、显示尺寸、`body_rect`、近距提示、过门对齐和入口
  落点必须消费同一描述；碰撞框不得兼任最终贴图。当前同源定向门已通过，动态玩家
  观感仍需单独签收。
- 战斗房可见祭坛必须由同一障碍合同约束玩家移动、近战绕障、攻击判定和扇区视觉
  裁剪；攻击 windup/active/recovery 中 simulation facing、attack geometry 与角色
  贴图必须同源锁定，恢复后才可接受反向输入。持续顶住战斗封锁门只能产生一次玩家
  拒绝反馈，释放前不得重复 room-transition dispatch。敌预警、遮挡未命中、无遮挡
  命中、战斗结算和正常离房必须沿生产输入链可观察。
- `周围雷险` 按 UE 已有语义计算当前房间八邻域中的真实雷房数量，不包含当前格；
  当前格未扫描时不显示伪造数值，已知的零必须明确显示 `周围雷险：0`。
- 边框必须使用获准像素材质和逐素材安全内边距；禁止在完整外框内再叠放无语义的
  第二层完整框，也禁止文字进入角饰、描边或滚动条占用区。
- 生产 UI 缩放权威位于共享 UI 接口，并由 RunScene/AppShell 传播到实际页面。
  物理分辨率仍由生产 canvas 适配，UI 100/125/150% 不得二次缩放房间和背景。
  旧问题的根因是把 UI 缩放施加到整个 Window，同时页面仍使用未缩放的字号与固定
  偏移，因而同时造成世界裁切、塑料式拉伸边框、文字压线和焦点框错位。

字体同样是共享接口而不是逐页装饰：FusionPixel 是所有玩家可见 UI（包括设置、
原生 tooltip、物品/世界悬浮窗、确认框、下拉菜单和结果页）的默认字体；Noto Sans
CJK 只作为缺字回退或经可见可读性门批准的无障碍替代。长中文必须通过字号、行距、
换行和安全区保持可读，不能因使用像素字体重新出现裁切或边框交叉。

玩家反馈同样不得由各页面临时播放：命令确认/拒绝、搜索揭示、拾取、箱子开启、
攻击、实际命中、受伤、雷爆、敌人死亡和终局结果统一路由到
`PlayerFeedbackService`。音效只观察已发生的领域/呈现事件，不得取得玩法权威；
同一领域事件必须防重。`master_volume` 与 `effects_volume` 必须真实作用于 Master
和 Effects 总线，`haptics_enabled` 必须随设置事务保存和回滚。震动只发送到已连接
的语义手柄设备；无设备安全跳过，reduced-motion 保留必要音频并限制强震动。

### 5.1 天赋最小真实规则

现有存档、`RunStartConfig` 和局内规则已经保留天赋字段与六类真实效果 hook，I3R
不得继续把这些字段作为不可操作的预览接口。长期系统新增“天赋”模块，并遵守：

- 资历等级 1 之后每级提供 1 个永久天赋点；旧档按等级补足总预算，同时保留已有
  `talent_flags` 与尚未消费的点；
- 本阶段只开放已经具有真实运行时消费者的三条两级分支：整备（负重 → 失败抢救）、
  安全（雷伤减免 → 协议增量减免）、勘探（扫描扩展 → 搜索收益）；
- 节点必须显示前置、消耗、精确数值、可用原因和当前生效状态；不得使用“更清楚”
  “更容易”等不可验证描述；
- 解锁通过 `MetaActionEnvelope` 提交，按 `request_id` 幂等；扣点、写 flag 与保存是
  同一事务，保存失败必须完整回滚；
- 已解锁效果只通过普通 Deploy → `RunStartConfig` 快照进入新一局，不可中途改写
  活动局；教程地图仍为零正式成长污染；
- I3R 不虚构尚无消费者的“首次雷险免疫”和“信标嗅觉”，它们继续留在原始策划案
  作为后续候选，不能以禁用假节点冒充实现。

### 5.2 动画策略边界

当前生产基线采用已登记像素帧、动画目录和可替换 `appearance/animation_set`。
它允许后续时装或角色素材替换，但动画仍是只读呈现层。骨骼帧生成不是通用“补帧”
开关；只有在来源许可、像素风格、轴点、碰撞同步、性能和玩家观感均有单独证据时，
才能作为某个角色的呈现实现。当前尚未完成角色、敌人和入场动画的最终玩家手感签收，
因此只能记为 `PRESENTATION_BOUNDARY_IMPLEMENTED / PLAYER_ANIMATION_PASS_PENDING`。

当前定向门还证明：角色逻辑位移只走 InputMap 连续路径，边界拒绝不会产生回弹；
生产 `main.tscn` 的局内真实 Sprite2D 会消费外观 profile。`graytail.field_coat`
目前只是已登记的审计安全色型基线，用于证明可观察的局内替换管线；未拥有选择
和未知 catalog ID 均 fail closed；受击色与当前 profile 组合，反馈结束后精确恢复。
它不是独立真实时装素材，也不代表生产获取/选择 UI、外观拥有/应用交易、跨局外
场景一致或动态换装体验已经完成。

## 6. 教程地图模式

教程必须满足：

1. 在出发探索地图列表中显示为一个可识别的普通地图项；`tutorial` 只选择教学内容
   规则，不建立第二套页面、启动器或运行状态机；
2. 使用与普通地图相同的选择、详情、配置和确认出发接口；
3. 固定 5×5 地图和 UE 已有教学顺序作为内容基线；
4. 出生与撤离说明阻塞，房间规则提示默认非阻塞，雷房说明在房间效果后出现；
5. 按键文案从当前 `ActionHintDescriptor` 取得，不硬编码 F/E/M；
6. 只持久化教程完成/重播状态，不写正式金币、仓库、局数、成功数、历史或最近探索；
7. 活动标准局存在时不得被教程启动覆盖。

当前真实 `main.tscn` 自动旅程已从 Deploy 可见地图目录完成首通和重播：两次都沿
`standard_run` 进入固定教学地图，结果金币、物品和 salvage 为零；首通只写
`tutorial_completed` 并返回 Deploy，重播不再写存档并按规则返回主菜单。该 PASS
不替代真实键鼠/手柄设备和动态玩家观感签收。

当前 UE 对照后的生产校准还要求并已由 I3R.6 合并定向套件证明：固定四个事件格不能坍缩成同一
事件，而应按同源权重产生 `trap → dice → altar → trader`；区域扫描图的鼠标单击与
`ui_accept` 共用一次执行边界，未知格标记/取消、已探索且可回传安全格直接回传，
焦点移动只负责选择；非阻塞房间提示提供主动关闭但不抢键盘焦点。响应式门覆盖
1280×720/1920×1080 × UI 100/125/150 的标题、按钮、左 HUD、房间、协议卡和底栏
安全区；当前合并定向日志位于 `.tmp/i3r6_final_combined_20260726`。

## 7. Base 原始策划案与素材治理

- `sources/base/原始策划案` 是不可变来源层：25 份原件保留原名、完整字节、信息量
  和来源 SHA；只允许统一承载格式，不得改名、摘要替换或删减策划内容。
- 素材仅按内容 SHA 精确去重；重复对象保留每个原始 alias 和来源路径，同名不同内容
  不得覆盖，同内容不同语义不得丢失关联说明。
- Base 不得被运行时直接扫描或加载。任何生产使用必须经显式 promotion 记录来源、
  输出、运行时 key、真实 consumer、许可和 rollback，并进入 Base/runtime 交叉账。
- 当前机器账为 25 份原始策划案、1407 个素材成员、1012 个唯一对象和 395 个精确
  alias。语义对象交叉到账为 178 行 runtime、175 个 runtime 路径、149 个 runtime
  SHA 和 1 条显式 promotion；真实消费者证明分类为 direct 47、dynamic 108、
  staging 6、无生产 consumer 17，另有 2 组共享 alias 作为显式替换债登记。
- 75 个 runtime 精确匹配已有逐 SHA 裁决且待裁决为 0；该结果仍是机器治理门，
  不替代生产玩家路线对受限素材和实际消费者的最终签收。

### 7.1 当前长期系统与历史 ART23 分权

- 当前 I3R 生产长期系统固定为 6 个一级模块、25 个二级页面和 58 个运行资产；
  gacha 运行资产为 0，天赋模块使用独立的 furniture，不复用历史 gacha furniture。
- `docs/40_validation/i3r_long_term_current/` 是当前生产治理账；当前门输出
  `I3R_LONG_TERM_CURRENT_GOVERNANCE=PASS modules=6 pages=25 runtime_assets=58 gacha_runtime=0 talent_furniture=dedicated historical_art23=preserved`。
- 历史 ART23 的 6×27 页面/58 资产闭环原样保留，只证明其历史冻结对象；历史 validator、
  gacha 来源与矩阵不得替代当前 I3R 长期系统门。

## 8. 快速阅览与测试基线

I3R.8 关闭前必须提供：

- UI 字体、边框、长文本、品质和焦点状态画廊；
- 箱子、门、掉落物和特殊房状态画廊；
- 可显示攻击/受击逻辑几何的战斗沙盒；
- 固定种子的主菜单 → Deploy → Run → Result 玩家旅程；
- 固定 seed 战斗房的可见障碍、封锁门、敌预警、遮挡/命中、结算与离房旅程；
- 教程地图的完成、重播和零经济污染旅程；
- 每个入口的启动命令、操作说明、预期结果、证据路径和失败判据。

较早只实例化生产 `main.tscn` 的矩阵已生成 11 页面 × 4 分辨率 × 3 UI 缩放共
132/132 例；预检、捕获期污染与镜像一致性门通过。其后长期系统补上 100/125/150%
真实字号、换行和安全区变化，并要求同场景同分辨率三档 PNG 哈希互异；该定向反自证门
已通过，但包含当前修改的最终矩阵仍待刷新。单次实例化生产 `main.tscn`、
固定 seed 13 的历史对象/特殊房/战斗画廊保留 11/11 状态；当前 I3R.4 画廊已在
`.tmp/i1/20260726T021919201Z_7d105484/i3r_production_state_gallery/` 重新生成 12/12 状态；
fixture 字段与 `player_journey=false` 已进入逐项 metadata。另有固定 seed 13 的标准生产
玩家旅程通过 20 个 checkpoint/截图，覆盖主菜单、洞口转场、Deploy、Run、撤离、真实保存
失败重试与返回主菜单；满包替换旅程为 13 张截图，放弃/自然失败终局旅程为 15 张截图，
自然失败原因为 `runtime_combat_projectile`；教程也已通过真实 `main.tscn` 的首通/重播自动旅程，且无
正式成长污染。战斗房还以 seed 13、真实 `main.tscn` 和 64 次解析输入证明：
玩家移动会在可见祭坛前停止，近战敌人会绕过祭坛并恢复无遮挡接近；持续顶住封锁门
只拒绝一次且不重复 dispatch；敌预警可见；攻击三个阶段的判定、扇区与贴图朝向锁定
并在恢复后释放；祭坛遮挡会同步裁剪视觉且 blocked/no-hit，无遮挡攻击为 one-hit，
最后可结算并正常离房。

I3R.5 另以真实 `main.tscn` 和 36 次解析输入完成 22 checkpoint/22 PNG 的局外生产
旅程，覆盖设置安全应用、未应用取消、危险显示回退、Deploy 五页、仓库批售取消后确认、
长期任务/天赋/档案和三级 Esc 返回。当前证据位于
`.tmp/i3r5_out_of_run_rendered_20260726`。范围化 Codex 视觉复核据此修正了显示确认态
居中与焦点、Deploy 详情动作安全区和权威藏品等级、长期系统转场底图、任务信息密度、
天赋图标、档案时间裁切及收起控件语义；该复核不替代动态玩家或真实设备签收。

I3R.7 已分别完成 Base 真实消费者证明和当前长期系统治理：Base 门核对 1012 个语义
对象、178 行 runtime 账、175 个路径、149 个 SHA、1 条显式 promotion，以及
direct 47/dynamic 108/staging 6/无生产 consumer 17 和 2 组 alias 债；长期系统门
核对当前 6 模块/25 页面/58 资产、gacha runtime 0 和独立 talent furniture，同时
保护历史 ART23 6×27/58 证据不被改写。两者均不替代最终玩家路线或设备签收。

空间方面，旧 CAS/index、V2 restore 和 7.4064 GiB 只属于历史检查点。2026-07-26
当前 `E:\AGAME1` 审计为 16.947 GiB；I3R.8 仍须在最终产物冻结后完成归档、校验、
V2 恢复证明、事务清理与终态复量，不能沿用旧 `SPACE PASS` 宣布当前空间闭环。

上述自动状态仍为 `PASS_WITH_VISUAL_REVIEW_REQUIRED`；历史联系表复核早于当前冻结，
而 I3R.4 的箱/门、雷机关 armed/triggered/resolved、地雷/角色/FX 深度、满包替换行、
战斗入口净空和三种终局结果已完成范围化 Codex 视觉复核。该 scoped review 不替代刷新后的
最终矩阵、真实键鼠/手柄、目标 GPU 长局、动态玩家体验或用户签收；这些仍未完成。
2026-07-24 与 2026-07-25 的 89/89 worktree full 也均已被当前修改超越，不能作为
final post-governance full。

## 9. 完成定义

I3R 只有同时满足以下条件才能关闭：

1. I3R.0–I3R.8 均完成前检查、实现、定向验证和完成检查；
2. 用户提出的每项问题均为 `VERIFIED`、`REJECTED_WITH_EVIDENCE` 或具有真实外部
   阻塞条件的 `BLOCKED`，核心玩家闭环不得降级为 note；
3. 1280×720、1366×768、1600×900、1920×1080 和 UI 100/125/150% 有渲染证据；
4. 键鼠和真实手柄的输入、焦点、弹层、战斗、教程和结果旅程通过；
5. 目标设备战斗帧时间、长局、音频和 reduced-motion 通过；
6. Base、运行时素材、消费者与许可交叉账无未裁决生产项；
7. worktree、exact-head、污染、cleanup、push 和远端 SHA 门全部通过；
8. 最终动态玩家体验获得人工签收，不能只凭自动化关闭。
