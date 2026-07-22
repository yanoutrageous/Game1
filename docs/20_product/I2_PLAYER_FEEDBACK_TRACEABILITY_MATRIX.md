# I2 Player Feedback Traceability Matrix

文档状态：I2 最终反馈追踪入口；第 9 节登记逐项的获批范围结果与延期门，不能替代最终审美、完整手感或通用性能声明。
最后更新：2026-07-22

## 1. 使用规则

本矩阵保留用户意见，但不把意见自动升级为仓库事实或最终实现方案。每条都必须综合：

- `U`：玩家/用户观察或期望；
- `R`：当前 Godot 代码、数据、运行或预览证据；
- `UE`：`E:\UE` 的只读语义/交互/视觉参考；
- `D`：仍需产品或工程决策；
- `A`：实现后必须取得的验收证据。

主要事实入口包括 `scripts/ui/main_menu/main_menu_shell.gd`、`scripts/ui/app_shell.gd`、`scripts/ui/deploy_prep/`、`scripts/ui/long_term/`、`scripts/ui/run_surface/`、`scripts/core/run/run_scene.gd`、`scripts/ui/result/result_panel.gd` 和 `scripts/gameplay/combat/g41_combat_simulation.gd`。表中的“接受方向”只表示进入 I2 范围，不表示实现已完成或解决方案已冻结。

验收缩写：`AUTO` 自动化/runner，`CAP` 生产截图，`DYN` 动态人工，`INPUT` 键鼠/手柄/焦点，`PERF` 真实工作负载，`FAIL` 失败/恢复路径，`ASSET` 来源许可/import，`TEXT` 长文本/本地化。

## 2. 主菜单

| ID | U：原始观察/要求 | R / UE：现有证据 | D：I2 处置 | Slice | A：验收 |
| --- | --- | --- | --- | --- | --- |
| MAIN-01 | 各文字与场景搭配较差。 | R：文字主要以控件覆盖像素场景；27 图只证明容器稳定，不证明场景语义。UE：只可比较信息层级，不复制烤字页。 | `ACCEPTED_DIRECTION`：重做文字落点、层级、对比、语气和安全区，仍用动态文本。 | I2.2 | CAP 三分辨率；DYN 可读性；TEXT 长中文/英文伪本地化；无遮挡/无烤字。 |
| MAIN-02 | 动画割裂机械，角色更甚；评估骨骼帧生成。 | R：已有 idle/move/attack 等帧和 cache，但焦点态存在固定帧/冻结式表现，walk 未形成空间叙事。UE：只作节奏参考。 | `CONDITIONAL`：先做离线 rig-assisted/baked pixel proof 与逐帧方案 A/B；不承诺运行时骨骼“自动生成”。角色表现接口必须支持替换/时装。 | I2.1→I2.2 | DYN idle/focus/walk/return 连续性；reduced-motion；素材替换 proof；PERF 加载/内存。 |
| MAIN-03 | 旗帜、选中框等动效与对象错位。 | R：环境效果和焦点表现依赖固定区域/锚点，窗口变化与图层漂移需实测。 | `ACCEPTED_DIRECTION`：绑定语义锚点/局部坐标，禁止靠独立 magic rect 维持。 | I2.2 | AUTO 锚点/resize；CAP 三分辨率；DYN focus 切换与窗口缩放，无漂移/穿层。 |
| MAIN-04 | Deploy 以角色走入洞口转场；Long 画面向下移；其他入口也有语义转场。 | R：生产路由当前主要为统一 ColorRect fade；目标空间转场未实现。 | `ACCEPTED_DIRECTION`：先原型再冻结；转场只协调表现，路由提交和失败回退仍由导航权威；提供 reduced-motion 静态路径。 | I2.1→I2.2 | AUTO 重入/取消/目标路由；DYN 四入口、快点/连点、返回；INPUT 焦点恢复；FAIL 动画/加载失败。 |
| MAIN-05 | 设置没有实际作用，应新增对应内容。 | R：设置覆盖层与 SettingsManager 存在，但可见行为/持久化覆盖不足；音频素材/消费者不构成已完成音频设置。 | `ACCEPTED_WITH_GATE`：只显示真实生效、可持久化、有默认/回滚/失败反馈的字段；字段清单在 I2.1 冻结，禁用“假设置”。 | I2.1 | AUTO round-trip/default/future schema；DYN 生效；INPUT；FAIL 拒绝写入/恢复；设置清单逐项证据。 |

## 3. 出发探索

