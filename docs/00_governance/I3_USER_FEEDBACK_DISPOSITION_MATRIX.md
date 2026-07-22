# I3 用户反馈处置矩阵

状态：I3 `CLOSED / PASS_WITH_NOTES` 冻结处置账本。代码与自动化证据优先于早期文档；视觉观感类结论必须等待可见运行证据与人工复核，不能由静态文本测试替代。

处置标签：

- `IMPLEMENTED_AND_VERIFIED`：已有真实消费者，且对应自动化门通过。
- `REMEDIATION_IN_PROGRESS`：完成审计发现不满足原反馈，I3 关闭前必须补救并复验。
- `BLOCKED_WITH_OWNER_AND_GATE`：不属于可在现有权威下安全补齐的内容，已给出后续 owner 与准入门。
- `REJECTED_WITH_EVIDENCE`：与当前权威、信息安全或用户后续指正冲突，明确不采纳。

## 主菜单

| 反馈 | 处置 | 当前证据或剩余门 |
| --- | --- | --- |
| 文字与场景语义不协调 | `IMPLEMENTED_AND_VERIFIED` | 主菜单文案已改为基地门厅、洞口与基地下层语义；`I2_MAIN_MENU_ANCHOR_TEXT`、`ART21_MAIN_MENU_RUNTIME` 已通过。 |
| 最终文字、美术与整体观感协调 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：UI/视觉；需三分辨率可见动态截图与人工视觉签收。 |
| 运行时采用骨骼帧生成 | `REJECTED_WITH_EVIDENCE` | 当前素材没有可用骨骼、蒙皮与动作源；只允许已审计帧序列。未来可在素材门中离线绑定、烘焙并准入。 |
| 角色动画最终手感 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：角色动画/视觉；I3 提供 appearance/clip 替换接口，但接口通过不等于美术品质通过。 |
| 旗帜、选中框、文字和角色锚点错位 | `IMPLEMENTED_AND_VERIFIED` | 语义锚点与三分辨率布局契约已落地；逐像素观感仍归最终视觉门。 |
| “出发探索”角色实际走入洞口 | `IMPLEMENTED_AND_VERIFIED` | 完成审计先否决旧 focus/fade；补救后使用已登记 4 帧 walk clip，角色向洞内锚点移动、缩小/淡出，取消精确恢复，路由完成前不提交。 |
| “长期系统”整幅画面明显下移 | `IMPLEMENTED_AND_VERIFIED` | 完成审计先否决旧 48 px；补救后全部非 overlay 根节点同步最大下移 180 px，并验证中途可读距离与完成后恢复。 |
| 设置实际生效 | `IMPLEMENTED_AND_VERIFIED` | schema v2、AudioServer 主音量、显示设置预览/应用/取消/重启读取均有真实消费者；设置事务与壳层接线门通过。 |
| 继续新增未定义的设置类别 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：产品/无障碍；必须先定义值域、默认值、迁移、运行 adapter 与测试。 |

## 出发探索

| 反馈 | 处置 | 当前证据或剩余门 |
| --- | --- | --- |
| 左侧角色支持后续时装和动作替换 | `IMPLEMENTED_AND_VERIFIED` | appearance/clip 接口和角色呈现替换门已通过。 |
| 实际时装素材与最终动作质量 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：角色资产；候选必须走 source→derivative→runtime→consumer→visual validation，Base 素材不会自动准入。 |
| 中心区域左右分栏、右上常驻金币 | `IMPLEMENTED_AND_VERIFIED` | 出发页已使用 selection/detail 分栏并显示真实金币。 |
| 地图同页左选地图/规模、右选难度/详情 | `IMPLEMENTED_AND_VERIFIED` | 真实地图 ID、规模与难度投影已接入。 |
| 回退为“区域→难度”的分步页面 | `REJECTED_WITH_EVIDENCE` | 与用户后续指正冲突；地图继续是“出发探索”同页组件。 |
| 仓库显示拥有/使用/出勤/单件售卖/品质 | `IMPLEMENTED_AND_VERIFIED` | 使用真实 instance ID 和元进度事务，不以展示假数据替代。 |
| 快捷多选与批量售卖 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：经济/事务；需定义总价、部分失败、幂等、二次确认和存档恢复。 |
| 申领功能特化 | `IMPLEMENTED_AND_VERIFIED` | 申领使用独立购买/领取事务并刷新余额。 |
| 当前出发目标 | `IMPLEMENTED_AND_VERIFIED` | 当前页只承载本次出发目标，长期任务归任务档案。 |
| 将成就、等级任务等长期 taxonomy 混入出发页 | `REJECTED_WITH_EVIDENCE` | 当前真实消费者把长期任务归任务档案；若改变产品 taxonomy，须另开迁移门。 |
| 出勤配置必须有实际意义 | `IMPLEMENTED_AND_VERIFIED` | `RunStartConfig` 在配置、摘要和开局 round-trip 中被真实消费。 |
| 摘要删除说明语、风险改目标、删除运行状态 | `IMPLEMENTED_AND_VERIFIED` | 页签已为“速览/携带/本局/目标”，不再显示 `Running/运行状态`。 |

