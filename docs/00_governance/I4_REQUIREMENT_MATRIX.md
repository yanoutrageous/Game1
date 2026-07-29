# I4 需求矩阵

文档状态：`ACTIVE`

状态值：

- `NOT_STARTED`
- `IMPLEMENTING`
- `TARGETED_PASS`
- `PRODUCTION_PASS`
- `IMPLEMENTED_AND_VERIFIED`
- `REJECTED_WITH_EVIDENCE`
- `EXPLICITLY_DEFERRED`

| ID | 必须结果 | 当前状态 | 证明要求 |
| --- | --- | --- | --- |
| I4-R001 | I4 入口 commit/tree、远端、工具链、dirty 和 I3R 开放反馈可追溯 | `IMPLEMENTING` | 入口报告、台账、Git 证据 |
| I4-R002 | Base 治理验证跨 Windows/Linux 换行稳定，真实内容漂移仍失败 | `TARGETED_PASS` | 单元测试、overlay verify、exact-head |
| I4-R003 | debug/editor-only 测试场从设置主菜单入口进入 | `NOT_STARTED` | 生产路由 runner、release 隐藏门 |
| I4-R004 | 测试场强制使用独立 `dev_sandbox` profile 并在退出后恢复 | `NOT_STARTED` | 前后 profile/save hash |
| I4-R005 | 第一个写命令 taint 会话，tainted 会话不能写默认档结算 | `NOT_STARTED` | 命令、结算、保存失败路径测试 |
| I4-R006 | 诊断面板分离只读状态与写命令并显示 profile/scenario/seed/save target | `NOT_STARTED` | 生产截图、焦点/输入 runner |
| I4-R007 | 固定场景目录覆盖房型、战斗、满包、重复物品、终局和保存失败 | `NOT_STARTED` | 场景 manifest 与重复报告 |
| I4-R008 | 失败包包含完整复现身份和前后保存证据 | `NOT_STARTED` | 人工注入失败 probe |
| I4-R009 | 携带卡使用 `− 已携带/持有 +` 且修改可撤销草稿 | `NOT_STARTED` | Deploy 生产 runner |
| I4-R010 | N 件购买预检总价、生成 N 个不同实例、一次保存、失败全回滚 | `NOT_STARTED` | 领域单元/集成/失败注入 |
| I4-R011 | 待售数量稳定映射精确可售实例并一次原子提交 | `NOT_STARTED` | batch sale 集成、幂等/回滚 |
| I4-R012 | 同一物品卡一次只显示一种数量语义 | `NOT_STARTED` | 投影测试和视觉检查 |
| I4-R013 | 普通卡只保留名称与类别/价格/数量两行，不显示玩家 T 码 | `NOT_STARTED` | 生产截图、文案扫描 |
| I4-R014 | 普通 Deploy 页为 310/12/310，地图页继续 198/424 | `NOT_STARTED` | 几何合同、分辨率矩阵 |
| I4-R015 | 详情与摘要可滚动且不再截断为四行 | `NOT_STARTED` | 超长 fixture、滚动可达测试 |
| I4-R016 | 速览/携带/本局/目标内容严格按语义分栏 | `NOT_STARTED` | model 投影测试 |
| I4-R017 | 金币只在交易上下文出现，动作区显示总价/收益/交易后余额 | `NOT_STARTED` | Deploy 各页生产矩阵 |
| I4-R018 | 快速出售支持全选可售/清空/一次确认 | `NOT_STARTED` | 局外生产旅程 |
| I4-R019 | 局内重复可堆叠物品紧凑聚合，底层精确实例不变 | `NOT_STARTED` | ledger/投影/截图测试 |
| I4-R020 | 使用/丢弃只消费一个确定实例，重量与结算按实例正确 | `NOT_STARTED` | 使用/丢弃/成功/失败 runner |
| I4-R021 | 长期通知直达具体页/卡，打开模块不提前清未读 | `NOT_STARTED` | 长期系统生产旅程 |
| I4-R022 | Back 使用页面历史；筛选、滚动、选中状态可恢复 | `NOT_STARTED` | 键鼠/手柄导航 runner |
| I4-R023 | display/readable 字体角色分离；正文使用可读 CJK 与 AA | `NOT_STARTED` | 字体策略测试、视觉矩阵 |
| I4-R024 | 品质、焦点和选中视觉通道分离且颜色有冗余 | `NOT_STARTED` | 静态规则与人工复核 |
| I4-R025 | 四分辨率×三 UI 比例无文字遮挡、裁切或不可达区域 | `NOT_STARTED` | 几何报告、12 组动态截图 |
| I4-R026 | 关键 runner 等待语义状态/信号，不依赖固定帧证明正确性 | `NOT_STARTED` | runner 静态门与重复运行 |
| I4-R027 | 关键场景 10 连过（至少 3 个新进程），局外旅程 3 连过 | `NOT_STARTED` | repetition report |
| I4-R028 | 旧档兼容，sandbox 前后默认档语义哈希一致 | `NOT_STARTED` | save fixture 与污染门 |
| I4-R029 | worktree/full、exact-head/full、远端 SHA 和最终审计一致 | `NOT_STARTED` | 最终报告、commit、push proof |
| I4-R030 | 最终 diff 无未知 dirty 或未授权 Godot metadata | `NOT_STARTED` | status、diff、metadata gate |
