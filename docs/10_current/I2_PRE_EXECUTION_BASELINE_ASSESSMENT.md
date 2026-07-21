# I2 Pre-execution Baseline Assessment

文档状态：I2 启动时点事实评估；实现尚未开始，阶段关闭后冻结。
最后更新：2026-07-22

## 1. 评估结论

I2 起点具备可实施性：Godot 主路径、真实玩法/结算闭环、I1 权威边界、统一回归 runner 和生产预览均已存在。用户提出的问题大多不是“没有页面”，而是页面信息架构、视觉/动效、真实交互反馈与可扩展性没有达到玩家体验基线。

因此不建议全面推倒重写。应保留已验证的领域权威和数据路径，在视图模型、表现控制、导航转场、设置、角色替换接口和真实工作负载测量处做受控重构。I2 当前只能声明“阶段已启动、范围和门已定义”，不能声明任何体验已经改善。

## 2. 精确起点

```text
repo: resolved by git rev-parse --show-toplevel
observed worktree: E:\AGAME1\.tmp\worktrees\i2
branch: codex/i2-player-experience-refactor
head: b77132b9de655b36f71c930a35a191c383b55522
tree: 1d26f1415851755f1a8cc57f4804dfb12d9cea4d
origin/main at observation: b77132b9de655b36f71c930a35a191c383b55522
godot project: <repo>/Godot/GraytailGodot
stage: I2 ACTIVE / implementation not yet claimed
```

精确 HEAD 自动化基线：

| 字段 | 结果 |
| --- | --- |
| 报告 | `E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T193513816Z_48329748\report.json` |
| 报告 SHA-256 | `2072F1DBD067C607E82220F06DEFE15F410ED68807BFAA4EF36B5202007167E8` |
| profile/source | `full/head` |
| overall | `PASS` |
| runner | 39/39 |
| 分类 | 17 `PASS`; 22 `PASS_WITH_CLEANUP_DIAGNOSTIC`; 0 blocking |
| 时长 | 254980 ms |

这是 I2 的 entry regression baseline，不改写 I1 当时的关闭报告。报告保持未版本化，也不证明人工动态、交互手感、通用性能或 I2 实现。

## 3. 已有可保留底盘

### 程序与领域

- 生产 `main.tscn` 已可路由主菜单、Deploy、长期、局内和结果页。
- `RunStateMachine`、`RunAssetLedger`、`RunRuntimeController`/meta adapter、`SaveAdapter` 已形成必须保留的 phase、物品、terminal settlement 和安全保存权威。
- G41/M6/M7 已提供房间移动/交互、基础战斗、物品闭环、成功/失败/放弃结算、地图难度与第一批长期内容。
- combat scoped refresh 和可见页面 revision refresh 可作为后续优化的分项基础。
- I1 runner 已提供 quick/core/ui/full、worktree/head、污染守卫和隔离预览入口。

### 资源与表现

- 主菜单、Deploy、长期和局内已有大量受控 Godot 资产及生产接线，不存在“必须先从 UE 批量导入素材才能开始 I2”的前置阻塞。
- 当前动画 catalog 已覆盖角色基础状态和 reduced motion 路径，可作为可替换表现接口的起点。
- Noto Sans CJK 已用于生产字体；I2 需要解决排版与语境，而不是回退到烤字整屏图。

### 快速阅览

最新 exact HEAD 生产预览报告：

```text
E:\AGAME1\.tmp\i1\20260721T181135224Z_4a0a6ca0\preview_report.json
SHA-256: 575113D718A4E1D399FA0EB4EA6C1BE0C0E38B881348C134450E6FF43E77F9FF
source/head: head / b77132b9de655b36f71c930a35a191c383b55522
images: 27/27
machine status: PASS_WITH_VISUAL_REVIEW_REQUIRED
visual acceptance: NOT_RUN
```

三档 16:9 截图可证明现有页面容器基本保持等比、不发生明显出界；它们同时显示固定空白、信息截断、层级拥挤等问题会随分辨率一同放大。该证据不能证明动态动画、焦点、鼠标/手柄、超宽屏、DPI 或实际交互。

## 4. 分区域当前事实

### 主菜单

- 当前可见文字主要覆盖在像素场景上，环境动效和选中框依赖固定区域/锚点，存在场景与 UI 漂移风险。
- 角色拥有基础帧资源，但焦点状态存在固定帧/冻结式表现，步行动画没有形成用户要求的空间叙事。
- 页面切换当前主要是统一淡色遮罩；“进入洞口”“镜头下移”尚不是生产路由事实。
- 设置覆盖层存在，但可见选项与实际可持久化行为不足；I2 不能通过增加无效控件解决。

判断：保留主场景和已审计图层，重构文字落点、锚点、表现状态和路由转场协调；先验证离线骨骼辅助烘焙是否优于现有逐帧方案，不默认引入运行时骨骼系统。