## 长期系统

| 反馈 | 处置 | 当前证据或剩余门 |
| --- | --- | --- |
| 导航、主菜单/出发复用、收起档案与焦点 | `IMPLEMENTED_AND_VERIFIED` | 长期系统运行门和主路由门通过。 |
| 跨页面最终视觉统一与按钮品质 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：UI/视觉；需统一视觉 token、动态截图与人工签收。 |
| 增加内容密度和详细说明 | `IMPLEMENTED_AND_VERIFIED` | 列表、详情、滚动区域和玩家文案已重排；I3 长期系统玩家契约门通过。 |
| 把“目标”真正改为天赋树规则 | `BLOCKED_WITH_OWNER_AND_GATE` | 当前只是 M7 真实研究前置链的“研究解锁树”，明确 `talent_rules=0`；owner：成长/存档，需天赋点、费用、效果、重置与迁移规则。 |
| 真实研究解锁链以树形呈现 | `IMPLEMENTED_AND_VERIFIED` | 使用 `m7_research_prerequisite` 和真实 `complete_research` 事务，不发明新权威。 |
| 角色及档案读取真实数据 | `IMPLEMENTED_AND_VERIFIED` | 任务档案和长期模块工作区门通过。 |
| 最终角色档案美术、时装与动画 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：角色/UI；需准入素材与视觉验收。 |

## 局内通用体验

| 反馈 | 处置 | 当前证据或剩余门 |
| --- | --- | --- |
| 箱子、门的显示必须对应真实状态 | `IMPLEMENTED_AND_VERIFIED` | presentation mapping、房间运行视图和唯一动态箱对象均读取权威状态。 |
| 角色运动首键、键盘/手柄路径与替换接口 | `IMPLEMENTED_AND_VERIFIED` | 消除首帧重复位移，统一输入向量并验证手柄传播、appearance/animation-set。 |
| 角色运动最终动画手感 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：角色动画/视觉；需可见运行节奏、转向与目标设备体验门。 |
| 箱子首次搜索后直接显示、再次靠近稳定显示 | `IMPLEMENTED_AND_VERIFIED` | 搜索→揭示→稳定→拾取时序和重复靠近内容门通过。 |
| 箱子与物品弹窗不能遮挡对象/玩家 | `IMPLEMENTED_AND_VERIFIED` | 使用真实 UI 变换、边界和多方向回退定位。 |
| 地面物靠近自动显示 | `IMPLEMENTED_AND_VERIFIED` | proximity 与滞回已接入；拾取仍要求显式输入，以保留容量与替换事务。 |
| 品质颜色、无伪空位、可滚动、负重居中 | `IMPLEMENTED_AND_VERIFIED` | 共享 item descriptor、真实条目数量、滚动与居中 footer 已接入。 |
| “周围雷险”与删除左侧重复工程状态 | `IMPLEMENTED_AND_VERIFIED` | 信息面已改为玩家可理解的雷险信息，移除左侧重复状态。 |
| 删除协议等级 5 的正式名称“正常作业” | `REJECTED_WITH_EVIDENCE` | 这是权威协议名；只删除重复显示，不能篡改协议定义。 |
| 小地图/展开图、周围雷数、图层、外点关闭 | `IMPLEMENTED_AND_VERIFIED` | 5×5 玩家中心局部图、共享 marker 语义、KnownMap 防泄漏、选择/确认分离与外点/Esc/右键关闭已验证。 |
| 右上协议改为玩家信息 | `IMPLEMENTED_AND_VERIFIED` | 显示等级、名称与压力，不暴露原始 phase/mode。 |
| 背包 hover/focus 详情且不误发命令 | `IMPLEMENTED_AND_VERIFIED` | 共享物品描述器和 hover/focus 详情门通过。 |
| 全局边框、图层和最终 UI 风格 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：UI/视觉；仍需统一 StyleBox/token、层级和动态视觉门。 |
| Esc 模态优先级、居中、二次确认和焦点恢复 | `IMPLEMENTED_AND_VERIFIED` | modal focus stack、居中布局及确定/取消权威门通过。 |
| Esc 整体最终体验 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：UX/视觉；需键鼠、手柄完整人工旅程和可见截图，状态测试不能单独关闭观感反馈。 |
| 成功/失败/放弃原因、带回、损失与保存失败恢复 | `IMPLEMENTED_AND_VERIFIED` | 结果展示模型、生命周期原因、权威物品数组、重试幂等和返回保护均有测试。 |

## 特殊房型与性能