| ID | U：原始观察/要求 | R / UE：现有证据 | D：I2 处置 | Slice | A：验收 |
| --- | --- | --- | --- | --- | --- |
| DEP-01 | 左侧角色动作生硬；后续时装会替换角色素材。 | R：可复用动画 catalog 已存在，但页面侧换装/角色替换契约未成为完成事实。 | `ACCEPTED_DIRECTION`：复用 I2.1 角色表现端口，页面不硬编码 sprite 路径、帧数或角色尺寸。 | I2.1→I2.3 | DYN 动作；至少一个替换夹具；reduced motion；缺帧 fallback；ASSET。 |
| DEP-02 | 中心改左右分栏：左选择、右详情；右上常驻金币。 | R：当前中心为单列卡片，真实金币快照可取。 | `ACCEPTED_DIRECTION`：中央双栏，金币来自局外权威且不由 UI 自算；小分辨率不得退化为信息缺失。 | I2.3 | CAP 三分辨率；INPUT 列表↔详情焦点；TEXT；金币随真实交易刷新。 |
| DEP-03 | 地图左侧名称+比例/规模，右侧难度+详情；符合玩家认知。 | R：当前 Deploy 默认 `tab=map`，已有 8 个稳定地图 ID。UE 有 region→difficulty 参考，但会造成分步路由回归。 | `HARD_CONSTRAINT`：地图与难度始终同一 Deploy 地图页签；禁止 region→difficulty 分步页；ID/存档不改，只加 7×7/10×10/13×13 显示分组。 | I2.3 | AUTO 八 ID round-trip、启动配置；DYN 单页选择；INPUT；CAP；路由/返回无额外页。 |
| DEP-04 | 仓库显示拥有/使用，支持出勤、使用、售卖、快捷选定售卖；左右布局、品质明显、减少空间浪费。 | R：真实库存、品质和部分单件命令存在；完整整理/批量售卖/经济并未完成。UE 只可借交互语义。 | `PARTIAL_ACCEPT + PRODUCT_GATE`：先完成真实信息与已有命令的双栏表现；批量选择/售卖须冻结价格、确认、失败、幂等、存档，不做假按钮。颜色必须有文字/图标/边框冗余。 | I2.3 | AUTO command/idempotency/save；DYN 筛选/出勤/使用/单售/批量（若批准）；INPUT；FAIL；CAP 品质和密度。 |
| DEP-05 | 申领参考仓库，但需按功能特化。 | R：当前多个页签复用卡片骨架，业务差异表达不足。 | `ACCEPTED_DIRECTION`：复用布局/焦点组件，详情与动作按领取、购买、条件、剩余量、地图适配特化；不复制仓库文案或命令。 | I2.3 | AUTO 条件/库存/货币；DYN 申领成功/不足/重复；INPUT；TEXT。 |
| DEP-06 | 目标未来可能含委托、成就、等级任务，应修改页签。 | R：本局委托与局外任务/成就的生命周期不同，长期目标当前还承担真实记录。 | `DECISION_REQUIRED`：Deploy 首要名为“本局委托”；成就/等级任务原则上进入任务档案/长期。最终 taxonomy 在 I2.3/I2.4 联合门冻结，不能先造空页。 | I2.3→I2.4 | 内容生命周期映射；AUTO 导航/红点/领取；DYN 可发现性；无重复/丢项。 |
| DEP-07 | 不理解“出勤配置”的实际意义。 | R：底层 `RunStartConfig` 对携带物、地图、难度等启动数据有真实意义；问题是 UI 解释不足。 | `RESTRUCTURE_BEFORE_REMOVE`：显示真实配置与限制；评估合并到仓库/概览或保留。若移除页签，全部操作必须有新落点并通过发现性测试。 | I2.3 | AUTO 配置→run round-trip；DYN 玩家能说明用途；无隐藏必需项；TEXT。 |
| DEP-08 | 右摘要删“当前选择”“路线/难度”等说明句；四个二级页签都聚焦核心简写内容。 | R：当前摘要含通用说明/状态性占位。 | `ACCEPTED_DIRECTION`：删除同义标题和解释前缀，以真实名词、数值、图标、异常为主；不能删掉必要差异。 | I2.3 | CAP 信息层级；DYN 5 秒识别测试；TEXT 长值；四页签一致。 |
| DEP-09 | 配置要写具体内容；效果可保留为本局附加效果；风险改目标。 | R：配置存在数量化摘要；风险信息仍有玩法价值但不必占顶层。 | `ACCEPTED_DIRECTION`：摘要顶层“概览/配置/效果/目标”；配置列具体项，效果仅显示本局附加效果，风险转为相应内容的上下文警示。 | I2.3 | AUTO 与 RunStartConfig/效果/委托 truth 对照；CAP；DYN 切换同步；空/溢出状态。 |
| DEP-10 | 删除“运行状态”，底部确认出发已足够表达。 | R：运行状态与 CTA 可重复；当前进程 continue 仍需可见差异。 | `ACCEPTED_WITH_EXCEPTION`：删除独立运行状态块；开始/继续/禁用/错误由 CTA、摘要和反馈表达，不得隐藏正在继续同一 run 的事实。 | I2.3 | AUTO new/continue/blocked；DYN CTA 可理解；FAIL；INPUT。 |