### 出发探索

- 当前中央内容以单列卡片为主，尚未形成稳定的选择/详情双栏。
- 地图、难度和出发配置已有真实数据与 RunStartConfig；必须保留同一 Deploy 页面，不应复制 UE 的分步页面。
- 仓库存在真实库存、装备/消耗品和部分单件操作，但“拥有/使用/出勤/品质/快捷售卖”的完整玩家表达和经济规则并不都已完成。
- 右侧摘要仍含通用说明和数量化占位，未把具体配置、附加效果和本局目标作为首要信息。

判断：这是信息架构与真实命令接线的联合重构；布局可以先行，新增批量售卖等不可逆规则必须等产品/持久化门。

### 长期系统

- 当前具有目标、图鉴、研究、资历、收藏等真实内容入口，但多个模块被压进相近的卡片模板，详情和可执行状态不足。
- 当前“目标”仍承载任务、成就和委托记录，不能直接改名为天赋树。
- 导航、顶部标识、档案栏与 Deploy/主菜单的视觉和交互语言不完全统一。

判断：先分离任务档案职责，再建立天赋树的数据权威和页面；按模块数据重排，不使用一个通用模板硬套所有内容。

### 局内、特殊房与结果

- 当前 HUD、地图、背包、箱子、地面物品、协议、战斗和结果均有生产路径，但用户指出的显示真实性、靠近反馈、层级、模态、说明文案和结果解释仍需逐项验证。
- 现有战斗方向保留 60 Hz 固定步、确定性 RNG、领域事件和增量刷新；主要性能风险不能仅用 refresh 函数微基准判断。
- combat refresh 的历史 p95 是分项微基准，不是整帧 FPS、加载尖峰、内存或长局证据。
- UE 可提供攻击预警、战斗离房、雷险、协议、地图格和结算解释的概念参考；其大型 Tick/UI 权威和固定布局不是目标架构。

判断：先以权威事件和状态为内容源重构表现，再测真实 1/3/5 敌人与峰值效果；不得让动画计时、靠近 UI 或结果页重新拥有奖励/结算权威。

## 5. 素材事实与缺口

- 优先复用当前 Godot 已审计、已许可、已接线的主菜单/Deploy/长期/局内资产。
- UE `.uasset`、旧烤字页面、过程视频帧和无许可证据的音频/图片禁止直接迁入。
- 当前明确的高价值低生成方向是既有结果页空白框、协议五级状态和物品 manifest/运行绑定治理；这些仍需逐切片资产审计，不能因本评估自动接线。
- 未登记或 `replacement_needed=true` 的生产绑定属于治理债；扩大使用前必须补登记或改绑已审计输出。
- 音频目前缺少许可闭环，不应作为首批素材迁入；可先定义事件槽和验收矩阵，不能使用未知许可文件填充。

## 6. 保护状态

隔离 I2 worktree 在启动时干净。另一个主工作树 `E:\AGAME1` 的 `project.godot` 与七个 `asset_manifest.*.translation` 文件已有受保护状态；它们不属于 I2，不得被清理、覆盖或吸收。未来任何 scene/resource/metadata/import 变更都需精确 allowed-path 和 asset/project gate。

## 7. 主要决策缺口

| 决策 | 当前结论 | 阻塞范围 |
| --- | --- | --- |
| 角色动画技术 | 先做离线 rig-assisted/baked frame 与换装替换 proof；不承诺 runtime skeleton | 主菜单、Deploy、长期角色表现切片 |
| 设置字段 | 只允许真实生效和可持久化字段；字段清单需结合现有 SettingsManager/音频缺口冻结 | I2.1 |
| 快捷/批量售卖 | 属于新增经济与不可逆操作；需要价格、确认、失败、幂等和存档规则 | I2.3 仓库命令接线 |
| 出勤配置页签 | RunStartConfig 有真实意义；应先解释/重排，再决定合并或保留 | I2.3 |
| 委托/成就/等级任务分类 | 需按局内与局外生命周期冻结 taxonomy | I2.3/I2.4 |
| 天赋树 | 必须先迁移当前任务/成就职责并定义真实数据/效果权威 | I2.4 |
| 性能阈值 | 需先采集真实工作负载基线，再按目标设备冻结阈值 | I2.6 |

这些缺口不阻塞 I2.0 文档启动，但阻塞对应实现切片越过产品/工程门。

## 8. 起点评价

```text
implementation feasibility: sufficient
rewrite strategy: selective, authority-preserving
visual evidence: baseline only; review required
interaction evidence: incomplete
general performance evidence: not established
asset availability: sufficient to start without new generation
stage status: I2 ACTIVE
I2 runtime capability delta: none claimed
```