| 反馈 | 处置 | 当前证据或剩余门 |
| --- | --- | --- |
| 战斗房玩家设备掉帧已解决 | `BLOCKED_WITH_OWNER_AND_GATE` | 冻结 CPU 五轮中 15 弹幕关键分位已收敛到入口约 +3%–4.8%、max −3.2%，5 敌人改善；但 enemy1 有 +0.036–0.447 ms 残余且 headless 不能证明目标设备 GPU/FPS，owner：性能/发布验证。 |
| 怪物出现增加入场反馈 | `IMPLEMENTED_AND_VERIFIED` | arrival→anticipation→impact→recovery 及 reduced-motion 静态姿态已接入。 |
| 战斗房离开必须显式确认 | `IMPLEMENTED_AND_VERIFIED` | 触碰不发命令，显式离开确认只扣除一次。 |
| 特殊房工程信息改为玩家信息 | `IMPLEMENTED_AND_VERIFIED` | 由只读特殊房展示模型生成，不改变权威状态。 |
| 撤离点首次发现、靠近收益与目标摘要 | `IMPLEMENTED_AND_VERIFIED` | 首次通知、预计带回、携带、地面遗留和目标摘要已接入。 |
| 雷房视觉、伤害和压力反馈 | `IMPLEMENTED_AND_VERIFIED` | burst、红闪、伤害/压力/致命文案和 reduced-motion 已接入。 |
| 雷房最终视听手感 | `BLOCKED_WITH_OWNER_AND_GATE` | owner：视觉/音频；需目标设备音效、震动与人工体验签收。 |

## UE/Godot 对照与 Base

| 反馈 | 处置 | 当前证据或剩余门 |
| --- | --- | --- |
| 先分析 UE 更好原因，再决定保留或对齐 | `IMPLEMENTED_AND_VERIFIED` | 地图/搜索采用 UE 的信息层级与反馈时序，保留 Godot KnownMap、防泄漏、GroundLoot、容量与输入权威。 |
| 整体复制 UE/Lua 到 Godot | `REJECTED_WITH_EVIDENCE` | 原型不拥有当前领域、存档、许可或 Godot 消费者权威，只作为体验证据。 |
| 文档/素材长期混乱的根因 | `IMPLEMENTED_AND_VERIFIED` | 根因审计记录了目录象征性分类、复制快照、无 hash 身份、无关系/消费者登记与晋级门，以及误把 working/pending 当成可删除状态。 |
| “原始策划案”名称不变且不减少信息 | `IMPLEMENTED_AND_VERIFIED` | 25 份文件保持原 basename、原字节和原 SHA，策略为 `byte_exact_no_rename_no_reduction`。 |
| 美术重复内容去重 | `IMPLEMENTED_AND_VERIFIED` | 1407 个成员折叠为 1012 个唯一对象，395 条 alias，节省 79,256,439 bytes。 |
| 保留内容和重复来源仍需说明 | `IMPLEMENTED_AND_VERIFIED` | 完整 inventory、alias manifest、关系登记、保留理由和原路径均保留。 |
| 嵌套包/治理快照不重复提交但不得遗忘 | `IMPLEMENTED_AND_VERIFIED` | `Art.zip`、治理快照和外层 `sources.zip` 均登记排除理由，不复制入 Git。 |
| Base 入库即自动成为运行时素材 | `REJECTED_WITH_EVIDENCE` | Base 默认 `pending_verification/pending_review/not_admitted`，仍需运行时素材晋级门。 |
| Base 已形成可提交、可验证并可远端交付的仓库基线 | `IMPLEMENTED_AND_VERIFIED` | committed verifier 与 full/worktree 已通过；提交后 exact-head、push 和远端 SHA 一致性由最终交付记录证明，任一步失败则本关闭无效。 |

## 跨模块关闭门

| 范围 | 处置 | 当前证据或剩余门 |
| --- | --- | --- |
| production 真实输入主旅程 | `IMPLEMENTED_AND_VERIFIED` | 3 个 runner 的 headless/rendered 六次运行均 PASS；覆盖主链、满包真实替换、成功/失败/放弃、保存重试与空间转场，47 张 1280×720、6 组 JSON/CSV、`failures=0`。 |
| `RunScene` 职责确实下降 | `IMPLEMENTED_AND_VERIFIED` | 完成审计时为 2687 行/161 函数；模态/调试布局计算迁至纯只读模型后为 2646 行/159 函数，五分辨率独立门和既有模态/UI 回归均通过。 |
| I3 综合关闭 | `IMPLEMENTED_AND_VERIFIED` | Base、生产旅程、视觉抽查、性能复验与 full/worktree 75/75 已通过；提交后 exact-head/full、push/remote SHA 是最终外部交付门，失败不得宣称关闭。 |

本矩阵只关闭已有证据支持的内容；`BLOCKED_WITH_OWNER_AND_GATE` 不伪装为 I3 已完成，`REJECTED_WITH_EVIDENCE` 也不会因偏好而绕过现有权威。