## 4. 长期系统

| ID | U：原始观察/要求 | R / UE：现有证据 | D：I2 处置 | Slice | A：验收 |
| --- | --- | --- | --- | --- | --- |
| LONG-01 | 顶部标识、主菜单/Deploy 按钮、左下收起档案粗糙，UI 风格不统一。 | R：长期页有独立导航和档案控制语言；多页面共享样式不足。 | `ACCEPTED_DIRECTION`：复用共享导航、焦点、按钮状态和动效语言；长期内容布局保持模块特化。 | I2.1→I2.4 | CAP 跨页对照；DYN 返回/收起/恢复；INPUT 焦点；reduced motion。 |
| LONG-02 | 主内容过简、详情和展示量少，需重排。 | R：多个模块被压成相近的少量卡片，真实数据存在但信息密度低。 | `ACCEPTED_DIRECTION`：按任务、研究、图鉴、资历、收藏、角色的真实字段分别布局；禁止虚构数据填满界面。 | I2.4 | 每模块状态矩阵；CAP 三分辨率；DYN 详情/操作；TEXT/空态/锁定态。 |
| LONG-03 | “目标”替换为策划案中的天赋树。 | R：当前 Goal 承载真实任务、成就、委托记录；历史设计提及天赋，但完整天赋树不属于已完成能力。 | `CONDITIONAL_MIGRATION`：认可天赋树方向；先把现有任务/成就迁到任务档案并验证数据/红点/领取，再定义真实天赋数据和效果，最后改导航。禁止只改名。 | I2.4 | AUTO 数据迁移/领取/红点/存档；DYN 树导航；FAIL；能力实际生效；旧内容无丢失。 |
| LONG-04 | 角色及角色档案按此前意见优化。 | R：当前档案栏和角色内容较压缩；可替换角色/时装接口尚未闭环。 | `ACCEPTED_DIRECTION`：共享角色表现端口，角色档案按真实身份、成长、外观、记录和操作分层；无数据项不占位伪装。 | I2.1→I2.4 | 替换夹具；CAP；DYN 详情/筛选；INPUT；TEXT；ASSET。 |

## 5. 局内核心 12 条

| ID | U：原始观察/要求 | R / UE：现有证据 | D：I2 处置 | Slice | A：验收 |
| --- | --- | --- | --- | --- | --- |
| RUN-01 | 显示与真实内容不符，箱/门尤其严重且箱错位。 | R：箱、门、房间有权威状态与视图接线，但用户报告具体错位；静态预览不能确认交互全过程。 | `INVESTIGATE_THEN_FIX`：建立对象 ID→状态→锚点→可见层映射，先复现每种错位；不以换图遮蔽状态错误。 | I2.5 | AUTO 状态映射；CAP/DYN 未开/已开/锁定/门/多分辨率；房间切换无残影。 |
| RUN-02 | 角色运动动效生硬。 | R：已有 move/idle/hurt 等帧和固定步领域移动，视觉插值/朝向/停步节奏需动态复核。 | `ACCEPTED_DIRECTION`：表现与领域位置解耦但不得产生位置谎报；复用可替换角色端口。 | I2.1→I2.5 | DYN 启停/转向/碰撞/受击；reduced motion；PERF；状态与碰撞位置一致。 |
| RUN-03 | 箱首次打开直接呈现内部物品；以后靠近自动呈现；删说明语句。 | R：现有箱交互/奖励命令存在，展示层仍需贴合首次/已开状态。UE 可借“靠近提示→打开→奖励明细”语义。 | `ACCEPTED_DIRECTION`：首次打开由命令结果触发展示；已开箱靠近自动显示内容。自动显示不是自动提交奖励，动画计时器不掌权。 | I2.5 | AUTO unopened/opened/revisit；DYN 距离进出/满包/重复；FAIL；无双发奖励。 |
| RUN-04 | 地面掉落靠近自动显示可拾取物，不是自动拾取。 | R：地面 ledger/拾取/替换/丢弃命令已存在。 | `HARD_BEHAVIOR`：proximity 只控制展示和焦点候选，拾取仍需显式意图；离开范围关闭并恢复主焦点。 | I2.5 | AUTO ledger 不因 proximity 改变；DYN 多物/满包/进出；INPUT；无自动拾取。 |
| RUN-05 | 物品用 UE 式语义颜色；快捷背包不画空位/空边缘，按内容且可滚动；负重放下中。 | R：品质数据存在，当前快捷区固定槽/空白与品质表达不足。UE 只可借语义，不能复制色板。 | `ACCEPTED_DIRECTION`：动态内容列表+滚动；颜色必须配品质文字/图标/边框；负重下中。不得改库存容量或 ledger truth。 | I2.5 | AUTO 列表与 ledger；CAP 空/少/满/溢出；INPUT 滚动/焦点；色弱冗余；TEXT。 |
| RUN-06 | 操作说明上方改“周围雷险”；删“正常作业”等冗余并直观化。 | R：底部/左栏仍有工程式状态和截断；雷险数据已有地图 truth。 | `ACCEPTED_DIRECTION`：把当前格周围雷数/风险作为直接信息；操作只显示当前可执行动作及禁用原因，删除重复氛围标签。 | I2.5 | AUTO truth 对照且不泄露未知雷；CAP/DYN 可读；TEXT；不同房态。 |
| RUN-07 | 丰富小地图/全图；已知格右下邻雷数；图层合理；点地图外关闭；底部说明放松。 | R：mini/full map 已存在，10×10 等容器预览稳定；输入/信息密度需改。UE 可借未知/扫描/房型/标记语义。 | `ACCEPTED_DIRECTION`：已知格显示右下邻雷数，保持未知信息不泄露；明确 layer order；外部点击关闭；底部帮助降噪。 | I2.5 | AUTO fog/truth/marker/current cell；CAP 三分辨率与三规模；INPUT 外点/手柄关闭；色弱；TEXT。 |
| RUN-08 | 右上协议参考 UE 语义。 | R：生产使用外框+动态协议/压力文本；五级状态资源有预览证据但未成为生产接线事实。 | `ACCEPTED_SEMANTICS_ONLY`：表达协议等级、压力和变化原因；可评估已审计五级色板，拒绝 UE 烤字条/固定布局。 | I2.5 | AUTO 值/等级映射；CAP 五级/异常；DYN 变化反馈；色弱冗余；ASSET。 |
| RUN-09 | 背包删冗余工程文案；鼠标/焦点到物品显示详情悬浮窗。 | R：背包已有真实物品与操作，但空态/工程文案和 tooltip 交互不足。 | `ACCEPTED_DIRECTION`：详情来自只读 view model；hover 与 focus 等价，模态边界内显示，不遮住当前主要操作。 | I2.5 | AUTO 字段来源；DYN hover/focus/移动/关闭；INPUT 键盘手柄；TEXT 长属性；空态。 |
| RUN-10 | 边框风格不符且图层错误，系统统一。 | R：HUD、inventory、map 的遮罩/框体/层级规则不一致，部分旧资产仍有替换债。 | `ACCEPTED_DIRECTION`：建立共享 layer/token 规则与模块变体；统一状态语义，不要求所有页面同一框图。 | I2.1→I2.5 | CAP 跨页面 layer 对照；DYN 模态遮罩/点击穿透；ASSET manifest；三分辨率。 |
| RUN-11 | Esc 后布局、跳转、二次确认、说明、居中、工程文案全面玩家化。 | R：暂停/模态/返回存在多输入所有权风险，静态截图不能证明阻塞与焦点恢复。UE 的优先级概念可参考。 | `ACCEPTED_DIRECTION`：唯一 modal priority；继续/设置/放弃/返回语义明确；破坏性离开二次确认；关闭后焦点归还；文案玩家化。 | I2.1→I2.5 | AUTO pause/state unchanged；DYN Esc 嵌套/连按/确认取消；INPUT；FAIL；CAP 居中。 |
| RUN-12 | 成功/失败结算清晰说明局内发生了什么、失败原因、可带走/可选择什么。 | R：结果页已有真实结算快照与失败保全，但展示解释不足；UI 不拥有提交权。 | `ACCEPTED_DIRECTION`：按结局原因、获得/保全/待选择/损失、物品去向、下一步和保存状态分层；失败选择仍在确认前不写局外。 | I2.6 | AUTO snapshot/result_id/idempotency；DYN success/failure/abandon/salvage；FAIL 保存失败/重试；TEXT。 |

## 6. 特殊房 4 条

| ID | U：原始观察/要求 | R / UE：现有证据 | D：I2 处置 | Slice | A：验收 |
| --- | --- | --- | --- | --- | --- |
| ROOM-01 | 战斗房掉帧、怪物突兀；需入场表现；离开须特殊操作而非接触离开。 | R：Godot 采用 60 Hz 固定步与 combat scope refresh；用户掉帧观察尚无真实整帧测量，历史 p95 仅是 refresh 微基准。UE 支持“门口提示代价+独立确认”概念，但其大型 Tick 架构被拒绝。 | `ACCEPTED_WITH_MEASUREMENT`：先分解模拟/快照/表现/加载，测 1/3/5 敌人与峰值；添加怪物入场状态；战斗离房改明确操作/确认，领域规则另设门。 | I2.6 | PERF 真实帧 P50/P95/P99/max、分配/加载；AUTO deterministic；DYN 入场/逃跑；INPUT；无触边误退。 |
| ROOM-02 | 特殊房工程信息多、手感差。 | R：不同房型已有规则/状态，但通用工程提示不能证明玩家可理解。 | `INVESTIGATE_PER_ROOM`：按事件/宝箱/怪物/撤离/雷等房型建立“发现→意图→结果→离开”矩阵；不以一套通用面板假装解决。 | I2.5→I2.6 | 每房型 DYN 状态矩阵；AUTO 领域结果；INPUT；CAP；玩家能复述代价/结果。 |
| ROOM-03 | 撤离点出现时明确通知；靠近显示大概收益/总结。 | R：撤离状态与结算预览数据存在，但通知和 proximity 摘要需核对。 | `ACCEPTED_DIRECTION`：首次可撤离给非阻塞多通道通知；靠近显示基于权威快照的估算并标明未结算，不提前提交。 | I2.6 | AUTO eligibility/preview vs final；DYN 通知一次性、靠近/离开；FAIL 状态变化；reduced motion。 |
| ROOM-04 | 雷房反馈参考 UE 增强。 | R：领域伤害/文本存在，动态多通道反馈是否足够尚未验证。UE 可借红闪、受击、声音、数值/原因组合，不复制参数。 | `ACCEPTED_SEMANTICS_ONLY`：视觉、角色受击、数值/原因和可许可音频槽的冗余反馈；reduced motion 禁止强闪。 | I2.6 | AUTO 伤害原因；DYN 正常/减少动态；色觉/闪烁安全；PERF；音频若接入须 ASSET。 |

## 7. 补充跨域判断

| ID | U：约束/判断 | R / UE：现有证据 | D：冻结处置 | Slice | A：验收 |
| --- | --- | --- | --- | --- | --- |
| CROSS-01 | 用户补充必须与运行/代码/UE/资产综合，不能按偏好覆盖仓库事实。 | R：部分反馈涉及已存在权威、尚未实现经济或尚未测量性能。 | `FROZEN`：每项保持 U/R/UE/D/A 链；冲突时当前可复现仓库事实优先，偏好进入决策而非改写事实。 | 全部 | 逐项 evidence link、处置和 claim review。 |
| CROSS-02 | I2 是工程侧→玩家体验侧完整重构；内部切片但单一阶段/综合验收。 | R：范围跨程序、美术、产品、治理，单次实施风险过高。 | `FROZEN`：I2 单一 `ACTIVE` stage；I2.0–I2.7 是门控切片，不独立宣称阶段完成。 | 全部 | active ledger + 最终一份 validation/handoff；中途无 premature closeout。 |
| CROSS-03 | Godot/UE/本地素材优先，经来源许可/import gate；不足才生成。 | R：Godot 已有大量可用资产；UE 含未知许可和烤字/`.uasset`。 | `FROZEN`：复用→审计接线→批准导入→确认不足后生成；任何新 binding 有 manifest/runtime key。 | 资产相关切片 | ASSET source/license/hash/import/determinism；unknown 隔离。 |
| CROSS-04 | 继承 I1 权威/结算/保存不变量。 | R：I1 已建立 RunStateMachine、RunAssetLedger、terminal settlement、SaveAdapter 等边界。 | `FROZEN`：任何绕开均为 blocking regression，除非独立架构迁移契约与等价证明。 | 全部 | core/full；characterization；save/settlement failure；idempotency。 |
| CROSS-05 | 快速效果阅览、测试和明确操作说明是基线目标。 | R：I1 有隔离 preview 与 profiles，但动态/输入/说明覆盖不足。 | `FROZEN`：每切片提供最短可执行命令、目标状态、操作步骤、预期结果和证据位置。 | 全部 | quick/ui/core/full + CAP/DYN/INPUT；runbook 可由新接手者执行。 |
| CROSS-06 | 性能必须测真实工作负载，不能把 refresh 微基准当 FPS。 | R：现有 combat/full refresh 指标只覆盖刷新函数。 | `FROZEN`：记录整帧、模拟、快照、表现、加载、分配和内存；同机同配置前后比较。 | I2.6 | PERF 1/3/5 敌人、峰值、60 秒以上；P50/P95/P99/max；无微基准越权声明。 |
| CROSS-07 | UE 只借语义/交互/视觉概念，拒绝架构、烤字固定布局和未知许可。 | UE：当前参考为 Editor `-game`，不是打包性能基线；部分逻辑集中在大型 Tick/UI。 | `FROZEN`：所有 UE 引用标记 concept-only；禁止代码/架构照搬和未经许可资产导入。 | 全部 | code/asset review；无 UE runtime dependency；ASSET；Godot 生产路径验证。 |
| CROSS-08 | input/gamepad/focus、reduced motion/color redundancy、localization/long text、lifecycle/save failure 纳入验收。 | R：静态 27 图不覆盖这些风险，当前输入由多页面处理且保存失败需单独验证。 | `FROZEN`：作为每个相关切片的横向 gate，未运行保持 `NOT_RUN`，不可用截图替代。 | 全部 | INPUT、DYN、TEXT、FAIL；焦点图、减少动态、色觉冗余、伪本地化、重启/写入失败。 |

## 8. 处置与关闭规则

每项只允许以下最终状态：

```text
IMPLEMENTED_AND_VERIFIED
REJECTED_WITH_REPOSITORY_EVIDENCE
DEFERRED_WITH_OWNER_AND_GATE
```

`ACCEPTED_DIRECTION`、`CONDITIONAL`、`DECISION_REQUIRED` 等都是 I2 启动状态，不是完成状态。I2 最终审计必须逐条附证据或明确延期责任；任何未追踪条目都会阻止综合 closeout。

## 9. I2 最终逐项处置

本节是本矩阵的最终处置层：它不删除上文的用户原意、起点证据或当时的决策理由。`IMPLEMENTED_AND_VERIFIED` 只表示该条在 I2 已批准的范围内有自动化、生产 capture、权威/失败路径或独立复核证据；它不等同于最终美术、完整玩家手感、通用 FPS、长时人工游玩、导出或发布通过。所有精确 marker、capture 与报告以 I2.7 validation/handoff 为准；本表只提供稳定的追踪入口。

计数：`IMPLEMENTED_AND_VERIFIED = 34`；`DEFERRED_WITH_OWNER_AND_GATE = 9`；`REJECTED_WITH_REPOSITORY_EVIDENCE = 0`（被拒绝的是下文列出的具体子方案，不是任何一整条用户意见）。

| ID | 最终状态 | 已验证范围与证据，或延期 owner / 重新开启门 |
| --- | --- | --- |
| MAIN-01 | `IMPLEMENTED_AND_VERIFIED` | I2.2A 主菜单文字层级、动态文本、安全区与三分辨率 production capture；I2.7 final visual matrix。不是最终审美签收。 |
| MAIN-02 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：美术/动画管线；需获批的离线 rig-assisted 或逐帧素材方案、时装替换夹具、动态 idle/focus/walk 人工复核及加载/内存门。现有 catalog/表现端口不是最终动作手感。 |
| MAIN-03 | `IMPLEMENTED_AND_VERIFIED` | I2.2A 语义锚点/resize/focus 复核、三分辨率 capture 与独立 review；不以固定 rect 维持对象效果。 |
| MAIN-04 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：产品 UX + 导航表现；现有安全路由、取消/回退、reduced-motion 已验证。洞口步入、Long 向下连续空间及各入口动态叙事须有原型、失败回退和动态人工验收后再开。 |
| MAIN-05 | `IMPLEMENTED_AND_VERIFIED` | I2.1 设置 round-trip/default/failure 及 `I1_SAVE_RELIABILITY`；仅真实生效、可持久化字段进入界面，不宣称音频设置或完整音频已完成。 |
| DEP-01 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：角色表现/资产；共享角色表现端口和缺失回退已接入，但真实时装素材替换与页面侧动态手感仍需至少一套获批素材夹具、reduced-motion 与人工复核。 |
| DEP-02 | `IMPLEMENTED_AND_VERIFIED` | I2.3A 同页左右选择/详情、局外权威金币投影、三分辨率 capture、焦点与交易刷新回归。 |
| DEP-03 | `IMPLEMENTED_AND_VERIFIED` | I2.3A 八地图 ID/规模与难度同页投影、启动 round-trip、单页返回无额外 route；保留地图→难度同页硬约束。 |
| DEP-04 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：经济/产品规则；拥有/使用、品质冗余、单件买卖与真实回执已验证（I2.3B）。批量选择/售卖仍需价格、确认、原子性、幂等、保存失败回滚契约。 |
| DEP-05 | `IMPLEMENTED_AND_VERIFIED` | I2.3B 领取/购买条件、库存、货币和重复/失败回执的真实投影；不复制仓库命令文案。 |
| DEP-06 | `IMPLEMENTED_AND_VERIFIED` | I2.3/I2.4 任务档案与本局委托分流、导航/红点/领取回归；未造空页。 |
| DEP-07 | `IMPLEMENTED_AND_VERIFIED` | `RunStartConfig` 的真实配置、限制与启动 round-trip 已投影；隐藏必需项与仅为工程术语的独立页签被移除/重构。 |
| DEP-08 | `IMPLEMENTED_AND_VERIFIED` | I2.3A/B 摘要禁词、具体内容、四页同步与三分辨率 layout evidence。 |
| DEP-09 | `IMPLEMENTED_AND_VERIFIED` | I2.3A/B 的“概览/配置/效果/目标”真实投影、`RunStartConfig`/委托 truth 对照、空/溢出状态回归。 |
| DEP-10 | `IMPLEMENTED_AND_VERIFIED` | I2.3A 的 CTA、continue、blocked/错误反馈取代独立运行状态块；new/continue/blocked 路径已回归。 |
| LONG-01 | `IMPLEMENTED_AND_VERIFIED` | I2.4A/B 共享导航、按钮/focus、收起/恢复、reduced-motion 与跨页 capture；不宣称最终统一美术风格。 |
| LONG-02 | `IMPLEMENTED_AND_VERIFIED` | `I2_LONG_TERM_TASK_ARCHIVE`、ART23 runtime/main-route、五模块/二十四二级页真实记录投影与 72 capture；无假数据填充。 |
| LONG-03 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：产品成长系统；任务/成就已迁到任务档案，但天赋点来源、成本、依赖、节点效果、重置/返还权威未冻结。不得以改名、空树或禁用按钮冒充完成。 |
| LONG-04 | `IMPLEMENTED_AND_VERIFIED` | I2.4B 角色档案按真实身份/成长/外观/记录分层、共享表现端口、缺帧回退、三分辨率和 focus 复核；不等于多角色/外观持有已实现。 |
| RUN-01 | `IMPLEMENTED_AND_VERIFIED` | I2.5B 世界对象 ID→状态→投影/锚点统一；chest/door/ground-loot 状态、重建和三分辨率 capture；`I2_WORLD_INTERACTION_RUNTIME`/G41 回归。 |
| RUN-02 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：角色表现 + UX QA；四姿态、30/60/144Hz、reduced-motion 与逻辑位置一致已验证，但启停/转向/受击的最终玩家手感和最终素材仍需动态人工验收。 |
| RUN-03 | `IMPLEMENTED_AND_VERIFIED` | I2.5B 首开命令结果展示、重进已开箱 proximity 内容、满包/重复零双发及无工程式状态句回归。 |
| RUN-04 | `IMPLEMENTED_AND_VERIFIED` | I2.5B proximity 零命令/零 ledger 变化；仅显式拾取改变位置，多物/满包/离开范围已覆盖。 |
| RUN-05 | `IMPLEMENTED_AND_VERIFIED` | I2.5C 43 项品质非颜色冗余、动态快捷列表/滚动、无假空位、居中负重、空/少/满/溢出 capture 与 ledger truth 回归。 |
| RUN-06 | `IMPLEMENTED_AND_VERIFIED` | I2.5C 已知周围雷险/未知不泄露、当前可执行动作与禁用原因、工程式冗余文本清理。 |
| RUN-07 | `IMPLEMENTED_AND_VERIFIED` | I2.5C KnownMap/邻雷数/隐藏房型无泄露、外点关闭、Esc/focus 归还、三规模与三分辨率 capture。 |
| RUN-08 | `IMPLEMENTED_AND_VERIFIED` | I2.5C 协议 1–5 的权威值/等级/原因映射、颜色冗余和房间主题分离；仅借 UE 语义。 |
| RUN-09 | `IMPLEMENTED_AND_VERIFIED` | I2.5C 只读 item tooltip、hover/focus 等价、长文本、空态和显式 action 一次性回归。 |
| RUN-10 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：UI 美术系统；layer/token、模态遮罩和点击穿透等工程边界已验证，但跨页最终框体风格与图层美术签收仍需批准的视觉方向、全页动态人工复核和资产门。 |
| RUN-11 | `IMPLEMENTED_AND_VERIFIED` | `I2_RUNTIME_MODAL_PRIORITY`、I2.5C 暂停→设置/放弃、两次确认、嵌套 Esc、焦点恢复和居中 capture；领域状态不因取消改变。 |
| RUN-12 | `IMPLEMENTED_AND_VERIFIED` | Gate21 的 `I2_TERMINAL_RESULT_AUTHORITY`、`I2_TERMINAL_COMMIT_RECOVERY`、ART24 result matrix：成功/失败待选/最终/放弃/保存失败、权威物品分类、重试及两次丢弃确认。 |
| ROOM-01 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：性能/战斗体验；显式战斗撤离、确认不双扣、0.18s 怪物入场、固定步确定性和 1/3/5 敌人+弹丸真实 workload 已验证。五轮同机 A/B/A 仅支持“未见系统性相对代码退化”，不能宣称掉帧/FPS 已解决；需设备/GPU/长时体验门。 |
| ROOM-02 | `IMPLEMENTED_AND_VERIFIED` | Gate20 的 event/chest/monster/mine/exit “发现→意图→结果→离开”公开旅程、工程枚举清理、proximity fail-closed 与 production visual matrix。 |
| ROOM-03 | `IMPLEMENTED_AND_VERIFIED` | Gate20 exit 的一次性提示、基于权威快照的未结算摘要、靠近/离开和 popup/entity prompt 互斥回归。 |
| ROOM-04 | `IMPLEMENTED_AND_VERIFIED` | Gate20 mine 的伤害原因、正常/减少动态下的冗余反馈和 0.18s entry envelope；未接入或验收最终音频。 |
| CROSS-01 | `IMPLEMENTED_AND_VERIFIED` | 本矩阵 U/R/UE/D/A 链、I2 gate ledger、独立 scope/claim reviews；运行事实优先于偏好。 |
| CROSS-02 | `IMPLEMENTED_AND_VERIFIED` | I2 作为单一阶段，I2.0–I2.7 仅内部门；唯一 validation/handoff closeout 路径由 ledger 与阶段索引登记。 |
| CROSS-03 | `IMPLEMENTED_AND_VERIFIED` | I2 复用已治理 Godot 资产；无 UE runtime dependency、`.uasset` 导入或未经批准的新素材；asset/source review 与 ART25/I2 binding 证据。 |
| CROSS-04 | `IMPLEMENTED_AND_VERIFIED` | `I1_TERMINAL_AUTHORITY`、`I1_SAVE_RELIABILITY`、G41、result authority/recovery 与 full 回归保持 RunStateMachine、ledger、settlement、SaveAdapter 权威。 |
| CROSS-05 | `IMPLEMENTED_AND_VERIFIED` | I1 profiles、I2 定向 runner、production capture matrix 与 ledger 的最短命令/操作步骤；具体报告位置由 I2 validation/handoff 固化。 |
| CROSS-06 | `IMPLEMENTED_AND_VERIFIED` | `I2_COMBAT_FRAME_BASELINE` 的真实 Main/Run 路径、60 秒 visible 测量和同机 A/B/A；已正确区分 refresh 微基准与整帧测量，未声明绝对性能改善。 |
| CROSS-07 | `IMPLEMENTED_AND_VERIFIED` | 所有 UE 引用限定 concept-only；代码/资产审查无 UE 架构复制、烤字布局或 `.uasset` 运行时依赖。 |
| CROSS-08 | `DEFERRED_WITH_OWNER_AND_GATE` | owner：整合 UX QA；局部 focus/ESC/reduced-motion、保存失败和文本门已覆盖，但跨页面键鼠/手柄手感、长文本/DPI、长局动态人工体验未整体运行。截图不能替代该门。 |

### 9.1 被拒绝的子方案，不是整项需求被拒绝

- 运行时骨骼“自动生成”被拒绝为当前实现方案：缺少获批素材管线、时装替换夹具及性能/可见验收；这不拒绝 `MAIN-02` 的动画连续性或 `DEP-01` 的可替换角色需求。
- 将地图拆为“区域→难度”的分步页面被拒绝：它会违反同一 Deploy 地图页的 `DEP-03` 硬约束并回退既定路由；这不拒绝地图规模、难度和详情的清晰分栏需求。
- 复制 UE 架构、Tick/UI 组织或导入 `.uasset` 被拒绝：UE 仅作只读概念参考，且来源/许可不构成 Godot 运行时授权；这不拒绝 `CROSS-07` 下的交互、信息层级和视觉语义借鉴。
